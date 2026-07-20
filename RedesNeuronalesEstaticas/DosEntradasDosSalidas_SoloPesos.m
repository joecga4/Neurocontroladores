% DosEntradasDosSalidas_SoloPesos (original: NeuronDosEntradasDosSalidas.m)
% =========================================================================
% MLP feedforward 2-50-2 (mas neurona bias opcional) entrenado a mano con
% retropropagacion de errores (sin toolbox), en modo BATCH, con SALIDA
% VECTORIAL: dos entradas (x1, x2) y dos salidas deseadas (yb1, yb2), cada
% una un polinomio cubico cruzado de ambas entradas mas ruido. Solo se
% entrenan los pesos v y w; la pendiente de las sigmoideas queda fija en
% a = ones(nm,1) (comparar con DosEntradasDosSalidas_PendienteCentro, que
% ademas entrena la pendiente a y el centro c).
%
% Pipeline en cada epoca (iter):
%   1. Para cada patron k (sin actualizar pesos):
%      a. PROPAGACION   m = v'*in ; n = 2./(1+exp(-m./a)) - 1 ; out = w'*n
%      b. COSTO         JJ = JJ + 0.5*er'*er  (er es vector 2x1)
%      c. ACUMULACION   dJdw += n*er' ; dJdv += in*(dndm.*(w*er))'
%         (w*er retropropaga el error vectorial hacia la capa oculta)
%   2. ACTUALIZACION batch: w = w - eta*dJdw/N ; v = v - eta*dJdv/N
%
% Activacion: sigmoidea tipo 2 (bipolar) con pendiente fija a = 1,
% n = 2./(1+exp(-m./a)) - 1, derivada dndm = (1 - n.^2)/2; la gaussiana
% queda comentada, igual que la actualizacion por patron.
%
% El enunciado original pide probar:
%   (a) cantidad de neuronas en la capa intermedia nm
%   (b) valor inicial de los pesos v y w
%   (c) tipo de funcion de activacion (y su derivada)
%   (d) neurona bias
%
% Rarezas conservadas por fidelidad con el original (NO corregir):
% - No hay criterio de parada: siempre corre las 3000 epocas completas.
% - a = ones(nm,1) se usa en la sigmoidea (-m./a) pero nunca se entrena
%   aqui: es el gancho didactico hacia el script de pendiente/centro.
% - La variable "error" sombrea al builtin error(); se conserva el nombre.
% - La numeracion de figuras salta la 4 (1,2,3,5,6), como el original.
% - Arrays y, error, J crecen dinamicamente (sin preasignar), como el
%   original.
% - JJ solo en una linea: imprime el costo en cada epoca, como el original.

clear;
clc;
close all;

%% Datos de entrenamiento: dos cubicas cruzadas ruidosas
a3 = 0.5*2;                % coeficientes de los polinomios
a2 = 0.3*4;
a1 = -0.8*25;
a0 = -0*30;                % igual a 0 (se conserva el literal)

x1 = -4:0.1:4;
x1 = x1';
N = length(x1);
x2 = linspace(-3,3,N);
x2 = x2';
x = [ x1 x2 ];             % matriz de entradas N x 2

yb1 = a3*x1.^3 + a2*x1.^2 + a1*x2.^1 + a0;
yb1 = 1*0.075*yb1;
yb1 = yb1 + 0.1*randn(N,1);        % Salida deseada 1
yb2 = a3*x2.^3 + a2*x2.^2 + a1*x1.^1 + a0;
yb2 = 0.6*0.075*yb2;
yb2 = yb2 + 0.1*randn(N,1);        % Salida deseada 2
yb = [ yb1  yb2 ];         % matriz de salidas deseadas N x 2

%% Arquitectura de la red y parametros de entrenamiento
ne = 2;    % Numero de neuronas de entrada
nm = 50;   % Numero de neuronas intermedias
ns = 2;    % Numero de salidas

bias = input('Bias:  SI = 1 : ');
if(bias == 1)
    ne = ne + 1;
    x = [ x ones(N,1) ];
end

v = 0.25*randn(ne,nm);     % Valor inicial de coeficientes v (matricial)
w = 0.25*randn(nm,ns);     % Valor inicial de coeficientes w (matricial)
a = ones(nm,1);            % pendiente de las sigmoideas, FIJA en este script

eta = input('eta pesos [0.1]: ');

%% Entrenamiento batch (3000 epocas fijas, sin criterio de parada)
for iter = 1:3000
    JJ = 0;                        % costo acumulado de la epoca
    dJdw = 0;      dJdv = 0;       % acumuladores de gradiente
    for k = 1:N
        in = (x(k,:))';            % patron k como columna
        m = v'*in;                 % entrada neta de la capa oculta
        n = 2.0./(1+exp(-m./a)) - 1;     % Sigmoidea Tipo 2 (pendiente a fija)
        % n = exp(-m.^2);                % Gaussiana
        out = w'*n;                % salida lineal de la red (vector ns x 1)
        y(k,:) = out';
        er = out - (yb(k,:))';     % error vectorial del patron k
        error(k,:) = er';          % ("error" sombrea al builtin; se conserva)
        JJ = JJ + 0.5*er'*er;      % acumula el costo del patron
        dndm = (1 - n.*n)/2;             % Sigmoidea Tipo 2
        % dndm = -2.0*(n.*m);            % Gaussiana
        dJdw = dJdw + n*er';                 % acumula gradiente respecto a w
        dJdv  = dJdv + in * (dndm.*(w*er))'; % acumula gradiente respecto a v

        %  w = w - eta*dJdw;        % (actualizacion por patron, comentada)
        %  v = v - eta*dJdv;
    end
    w = w - eta*dJdw/N;            % actualizacion BATCH: una vez por epoca,
    v = v - eta*dJdv/N;            % con el gradiente promedio
    JJ                             % sin ; -> imprime el costo de la epoca
    J(iter,1) = JJ;
end

%% Graficas de resultados
figure(1);
plot(y(:,1),'-r');
hold on;
plot(yb(:,1),'*b');
title('Salida y1: Datos y Red Neuronal');
figure(2);
plot(y(:,2),'-r');
hold on;
plot(yb(:,2),'*b');
title('Salida y2: Datos y Red Neuronal');
figure(3);
plot(J);
title('Funcion de Costo J - Iteraciones');
figure(5);                 % la numeracion salta la 4, como el original
plot3(x1,x2,y(:,1),'-r',x1,x2,yb(:,1),'-b');
title('Salida y1 en Funcion de x1 y x2');
figure(6);
plot3(x1,x2,y(:,2),'-r',x1,x2,yb(:,2),'-b');
title('Salida y2 en Funcion de x1 y x2');
