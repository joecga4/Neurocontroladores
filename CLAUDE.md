# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

MATLAB research scripts that train a **neural network controller** (neurocontrolador) to regulate a 2-state discrete-time dynamical system. Each script is a self-contained experiment that trains the controller via gradient descent through the plant dynamics, then plots the closed-loop response. There is no build/test harness — these are interactive MATLAB scripts run from the editor or command window.

There are **two families** of scripts, sharing the same section layout, plant model, and network architecture but differing in how the gradient is computed:
- **`DynamicBPControlEstaticoModelo{0,1,3}.m`** — *static* dynamic-BP: the state-to-parameter derivatives use only the **instantaneous** sensitivity `dxdu·du/dp` (no time recursion).
- **`DynamicBPControl2{,a,b}.m`** and **`DynamicBPCarro.m`** — *true* dynamic backpropagation (BPTT): the derivatives are propagated **recursively through time** via the closed-loop Jacobian (`jacob`, `dudx`, `jacob_t`). These target genuinely **unstable** plants (or, for the carro, a nonlinear kinematic plant), where the recursion is needed. In this family the recursion is **vectorized**: per-state sensitivities are stored as matrices `Sw_t`/`Sc_t`/`Sa_t` (`nm×nx`) and `Sv_t` (`ne×nm×nx`) and updated **simultaneously** (`S_p = du/dp·dxdu' + S_p·jacob_t'`), not as hand-unrolled `dx1.../dx2...` terms. The `Estatico` family was given the analogous refactor (dynamic `nini`, preallocation, looped plots), but since its gradient is *static* the per-state derivatives collapse to a single scalar coefficient instead of carried matrices — see below.

## Running

Run a script in MATLAB (or `matlab -batch "DynamicBPControlEstaticoModelo0"` for headless, though the scripts use `input()` prompts and `figure` plots that assume an interactive session):

Most scripts prompt at the console for:
- Learning rate of `v` and `w`
- Learning rate of sigmoid slope `a`
- Maximum error (%) — training stops when the relative cost falls below this. This criterion is now **active** in the BPTT family: each epoch sets `erreltotal = ersum2total/J0` (cost relative to the first epoch `J0`), so the `while` loop really exits when it drops below `errormax` (it is normalized to the *initial* cost, not to the reference energy, so it also works for regulation to the origin where the reference energy is 0).
- Maximum number of iterations
- At the end: `Save [1]:` (the `Estatico` family says `Save YES [1]:`) — enter `1` to persist trained weights to the `.mat` file. `DynamicBPControl2b.m` is the exception: it saves to `redcontrol201` automatically with no prompt.

`DynamicBPCarro.m` is the other exception: it does **not** prompt at the console at all. Its training params (`eta`, `etaa`, `errormax`, `contmax`, the cost weights `q`) and the `guardar` flag are set in-file, and it **warm-starts** from `redcarro11` (the `load redcarro11` line is active — comment it on a fresh checkout where the `.mat` does not yet exist). It saves back to `redcarro11` when `guardar==1`. The initial conditions are no longer a fixed matrix: an in-file `etapa` (1/2/3) selects a **curriculum stage** that builds `x_ini` as the `meshgrid` cartesian product of an `x1set` and an angular `thset`, covering x1∈[-15,15] × orientation 0–360° from near to far. Train stage 1 → save, switch to stage 2 → re-run (re-loads the stage-1 weights) → stage 3 (incremental / warm-started). `ndata` is `6000` (long horizon: net travel per rollout is `ndata·r`, needed to maneuver x1 from ±15 to 0).

The `.mat` weight files are **loaded at startup** to warm-start training and are **not in the repo** — they are produced/overwritten by the save step. Running a fresh checkout will fail on the `load` line until those files exist; either create them or comment out the `load`. The files per family are: `redcontrolestatico0`, `redcontrolestatico00`, `redcontrolestatico4` (Estatico family) and `redcontrol2`, `redcontrol2a`, `redcontrol201`, `redcontrol202` (DynamicBPControl2 family), plus `redcarro11` (carro).

## Architecture

All scripts share an **identical section layout** (the differences are plant parameters, controller input dimension, and static-vs-dynamic gradient). Each is divided into MATLAB cells (`%%`) in this fixed order, so they can be studied/run section by section:

