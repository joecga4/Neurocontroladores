# Redes Neuronales Estáticas (Clases 2–3)

Redes feedforward (MLP) entrenadas con retropropagación de errores implementada
a mano (sin toolbox). Todos son **scripts** autónomos: no cargan `.mat` ni llaman
a otros archivos; los parámetros (`bias`, `eta`) se piden por teclado en varios.

## Orden de estudio sugerido

| # | Archivo | Nombre original | Qué hace |
|---|---------|-----------------|----------|
| 1 | `AjusteRecta_EntrenaPorPatron.m` | NeuronLinealPatron.m | MLP 1-20-1 que aproxima una recta ruidosa. Entrenamiento **por patrón** (online): actualiza pesos en cada muestra. |
| 2 | `AjusteRecta_EntrenaBatch.m` | NeuronLinealPatronBatch.m | Misma tarea pero en **batch**: acumula gradientes y actualiza una vez por época (`nm=2`). Contrasta patrón vs batch. |
| 3 | `AjusteCubica_Escalamiento.m` | NeuronCubicaEscalamiento.m | MLP 1-25-1 que aproxima una cúbica. Estudia el **problema de escalamiento** de la salida (variable `FACTOR`). |
| 4 | `DosEntradasDosSalidas_SoloPesos.m` | NeuronDosEntradasDosSalidas.m | MLP 2-50-2 con salida vectorial; solo entrena pesos `v,w` (pendiente y centro fijos). |
| 5 | `DosEntradasDosSalidas_PendienteCentro.m` | NeuronDosEntradasDosSalidas_PendienteCentro.m | Igual que el anterior pero además **entrena la pendiente `a` y el centro `c`** de las sigmoideas (`etaa`, `etac`). |
| 6 | `DosEntradasDosSalidas_DosCapasOcultas.m` | NeuronDosEntradasDosIntermediasBP.m | MLP con **dos capas ocultas** (30 y 40 neuronas): retropropagación encadenada en dos etapas. |

## Ideas clave para el examen

- Entrenamiento por patrón vs batch (dónde va la actualización de pesos respecto al bucle de muestras).
- Efecto del escalamiento de la salida deseada en la convergencia.
- Gradientes adicionales `dJ/da` y `dJ/dc` cuando se adaptan las activaciones.
- Cómo se encadena la retropropagación al agregar una segunda capa oculta.

## Material

- `Clase02_RedesNeuronales_Entrenamiento.pdf`, `Clase03_Retropropagacion_Aplicaciones.pdf`
- `Informe/` (LaTeX + PDF del informe 1), `Informe1.zip` (copia entregada)
