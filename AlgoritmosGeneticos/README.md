# Algoritmos Genéticos (Clase 15)

GA con codificación binaria implementado a mano: selección (padre entre los
mejores, madre aleatoria), cruce por bloques de bits, mutación y elitismo.
Dos archivos son **funciones** (`CrucePermutacion.m`, `GeneraPermutacionBinaria.m`);
el resto son scripts.

## Orden de estudio sugerido

| # | Archivo | Nombre original | Qué hace |
|---|---------|-----------------|----------|
| 1 | `OptimizaFuncion_UnaVariable.m` | genetico1.m | Maximiza una función 1D con dos máximos. Fundamentos: codificación binaria (16 bits), selección, cruce, mutación, elitismo. |
| 2 | `OptimizaFuncion_DosVariables.m` | genetico2.m | Extiende a 2 variables (cromosoma = concatenación de dos codificaciones). |
| 3 | `OptimizaFuncion_ConRestriccion.m` | genetico3.m | Restricción de caja manejada por **penalización** en el fitness. |
| 4 | `RepartoCartas_SumaProducto.m` | genetico4.m | Problema combinatorio: repartir 10 cartas en dos grupos (suma 32 / producto 1260). Fitness personalizado. |
| 5 | `MatrizMagica3x3.m` | genetico7.m | Matriz 3×3 con 1–9 donde filas y columnas suman igual. Codificación multi-número (4 bits por número). |
| 6 | `MatrizMagica4x4.m` | genetico8.m | Escala a 4×4 con población 400, 25 hijos y 40 mutaciones por generación (usa `GeneraPermutacionBinaria`). ⚠️ No ejecutable: ver abajo. |
| 7 | `RompecabezasImagen_VersionAntigua.m` | genetico81.m | Borrador del rompecabezas de imagen 4×4 (reordenar piezas de `mariobros.jpg`). ⚠️ No ejecutable: ver abajo. |
| 8 | `RompecabezasImagen.m` | genetico83.m | **Versión definitiva** del rompecabezas (M configurable, aquí 12×12=144 piezas) con **bloqueo progresivo**: las piezas correctas se eliminan del problema. Usa `CrucePermutacion` + `GeneraPermutacionBinaria`. |
| 9 | `EntrenaRedNeuronalConGA.m` | geneticoneuronal1.m | Culminación: entrena los pesos de una red 1-10-1 con GA (8 bits por peso, rango [−4,4]) minimizando el SSE. Enlaza GA con redes neuronales. |

## Funciones auxiliares

| Archivo | Nombre original | Qué hace |
|---------|-----------------|----------|
| `GeneraPermutacionBinaria.m` | generacionrandombits.m | Genera una permutación aleatoria de 1..M2 codificada en binario (operador de mutación válida). Usada por 6, 7-antigua y 8. |
| `CrucePermutacion.m` | crossover1.m | Cruce por segmentos con **reparación** (garantiza permutación sin repetidos). Usada solo por `RompecabezasImagen.m`. |

## ⚠️ Archivos faltantes (anteriores a git, irrecuperables)

- `MatrizMagica4x4.m` y `RompecabezasImagen_VersionAntigua.m` llaman a una función
  `crossover(z1,z2,bpm,start1,start2)` de 5 argumentos que **no existe en el repo**
  (solo existe la de 7 argumentos, hoy `CrucePermutacion.m`, con otra firma).
- Los dos rompecabezas necesitan la imagen `mariobros.jpg`, que tampoco está en
  el repo; cualquier `.jpg` renombrado sirve.

## Ideas clave para el examen

- Los 4 operadores del GA: selección, cruce, mutación, elitismo.
- Restricciones por penalización del fitness.
- Codificación de permutaciones y cruce con reparación (evitar hijos inválidos).
- GA como alternativa al gradiente para entrenar redes neuronales (no requiere derivadas).

## Material

- `Clase15_AlgoritmosGeneticos.pdf`