1. Encabezado — objetivo del modelo y sus particularidades
2. Inicialización del entorno (`clear; clc; close all`)
3. Definición del sistema dinámico (planta: `A`, `B`, `G`, `W`, `Am`)
4. Parámetros de simulación y condiciones iniciales (`ndata`, `x_ini`, `r`)
5. Punto de operación deseado (`x1ast`/`x2ast`/`uast`; ausente en Modelo0)
6. Arquitectura de la red neuronal (`ne`, `nm`, `ns`, `v`, `w`, `c`, `a`)
7. Carga de pesos previos (`load redcontrolestatico*`)
8. Parámetros de entrenamiento (`input` de `eta`, `etaa`, `errormax`, `contmax`)
9. Inicialización del bucle de entrenamiento
10. Bucle principal de entrenamiento (sub-bloques: forward de la red → dinámica de la planta → derivadas → regla de la cadena → costo y gradiente → actualización de pesos)
11. Visualización (figuras 1–3)
12. Guardado de los pesos

When editing, keep this section order and the `%%` cell banners consistent across all files. Note minor per-script variants of the layout: the `Estatico` family uses an `Am` reference matrix in section 3 and an `R·u²` control-effort term in the cost; the `DynamicBPControl2` family (and the carro) instead builds a per-step desired-state array `dataoutesc` in sections 4–5 and reads `out_des = dataoutesc(k+1,:)'` inside the loop (the carro uses a constant `out_des = [0; pi/2]`).

In the BPTT family the visualization section now loops over the initial conditions (`for j = 1:nini`), drawing **one figure per initial condition** — states on top, control below (the carro is the exception: it overlays all initial conditions into two state-only figures, see its entry below). `DynamicBPControl2.m` truncates the response to `nplot = min(100, ndata-1)` steps inline (the old `estadoA`/`uA` temporaries were removed); `2a.m` adds a final cost figure (`figure(nini+1)`) plotting `JJ/JJ1/JJ2`.

The shared model below holds for every script:

**Plant (system being controlled):** discrete-time `x(k+1) = A·x + B·u + (G·x)·u`, a 2-state system with bilinear (state-dependent) input gain `G`. `Am` is a reference model (currently zeroed via `0*Am` — desired output `out_des` is 0, i.e. pure regulation to the origin).

**Controller (neural network):** single hidden layer, scalar control output `u` (`nm = 50` neurons in the Estatico family, `DynamicBPControl2.m` and the carro; `nm = 40` in `2a.m`/`2b.m`).
- `v` (ne×nm): input→hidden weights
- `w` (nm×1): hidden→output weights
- `c`, `a` (nm×1): per-neuron sigmoid center and slope
- Hidden activation: bipolar sigmoid `n = 2/(1+exp(-(m-c)/a)) - 1` where `m = v'·in_red`

**Training loop:** This is *not* standard backprop on a static dataset. The cost `J = Σ(x - out_des)² (+ R·u²)` is minimized by backpropagating through the **plant dynamics**: `dxdu = B + G·x` is the analytic sensitivity of the next state to the control, chained with the network's `du/d{w,v,c,a}` derivatives (`dudw_s`, `dudv_s`, `dudc_s`, `duda_s`). Gradients accumulate over a `ndata`-step rollout for each initial state in `x_ini`, averaged by `ktot`, then a batch gradient-descent step updates the weights. The number of initial conditions is no longer hardcoded as `4`: every script derives `nx = size(x_ini,1)` and `nini = size(x_ini,2)` and loops `for j = 1:nini` (so adding/removing columns of `x_ini` just works; `Modelo3` analogously uses `nvar = numel(Avar)`); `estado`/`deseado`/`u` are preallocated to `ndata-1`. `etac` is hardcoded to 0, so `c` is never updated.

