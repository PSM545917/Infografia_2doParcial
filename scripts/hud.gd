extends PanelContainer

@onready var fase_label: Label = $margen/columna/fase_label
@onready var pasos_label: Label = $margen/columna/pasos_label
@onready var visitadas_label: Label = $margen/columna/visitadas_label
@onready var tiempo_label: Label = $margen/columna/tiempo_label
@onready var record_label: Label = $margen/columna/record_label


func _ready() -> void:
	var game = get_parent().get_parent()
	game.fase_cambiada.connect(update_fase)
	game.pasos_cambiados.connect(update_pasos)
	game.visitadas_cambiadas.connect(update_visitadas)
	game.tiempo_cambiado.connect(update_tiempo)
	update_record(-1)


func update_fase(nombre: String) -> void:
	fase_label.text = "fase: %s" % nombre


func update_pasos(pasos: int) -> void:
	pasos_label.text = "pasos: %d" % pasos


func update_visitadas(cantidad: int) -> void:
	visitadas_label.text = "visitadas: %d" % cantidad


func update_tiempo(segundos: float) -> void:
	tiempo_label.text = "tiempo: %.1f s" % segundos


func update_record(pasos: int) -> void:
	if pasos < 0:
		record_label.text = "record: -"
	else:
		record_label.text = "record: %d" % pasos
