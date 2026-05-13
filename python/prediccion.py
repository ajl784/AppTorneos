import argparse
import math
from typing import Dict, Iterable, List, Tuple

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


def prediccion_duelo_por_equipos(
    client: AppTorneosClient,
    id_equipo_a: int,
    id_equipo_b: int,
    scale: float = 400.0,
) -> Dict:
    equipo_a = client.obtener_equipo(id_equipo_a)
    equipo_b = client.obtener_equipo(id_equipo_b)

    if not equipo_a or not equipo_b:
        raise RuntimeError("No se pudieron obtener ambos equipos desde la API")

    elo_a = float(equipo_a.get("elo", 0) or 0)
    elo_b = float(equipo_b.get("elo", 0) or 0)

    p_a = prob_victoria_elo(elo_a, elo_b, scale=scale)
    p_b = 1.0 - p_a

    return {
        "metodo": "elo_expected_score",
        "scale": scale,
        "delta_elo": elo_a - elo_b,
        "equipo_a": {
            "id_equipo": int(equipo_a.get("id_equipo")),
            "nombre": equipo_a.get("nombre"),
            "elo": elo_a,
            "probabilidad_victoria": round(p_a, 4),
        },
        "equipo_b": {
            "id_equipo": int(equipo_b.get("id_equipo")),
            "nombre": equipo_b.get("nombre"),
            "elo": elo_b,
            "probabilidad_victoria": round(p_b, 4),
        },
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
        description="Predicción 1v1 (probabilidad de victoria) usando Elo",
    )

    parser.add_argument("--base-url", default="http://localhost:3000/api/v1")
    parser.add_argument("--timeout", type=int, default=10)

    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "--equipos",
        nargs=2,
        type=int,
        metavar=("ID_EQUIPO_A", "ID_EQUIPO_B"),
        help="IDs de los equipos en la API",
    )
    group.add_argument(
        "--elos",
        nargs=2,
        type=float,
        metavar=("ELO_A", "ELO_B"),
        help="Elo directos (sin llamar a la API)",
    )

    parser.add_argument(
        "--scale",
        type=float,
        default=400.0,
        help="Parámetro de escala del Elo (por defecto 400)",
    )

    args = parser.parse_args()

    if args.elos:
        elo_a, elo_b = args.elos
        p_a = prob_victoria_elo(elo_a, elo_b, scale=args.scale)
        p_b = 1.0 - p_a
        print(f"Equipo A: {_fmt_pct(p_a)} | Equipo B: {_fmt_pct(p_b)} (deltaElo={elo_a-elo_b:.1f})")
        return 0

    id_a, id_b = args.equipos
    client = AppTorneosClient(base_url=args.base_url, timeout=args.timeout)
    pred = prediccion_duelo_por_equipos(client, id_a, id_b, scale=args.scale)

    a = pred["equipo_a"]
    b = pred["equipo_b"]

    print(
        f"{a['nombre']} (Elo {a['elo']:.0f}): {_fmt_pct(a['probabilidad_victoria'])} | "
        f"{b['nombre']} (Elo {b['elo']:.0f}): {_fmt_pct(b['probabilidad_victoria'])}"
    )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