The two families differ in **how the state-to-parameter derivative `dx_i/dp` is formed** inside the rollout:
- **Static (`Estatico` family):** `dx_i/dp = dxdu(i)·du/dp` — only the instantaneous one-step term, recomputed each step. Because there is no time recursion, all four parameter gradients share **one scalar coefficient** per step: `g = (q.*er)'·dxdu + R·u`, and the loop just does `dJdp += g·du/dp` (this vectorized form is numerically identical to the old hand-unrolled `dx1.../dx2...` — there was no simultaneous-update bug to fix in the static case). Only `Modelo0` trains; `Modelo1`/`Modelo3` have no training loop.
- **Dynamic / BPTT (`DynamicBPControl2` family + carro):** `dx_i/dp = dxdu(i)·du/dp + Σ_l jacob_t(i,l)·(dx_l/dp from previous step)`, where `jacob = A + u·G` (plant Jacobian; for the carro it is the analytic Jacobian of the kinematics), `dudx = w'·dndm·v'` (control-to-state sensitivity) and `jacob_t = dxdu·dudx + jacob` (closed-loop Jacobian). The recurrence carries gradient information backward through time, which is what lets it stabilize the unstable plants. This is now **vectorized**: per-state sensitivities live in `Sw_t`/`Sc_t`/`Sa_t` (`nm×nx`) and `Sv_t` (`ne×nm×nx`), updated simultaneously as `S_p = du/dp·dxdu' + S_p·jacob_t'` (the gradient is then `dJdp += S_p·erq`, with `erq = q.*er` the `q1`/`q2`-weighted error as the vector `q`). The simultaneous matrix update also **fixes a latent bug** in the old hand-unrolled form, where `dx2dp` consumed the already-overwritten `dx1dp` of the same step instead of the previous step's value — so BPTT-family gradients differ slightly from the pre-refactor scripts. **Reset scope of the recursive accumulators differs per script:** `DynamicBPControl2.m` resets them at the start of each initial-condition loop (`for j`); `2a.m`, `2b.m` and the carro reset them per epoch (so they carry across initial conditions) — but the carro **additionally truncates** the recursion within each rollout, zeroing the accumulators every `Ttrunc` steps to keep the long-horizon BPTT from exploding.

### Differences between the scripts

**Static family (`DynamicBPControlEstaticoModelo*.m`):**

| Script | Plant | Controller input `in_red` (ne) | Purpose |
|---|---|---|---|
| `...Modelo0.m` | stable A (0.98 diag) | current state only, `ne=2` | **Train** the regulator; saves `redcontrolestatico0` + `redcontrolestatico00` |
| `...Modelo1.m` | stable A | current state only, `ne=2` | **Validate/track**: nonzero setpoint `r=[x1ast;x2ast]` with feedforward `uast` added to `u`; optional disturbance `pert`. Loads `redcontrolestatico0` |
| `...Modelo3.m` | unstable A (1.04 diag) | state + 2 past states `[x; xold1; xold2]`, `ne=6` | **Tapped-delay** controller for an unstable plant, trained incrementally. Loads/saves `redcontrolestatico4` |

**Dynamic-BP / BPTT family (`DynamicBPControl2*.m`):** all use plant `A=[1.20 0.3; -0.2 1.15]` (and more-unstable variants) trained incrementally; tracking target is `x1*=1, x2*=-0.7745, u*=0.3235`.

| Script | Controller input `in_red` (ne) | Purpose |
|---|---|---|
| `DynamicBPControl2.m` | full state, `ne=2`, `nm=50` | **Train** the stabilizer with sinusoidal disturbance (`W=[0;0.01]`, `pert=1*0.05`). Loads/saves `redcontrol202`. Resets recursive derivatives per `j`; truncates plots to 100 steps. |
| `DynamicBPControl2a.m` | **partial** output `y=C·x`, `ne=1`, `nm=40` | Train with **partial feedback** (`C=[0 1]` works, `C=[1 0]` does not). Loads/saves `redcontrol2a`; logs `JJ/JJ1/JJ2`. |
| `DynamicBPControl2b.m` | full state, `ne=2`, `nm=40` | **Validate** disturbance rejection: active setpoint tracking, `x_ini=4*x_ini`, sinusoidal `wr` via `W=[0;1]`. Loads `redcontrol202`, auto-saves `redcontrol201`. |

`DynamicBPCarro.m` is a separate BPTT experiment with a **different (nonlinear, kinematic) plant** — a car-like robot `x1(k+1)=x1+r·cos(x2)`, `x2(k+1)=x2-(r/L)·u` (`r=0.01`, `L=2`), state error fed in (`ne=2`, `nm=50`), regulating to `out_des=[0; pi/2]`. It runs headless (no console prompts), seeds `rng(1)` for reproducibility, and saves to `redcarro11`. It was extended to learn **wide coverage** (x1∈[-15,15] × orientation 0–360°), which required several changes beyond the plain BPTT rollout:
- **Wrapped orientation error**: the orientation component of both `in_red` and the cost error `er` is wrapped to (−π, π] via `mod(θ+π, 2π)−π`, so identical poses (0° vs 360°) produce identical inputs. The wrap's derivative is 1 a.e., so the BPTT Jacobian is unchanged.
- **Input normalization**: `in_red = (x − out_des) ./ inscale` (`inscale=[10;1]`) keeps activations out of sigmoid saturation over the wide x1 range; the chain rule is propagated into `dudx = (w'·dndm·v')./inscale'`. Because of this, **stage 1 trains from the fresh `rng(1)` init** (old raw-scale weights are incompatible) — the `load redcarro11` is now guarded by `if etapa>1`, so only stages 2–3 warm-start.
- **Curriculum**: an in-file `etapa` (1/2/3) selects `x1set`/`thset`, and `x_ini` is their `meshgrid` cartesian product (12 → 40 → 56 cases, near→far). Train each stage in sequence, saving/reloading `redcarro11`.
- **Cost weights** `q=[1;10]` (orientation up-weighted since position error ≤15 dominates ≤π), applied as `erq=q.*er` in the gradient and `q.*er.^2` in the monitored cost.
- **Truncated BPTT + gradient clipping** (the key stability fix): over the long horizon (`ndata=6000`) the recursive `S_p` accumulators explode to Inf/NaN, so they are zeroed every `Ttrunc=200` steps, and each parameter gradient is clipped to norm `gmax=20` before the update. The safety cutoff watches position only (`abs(x1)>25`, was `abs(x)>10`), since orientation legitimately winds.
The visualization no longer draws one figure per initial condition (unmanageable at dozens of cases): it **overlays all trajectories** into two figures — position x1 and orientation x2 — each with a dashed setpoint line.

