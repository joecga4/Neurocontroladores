% DosEntradasDosSalidas_PendienteCentro (original: NeuronDosEntradasDosSalidas_PendienteCentro.m)
% =========================================================================
% MLP feedforward 2-10-2 (mas neurona bias opcional) entrenado a mano con
% retropropagacion de errores (sin toolbox), en modo BATCH y con salida
% vectorial. Tema didactico: ademas de los pesos v y w se entrenan la
% PENDIENTE a y el CENTRO c de las sigmoideas, con tasas propias etaa y
% etac. La sigmoidea parametrizada es n = 1./(1+exp(-(m-c)./a)) (tipo 1);
% el original indica que se pueden incluir la tipo 2 y la gaussiana.
%
% Gradientes adicionales respecto de los parametros de la activacion
% (encadenando con el error retropropagado w*er):
%   dJda += (w*er).*n.*(n-1).*(m-c)./(a.*a)
%   dJdc += (w*er).*n.*(n-1)./a
%
% Pipeline en cada epoca (iter):
%   1. Para cada patron k (sin actualizar parametros):
%      PROPAGACION  m = v'*in ; n = 1./(1+exp(-(m-c)./a)) ; out = w'*n
%      ACUMULACION  dJdw, dJdv (como siempre) y ademas dJda, dJdc
%   2. ACTUALIZACION batch: w, v con eta; a con etaa; c con etac
%      (todas con gradiente promedio /N)
%
% Experimentos que propone el original (aislar el efecto de cada tasa):
%   Probar: eta=0.1  etaa=0     etac=0
%   Probar: eta=0.1  etaa=0.01  etac=0
%   Probar: eta=0.1  etaa=0.0   etac=0.01
% La salida deseada se agranda con FACTOR = 30/1: con ese escalamiento se
% aprecia mejor la ayuda de adaptar a y c ("mayores valores de v y w si
% solo se cambia a y c", decia el original).
%
% Rarezas conservadas por fidelidad con el original (NO corregir):
% - No hay criterio de parada: siempre corre las 15000 epocas completas.
% - dJda y dJdc se acumulan con un multiplicador 1* redundante (1*dJda + ...),
%   conservado tal cual.
% - La variable "error" sombrea al builtin error(); se conserva el nombre.
% - La numeracion de figuras salta la 4 (1,2,3,5,6), como el original.
% - Arrays y, error, J crecen dinamicamente (sin preasignar), como el
%   original.
% - JJ solo en una linea: imprime el costo en cada epoca, como el original.

clear;
clc;
close all;

%% Datos de entrenamiento: dos cubicas cruzadas ruidosas, escaladas
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

FACTOR = 30/1;             % escalamiento de la salida deseada
yb1 = a3*x1.^3 + a2*x1.^2 + a1*x2.^1 + a0;
yb1 = 1*0.075*yb1;
yb1 = yb1 + 0.1*randn(N,1);        % Salida deseada 1
yb2 = a3*x2.^3 + a2*x2.^2 + a1*x1.^1 + a0;
yb2 = 1*0.075*yb2;
yb2 = yb2 + 0.1*randn(N,1);        % Salida deseada 2
yb = FACTOR*[ yb1  yb2 ];  % matriz de salidas deseadas N x 2, escalada

%% Arquitectura de la red y parametros de entrenamiento
ne = 2;    % Numero de neuronas de entrada
nm = 10;   % Numero de neuronas intermedias
ns = 2;    % Numero de salidas

bias = input('Bias:  SI = 1 : ');
if(bias == 1)
    ne = ne + 1;
    x = [ x ones(N,1) ];
end

v = 1*0.25*randn(ne,nm);   % Mayores valores de v y w si solo se cambia a y c
w = 1*0.25*randn(nm,ns);
a = ones(nm,1);            % pendiente inicial de las sigmoideas (entrenable)
c = zeros(nm,1);           % centro inicial de las sigmoideas (entrenable)

eta  = input('eta pesos [0.1]: ');
etaa = input('eta pendiente de sigmoidea: ');
etac = input('eta centro de sigmoidea: ');

%% Entrenamiento batch de w, v, a y c (15000 epocas fijas)
for iter = 1:15000
    JJ = 0;                        % costo acumulado de la epoca
    dJdw = 0;      dJdv = 0;       % acumuladores de gradiente de pesos
    dJda = 0;      dJdc = 0;       % acumuladores de gradiente de a y c
    for k = 1:N
        in = (x(k,:))';            % patron k como columna
        m = v'*in;                 % entrada neta de la capa oculta
        n = 1.0./(1+exp(-(m-c)./a));   % Sigmoidea Tipo 1 (centro c, pendiente a)
        out = w'*n;                % salida lineal de la red (vector ns x 1)
        y(k,:) = out';
        er = out - (yb(k,:))';     % error vectorial del patron k
        error(k,:) = er';          % ("error" sombrea al builtin; se conserva)
        JJ = JJ + 0.5*er'*er;      % acumula el costo del patron
        dndm = n.*(1-n)./a;            % Sigmoidea 1 (derivada respecto a m)
        dJdw = dJdw + n*er';                 % acumula gradiente respecto a w
        dJdv = dJdv + in * (dndm.*(w*er))';  % acumula gradiente respecto a v
        dJda = 1*dJda + (w*er).*n.*(n-1).*(m-c)./(a.*a);  % gradiente de la pendiente
        dJdc = 1*dJdc + (w*er).*n.*(n-1)./a;              % gradiente del centro

        %  w = w - eta*dJdw;        % (actualizacion por patron, comentada)
        %  v = v - eta*dJdv;
    end
    w = w - eta*dJdw/N;            % actualizacion BATCH con gradiente promedio
    v = v - eta*dJdv/N;
    a = a - etaa*dJda/N;           % adapta la pendiente de cada sigmoidea
    c = c - etac*dJdc/N;           % adapta el centro de cada sigmoidea
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
