class_name CerebroEstudiante
extends RefCounted

const FASE_EXPLORANDO := "EXPLORANDO"
const FASE_META := "META"
const FASE_VOLVIENDO := "VOLVIENDO"
const FASE_SPEED_RUN := "SPEED_RUN"
const FASE_FIN := "FIN"

const INF := 1000000

var ancho: int = 0
var alto: int = 0
var metas: Array[Vector2i] = []
var inicio: Vector2i = Vector2i.ZERO
var mapa_descubierto: Laberinto = null
var visitadas := {}
var conteo_visitas := {}
var distancias := []
var ruta_exploracion: Array[Vector2i] = []
var fase := FASE_EXPLORANDO

# Variables para control de fases y speed run
var ruta_sr_planificada: Array[Vector2i] = []
var indice_speed_run := 0
var pasos_fin_exploracion := 0
var pasos_antes_speed_run := 0


func preparar(ancho_: int, alto_: int, metas_: Array[Vector2i],
		inicio_: Vector2i = Vector2i.ZERO) -> void:
	ancho = ancho_
	alto = alto_
	metas = metas_
	inicio = inicio_
	mapa_descubierto = Laberinto.vacio(ancho, alto)
	mapa_descubierto.inicio = inicio
	mapa_descubierto.metas = metas.duplicate()
	visitadas = {}
	conteo_visitas = {}
	distancias = []
	ruta_exploracion = []
	fase = FASE_EXPLORANDO
	ruta_sr_planificada = []
	indice_speed_run = 0
	pasos_fin_exploracion = 0
	pasos_antes_speed_run = 0


func paso(raton: Raton) -> void:
	if fase == FASE_EXPLORANDO:
		_registrar_visita(raton.celda)
		_anotar_paredes(raton)
		distancias = _flood_fill(metas)
		
		if raton.celda in metas:
			pasos_fin_exploracion = raton.pasos
			fase = FASE_META
			return
			
		var rumbo_objetivo = _mejor_vecina(raton.celda, distancias)
		_mover_hacia(raton, rumbo_objetivo)

	elif fase == FASE_META:
		fase = FASE_VOLVIENDO
		paso(raton)

	elif fase == FASE_VOLVIENDO:
		_registrar_visita(raton.celda)
		_anotar_paredes(raton)
		distancias = _flood_fill([inicio])
		
		if raton.celda == inicio:
			ruta_sr_planificada = _calcular_ruta_speed_run()
			pasos_antes_speed_run = raton.pasos
			fase = FASE_SPEED_RUN
			return
			
		var rumbo_objetivo = _mejor_vecina(raton.celda, distancias)
		_mover_hacia(raton, rumbo_objetivo)

	elif fase == FASE_SPEED_RUN:
		if ruta_sr_planificada.is_empty():
			fase = FASE_FIN
			return
			
		var index_actual = ruta_sr_planificada.find(raton.celda)
		if index_actual != -1:
			indice_speed_run = index_actual
			
		if raton.celda in metas:
			fase = FASE_FIN
			return
			
		if indice_speed_run + 1 < ruta_sr_planificada.size():
			var objetivo = ruta_sr_planificada[indice_speed_run + 1]
			var dir_objetivo = -1
			for dir in 4:
				if raton.celda + Laberinto.DELTAS[dir] == objetivo:
					dir_objetivo = dir
					break
			if dir_objetivo != -1:
				var giro = (dir_objetivo - raton.rumbo + 4) % 4
				if giro == 0:
					raton.avanzar()
				elif giro == 1:
					raton.girar_derecha()
				elif giro == 3:
					raton.girar_izquierda()
				else:
					raton.girar_derecha()
		else:
			fase = FASE_FIN


func _registrar_visita(celda: Vector2i) -> void:
	visitadas[celda] = true
	conteo_visitas[celda] = conteo_visitas.get(celda, 0) + 1
	if ruta_exploracion.is_empty() or ruta_exploracion[ruta_exploracion.size() - 1] != celda:
		ruta_exploracion.append(celda)


func _anotar_paredes(raton: Raton) -> void:
	var celda = raton.celda
	var frente = raton.rumbo
	var izquierda = (raton.rumbo + 3) % 4
	var derecha = (raton.rumbo + 1) % 4
	if raton.pared_frente():
		mapa_descubierto.poner_pared(celda, frente)
	if raton.pared_izquierda():
		mapa_descubierto.poner_pared(celda, izquierda)
	if raton.pared_derecha():
		mapa_descubierto.poner_pared(celda, derecha)


