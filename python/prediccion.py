import argparse
import json
import math
from datetime import datetime, timezone
from typing import Dict, Iterable, List, Optional, Sequence, Tuple

from nada import AppTorneosClient


def prob_victoria_elo(elo_a: float, elo_b: float, scale: float = 400.0) -> float:
    """Probabilidad de victoria según Elo (expected score).

    Fórmula estándar:
      P(A gana) = 1 / (1 + 10^((Elo_B - Elo_A)/scale))

    `scale=400` es el valor típico en Elo clásico.
    """

    elo_a = float(elo_a)
    elo_b = float(elo_b)
    scale = float(scale)
    if scale <= 0:
        raise ValueError("scale debe ser > 0")
    return 1.0 / (1.0 + 10.0 ** ((elo_b - elo_a) / scale))


def _clamp01(x: float) -> float:
    return max(0.0, min(1.0, x))


def _fmt_pct(p: float) -> str:
    return f"{100.0 * _clamp01(p):.2f}%"


def _parse_iso_datetime(value: Optional[str]) -> Optional[datetime]:
    if value is None:
        return None
    s = str(value).strip()
    if not s:
        return None
    # Acepta "YYYY-MM-DDTHH:MM:SS" con o sin zona horaria (Z / +HH:MM)
    # datetime.fromisoformat no acepta 'Z', lo normalizamos.
    if s.endswith("Z"):
        s = s[:-1] + "+00:00"
    try:
        return datetime.fromisoformat(s)
    except ValueError as exc:
        raise ValueError(
            "--fecha debe ser ISO-8601, ej: 2026-05-18T20:30:00 o 2026-05-18T20:30:00Z"
        ) from exc


