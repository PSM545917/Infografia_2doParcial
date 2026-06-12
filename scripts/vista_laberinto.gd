class_name VistaLaberinto
extends Node2D

# Dibuja un Laberinto con _draw(): rejilla tenue, paredes, inicio y metas.
#
# La "vista de dios" (el laberinto real completo) ya viene configurada desde
# game.gd. Para la mecánica M2 puedes reutilizar esta misma clase sobre el
# nodo "vista_mapa_raton": mantén un Laberinto.vacio() con las paredes que tu
# cerebro va descubriendo, llama configurar() una vez y queue_redraw() cada
# vez que aprendas algo. Lo que esta vista NO hace (y te toca a ti) es
# distinguir celdas visitadas / no visitadas — puedes extender esta clase o
# dibujar encima desde otro nodo.

var laberinto: Laberinto = null
var origen := Vector2.ZERO
var tam := 32.0

# Propiedades para el mapa del ratón (M2 / Rutas / Heat-map)
var mostrar_visitadas: bool = false
var mostrar_rutas: bool = false
var mostrar_heatmap: bool = false
var conteo_visitas: Dictionary = {}
var ruta_exploracion: Array[Vector2i] = []
var ruta_speed_run: Array[Vector2i] = []

@export var color_paredes := Color(0.92, 0.92, 0.95)
@export var color_rejilla := Color(0.22, 0.22, 0.28)
@export var color_meta := Color(0.25, 0.65, 0.30, 0.45)
@export var color_inicio := Color(0.25, 0.45, 0.85, 0.45)
@export var grosor_pared := 3.0


func configurar(laberinto_: Laberinto, origen_: Vector2, tam_: float) -> void:
	laberinto = laberinto_
	origen = origen_
	tam = tam_
	queue_redraw()


func celda_a_pixel(celda: Vector2i) -> Vector2:
	# centro de la celda en píxeles
	return origen + (Vector2(celda) + Vector2(0.5, 0.5)) * tam


func _draw() -> void:
	if laberinto == null:
		return

	# 1. Celdas visitadas y heat-map (abajo de todo)
	if mostrar_visitadas and not conteo_visitas.is_empty():
		var max_visitas := 1
		if mostrar_heatmap:
			for v in conteo_visitas.values():
				if v > max_visitas:
					max_visitas = v

		for celda in conteo_visitas:
			if not laberinto.en_rango(celda):
				continue
			var rect = Rect2(origen + Vector2(celda) * tam, Vector2(tam, tam))
			if mostrar_heatmap:
				var visitas = conteo_visitas[celda]
				# Interpolar color: desde un celeste/azul suave (pocas visitas)
				# hasta un rojo cálido/vibrante (muchas visitas).
				var ratio = float(visitas - 1) / maxf(1.0, float(max_visitas - 1))
				var color_heat = Color(0.12, 0.35, 0.65, 0.22).lerp(Color(0.95, 0.25, 0.2, 0.45), ratio)
				draw_rect(rect, color_heat)
			else:
				draw_rect(rect, Color(0.12, 0.35, 0.65, 0.22))

	# 2. rejilla tenue de fondo
	for col in laberinto.ancho + 1:
		draw_line(origen + Vector2(col * tam, 0),
				origen + Vector2(col * tam, laberinto.alto * tam), color_rejilla, 1.0)
	for fila in laberinto.alto + 1:
		draw_line(origen + Vector2(0, fila * tam),
				origen + Vector2(laberinto.ancho * tam, fila * tam), color_rejilla, 1.0)

	# 3. inicio y metas
	var rect_inicio = Rect2(origen + Vector2(laberinto.inicio) * tam, Vector2(tam, tam))
	draw_rect(rect_inicio, color_inicio)
	for meta in laberinto.metas:
		draw_rect(Rect2(origen + Vector2(meta) * tam, Vector2(tam, tam)), color_meta)

	# 4. Dibujar rutas (debajo de las paredes para que no sobresalgan de los bordes)
	if mostrar_rutas:
		if ruta_exploracion.size() > 1:
			var puntos: PackedVector2Array = []
			for celda in ruta_exploracion:
				puntos.append(celda_a_pixel(celda))
			draw_polyline(puntos, Color(0.95, 0.55, 0.1, 0.45), 2.0)
		if ruta_speed_run.size() > 1:
			var puntos: PackedVector2Array = []
			for celda in ruta_speed_run:
				puntos.append(celda_a_pixel(celda))
			draw_polyline(puntos, Color(0.0, 0.85, 0.95, 0.8), 4.5)

	# 5. paredes
	for fila in laberinto.alto:
		for col in laberinto.ancho:
			var celda = Vector2i(col, fila)
			var esquina = origen + Vector2(celda) * tam
			if laberinto.tiene_pared(celda, Laberinto.NORTE):
				draw_line(esquina, esquina + Vector2(tam, 0), color_paredes, grosor_pared)
			if laberinto.tiene_pared(celda, Laberinto.OESTE):
				draw_line(esquina, esquina + Vector2(0, tam), color_paredes, grosor_pared)
			# bordes sur y este solo en la última fila / columna
			if fila == laberinto.alto - 1 and laberinto.tiene_pared(celda, Laberinto.SUR):
				draw_line(esquina + Vector2(0, tam), esquina + Vector2(tam, tam),
						color_paredes, grosor_pared)
			if col == laberinto.ancho - 1 and laberinto.tiene_pared(celda, Laberinto.ESTE):
				draw_line(esquina + Vector2(tam, 0), esquina + Vector2(tam, tam),
						color_paredes, grosor_pared)
