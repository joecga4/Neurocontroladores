# Redes Neuro-Difusas (ANFIS manual)

Controladores neuro-difusos tipo **Sugeno de orden cero** implementados a mano
(sin `anfis` ni toolbox): membresías **gaussianas** + sigmoides en los bordes,
consecuentes numéricos (`deltanf`) y salida por **promedio ponderado normalizado**
— equivalente a la capa de defuzzificación de una red neuro-difusa.
Todos son **scripts**; el núcleo neuro-difuso es idéntico en los 6, lo que cambia
es la tarea de navegación.

## Orden de estudio sugerido

| # | Archivo | Nombre original | Qué hace |
|---|---------|-----------------|----------|
| 1 | `NeuroDifusoCarroPosicion.m` | neurofuzzy1.m | El núcleo puro: un robot carro llevado a una X deseada con orientación 90°. Base para todos los demás. |
| 2 | `NeuroDifusoEvasionUnObstaculo.m` | neurofuzzyObstacle1.m | Añade planificación de camino por tramos (waypoints) para evadir 1 obstáculo rectangular. |
| 3 | `NeuroDifusoEvasionDosObstaculos.m` | neurofuzzyObstacle2.m | Extiende a 2 obstáculos (5 tramos de camino). |
| 4 | `NeuroDifusoEvasionMapaObstaculos.m` | neurofuzzyObstacle3.m | Mapa complejo con múltiples obstáculos irregulares; graba video `RobotPlantObstacleX.mp4`. |
| 5 | `NeuroDifusoSeguimientoDosRobots.m` | neurofuzzy71.m | Cooperación líder-seguidor: robot 1 sigue una recta, robot 2 persigue al 1 (control de rumbo y de velocidad por distancia). |
| 6 | `NeuroDifusoSeguimientoTresRobots.m` | neurofuzzy72.m | Escala a 3 robots en cadena (condiciones iniciales fijas en el código). |

Nota: el `fuzzytrailerLQ.m` que estaba en esta carpeta era un duplicado del de
LogicaDifusa (difería solo en un parámetro de sintonía); se movió allí como
`ControlDifusoLQRTrailer_MembresiaEstrecha.m`.

## Ideas clave para el examen

- Sugeno de orden cero: salida = Σ(pertenencia·consecuente)/Σ(pertenencia).
- Membresías gaussianas (diferenciables → entrenables) vs triangulares del Mamdani clásico.
- Cómo el mismo controlador de rumbo se reutiliza cambiando solo la referencia
  (posición fija, proyección sobre un tramo, o el robot líder).