`DynamicBPCarroValida.m` is the **validation / visualization** companion for the carro (it does *not* train). It loads `redcarro11` and runs a closed-loop parking simulation on a **3-state** version of the kinematics — `X(k+1)=X+r·cos(phi)`, `Y(k+1)=Y+r·sin(phi)`, `phi(k+1)=phi-(r/L)·u` — where the extra `Y` coordinate is integrated only to draw the trajectory into a parking row at `y=ymax=50`. The same `ne=2` net is reused, fed `in_red=[X-xast; phi-fiast]` (`fiast=pi/2`), with the steering saturated to `±umax=tan(45°)`. It is **interactive**: `input()` prompts for the initial pose (`xini`,`yini`,`phiini` in degrees) and the desired `xast`. Note the net was trained for `x*=0`, so it parks well for `xast` near 0; far-off setpoints would need retraining. Loop has a `kmax` step cap (no infinite loop) and arrays are preallocated then trimmed. Figures: trajectory (animated) + steering angle. Only `redcarro11.mat` exists in the tree — the old multi-`load` cascade (`redcarro10/12/13/14`) was removed since those files don't exist and only the last `load` ever took effect.

When modifying training behavior, the key knobs are: `R` (control-effort penalty, present only in the Estatico `Modelo0` cost, often zeroed via `0*0.05`), the per-state error weights `q = [q1; q2]` (now used by `Modelo0`, the BPTT family, and the carro), the additive measurement noise on `in_red` (usually zeroed via `0*...`), `x_ini` scaling (e.g. `2*x_ini`/`4*x_ini` to validate on larger initial conditions — and now simply adding/removing columns to change `nini`), the disturbance amplitude (`pert`/`wr`), the `errormax` relative-cost stop (now active via `erreltotal = ersum2total/J0`), and the `if(ersum2total > JJold) break` early-stop guard (present in Modelo1/3, commented out in Modelo0; the Dynamic family either omits it or — in `2a.m` — keeps the warning with the `break` commented out). The carro adds its own knobs: `etapa` (curriculum stage), `inscale` (input normalization), `Ttrunc` (BPTT truncation window), and `gmax` (gradient-clip norm).

## Conventions

- Explanatory comments are written in **Spanish** (the files were documented for study); identifiers are a mix of English and Spanish (`estado`=state, `deseado`=desired, `in_red`, `out_des`). Write new comments in Spanish to match.
- Commented-out alternative lines are marked `(alternativa)`; the math comments label each derivative by meaning (e.g. `du/dv`, `du/dc`).
- Coefficients are frequently left in `0*value` / `1*value` form so an experiment can be toggled by changing the leading factor rather than deleting the line — preserve this idiom when editing.
- Plots: **all scripts now loop** `for j = 1:nini` (or `1:nvar` in `Modelo3`), drawing one figure per initial condition / plant variant — states (and `deseado` overlay where present) on top, control below as subplots. A trailing figure `figure(nini+1)` holds the cost/error history where applicable (`JJ` in `Modelo0`, `JJ/JJ1/JJ2` in `2a.m`, `errk` in `Modelo1`/`Modelo3`); the carro overlays all initial conditions into two state-only figures (position x1, orientation x2) with dashed setpoint lines, no trailing cost figure. This replaced the old fixed two-subplot-pairs-per-figure layout (which also had a copy-paste bug in `Modelo0`, plotting `deseado(:,:,1)` for the 4th initial condition).
