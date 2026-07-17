# Control de Sistemas con Redes Neuronales (Clase 9)

Neurocontroladores para un sistema bilineal discreto `x(k+1) = A·x + B·u + (G·x)·u`.
Dos familias, ambas **scripts**:

- **`ControlEstatico_*`**: planta **estable**; gradiente estático (no recursivo) con momentum.
- **`ControlBPTT_*`**: planta **inestable** (`A=[1.20 0.3; -0.2 1.15]`); retropropagación
  dinámica a través del tiempo (BPTT) con el jacobiano de lazo cerrado.

## Orden de estudio sugerido

| # | Archivo | Nombre original | Qué hace |
|---|---------|-----------------|----------|
| 1 | `ControlEstatico_Entrena.m` | DynamicBPControlEstaticoModelo0.m | **Entrena** el regulador (llevar el estado al origen) con gradiente estático + momentum + guardia de divergencia. Único de su familia que entrena. |
| 2 | `ControlEstatico_ValidaSeguimiento.m` | DynamicBPControlEstaticoModelo1.m | **Valida** seguimiento a un setpoint no nulo con condiciones iniciales ×40 (generalización). |
| 3 | `ControlEstatico_ValidaRobustez.m` | DynamicBPControlEstaticoModelo3.m | **Valida** robustez: aplica la misma red a 4 variantes de planta (A menos estable, B −50%, G ×2). |
| 4 | `ControlBPTT_EntrenaRealimCompleta.m` | DynamicBPControl2.m | **Entrena** con BPTT el control de la planta inestable, realimentación completa del estado (`ne=2`, `nm=50`), con perturbación senoidal. |
| 5 | `ControlBPTT_RealimParcialSalida.m` | DynamicBPControl2a.m | Variante con realimentación **parcial**: la red solo ve la salida medida `y=C·x` (`ne=1`, `nm=40`); grafica historial de costo. |
| 6 | `ControlBPTT_ValidaPerturbaciones.m` | DynamicBPControl2b.m | **Valida/reentrena** en seguimiento de setpoint con perturbaciones fuertes y condiciones iniciales ×4. |

## ⚠️ Antes de ejecutar

- Los `ControlEstatico_*` cargan `redcontrolestatico0.mat`, que fue borrado del
  working tree pero **sigue en git**: recupéralo con
  `git checkout -- redcontrolestatico0.mat` (queda en la raíz del repo; muévelo
  aquí o ajusta la ruta) o reentrena con `ControlEstatico_Entrena.m`
  (descomentando su `save`).
- Los `ControlBPTT_*` cargan `redcontrol202.mat` / `redcontrol2a.mat`, que
  **nunca estuvieron en git** (irrecuperables): hay que reentrenar desde cero
  comentando el `load` y activando la inicialización aleatoria.

## Ideas clave para el examen

- Gradiente estático vs BPTT: cuándo basta `dx/dp = dxdu·du/dp` y cuándo hay que
  propagar sensibilidades `S_p` con el jacobiano de lazo cerrado.
- Realimentación completa del estado vs parcial de salida (`y=C·x`).
- Metodología entrenar → validar seguimiento → validar robustez.

## Material

- `Clase09_ControlSistemasConRedesNeuronales.pdf`
- `Informe/` (informe 4), `Informe4.zip` (copia entregada)
