%% ============================================================================
%  NEUROCONTROLADOR  -  MODELO 3 (SOLO VALIDACIÓN - Robustez ante variaciones de planta)
% ============================================================================
%  Objetivo:
%    VALIDAR (sin reentrenar) la ROBUSTEZ del controlador entrenado en
%    DynamicBPControlEstaticoModelo0.m cuando la PLANTA cambia respecto a la
%    nominal con la que se entrenó. Se aplica el MISMO controlador (red
%    redcontrolestatico0, ne = 2) sobre varias plantas modificadas y se
%    observa si el lazo cerrado sigue siendo estable (regulación al origen).
%
%  Este script NO entrena: carga los pesos guardados, simula el lazo cerrado
%  para cada variante de planta y grafica la respuesta. No modifica ni guarda
%  los pesos (los .mat quedan intactos). El entrenamiento se hace en Modelo 0.
%
%  Variaciones de planta evaluadas (editar libremente en la sección 3):
%    1) Nominal           : la planta con la que se entrenó (referencia).
%    2) A menos estable   : autovalores de A más cerca/encima del círculo unitario.
%    3) Ganancia B -50%   : el control entra a la planta con la mitad de efecto.
%    4) Bilineal G x2     : se duplica el término dependiente del estado (G*x)*u.
% ============================================================================

%% Inicialización del entorno de trabajo
clear;        % Borra todas las variables del espacio de trabajo
clc;          % Limpia la ventana de comandos
close all;    % Cierra todas las figuras abiertas

disp('Hello');

%% Definición del sistema dinámico (PLANTA NOMINAL y sus VARIACIONES)
%  Modelo discreto bilineal:  x(k+1) = A*x + B*u + (G*x)*u

% --- Planta NOMINAL (con la que se entrenó el controlador) ---
A = [  0.98   0.18
    -0.10   0.98 ];
B = [  0
    0.8 ];
G = [   0.1    0.0
    0.1   -0.1 ];

% --- Conjunto de VARIANTES de planta a evaluar (una por celda) ---
%  Para añadir/quitar casos, edita estas celdas y la lista de etiquetas.
Avar = { A , [1.06 0.18; -0.10 1.06] , A           , A      };
Bvar = { B , B                       , 0.5*B       , B      };
Gvar = { G , G                       , G           , 2*G    };
etiq = { 'Nominal' , 'A menos estable (diag=1.00)' , 'Ganancia B -50%' , 'Bilineal G x2' };
nvar = numel(Avar);   % Número de variantes (= 4)

%% Parámetros de simulación y condición inicial
ndata = 800;   % Número de pasos (horizonte) de cada simulación

% Condición inicial única (igual para todas las variantes, para comparar SOLO
% el efecto del cambio de planta y no el de la condición inicial)
x0 = [ 0.1
    0.1 ];
x0 = 1*x0;     % Factor de escala de la condición inicial

%% Punto de operación deseado (REGULACIÓN al origen)
%  Para probar la estabilización ante variaciones, el objetivo es el origen.
x1ast = 0; x2ast = 0; uast = 0;
r = [ x1ast
    x2ast ];

%% Arquitectura de la red neuronal (el CONTROLADOR)
ne = 2;    % Número de entradas (= estado actual; sin sesgo/bias)
nm = 50;   % Número de neuronas en la capa oculta
ns = 1;    % Número de salidas (señal de control escalar)

%% Carga de los pesos entrenados en el Modelo 0
%  Trae v, w, c, a, nm. El controlador se usa TAL CUAL (no se reentrena).
load redcontrolestatico0;

%% Simulación del lazo cerrado para cada VARIANTE de planta (solo validación)
estado  = zeros(ndata-1,2,nvar);   % Trayectoria de estados por variante
u       = zeros(ndata-1,nvar);     % Señal de control por variante
errk    = zeros(ndata-1,nvar);     % Norma del error (= |x| en regulación) por paso

for iv = 1:nvar
    % Planta de esta variante
    Av = Avar{iv};  Bv = Bvar{iv};  Gv = Gvar{iv};

    x = x0;   % Misma condición inicial para todas las variantes
    for k = 1:ndata-1
        % ---------- Propagación hacia adelante de la red (cálculo de u) ----------
        in_red = x - r;                        % Entrada a la red = error de estado
        m = v'*in_red;                         % Activación lineal de la capa oculta
        n = 2.0./(1 + exp(-(m-c)./a)) - 1;     % Sigmoide BIPOLAR (salida en [-1,1])
        out_red = w'*n;                        % Salida de la red
        u(k,iv) = out_red' + uast;             % Control = salida de la red + feedforward u*

        % ---------- Dinámica de la planta MODIFICADA ----------
        x = Av*x + Bv*u(k,iv) + (Gv*x)*u(k,iv);

        estado(k,:,iv) = x';
        errk(k,iv)     = norm(x - r);
    end
end

%% Métricas de validación (¿sigue estabilizando ante el cambio de planta?)
fprintf('\n=== VALIDACION ROBUSTEZ ANTE VARIACIONES DE PLANTA ===\n');
for iv = 1:nvar
    xf = estado(end,:,iv)';
    if all(isfinite(xf)) && norm(xf) < 1e-2
        veredicto = 'ESTABLE';
    else
        veredicto = 'NO estabiliza';
    end
    fprintf('Var %d (%-28s): |x_final| = %10.3e -> %s\n', ...
        iv, etiq{iv}, norm(xf), veredicto);
end

%% Visualización de resultados
%  Una figura por variante de planta: estados arriba, control abajo.
%  Figura final: norma del estado ||x|| a lo largo del tiempo (todas las variantes).
for iv = 1:nvar
    figure(iv);
    subplot(2,1,1);
    plot(estado(:,:,iv));   title(['States - ' etiq{iv}]);
    subplot(2,1,2);
    plot(u(:,iv));          title('Control input');
end

figure(nvar+1);
plot(errk);   title('Norma del estado ||x|| por variante de planta');
xlabel('k'); ylabel('||x||'); legend(etiq, 'Location', 'best');

% NOTA: este script es SOLO de validación. No actualiza ni guarda los pesos;
%       el entrenamiento se realiza en DynamicBPControlEstaticoModelo0.m.
