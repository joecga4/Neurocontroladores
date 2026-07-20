% AjusteRecta_EntrenaPorPatron (original: NeuronLinealPatron.m)
% =========================================================================
% MLP feedforward 1-20-1 (mas neurona bias opcional) entrenado a mano con
% retropropagacion de errores (sin toolbox) para aproximar la recta ruidosa
% yb = a*x + b + ruido. Tema didactico: entrenamiento POR PATRON (online),
% los pesos v y w se actualizan DENTRO del bucle de muestras, una vez por
% cada patron k (contrastar con AjusteRecta_EntrenaBatch, que acumula los
% gradientes y actualiza una sola vez por epoca).
%
% Pipeline en cada epoca (iter):
%   1. Para cada patron k:
%      a. PROPAGACION    m = v'*in ; n = sigmoide(m) ; out = w'*n
%      b. GRADIENTES     dJdw = er.*n ; dJdv = er.*in*(w.*dndm)'
%      c. ACTUALIZACION  w = w - eta*dJdw ; v = v - eta*dJdv  (por patron)
%   2. Costo JJ = 0.5*sum(error.^2)/N (se imprime) y criterio de parada
%      porcentual: dJpor = sqrt(|JJ - Jold|/JJ)*100 < errorporc.
%
% Activacion usada: sigmoidea tipo 1, n = 1./(1+exp(-m)), dndm = n.*(1-n).
% Quedan comentadas las alternativas que el enunciado original pide probar:
% sigmoidea tipo 2 (bipolar) n = 2./(1+exp(-m)) - 1 con dndm = (1-n.^2)/2,
% y gaussiana n = exp(-m.^2) con dndm = -2*(n.*m).
%
% El enunciado original pide probar ademas:
%   (a) cantidad de neuronas en la capa intermedia nm
%   (b) valor inicial de los pesos v y w
%   (c) tipo de funcion de activacion (y su derivada)
%   (d) neurona bias
%
% Rarezas conservadas por fidelidad con el original (NO corregir):
% - dJdw = 0 y dJdv = 0 al inicio de cada epoca son vestigiales: en el modo
%   por patron los gradientes se ASIGNAN (=), no se acumulan (+); esos ceros
%   corresponden a la version batch que quedo comentada al final del bucle.
% - La variable "error" sombrea al builtin error(); se conserva el nombre.
% - Si el criterio de parada se cumple en la epoca iter, el break ocurre
%   ANTES de asignar J(iter,1): J queda con iter-1 filas mientras que w11 y
%   v12 tienen iter filas. Por eso NINGUN array historico se preasigna
%   (y, error, J, w11, v12 crecen dinamicamente, igual que en el original).
% - La neurona bias entra con valor 0.5 (en la version batch entra con 1).
% - Multiplicadores redundantes en literales (1*0.05, 0.5*0.075): tal cual.
% - JJ sin punto y coma: imprime el costo en cada epoca, como el original.

clear;
clc;
close all;

%% Datos de entrenamiento: recta ruidosa
a = 1;                             % pendiente de la recta
b = 2;                             % intercepto

x = -2:0.05:3;
x = x';
N = length(x);
yb = a*x + b + 0.2*randn(N,1);     % salida deseada = recta + ruido gaussiano

%% Arquitectura de la red y parametros de entrenamiento
ne = 1;     % Numero de entradas
nm = 20;    % Numero de neuronas intermedias

bias = 1;   % SI = 1 : Se agrega neurona bias
if(bias == 1)
    ne = ne + 1;
    x = [ x  0.5*ones(N,1) ];      % la entrada bias vale 0.5 en este script
end
v = 1*0.05*randn(ne,nm);   % Valor inicial de coeficientes v (matricial)
w = 1*0.05*randn(nm,1);    % Valor inicial de coeficientes w (matricial)
Jold = 1e15;               % Valor grande de funcion de costo al principio
errorporc = 0.5*0.075;     % Maximo error porcentual (criterio de parada)
eta = 0.05;                % Tasa de aprendizaje

%% Entrenamiento por patron (online)
for iter = 1:50000
    w11(iter,1) = w(1,1);          % historia de un peso de salida
    v12(iter,1) = v(1,2);          % historia de un peso de entrada
    dJdw = 0;    dJdv = 0;         % vestigial aqui: por patron se usa =, no +
    for k = 1:N
        in = (x(k,:))';            % patron k como columna
        m = v'*in;                 % entrada neta de la capa oculta
        n = 1.0./(1+exp(-m));          % Sigmoidea 1
        % n = 2.0./(1+exp(-m)) - 1;    % Sigmoidea 2
        % n = exp(-m.^2);              % Gaussiana
        out = w'*n;                % salida lineal de la red
        y(k,1) = out;
        er = out - yb(k,1);        % error del patron k
        error(k,1) = er;           % ("error" sombrea al builtin; se conserva)
        dndm = n.*(1-n);           % Sigmoidea 1
        % dndm = (1 - n.*n)/2;     % Sigmoidea 2
        % dndm = -2.0*(n.*m);      % Gaussiana
        dJdw = er.*n;                  % gradiente respecto a w (solo patron k)
        dJdv = er.*in*(w.*dndm)';      % gradiente respecto a v (solo patron k)

        w = w - eta*dJdw;          % actualizacion POR PATRON:
        v = v - eta*dJdv;          % dentro del bucle de muestras
    end
    % w = w - eta*dJdw/N;          % (actualizacion batch, version comentada)
    % v = v - eta*dJdv/N;
    JJ = 0.5*sum(error.*error)/N   % costo promedio; sin ; -> se imprime
    dJ = abs(JJ - Jold);
    dJpor = sqrt(dJ/JJ)*100;       % variacion porcentual (criterio peculiar)
    if(dJpor < errorporc)    % Porcentual
        break;                     % OJO: sale ANTES de asignar J(iter,1)
    end
    J(iter,1) = JJ;
    Jold = JJ;
end

%% Graficas de resultados
figure(1);
plot(x(:,1),y,x(:,1),yb,'*');
title('Grafico de los Datos y la Funcion de la Red Neuronal X-Y');
figure(2);
subplot(3,1,1);  plot(J);      title('Funcion de Costo J en cada Iteracion');
subplot(3,1,2);  plot(w11);    title('Coeficiente w11 en cada Iteracion');
subplot(3,1,3);  plot(v12);    title('Coeficiente v12 en cada Iteracion');
