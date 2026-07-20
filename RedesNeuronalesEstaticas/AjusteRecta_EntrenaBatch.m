% AjusteRecta_EntrenaBatch (original: NeuronLinealPatronBatch.m)
% =========================================================================
% MLP feedforward 1-2-1 (mas neurona bias opcional) entrenado a mano con
% retropropagacion de errores (sin toolbox) para aproximar la recta ruidosa
% yb = a*x + b + ruido. Tema didactico: entrenamiento BATCH, los gradientes
% se ACUMULAN sobre las N muestras y los pesos se actualizan UNA sola vez
% por epoca, con el promedio dJd*/N (contrastar con la version por patron:
% AjusteRecta_EntrenaPorPatron). El enunciado original tambien propone el
% ejercicio inverso: convertir este programa a entrenamiento por patron.
%
% Pipeline en cada epoca (iter):
%   1. Para cada patron k (SIN actualizar pesos):
%      a. PROPAGACION   m = v'*in ; n = sigmoide(m) ; out = w'*n
%      b. ACUMULACION   dJdw = dJdw + n*er' ; dJdv = dJdv + in*(dndm.*(w*er))'
%   2. ACTUALIZACION batch: w = w - eta*dJdw/N ; v = v - eta*dJdv/N
%   3. Costo JJ = 0.5*sum(error.^2) (se imprime; OJO aqui SIN dividir
%      entre N) y criterio de parada dJpor = sqrt(|JJ-Jold|/JJ)*100.
%
% Activacion usada: sigmoidea tipo 2 (bipolar), n = 2./(1+exp(-m)) - 1 con
% derivada dndm = (1 - n.^2)/2. Quedan comentadas la sigmoidea tipo 1 y la
% gaussiana, y tambien la forma "por patron" de los gradientes y de la
% actualizacion de pesos (los experimentos del enunciado original).
%
% El enunciado original pide probar:
%   (a) cantidad de neuronas en la capa intermedia nm
%   (b) valor inicial de los pesos v y w
%   (c) tipo de funcion de activacion (y su derivada)
%   (d) neurona bias
%
% Rarezas conservadas por fidelidad con el original (NO corregir):
% - JJ se calcula SIN promediar entre N (a diferencia de la version por
%   patron); la actualizacion de pesos si divide entre N.
% - La variable "error" sombrea al builtin error(); se conserva el nombre.
% - Si el criterio de parada se cumple en la epoca iter, el break ocurre
%   ANTES de asignar J(iter,1): J queda con iter-1 filas mientras que w11
%   tiene iter filas. Por eso NINGUN array historico se preasigna
%   (y, error, J, w11 crecen dinamicamente, igual que en el original).
% - Aqui la neurona bias entra con valor 1 (en la version por patron, 0.5).
% - Multiplicador redundante en 1*0.2: se conserva tal cual.
% - JJ sin punto y coma: imprime el costo en cada epoca, como el original.

clear;
clc;
close all;

%% Datos de entrenamiento: recta ruidosa
a = 1;                               % pendiente de la recta
b = 2;                               % intercepto

x = -2:0.05:3;
x = x';
N = length(x);
yb = a*x + b + 1*0.2*randn(N,1);     % salida deseada = recta + ruido gaussiano

%% Arquitectura de la red y parametros de entrenamiento
ne = 1;     % Numero de entradas
nm = 2;     % Numero de neuronas intermedias

bias = 1;   % SI = 1 : Se agrega neurona bias
if(bias == 1)
    ne = ne +1;
    x = [ x ones(N,1) ];             % la entrada bias vale 1 en este script
end
v = 0.15*randn(ne,nm);     % Valor inicial de coeficientes v (matricial)
w = 0.15*randn(nm,1);      % Valor inicial de coeficientes w (matricial)

Jold = 1e15;               % valor inicial de J se hace grande
errorporc = 0.25;          % Maximo error porcentual (criterio de parada)

eta = 0.05;                % Tasa de aprendizaje

%% Entrenamiento batch
for iter = 1:5000
    w11(iter,1) = w(1,1);            % historia de un peso de salida
    dJdv = 0;                        % acumuladores de gradiente de la epoca
    dJdw = 0;
    for k = 1:N
        in = (x(k,:))';              % patron k como columna
        m = v'*in;                   % entrada neta de la capa oculta
        %  n = 1.0./(1+exp(-m));         % Sigmoidea 1
        n = 2.0./(1+exp(-m)) - 1;        % Sigmoidea 2
        % n = exp(-m.^2);                % Gaussiana
        out = w'*n;                  % salida lineal de la red
        y(k,1) = out;
        er = out - yb(k,1);          % error del patron k
        error(k,1) = er;             % ("error" sombrea al builtin; se conserva)
        %  dndm = n.*(1-n);              % Sigmoidea 1
        dndm = (1 - n.*n)/2;             % Sigmoidea 2
        % dndm = -2.0*(n.*m);            % Gaussiana
        %  dJdw = 1*dJdw + er.*n;              % (forma escalar comentada
        %  dJdv = 1*dJdv + er.*in*(w.*dndm)';  %  del original)

        dJdw = dJdw + n*er';                 % acumula gradiente respecto a w
        dJdv  = dJdv + in * (dndm.*(w*er))'; % acumula gradiente respecto a v

        % w = w - eta*dJdw;          % (actualizacion por patron, comentada)
        % v = v - eta*dJdv;
    end
    w = w - eta*dJdw/N;              % actualizacion BATCH: una vez por epoca,
    v = v - eta*dJdv/N;              % con el gradiente promedio
    JJ = 0.5*sum(error.*error)       % costo total (sin /N); sin ; -> se imprime
    dJ = abs(JJ - Jold);
    dJpor = sqrt(dJ/JJ)*100;         % variacion porcentual (criterio peculiar)
    if(dJpor < errorporc)    % Porcentual
        break;                       % OJO: sale ANTES de asignar J(iter,1)
    end
    J(iter,1) = JJ;
    Jold = JJ;
end

%% Graficas de resultados
figure(1);
plot(x(:,1),y,x(:,1),yb,'*');
title('Grafico de los Datos y la Funcion de la Red Neuronal X-Y');
figure(2);
subplot(2,1,1);  plot(J);    title('Funcion de Costo J en cada Iteracion');
subplot(2,1,2);  plot(w11);  title('Coeficiente w11 en cada Iteracion');
