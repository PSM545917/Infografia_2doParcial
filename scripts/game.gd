extends Node2D

@export_file("*.maz") var archivo_laberinto: String = "res://mazes/01_entrenamiento.maz"
@export var usar_cerebro_estudiante: bool = false

const ORIGEN := Vector2(28, 44)

var tam_celda := 38.0
var laberinto: Laberinto
var cerebro = null
var fase := "EXPLORANDO"
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

@onready var vista_dios: VistaLaberinto = $vista_dios
@onready var vista_mapa_raton: VistaLaberinto = $vista_mapa_raton
@onready var raton: Raton = $raton
@onready var paso_timer: Timer = $paso_timer
@onready var boton_pausa: Button = $ui/hud/margen/columna/botones/boton_pausa
@onready var boton_velocidad: Button = $ui/hud/margen/columna/botones/boton_velocidad


func _ready() -> void:
	wait_time_base = paso_timer.wait_time
	duracion_paso_base = raton.duracion_paso
	_iniciar_corrida()
	_emitir_telemetria()


func _process(delta: float) -> void:
	if not pausado and not paso_timer.is_stopped():
		tiempo += delta
		tiempo_cambiado.emit(tiempo)


func _iniciar_corrida() -> void:
	laberinto = Laberinto.desde_archivo(archivo_laberinto)
	tam_celda = minf(56.0, 608.0 / maxf(laberinto.ancho, laberinto.alto))
	vista_dios.configurar(laberinto, ORIGEN, tam_celda)
	raton.configurar(laberinto, ORIGEN, tam_celda)
	fase = "EXPLORANDO"
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
	else:
		cerebro = CerebroWallFollower.new()
	paso_timer.start()


func _on_paso_timer_timeout() -> void:
	_ejecutar_paso()


func _ejecutar_paso() -> void:
	if raton.ocupado():
		return
	cerebro.paso(raton)
	visitadas[raton.celda] = true
	_emitir_telemetria()
	if laberinto.es_meta(raton.celda):
		_meta_alcanzada()


func _emitir_telemetria() -> void:
	fase_cambiada.emit(fase)
	pasos_cambiados.emit(raton.pasos)
	visitadas_cambiadas.emit(visitadas.size())
	tiempo_cambiado.emit(tiempo)


func _meta_alcanzada() -> void:
	paso_timer.stop()
	fase = "META"
	_emitir_telemetria()
	print("Meta alcanzada en ", raton.pasos, " pasos")


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
