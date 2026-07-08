%% ============================================================================
%  NEUROCONTROLADOR  -  MODELO 1 (SOLO VALIDACIÓN - Control por SEGUIMIENTO)
% ============================================================================
%  Objetivo:
%    VALIDAR (sin reentrenar) el controlador entrenado en
%    DynamicBPControlEstaticoModelo0.m para un problema de SEGUIMIENTO: que
%    el sistema alcance un ESTADO DESEADO (setpoint) en régimen permanente,
%    en lugar de ir al origen.
%
%  Este script NO entrena: carga los pesos guardados, simula el lazo cerrado
%  y grafica la respuesta. No modifica ni guarda los pesos (los .mat quedan
%  intactos). El entrenamiento se realiza únicamente en el Modelo 0.
%
%  Punto de operación deseado elegido:
%        x1* = 0.1     x2* = 0.01041     u* = 0.01262
%    Estos valores cumplen la condición de convergencia del sistema. Se fija
%    x1* = 0.1 y a partir de él se calculan x2* y u*. Pueden elegirse otros
%    estados deseados siempre que se satisfaga dicha condición.
%
%  Ley de control aplicada (idéntica al entrenamiento + feedforward):
%        in_red = x - r ;   u = red(in_red) + u*
% ============================================================================

%% Inicialización del entorno de trabajo
clear;        % Borra todas las variables del espacio de trabajo
clc;          % Limpia la ventana de comandos
close all;    % Cierra todas las figuras abiertas

disp('Hello');

%% Definición del sistema dinámico (la PLANTA a controlar)
%  Modelo discreto bilineal:  x(k+1) = A*x + B*u + (G*x)*u + W*perturbación

% Matriz de estado A (sistema ESTABLE)
A = [  0.98   0.18
    -0.10   0.98 ];

% Matriz de entrada B
B = [  0
    0.8 ];

% Matriz de la parte bilineal G (ganancia de entrada dependiente del estado)
G = [   0.1    0.0
    0.1   -0.1 ];

% Vector de acoplamiento de la perturbación externa
W = [ 0
    0.01 ];

pert = 0*0.02;   % Amplitud de la perturbación externa senoidal
                 % (desactivada por el 0*; pon 1*0.02 para validar rechazo)

%% Parámetros de simulación y condiciones iniciales
ndata = 1000;   % Número de pasos (horizonte) de cada simulación

% Cuatro estados iniciales (una columna por caso)
x_ini = [ 0.1   0.1  -0.1  -0.1
    0.1  -0.1   0.1  -0.1 ];

x_ini = 40*x_ini;   % Factor de escala: se valida con condiciones iniciales mayores
                   % que las de entrenamiento (prueba de generalización)

nx   = size(x_ini,1);   % Número de estados de la planta
nini = size(x_ini,2);   % Número de condiciones iniciales (deducido de x_ini)

%% Punto de operación deseado (setpoint y control de equilibrio)
x1ast = 0.1;       % Estado deseado x1*
x2ast = 0.01041;   % Estado deseado x2* (calculado a partir de x1*)
uast  = 0.01262;   % Control de equilibrio u* (feedforward)
%  x1ast = 0;        % (alternativa) regulación al origen
%  x2ast = 0;
%  uast  = 0;

% Vector de estado deseado (setpoint)
r = [ x1ast
    x2ast ];

%% Arquitectura de la red neuronal (el CONTROLADOR)
ne = 2;    % Número de entradas (= estado actual; sin sesgo/bias)
nm = 50;   % Número de neuronas en la capa oculta
ns = 1;    % Número de salidas (señal de control escalar)

%% Carga de los pesos entrenados en el Modelo 0
%  Trae v, w, c, a, nm. El controlador se usa TAL CUAL (no se reentrena).
load redcontrolestatico0;

%% Simulación del lazo cerrado (SOLO validación, sin entrenamiento)
estado  = zeros(ndata-1,nx,nini);   % Trayectoria de estados por condición inicial
deseado = zeros(ndata-1,nx,nini);   % Setpoint (constante) para graficar
u       = zeros(ndata-1,nini);      % Señal de control por condición inicial
errk    = zeros(ndata-1,nini);      % Norma del error de seguimiento por paso

% --- Recorrido sobre las condiciones iniciales ---
for j = 1:nini
    x = x_ini(:,j);   % Estado inicial del caso j

    % --- Simulación de ndata pasos para el caso j ---
    for k = 1:ndata-1

        % ---------- Propagación hacia adelante de la red (cálculo de u) ----------
        in_red = x - r;                        % Entrada a la red = error de estado respecto al setpoint
        m = v'*in_red;                         % Activación lineal de la capa oculta
        n = 2.0./(1 + exp(-(m-c)./a)) - 1;     % Sigmoide BIPOLAR (salida en [-1,1])
        out_red = w'*n;                        % Salida de la red
        u(k,j) = out_red' + uast;              % Control = salida de la red + feedforward u*

        % ---------- Dinámica de la planta ----------
        % Actualización del estado, incluyendo la perturbación senoidal externa
        x = A*x + B*u(k,j) + (G*x)*u(k,j) + W*pert*sin(2*pi*1*k*0.01);

        estado(k,:,j)  = x';          % Se guarda el estado para graficar
        deseado(k,:,j) = r';          % El deseado es el setpoint (constante)
        errk(k,j)      = norm(x - r); % Norma del error de seguimiento en el paso k
    end
end

%% Métricas de validación (error en régimen permanente)
fprintf('\n=== VALIDACION TRACKING (setpoint x1*=%.4f  x2*=%.5f  u*=%.5f) ===\n', ...
    x1ast, x2ast, uast);
for j = 1:nini
    xf = estado(end,:,j)';
    fprintf('CI %d: x_final = [% .5f % .5f] | error vs setpoint = %.3e\n', ...
        j, xf(1), xf(2), norm(xf - r));
end

%% Visualización de resultados
%  Una figura por condición inicial: estados (con su setpoint) arriba, control abajo.
%  Figura final: norma del error de seguimiento a lo largo del tiempo.
for j = 1:nini
    figure(j);
    subplot(2,1,1);
    plot(estado(:,:,j)); hold on; plot(deseado(:,:,j));
    title(sprintf('States - Initial %d', j));
    subplot(2,1,2);
    plot(u(:,j));   title('Control input');
end

figure(nini+1);
plot(errk);   title('Error de seguimiento ||x - r|| por condición inicial');
xlabel('k'); ylabel('||x - r||');

% NOTA: este script es SOLO de validación. No actualiza ni guarda los pesos;
%       el entrenamiento se realiza en DynamicBPControlEstaticoModelo0.m.