func _flood_fill(destinos: Array[Vector2i]) -> Array:
	var resultado := []
	for fila in alto:
		var fila_distancias := []
		for col in ancho:
			fila_distancias.append(INF)
		resultado.append(fila_distancias)

	var cola: Array[Vector2i] = []
	for destino in destinos:
		if mapa_descubierto.en_rango(destino):
			resultado[destino.y][destino.x] = 0
			cola.append(destino)

	var indice := 0
	while indice < cola.size():
		var actual = cola[indice]
		indice += 1
		var distancia_actual: int = resultado[actual.y][actual.x]
		for dir in 4:
			if mapa_descubierto.tiene_pared(actual, dir):
				continue
			var vecina = actual + Laberinto.DELTAS[dir]
			if not mapa_descubierto.en_rango(vecina):
				continue
			if resultado[vecina.y][vecina.x] > distancia_actual + 1:
				resultado[vecina.y][vecina.x] = distancia_actual + 1
				cola.append(vecina)
	return resultado


func _mejor_vecina(desde: Vector2i, distancias_: Array) -> int:
	var mejor_dir := -1
	var mejor_distancia := INF
	var mejor_visitada := true
	var mejor_visitas := INF
	for dir in 4:
		if mapa_descubierto.tiene_pared(desde, dir):
			continue
		var vecina = desde + Laberinto.DELTAS[dir]
		if not mapa_descubierto.en_rango(vecina):
			continue
		var distancia: int = distancias_[vecina.y][vecina.x]
		var ya_visitada := visitadas.has(vecina)
		var visitas: int = conteo_visitas.get(vecina, 0)
		if distancia < mejor_distancia:
			mejor_dir = dir
			mejor_distancia = distancia
			mejor_visitada = ya_visitada
			mejor_visitas = visitas
		elif distancia == mejor_distancia:
			if mejor_visitada and not ya_visitada:
				mejor_dir = dir
				mejor_visitada = ya_visitada
				mejor_visitas = visitas
			elif ya_visitada == mejor_visitada and visitas < mejor_visitas:
				mejor_dir = dir
				mejor_visitas = visitas
	if mejor_dir == -1:
		return Laberinto.NORTE
	return mejor_dir


func _mover_hacia(raton: Raton, rumbo_objetivo: int) -> void:
	var giro = (rumbo_objetivo - raton.rumbo + 4) % 4
	if giro == 0:
		raton.avanzar()
	elif giro == 1:
		raton.girar_derecha()
	elif giro == 3:
		raton.girar_izquierda()
	else:
		raton.girar_derecha()


func mapa_del_raton() -> Laberinto:
	return mapa_descubierto


func celdas_visitadas() -> Dictionary:
	return visitadas


func ruta_explorada() -> Array[Vector2i]:
	return ruta_exploracion


func ruta_speed_run() -> Array[Vector2i]:
	return ruta_sr_planificada


func _flood_fill_conocidas(destinos: Array[Vector2i]) -> Array:
	var resultado := []
	for fila in alto:
		var fila_distancias := []
		for col in ancho:
			fila_distancias.append(INF)
		resultado.append(fila_distancias)

	var cola: Array[Vector2i] = []
	for destino in destinos:
		if mapa_descubierto.en_rango(destino):
			resultado[destino.y][destino.x] = 0
			cola.append(destino)

	var indice := 0
	while indice < cola.size():
		var actual = cola[indice]
		indice += 1
		var distancia_actual: int = resultado[actual.y][actual.x]
		for dir in 4:
			if mapa_descubierto.tiene_pared(actual, dir):
				continue
			var vecina = actual + Laberinto.DELTAS[dir]
			if not mapa_descubierto.en_rango(vecina):
				continue
			if not visitadas.has(vecina):
				continue
			if resultado[vecina.y][vecina.x] > distancia_actual + 1:
				resultado[vecina.y][vecina.x] = distancia_actual + 1
				cola.append(vecina)
	return resultado


func _calcular_ruta_speed_run() -> Array[Vector2i]:
	var dists = _flood_fill_conocidas(metas)
	var ruta: Array[Vector2i] = [inicio]
	var actual = inicio
	
	if dists[actual.y][actual.x] >= INF:
		return []
		
	var max_pasos = ancho * alto * 2
	var paso_n = 0
	while not actual in metas and paso_n < max_pasos:
		paso_n += 1
		var mejor_vecina_celda = actual
		var mejor_dist = dists[actual.y][actual.x]
		for dir in 4:
			if mapa_descubierto.tiene_pared(actual, dir):
				continue
			var vecina = actual + Laberinto.DELTAS[dir]
			if not mapa_descubierto.en_rango(vecina):
				continue
			if not visitadas.has(vecina):
				continue
			if dists[vecina.y][vecina.x] < mejor_dist:
				mejor_dist = dists[vecina.y][vecina.x]
				mejor_vecina_celda = vecina
		if mejor_vecina_celda == actual:
			break
		actual = mejor_vecina_celda
		ruta.append(actual)
	return ruta
