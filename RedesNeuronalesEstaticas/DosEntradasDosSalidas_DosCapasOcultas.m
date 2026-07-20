% DosEntradasDosSalidas_DosCapasOcultas (original: NeuronDosEntradasDosIntermediasBP.m)
% =========================================================================
% MLP feedforward 2-30-40-2 (mas neurona bias opcional) con DOS CAPAS
% OCULTAS, entrenado a mano con retropropagacion de errores (sin toolbox),
% en modo BATCH y con salida vectorial. Tema didactico: como se ENCADENA
% la retropropagacion al agregar una segunda capa oculta.
%
% Capas y pesos:
%   entrada in (ne)  --u-->  oculta 1: m = u'*in, n = sigmoide(m)   (nm=30)
%   oculta 1 n       --v-->  oculta 2: p = v'*n,  q = sigmoide(p)   (pq=40)
%   oculta 2 q       --w-->  salida  : out = w'*q                  (ns=2)
%
% Retropropagacion encadenada (nucleo del script):
%   eb  = dqdp.*(w*er)    error retropropagado a la capa oculta 2
%   e2b = dndm.*(v*eb)    error retropropagado a la capa oculta 1
%   dJdw += q*er' ;  dJdv += n*eb' ;  dJdu += in*e2b'
% Cada capa recibe el error de la siguiente multiplicado por sus pesos y
% filtrado por la derivada de su activacion: mismo patron, una etapa mas.
%
% Activacion en ambas capas ocultas: sigmoidea tipo 2 (bipolar) con
% pendiente fija 1 escrita explicitamente, n = 2./(1+exp(-m./1)) - 1,
% derivada (1 - n.^2)/2.
%
% Rarezas conservadas por fidelidad con el original (NO corregir):
% - No hay criterio de parada: siempre corre las 10000 epocas completas.
% - Los acumuladores dJdu, dJdv, dJdw SI se preasignan con zeros(...) en
%   cada epoca (asi lo hacia el original; en los otros scripts eran 0).
% - La linea "%load pesos;" comentada documenta que el original preveia
%   cargar pesos guardados en lugar de inicializar con randn.
% - El "./1" en las sigmoideas es una pendiente unitaria explicita
%   (gancho hacia el script de pendiente/centro); se conserva tal cual.
% - La variable "error" sombrea al builtin error(); se conserva el nombre.
% - La numeracion de figuras salta la 4 (1,2,3,5,6), como el original.
% - Arrays y, error, J crecen dinamicamente (sin preasignar), como el
%   original.
% - JJ solo en una linea: imprime el costo en cada epoca, como el original.
% - El titulo original decia "retroprogacion" (sic); aqui se escribe bien.

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
yb1 = 0.075*yb1;
yb1 = yb1 + 2*0.1*randn(N,1);      % Salida deseada 1 (ruido mas fuerte)
yb2 = a3*x2.^3 + a2*x2.^2 + a1*x1.^1 + a0;
yb2 = 0.075*yb2;
yb2 = yb2 + 1.5*0.1*randn(N,1);    % Salida deseada 2
yb = [ yb1  yb2 ];         % matriz de salidas deseadas N x 2

%% Arquitectura de la red y parametros de entrenamiento
ne = 2;    % Numero de neuronas de entrada
nm = 30;   % Neuronas de la capa oculta 1
pq = 40;   % Neuronas de la capa oculta 2
ns = 2;    % Numero de salidas

bias = input('Bias:  SI = 1 : ');
if(bias == 1)
    ne = ne + 1;
    x = [ x ones(N,1) ];
end

u = 1*0.35*randn(ne,nm);   % pesos entrada -> oculta 1
v = 1*0.35*randn(nm,pq);   % pesos oculta 1 -> oculta 2
w = 1*0.35*randn(pq,ns);   % pesos oculta 2 -> salida
%load pesos;               % (alternativa del original: cargar pesos guardados)

eta = input('eta pesos [0.1]: ');

%% Entrenamiento batch con retropropagacion en dos etapas (10000 epocas)
for iter = 1:10000
    JJ = 0;                        % costo acumulado de la epoca
    dJdu = zeros(ne,nm);           % acumuladores de gradiente (preasignados
    dJdv = zeros(nm,pq);           % con zeros en el original, a diferencia
    dJdw = zeros(pq,ns);           % de los otros scripts que usan 0)
    for k = 1:N
        in = (x(k,:))';            % patron k como columna
        m = u'*in;                 % entrada neta de la capa oculta 1
        n = 2.0./(1+exp(-m./1)) - 1;   % Sigmoidea Tipo 2 (pendiente 1 explicita)
        p = v'*n;                  % entrada neta de la capa oculta 2
        q = 2.0./(1+exp(-p./1)) - 1;   % Sigmoidea Tipo 2
        out = w'*q;                % salida lineal de la red (vector ns x 1)
        y(k,:) = out';
        er = out - (yb(k,:))';     % error vectorial del patron k
        error(k,:) = er';          % ("error" sombrea al builtin; se conserva)
        JJ = JJ + 0.5*er'*er;      % acumula el costo del patron
        dqdp = (1 - q.*q)/2;       % derivada de la sigmoidea en oculta 2
        dndm = (1 - n.*n)/2;       % derivada de la sigmoidea en oculta 1
        eb = dqdp.*(w*er);         % error retropropagado a la capa oculta 2
        e2b = dndm.*(v*eb);        % error retropropagado a la capa oculta 1
        dJdw = dJdw + q*er';       % acumula gradiente respecto a w
        dJdv = dJdv + n*eb';       % acumula gradiente respecto a v
        dJdu = dJdu + in*e2b';     % acumula gradiente respecto a u

        %   w = w - eta*dJdw;      % (actualizacion por patron, comentada)
        %   v = v - eta*dJdv;
        %   u = u - eta*dJdu;
    end
    w = w - eta*dJdw/N;            % actualizacion BATCH con gradiente promedio
    v = v - eta*dJdv/N;
    u = u - eta*dJdu/N;
    JJ                             % sin ; -> imprime el costo de la epoca
    J(iter,1) = JJ;
end

%% Graficas de resultados
figure(1);
plot(y(:,1),'-r');
hold on;
plot(yb(:,1),'*b');
title('Salida y1');
figure(2);
plot(y(:,2),'-r');
hold on;
plot(yb(:,2),'*b');
title('Salida y2');
figure(3);
plot(J);
title('Funcion de costo J');
figure(5);                 % la numeracion salta la 4, como el original
plot3(x1,x2,y(:,1),'-r',x1,x2,yb(:,1),'-b');
title('Salida y1');
figure(6);
plot3(x1,x2,y(:,2),'-r',x1,x2,yb(:,2),'-b');
title('Salida y2');
