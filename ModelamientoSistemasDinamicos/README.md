# Modelamiento de Sistemas Dinámicos (Clase 7)

Identificación de sistemas con redes neuronales. Dos familias:

- **`DBP_*`**: redes **dinámicas recurrentes** entrenadas con Dynamic BackPropagation
  (la salida se realimenta como entrada y el gradiente se propaga en el tiempo vía jacobianos).
- **`ModeloMotor_*`**: redes **estáticas** tipo NARX (entradas retardadas) que modelan
  un motor electromecánico de 3 estados discretizado con `c2d`.

Todos son **scripts** independientes entre sí.

## Orden de estudio sugerido

| # | Archivo | Nombre original | Qué hace |
|---|---------|-----------------|----------|
| 1 | `DBP_LinealIdentificaMatricesAB.m` | DynamicBPLinealmodel2.m | Red lineal (activación identidad, `w` fija) que recupera las matrices A y B de un sistema lineal de orden 2. El caso DBP más simple e interpretable. |
| 2 | `DBP_NoLineal_DosSalidas.m` | DynamicBPModelamiento2v.m | DBP no lineal (sigmoidea activa, `nm=50`) para un sistema bilineal de 1 entrada y 2 salidas; entrena también centro `c` y pendiente `a`. |
| 3 | `DBP_TresSalidas.m` | DynamicBPModelamiento3v.m | Extensión a 3 salidas (`nm=60`) con entrada senoidal; activación lineal y `q3=0` (la 3ª salida no pondera en el costo). |
| 4 | `DBP_DosCapasOcultas.m` | DynamicBPModelamientoDosIntermedias.m | DBP con **dos capas ocultas** (12 y 10 neuronas): jacobiano encadenado a través de ambas capas. |
| 5 | `ModeloMotor_CuatroEntradasRetardos.m` | MotorNeuroEstatico1.m | Modelo NARX del motor con 4 entradas: voltaje + 3 posiciones retardadas. Por defecto usa la señal de validación `v4`. |
| 6 | `ModeloMotor_SieteEntradasRetardos.m` | MotorNeuroEstatico.m | Igual pero con 7 entradas (voltaje + 6 retardos): más memoria del modelo. |

## ⚠️ Antes de ejecutar

Los 6 scripts empiezan con un `load` de pesos entrenados (`zz1v`, `reddbp27`,
`reddbp1v1`, `reddbp2int`, `motorred`, `motorred1`) que **no existen en el repo**.
Para la primera corrida: **comenta la línea `load ...`**, descomenta/deja la
inicialización aleatoria y ejecuta; el `save` del final creará el `.mat` para
corridas siguientes.

## Ideas clave para el examen

- Diferencia entre identificación estática (NARX con retardos) y dinámica (recurrente con DBP).
- Recursión del gradiente en el tiempo: por qué aparece el jacobiano del sistema.
- Efecto del número de retardos en el modelo NARX (4 vs 7 entradas).

## Material

- `Clase07_ModelamientoSistemasDinamicos.pdf`
- `Informe/` (informe 3), `Informe3.zip` (copia entregada)
