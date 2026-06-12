# Simulador Micromouse - Segundo Parcial (Infografía, I/2026)

Este proyecto consiste en la implementación del cerebro algorítmico y los sistemas visuales de un robot **Micromouse** desarrollado sobre **Godot 4.6**. El ratón es capaz de explorar de forma autónoma laberintos con ciclos, mapear paredes sensadas en su propia memoria, retornar al inicio al completar la exploración y ejecutar una corrida rápida (Speed Run) por la ruta óptima sin chocar.

---

## 🚀 Cómo Ejecutar

1. Abre la carpeta `info_2do_parcial_micromouse/` en el motor de **Godot 4.6** (o superior).
2. Presiona `F5` (o el botón Play superior) para ejecutar la escena principal `scenes/game.tscn`.
3. Utiliza los controles en pantalla y el menú desplegable para cambiar de laberinto e interactuar con la simulación.

---

## 🕹️ Controles e Interfaz

El simulador cuenta con controles en vivo dentro del panel de telemetría (HUD):
* **Selector de Laberintos**: Menú desplegable dinámico que lista todos los archivos en `res://mazes/`. Al seleccionar uno, la simulación se reinicia de inmediato cargando el nuevo mapa.
* **Pausa / Reanudar**: Detiene temporalmente el avance del ratón.
* **Paso**: Ejecuta un único tick (acción) de forma manual cuando la simulación está pausada.
* **Velocidad**: Alterna la velocidad del temporizador de pasos entre `x1`, `x2` y `x4`.
* **Reiniciar**: Vuelve a iniciar la simulación del laberinto actual desde cero.

---

## 🛠️ Mecánicas Implementadas

### Requisitos Base
* **B1. Telemetría en vivo**: El panel HUD del juego reporta constantemente la fase de ejecución, pasos realizados, celdas descubiertas y tiempo transcurrido en tiempo real.
* **B2. Controles de ejecución**: Botones de pausa, avance manual tick a tick, selector de velocidad y reinicio completamente funcionales.
* **B3. Máquina de estados**: Soporte para las transiciones de estado del sistema: `EXPLORANDO` $\rightarrow$ `META` $\rightarrow$ `VOLVIENDO` $\rightarrow$ `SPEED_RUN` $\rightarrow$ `FIN`.
* **B4. Efectos de sonido**: Integración de audio espacial mediante `AudioStreamPlayer` para los sonidos de movimiento (`paso.wav`), choque con muros (`choque.wav`) y fanfarria de meta (`meta.wav`).
* **B5. Consola limpia**: Proyecto libre de warnings y errores de ejecución en la consola de Godot.

### Mecánicas Obligatorias (Micromouse Real)
* **M1. Exploración Flood-Fill**: Implementación del cerebro del estudiante (`CerebroEstudiante`). El robot no accede a los datos internos del laberinto real (`_laberinto`), sino que sensa paredes relativas a su rumbo en la celda actual, mapea las paredes descubiertas en un laberinto en blanco y recalcula las distancias por BFS (Breadth-First Search) Flood-fill a la meta en cada tick para tomar la mejor decisión de movimiento.
* **M2. Mapa Dual (Visualización)**: La pantalla derecha dibuja únicamente lo que el ratón sabe. Muestra las paredes descubiertas, sombrea las celdas visitadas (en celeste) y resalta las inexploradas.
* **M3. Regreso y Speed Run**:
  - Al completar la exploración (tocar la meta), el ratón guarda sus pasos y cambia a la fase `VOLVIENDO` para retornar al origen (`inicio`) usando flood-fill.
  - Una vez de vuelta en el inicio, el cerebro calcula la ruta óptima (`_flood_fill_conocidas`) limitándose exclusivamente a celdas visitadas.
  - Ejecuta la corrida rápida (`SPEED_RUN`) siguiendo la polilínea cian y, al llegar al centro por segunda vez, despliega una pantalla comparando los pasos de exploración vs. los del speed run.
* **M4. Selector Dinámico y Persistencia**:
  - El selector lee de forma dinámica el directorio `res://mazes/` al arrancar el juego. Copiar un nuevo archivo `.maz` a la carpeta lo incluirá de inmediato en el menú sin alterar código.
  - Guarda los récords persistentes (menor cantidad de pasos en el Speed Run) por laberinto en la ruta `user://records.cfg` usando la API `ConfigFile`. Los récords se muestran en el HUD y se cargan al cambiar de nivel o reabrir el simulador.

---

## 📈 Bonus Implementado: Heat-map de Visitas

Se ha añadido un sistema visual de **Heat-map térmico** en las celdas visitadas de la vista derecha:
* A medida que el ratón transita por una celda, incrementa su contador de visitas.
* La celda se colorea en un gradiente térmico adaptativo: desde un azul/celeste frío (1 visita) hasta un rojo/naranja caliente brillante (máximo de visitas de la simulación).
* Permite observar claramente en qué intersecciones el algoritmo debió realizar backtracking o quedó atrapado temporalmente resolviendo ciclos antes de encontrar la meta.

---

## 📚 Referencias y Recursos Consultados

1. **Wikipedia (Micromouse)**: [Micromouse Wiki](https://en.wikipedia.org/wiki/Micromouse) - Contexto histórico y reglas generales de la competencia.
2. **Algoritmo de Inundación (Flood-Fill)**: [Flood Fill Algorithm for Micromouse (Aditya Sharma)](https://medium.com/@adityashrm21/flood-fill-algorithm-for-micromouse-fb2c42289fdf) - Guía sobre la propagación de distancias en matrices micromouse.
3. **Búsqueda en Anchura (BFS)**: [BFS for Shortest Paths (GeeksforGeeks)](https://www.geeksforgeeks.org/breadth-first-search-or-bfs-for-a-graph/) - Lógica de BFS en grids para encontrar el camino más corto.
4. **Documentación de Godot Engine**: [Godot Docs](https://docs.godotengine.org/) - API para ConfigFile, OptionButton, DirAccess y dibujo en 2D CanvasItem (`draw_polyline`, `draw_rect`).

---

## 🧪 Validación Final

Se ha verificado el correcto funcionamiento del simulador en Godot 4.6 con los tres laberintos provistos por defecto, obteniendo un comportamiento robusto en todas las fases:
1. **01_entrenamiento.maz** (8x8): El ratón realiza la exploración Flood-Fill de manera limpia, registra la meta al llegar, vuelve al inicio recopilando las paredes restantes y ejecuta el Speed Run de manera óptima en pocos pasos.
2. **02_clasico.maz** (16x16): El ratón explora y mapea las paredes descubiertas resolviendo ciclos sin entrar en bucles infinitos. Regresa al inicio por el camino más rápido y ejecuta el Speed Run por la ruta ideal en la mitad de pasos que la exploración original.
3. **03_clasico.maz** (16x16): Prueba exitosa bajo condiciones de competencia real, confirmando el comportamiento robusto del algoritmo Flood-Fill restrictivo de celdas visitadas.
