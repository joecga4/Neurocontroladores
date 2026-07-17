# Lógica Difusa (Clases 11–13)

Control difuso implementado **100% a mano** (sin Fuzzy Logic Toolbox): funciones
de pertenencia triangulares/trapezoidales por tramos, AND de reglas con `min` y
defuzzificación por **centro de gravedad**. Todos son **scripts** independientes.

## Orden de estudio sugerido

| # | Archivo | Nombre original | Qué hace |
|---|---------|-----------------|----------|
| 1 | `ControlDifusoMotorDC.m` | fuzzymotor.m | El más simple: posiciona un motor DC/servo (modelo de estados discretizado con `c2d`). Mamdani 7×7 (posición, velocidad → voltaje), reglas simétricas. |
| 2 | `ControlDifusoCarroPosicionX.m` | fuzzycarxloco.m | Robot tipo carro/triciclo llevado a una X deseada. Mamdani con 7 particiones en X y φ → ángulo de timón; cinemática no lineal y animación. |
| 3 | `ControlDifusoMamdaniTrailer.m` | fuzzytrailerxbueno.m | Camión-remolque (truck-trailer): base de reglas **3D** (X, θ2, θ12 → δ) para evitar el jack-knife. Mamdani puro con animación. |
| 4 | `ControlDifusoLQRTrailer.m` | fuzzytrailerLQ.m | Enfoque avanzado **Takagi-Sugeno / gain-scheduling**: 3 membresías sobre θ12 ponderan entre −δmax, ley LQR (Riccati con `are`) y +δmax. Genera video `trailer4.avi`. |
| 5 | `ControlDifusoLQRTrailer_MembresiaEstrecha.m` | fuzzytrailerLQ.m (copia en RedesNeuroDifusas) | Idéntico al anterior salvo una línea: membresías de θ12 más estrechas (`np/40` vs `np/20`) → transición más brusca. Útil para comparar sintonía. |

## Ideas clave para el examen

- Pipeline Mamdani: fuzzificación → base de reglas (min) → agregación → centroide.
- Base de reglas 2D vs 3D (cuándo hace falta una tercera variable: el remolque).
- Mamdani puro vs Takagi-Sugeno con ponderación de controladores lineales (LQR).

## Material

- `Clase11_ControlDifusoRobotCarro.pdf`
- `Clase12_ControlDifusoTruckTrailer.pdf` (en `../RedesNeuroDifusas/`)
- `Clase13_Paper_ControlLinealDifuso_TruckTrailer.pdf` (paper IEEE FUZZ 2020 en que se basa el enfoque LQR)
- `Informe/` (informe 6 en LaTeX + PDF)
