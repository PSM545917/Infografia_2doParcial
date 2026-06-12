extends Node2D

@export_file("*.maz") var archivo_laberinto: String = "res://mazes/01_entrenamiento.maz"
@export var usar_cerebro_estudiante: bool = true

const ORIGEN := Vector2(28, 44)
const FASE_EXPLORANDO := "EXPLORANDO"
const FASE_META := "META"
const FASE_VOLVIENDO := "VOLVIENDO"
const FASE_SPEED_RUN := "SPEED_RUN"
const FASE_FIN := "FIN"

var tam_celda := 38.0
var laberinto: Laberinto
var cerebro = null
var fase := FASE_EXPLORANDO
var tiempo := 0.0
var visitadas := {}
var pausado := false
var velocidades := [1.0, 2.0, 4.0]
var indice_velocidad := 0
var wait_time_base := 0.12
var duracion_paso_base := 0.10

signal pasos_cambiados(pasos: int)
signal visitadas_cambiadas(cantidad: int)
signal tiempo_cambiado(segundos: float)
signal fase_cambiada(nombre: String)
signal corrida_terminada(exito: bool, pasos: int, tiempo_final: float, visitadas_final: int)

@onready var vista_dios: VistaLaberinto = $vista_dios
@onready var vista_mapa_raton: VistaLaberinto = $vista_mapa_raton
@onready var raton: Raton = $raton
@onready var paso_timer: Timer = $paso_timer
@onready var boton_pausa: Button = $ui/hud/margen/columna/botones/boton_pausa
@onready var boton_velocidad: Button = $ui/hud/margen/columna/botones/boton_velocidad
@onready var panel_final: PanelContainer = $ui/panel_final
@onready var resultado_label: Label = $ui/panel_final/margen/columna/resultado_label
@onready var detalle_resultado_label: Label = $ui/panel_final/margen/columna/detalle_resultado_label
@onready var sonido_paso: AudioStreamPlayer = $sonido_paso
@onready var sonido_choque: AudioStreamPlayer = $sonido_choque
@onready var sonido_meta: AudioStreamPlayer = $sonido_meta


func _ready() -> void:
	wait_time_base = paso_timer.wait_time
	duracion_paso_base = raton.duracion_paso
	raton.paso_terminado.connect(_on_raton_paso_terminado)
	raton.choque.connect(_on_raton_choque)
	_iniciar_corrida()
	_emitir_telemetria()


func _process(delta: float) -> void:
	if not pausado and not paso_timer.is_stopped():
		tiempo += delta
		tiempo_cambiado.emit(tiempo)


func _iniciar_corrida() -> void:
	panel_final.hide()
	laberinto = Laberinto.desde_archivo(archivo_laberinto)
	tam_celda = minf(56.0, 608.0 / maxf(laberinto.ancho, laberinto.alto))
	vista_dios.configurar(laberinto, ORIGEN, tam_celda)
	raton.configurar(laberinto, ORIGEN, tam_celda)
	fase = FASE_EXPLORANDO
	tiempo = 0.0
	visitadas = {}
	visitadas[raton.celda] = true
	pausado = false
	paso_timer.paused = false
	paso_timer.wait_time = wait_time_base / velocidades[indice_velocidad]
	raton.duracion_paso = duracion_paso_base / velocidades[indice_velocidad]
	boton_pausa.text = "Pausa"
	boton_velocidad.text = "Vel x%d" % int(velocidades[indice_velocidad])
	if usar_cerebro_estudiante:
		cerebro = CerebroEstudiante.new()
		cerebro.preparar(laberinto.ancho, laberinto.alto, laberinto.metas, laberinto.inicio)
		vista_mapa_raton.configurar(cerebro.mapa_del_raton(), ORIGEN, tam_celda)
		vista_mapa_raton.mostrar_visitadas = true
		vista_mapa_raton.mostrar_rutas = true
		vista_mapa_raton.mostrar_heatmap = true
		_actualizar_vista_raton()
	else:
		cerebro = CerebroWallFollower.new()
		vista_mapa_raton.configurar(null, ORIGEN, tam_celda)
	paso_timer.start()