def _to_aware_utc(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        # Si no hay tz, asumimos hora local del sistema y la convertimos a UTC
        return dt.astimezone(timezone.utc)
    return dt.astimezone(timezone.utc)


def _try_parse_api_datetime(value: object) -> Optional[datetime]:
    if value is None:
        return None
    s = str(value).strip()
    if not s:
        return None
    if s.endswith("Z"):
        s = s[:-1] + "+00:00"
    try:
        return datetime.fromisoformat(s)
    except ValueError:
        return None


def elo_en_fecha(historial_payload: Dict, cutoff: datetime) -> float:
    """Devuelve el Elo más reciente <= cutoff.

    historial_payload esperado desde la API:
      { equipo: { elo_actual, ... }, historial: [{creado_en, elo_nuevo, ...}, ...] }
    """

    equipo = historial_payload.get("equipo") or {}
    historial = historial_payload.get("historial") or []

    cutoff_utc = _to_aware_utc(cutoff)

    ultimo_elo: Optional[float] = None
    for item in historial:
        creado = _try_parse_api_datetime((item or {}).get("creado_en"))
        if creado is None:
            continue
        if _to_aware_utc(creado) <= cutoff_utc:
            if (item or {}).get("elo_nuevo") is not None:
                try:
                    ultimo_elo = float(item.get("elo_nuevo"))
                except (TypeError, ValueError):
                    continue

    if ultimo_elo is not None:
        return float(ultimo_elo)
    return float(equipo.get("elo_actual", 0) or 0)


def prob_ganar_multiequipo(elos: Sequence[float], scale: float = 400.0) -> List[float]:
    """Probabilidad de ganar para N equipos usando Bradley-Terry compatible con Elo.

    Usamos fuerza_i = 10^(elo_i/scale), entonces:
      P(i gana) = fuerza_i / sum_j fuerza_j
    Para N=2 coincide exactamente con Elo expected score.
    """

    scale = float(scale)
    if scale <= 0:
        raise ValueError("scale debe ser > 0")

    # Para estabilidad numérica, trabajamos en log-espacio.
    # log(fuerza) = ln(10) * elo/scale
    logs = [(math.log(10.0) * float(e) / scale) for e in elos]
    m = max(logs) if logs else 0.0
    ws = [math.exp(z - m) for z in logs]
    s = sum(ws) or 1.0
    return [w / s for w in ws]


def prediccion_duelo_por_equipos(
    client: AppTorneosClient,
    id_equipo_a: int,
    id_equipo_b: int,
    cutoff: Optional[datetime] = None,
    scale: float = 400.0,
) -> Dict:
    cutoff = cutoff or datetime.now(timezone.utc)

    hist_a = client.obtener_elo_historial_equipo(id_equipo_a)
    hist_b = client.obtener_elo_historial_equipo(id_equipo_b)

    if not hist_a or not hist_b:
        raise RuntimeError("No se pudieron obtener ambos historiales de Elo desde la API")

    elo_a = elo_en_fecha(hist_a, cutoff)
    elo_b = elo_en_fecha(hist_b, cutoff)

    p_a = prob_victoria_elo(elo_a, elo_b, scale=scale)
    p_b = 1.0 - p_a

    return {
        "metodo": "elo_expected_score",
        "scale": scale,
        "cutoff": cutoff.isoformat(),
        "delta_elo": elo_a - elo_b,
        "equipo_a": {
            "id_equipo": int((hist_a.get("equipo") or {}).get("id_equipo")),
            "nombre": (hist_a.get("equipo") or {}).get("nombre"),
            "elo": elo_a,
            "probabilidad_victoria": round(p_a, 4),
        },
        "equipo_b": {
            "id_equipo": int((hist_b.get("equipo") or {}).get("id_equipo")),
            "nombre": (hist_b.get("equipo") or {}).get("nombre"),
            "elo": elo_b,
            "probabilidad_victoria": round(p_b, 4),
        },
    }


def prediccion_partido_por_equipos(
    client: AppTorneosClient,
    ids_equipos: Sequence[int],
    cutoff: Optional[datetime] = None,
    scale: float = 400.0,
) -> Dict:
    ids = [int(x) for x in ids_equipos]
    if len(ids) < 2:
        raise ValueError("Se requieren al menos 2 equipos")

    cutoff = cutoff or datetime.now(timezone.utc)

    historiales = [client.obtener_elo_historial_equipo(i) for i in ids]
    if any(h is None for h in historiales):
        raise RuntimeError("No se pudo obtener el historial de Elo de uno o más equipos")

    equipos = []
    for h in historiales:
        equipo = (h or {}).get("equipo") or {}
        equipos.append(
            {
                "id_equipo": int(equipo.get("id_equipo")),
                "nombre": equipo.get("nombre"),
                "elo": elo_en_fecha(h, cutoff),
            }
        )

    elos = [e["elo"] for e in equipos]

    if len(equipos) == 2:
        p0 = prob_victoria_elo(elos[0], elos[1], scale=scale)
        probs = [p0, 1.0 - p0]
        metodo = "elo_expected_score"
    else:
        probs = prob_ganar_multiequipo(elos, scale=scale)
        metodo = "elo_bradley_terry_multiequipo"

    for e, p in zip(equipos, probs):
        e["probabilidad_victoria"] = round(float(p), 4)

    return {
        "metodo": metodo,
        "scale": float(scale),
        "cutoff": cutoff.isoformat(),
        "equipos": equipos,
    }


# --- Opcional: calibración con históricos ---
# Si más adelante exportas tus partidos históricos a una lista (elo_a_pre, elo_b_pre, y),
# puedes ajustar "beta" para que las probabilidades estén mejor calibradas.
#
# Modelo: P(A gana) = sigmoid(beta * (elo_a - elo_b))
# (esto es equivalente a Bradley-Terry / logística sobre diferencias de rating)

def _sigmoid(z: float) -> float:
    if z >= 0:
        ez = math.exp(-z)
        return 1.0 / (1.0 + ez)
    ez = math.exp(z)
    return ez / (1.0 + ez)


def fit_beta_logistica(
    samples: Iterable[Tuple[float, float, int]],
    beta_init: float = math.log(10.0) / 400.0,
    lr: float = 0.01,
    steps: int = 2000,
) -> float:
    """Ajusta beta con descenso de gradiente (sin dependencias).

    samples: (elo_a, elo_b, y) donde y=1 si gana A, y=0 si gana B
    """

    data: List[Tuple[float, float, int]] = []
    for elo_a, elo_b, y in samples:
        y = int(y)
        if y not in (0, 1):
            continue
        data.append((float(elo_a), float(elo_b), y))

    if not data:
        raise ValueError("No hay samples válidos")

    beta = float(beta_init)

    for _ in range(int(steps)):
        grad = 0.0
        for elo_a, elo_b, y in data:
            x = (elo_a - elo_b)
            p = _sigmoid(beta * x)
            # gradiente de log-loss w.r.t beta: (p - y) * x
            grad += (p - y) * x
        grad /= len(data)
        beta -= float(lr) * grad

    return beta


def prob_victoria_calibrada(elo_a: float, elo_b: float, beta: float) -> float:
    return _sigmoid(float(beta) * (float(elo_a) - float(elo_b)))


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Predicción de victoria usando Elo (2+ equipos) con historial hasta una fecha",
    )

    parser.add_argument("--base-url", default="http://localhost:3000/api/v1")
    parser.add_argument("--timeout", type=int, default=10)

    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "--equipos",
        nargs="+",
        type=int,
        metavar="ID_EQUIPO",
        help="IDs de los equipos en la API (2 o más)",
    )
    group.add_argument(
        "--elos",
        nargs="+",
        type=float,
        metavar="ELO",
        help="Elo directos (sin llamar a la API) (2 o más)",
    )

    parser.add_argument(
        "--scale",
        type=float,
        default=400.0,
        help="Parámetro de escala del Elo (por defecto 400)",
    )

    parser.add_argument(
        "--fecha",
        default=None,
        help="Fecha/hora ISO-8601 para cortar el historial (por defecto: ahora). Ej: 2026-05-18T20:30:00Z",
    )

    parser.add_argument(
        "--json",
        action="store_true",
        help="Imprime la salida en JSON (útil para integración con backend)",
    )

    args = parser.parse_args()

    cutoff = _parse_iso_datetime(args.fecha)
    if cutoff is not None:
        cutoff = _to_aware_utc(cutoff)

    if args.elos:
        if len(args.elos) < 2:
            raise SystemExit("--elos requiere 2 o más valores")

        elos = [float(x) for x in args.elos]
        if len(elos) == 2:
            p_a = prob_victoria_elo(elos[0], elos[1], scale=args.scale)
            p_b = 1.0 - p_a

            if args.json:
                payload = {
                    "metodo": "elo_expected_score",
                    "scale": float(args.scale),
                    "equipos": [
                        {"idx": 0, "elo": float(elos[0]), "probabilidad_victoria": round(float(p_a), 4)},
                        {"idx": 1, "elo": float(elos[1]), "probabilidad_victoria": round(float(p_b), 4)},
                    ],
                }
                print(json.dumps(payload, ensure_ascii=False))
            else:
                print(
                    f"Equipo A: {_fmt_pct(p_a)} | Equipo B: {_fmt_pct(p_b)} "
                    f"(deltaElo={elos[0]-elos[1]:.1f})"
                )
            return 0

        probs = prob_ganar_multiequipo(elos, scale=args.scale)

        if args.json:
            payload = {
                "metodo": "elo_bradley_terry_multiequipo",
                "scale": float(args.scale),
                "equipos": [
                    {
                        "idx": int(i),
                        "elo": float(elos[i]),
                        "probabilidad_victoria": round(float(p), 4),
                    }
                    for i, p in enumerate(probs)
                ],
            }
            print(json.dumps(payload, ensure_ascii=False))
        else:
            partes = [f"E{i+1}: {_fmt_pct(p)}" for i, p in enumerate(probs)]
            print(" | ".join(partes))
        return 0

    if len(args.equipos) < 2:
        raise SystemExit("--equipos requiere 2 o más IDs")

    client = AppTorneosClient(base_url=args.base_url, timeout=args.timeout)
    pred = prediccion_partido_por_equipos(client, args.equipos, cutoff=cutoff, scale=args.scale)

    equipos = pred["equipos"]
    if len(equipos) == 2:
        a, b = equipos
        if args.json:
            print(json.dumps(pred, ensure_ascii=False))
        else:
            print(
                f"{a['nombre']} (Elo {a['elo']:.0f}): {_fmt_pct(a['probabilidad_victoria'])} | "
                f"{b['nombre']} (Elo {b['elo']:.0f}): {_fmt_pct(b['probabilidad_victoria'])}"
            )
        return 0

    # Multi-equipo: imprimimos ordenado por probabilidad desc
    if args.json:
        print(json.dumps(pred, ensure_ascii=False))
    else:
        equipos_sorted = sorted(equipos, key=lambda e: e["probabilidad_victoria"], reverse=True)
        for e in equipos_sorted:
            print(f"{e['nombre']} (Elo {e['elo']:.0f}): {_fmt_pct(e['probabilidad_victoria'])}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
