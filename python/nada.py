import json
from urllib import error, parse, request


class AppTorneosClient:
	def __init__(self, base_url="http://localhost:3000/api/v1", timeout=10):
		self.base_url = base_url.rstrip("/")
		self.timeout = timeout

	def _url(self, path, query=None):
		qs = ""
		if query:
			clean_query = {k: v for k, v in query.items() if v is not None}
			encoded = parse.urlencode(clean_query)
			qs = f"?{encoded}" if encoded else ""
		return f"{self.base_url}/{path.lstrip('/')}" + qs

	def _request(self, method, path, payload=None, query=None):
		url = self._url(path, query=query)
		body = None
		headers = {"Accept": "application/json"}

		if payload is not None:
			body = json.dumps(payload).encode("utf-8")
			headers["Content-Type"] = "application/json"

		req = request.Request(url, data=body, headers=headers, method=method)

		try:
			with request.urlopen(req, timeout=self.timeout) as resp:
				raw = resp.read().decode("utf-8")
				if not raw:
					return None
				return json.loads(raw)
		except error.HTTPError as exc:
			detail = exc.read().decode("utf-8")
			try:
				parsed = json.loads(detail) if detail else None
			except json.JSONDecodeError:
				parsed = detail
			raise RuntimeError(f"HTTP {exc.code}: {parsed}") from exc
		except error.URLError as exc:
			raise RuntimeError(f"No se pudo conectar con API: {exc.reason}") from exc

	def health(self):
		return self._request("GET", "../health")

	def listar_usuarios(self, limit=50, offset=0, q=None):
		return self._request("GET", "/usuarios", query={"limit": limit, "offset": offset, "q": q})

	def crear_usuario(self, correo, nombre_usuario, password):
		return self._request(
			"POST",
			"/usuarios",
			payload={
				"correo": correo,
				"nombre_usuario": nombre_usuario,
				"password": password,
			},
		)

	def listar_equipos(self, limit=50, offset=0, nombre=None):
		return self._request(
			"GET",
			"/equipos",
			query={"limit": limit, "offset": offset, "nombre": nombre},
		)

	def obtener_equipo(self, id_equipo):
		return self._request("GET", f"/equipos/{id_equipo}")

	def crear_equipo(self, nombre, descripcion=None, elo=1200):
		return self._request(
			"POST",
			"/equipos",
			payload={"nombre": nombre, "descripcion": descripcion, "elo": elo},
		)

	def listar_torneos(self, limit=50, offset=0, estado=None):
		return self._request(
			"GET",
			"/torneos",
			query={"limit": limit, "offset": offset, "estado": estado},
		)

	def crear_torneo(
		self,
		nombre,
		id_categoria,
		id_tipo_torneo,
		descripcion=None,
		fecha_inicio=None,
		fecha_fin=None,
		estado="planificado",
		id_organizador=None,
	):
		return self._request(
			"POST",
			"/torneos",
			payload={
				"nombre": nombre,
				"descripcion": descripcion,
				"fecha_inicio": fecha_inicio,
				"fecha_fin": fecha_fin,
				"estado": estado,
				"id_categoria": id_categoria,
				"id_tipo_torneo": id_tipo_torneo,
				"id_organizador": id_organizador,
			},
		)

	def obtener_formulario_torneo(self, id_torneo):
		return self._request("GET", f"/torneos/{id_torneo}/formulario")

	def actualizar_formulario_torneo(self, id_torneo, formulario):
		return self._request(
			"PUT",
			f"/torneos/{id_torneo}/formulario",
			payload={"formulario": formulario},
		)

	def listar_solicitudes_torneo(self, id_torneo, estado=None):
		return self._request(
			"GET",
			f"/torneos/{id_torneo}/solicitudes",
			query={"estado": estado},
		)

	def crear_solicitud_torneo(self, id_torneo, id_equipo, respuesta):
		return self._request(
			"POST",
			f"/torneos/{id_torneo}/solicitudes",
			payload={"id_equipo": id_equipo, "respuesta": respuesta},
		)

	def decidir_solicitud(self, id_participacion_equipo, aceptar):
		return self._request(
			"PATCH",
			f"/participaciones/{id_participacion_equipo}/decision",
			payload={"aceptar": bool(aceptar)},
		)

	def listar_partidos(self, limit=50, offset=0, torneo_id=None, estado=None):
		return self._request(
			"GET",
			"/partidos",
			query={
				"limit": limit,
				"offset": offset,
				"torneoId": torneo_id,
				"estado": estado,
			},
		)

	def crear_partido(self, id_torneo, fecha_hora, lugar=None, estado="planificado"):
		return self._request(
			"POST",
			"/partidos",
			payload={
				"id_torneo": id_torneo,
				"fecha_hora": fecha_hora,
				"lugar": lugar,
				"estado": estado,
			},
		)

	def registrar_puntuaciones_partido(self, id_partido, puntuaciones, id_arbitro_torneo=None, acta=None):
		return self._request(
			"POST",
			f"/partidos/{id_partido}/puntuaciones",
			payload={
				"id_arbitro_torneo": id_arbitro_torneo,
				"acta": acta,
				"puntuaciones": puntuaciones,
			},
		)

	def listar_participaciones(self, limit=50, offset=0, torneo_id=None, equipo_id=None, estado=None):
		return self._request(
			"GET",
			"/participaciones",
			query={
				"limit": limit,
				"offset": offset,
				"torneoId": torneo_id,
				"equipoId": equipo_id,
				"estado": estado,
			},
		)

	def crear_participacion(self, id_torneo, id_equipo, respuesta=None, estado="pendiente", puntuacion=0):
		return self._request(
			"POST",
			"/participaciones",
			payload={
				"id_torneo": id_torneo,
				"id_equipo": id_equipo,
				"respuesta": respuesta,
				"estado": estado,
				"puntuacion": puntuacion,
			},
		)


if __name__ == "__main__":
	client = AppTorneosClient()
	print("Health:")
	print(json.dumps(client.health(), indent=2, ensure_ascii=False))

	print("\nTorneos:")
	print(json.dumps(client.listar_torneos(limit=5), indent=2, ensure_ascii=False))