func _on_paso_timer_timeout() -> void:
	_ejecutar_paso()


func _ejecutar_paso() -> void:
	if raton.ocupado():
		return
	if fase == FASE_FIN:
		return
	cerebro.paso(raton)
	if usar_cerebro_estudiante:
		fase = cerebro.fase
	visitadas[raton.celda] = true
	_emitir_telemetria()
	_actualizar_vista_raton()
	
	if usar_cerebro_estudiante:
		if fase == FASE_META:
			if not sonido_meta.playing:
				sonido_meta.play()
		elif fase == FASE_FIN:
			_terminar_corrida(true)
	else:
		if laberinto.es_meta(raton.celda):
			_meta_alcanzada()


func _emitir_telemetria() -> void:
	fase_cambiada.emit(fase)
	pasos_cambiados.emit(raton.pasos)
	visitadas_cambiadas.emit(visitadas.size())
	tiempo_cambiado.emit(tiempo)


func _actualizar_vista_raton() -> void:
	if usar_cerebro_estudiante and cerebro != null:
		vista_mapa_raton.conteo_visitas = cerebro.conteo_visitas
		vista_mapa_raton.ruta_exploracion = cerebro.ruta_exploracion
		if cerebro.has_method("ruta_speed_run"):
			var ruta_sr = cerebro.ruta_speed_run()
			if ruta_sr is Array:
				# Convert to Typed Array if necessary
				var typed_ruta: Array[Vector2i] = []
				for c in ruta_sr:
					typed_ruta.append(Vector2i(c))
				vista_mapa_raton.ruta_speed_run = typed_ruta
		else:
			vista_mapa_raton.ruta_speed_run = []
		vista_mapa_raton.queue_redraw()


func _meta_alcanzada() -> void:
	fase = FASE_META
	_terminar_corrida(true)


func _terminar_corrida(exito: bool) -> void:
	paso_timer.stop()
	fase = FASE_FIN
	_emitir_telemetria()
	_mostrar_resultado_final(exito)
	if exito:
		sonido_meta.play()
	corrida_terminada.emit(exito, raton.pasos, tiempo, visitadas.size())
	print("Meta alcanzada en ", raton.pasos, " pasos")


func _mostrar_resultado_final(exito: bool) -> void:
	resultado_label.text = "META ALCANZADA" if exito else "CORRIDA TERMINADA"
	if usar_cerebro_estudiante and fase == FASE_FIN:
		var exploracion_steps = cerebro.pasos_fin_exploracion
		var speed_run_steps = raton.pasos - cerebro.pasos_antes_speed_run
		detalle_resultado_label.text = "Exploración: %d pasos\nSpeed Run: %d pasos\nTiempo Total: %.1f s\nTotal visitadas: %d" % [
			exploracion_steps,
			speed_run_steps,
			tiempo,
			visitadas.size(),
		]
	else:
		detalle_resultado_label.text = "pasos: %d\ntiempo: %.1f s\nvisitadas: %d" % [
			raton.pasos,
			tiempo,
			visitadas.size(),
		]
	panel_final.show()


func _on_raton_paso_terminado() -> void:
	if fase != FASE_FIN:
		sonido_paso.play()


func _on_raton_choque() -> void:
	sonido_choque.play()


func _on_boton_pausa_pressed() -> void:
	pausado = not pausado
	paso_timer.paused = pausado
	boton_pausa.text = "Reanudar" if pausado else "Pausa"


func _on_boton_paso_pressed() -> void:
	if pausado:
		_ejecutar_paso()


func _on_boton_velocidad_pressed() -> void:
	indice_velocidad = (indice_velocidad + 1) % velocidades.size()
	var velocidad: float = velocidades[indice_velocidad]
	paso_timer.wait_time = wait_time_base / velocidad
	raton.duracion_paso = duracion_paso_base / velocidad
	boton_velocidad.text = "Vel x%d" % int(velocidad)


func _on_boton_reiniciar_pressed() -> void:
	_iniciar_corrida()
	_emitir_telemetria()
