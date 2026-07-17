# Neurocontroladores — Material de estudio

Curso de redes neuronales y control (PUCP, 2025-1 / 2026). Scripts MATLAB
implementados a mano (sin toolboxes de redes ni fuzzy), organizados por tema en
el orden del curso. **Cada carpeta tiene un `README.md`** con la descripción de
cada script, su nombre original, el orden de estudio sugerido y las ideas clave
para el examen.

## Ruta de estudio (orden del curso)

| # | Carpeta | Tema | Clases |
|---|---------|------|--------|
| 1 | `RedesNeuronalesEstaticas/` | MLP feedforward y retropropagación (patrón/batch, escalamiento, 2 capas ocultas) | 2–3 |
| 2 | `ModelamientoSistemasDinamicos/` | Identificación de sistemas: redes NARX estáticas y redes recurrentes con Dynamic BP | 7 |
| 3 | `ControlSistemasDinamicos/` | Neurocontrol de sistemas bilineales: gradiente estático y BPTT | 9 |
| 4 | `ControlRobotMovil/` | Neurocontrol BPTT de un carro-robot (estacionamiento, currículo) | 10 |
| 5 | `LogicaDifusa/` | Control difuso Mamdani manual + híbrido difuso-LQR (motor, carro, truck-trailer) | 11–13 |
| 6 | `RedesNeuroDifusas/` | Controladores neuro-difusos Sugeno (navegación, obstáculos, multi-robot) | — |
| 7 | `AlgoritmosGeneticos/` | GA binario: optimización, combinatoria, rompecabezas, entrenar redes con GA | 15 |

- `ExamenFinal_RedesNeuronales_2025-1.doc` — examen final del curso.
- Los `Informe/` de cada carpeta son los informes en LaTeX (con PDF compilado);
  los `InformeN.zip` son las copias tal como se entregaron.

## Convención de nombres

Los scripts fueron renombrados de forma descriptiva el 2026-07-17 (los README
conservan la tabla nombre nuevo ↔ nombre original, útil para cruzar con los
informes, que citan los nombres antiguos). Los PDFs de clase siguen el esquema
`ClaseNN_Tema.pdf`.

## Notas sobre archivos `.mat` (redes entrenadas)

Las redes entrenadas fueron retiradas del working tree. Consecuencias:

- `ControlSistemasDinamicos/ControlEstatico_*` y `ControlRobotMovil/*` pueden
  recuperar sus pesos con `git checkout -- <archivo>.mat` (siguen en git), o
  reentrenarse con el script de entrenamiento de su carpeta.
- Los demás scripts con `load` al inicio (ver README de cada carpeta) requieren
  comentar esa línea y entrenar desde cero la primera vez; el `save` final
  regenera el `.mat`.
