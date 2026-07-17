# Control Neuronal de Robot Móvil (Clase 10)

Neurocontrolador BPTT para la dirección de un carro-robot (estacionamiento).
Ambos archivos son **scripts**.

## Orden de estudio sugerido

| # | Archivo | Nombre original | Qué hace |
|---|---------|-----------------|----------|
| 1 | `EntrenaCarroBPTT_Curriculo.m` | DynamicBPCarro.m | **Entrena** la red (`ne=2, nm=50`) por currículo en 3 etapas (rangos crecientes de posición y ángulo). Incluye error de orientación envuelto a (−π,π], normalización de entradas, BPTT truncado cada 200 pasos y recorte de gradiente. |
| 2 | `ValidaCarro_Estacionamiento.m` | DynamicBPCarroValida.m | **Valida** el controlador: simula el estacionamiento desde una pose inicial pedida por consola, con modelo de 3 estados (X, Y, φ), saturación del timón a ±45° y animación 2D. |

## ⚠️ Antes de ejecutar

Los pesos entrenados (`redcarro11.mat`, `redcarro11_etapa1.mat`, etc.) fueron
borrados del working tree pero **siguen en git**; recupéralos con
`git checkout -- redcarro11.mat redcarro11_etapa1.mat` si no quieres reentrenar.
La etapa 1 de `EntrenaCarroBPTT_Curriculo.m` entrena desde cero (no necesita `.mat`).

## Ideas clave para el examen

- Aprendizaje por currículo (etapas con dificultad creciente).
- BPTT truncado y recorte de gradiente para horizontes largos.
- Envoltura del error angular y normalización de entradas.

## Material

- `Clase10_ControlRobotsMoviles.pdf`
- `Informe/` (informe 5), `Informe5.zip` (copia entregada)
