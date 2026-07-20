% AjusteCubica_Escalamiento (original: NeuronCubicaEscalamiento.m)
% =========================================================================
% MLP feedforward 1-25-1 (mas neurona bias opcional) entrenado a mano con
% retropropagacion de errores (sin toolbox), en modo BATCH, para aproximar
% una funcion cubica ruidosa. Tema didactico: el PROBLEMA DE ESCALAMIENTO
% de la salida deseada. La variable FACTOR multiplica la magnitud de yb;
% al agrandarla, la salida deseada queda fuera del rango util que puede
% componer la capa de sigmoideas y el ajuste se degrada (probar con
% FACTOR = 1, 10, 30, ... y comparar la convergencia de J).
%
% Pipeline en cada epoca (iter):
%   1. Para cada patron k (sin actualizar pesos):
%      a. PROPAGACION   m = v'*in ; n = sigmoide bipolar ; out = w'*n
%      b. ACUMULACION   dJdw += er.*dydw ; dJdv += er.*dydv, con las
%                       sensibilidades explicitas dydw = n y
%                       dydv = in*(w.*dndm)'
%   2. ACTUALIZACION batch: w = w - eta*dJdw/nx ; v = v - eta*dJdv/nx
%   3. Costo JJ = 0.5*sum(error.^2) impreso y guardado en J(iter).
%
% Activacion: sigmoidea tipo 2 (bipolar), n = 2./(1+exp(-m)) - 1, con
% derivada dndm = (1 - n.^2)/2; la gaussiana queda comentada.
%
% Rarezas conservadas por fidelidad con el original (NO corregir):
% - No hay criterio de parada: siempre corre las 20000 epocas completas
%   (J si termina con exactamente 20000 filas, pero se deja crecer
%   dinamicamente igual que en el original).
% - eta = input(...) SIN punto y coma: imprime el valor ingresado.
% - a0 = -0*30 es simplemente 0 (literal conservado tal cual).
% - La variable "error" sombrea al builtin error(); se conserva el nombre.
% - JJ sin punto y coma: imprime el costo en cada epoca, como el original.

clear;
clc;
close all;

%% Datos de entrenamiento: cubica ruidosa escalada por FACTOR
a3 = 0.8*2;                % coeficientes del polinomio cubico
a2 = 0.3*4;
a1 = -0.8*25;
a0 = -0*30;                % igual a 0 (se conserva el literal)

x = -4:0.1:4;
x = x';
nx = length(x);

FACTOR = 1;       % Probar (escala de la salida deseada: 1, 10, 30, ...)
yb = a3*x.^3 + a2*x.^2 + a1*x.^1 + a0;
yb = FACTOR*0.075*yb;              % escalamiento bajo estudio
yb = yb + 1*0.2*randn(nx,1);       % ruido gaussiano

%% Arquitectura de la red y parametros de entrenamiento
ne = 1;    % Numero de entradas
nm = 25;   % Numero de intermedias

bias = input('Bias:  SI = 1 : ');
if(bias == 1)
    ne = ne + 1;
    x = [ x ones(nx,1) ];
end
v = 0.15*randn(ne,nm);     % Valor inicial de coeficientes v (matricial)
w = 0.15*randn(nm,1);      % Valor inicial de coeficientes w (matricial)

eta = input('eta [0.1]: ')         % sin ; -> imprime el valor (original)

%% Entrenamiento batch (20000 epocas fijas, sin criterio de parada)
for iter = 1:20000
    dJdw = 0;                      % acumuladores de gradiente de la epoca
    dJdv = 0;
    for k = 1:nx
        in = (x(k,:))';            % patron k como columna
        m = v'*in;                 % entrada neta de la capa oculta
        n = 2.0./(1+exp(-m)) - 1;      % Sigmoidea Tipo 2
        %n = exp(-m.^2);               % Gaussiana
        out = w'*n;                % salida lineal de la red
        y(k,1) = out;
        er = out - yb(k,1);        % error del patron k
        error(k,1) = er;           % ("error" sombrea al builtin; se conserva)
        dndm = (1 - n.*n)/2;           % Sigmoidea Tipo 2
        %dndm = -2.0*(n.*m);           % Gaussiana
        dydw = n;                  % sensibilidad de la salida respecto a w
        dJdw = dJdw + er.*dydw;    % acumula gradiente respecto a w
        dydv = in*(w.*dndm)';      % sensibilidad de la salida respecto a v
        dJdv = dJdv + er.*dydv;    % acumula gradiente respecto a v
    end
    w = w - eta*dJdw/nx;           % actualizacion BATCH con gradiente promedio
    v = v - eta*dJdv/nx;
    JJ = 0.5*sum(error.*error)     % costo total; sin ; -> se imprime
    J(iter,1) = JJ;
end

%% Graficas de resultados
figure(1);
plot(x(:,1),y,x(:,1),yb,'*');
title('Salida - Datos Deseados y Red Neuronal');
figure(2);
plot(J);
title('Funcion de Costo - Iteracion');
