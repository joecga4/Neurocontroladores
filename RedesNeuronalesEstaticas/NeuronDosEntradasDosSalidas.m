% Entrenamiento Batch - Salida Vectorial.
% Dos entradas y dos salidas.
% Los pesos v y w se trabajan cada uno como matrix (en bloque).
% Probar con:
% (a) Cantidad de neuronas en la capa intermedia nm
% (b) Valor inicial de los pesos v y w
% (c) Tipo de función de activación (y su derivada)
% (d) Neurona bias

clear;
clc;
close all;

a3 = 0.5*2;
a2 = 0.3*4;
a1 = -0.8*25;
a0 = -0*30;

x1 = -4:0.1:4;
x1 = x1';
N = length(x1);
x2 = linspace(-3,3,N);
x2 = x2';
x = [ x1 x2 ];

yb1 = a3*x1.^3 + a2*x1.^2 + a1*x2.^1 + a0;
yb1 = 1*0.075*yb1;
yb1 = yb1 + 0.1*randn(N,1);       % Salida deseada 1
yb2 = a3*x2.^3 + a2*x2.^2 + a1*x1.^1 + a0;
yb2 = 0.6*0.075*yb2;
yb2 = yb2 + 0.1*randn(N,1);       % Salida deseada 2
yb = [ yb1  yb2 ];

ne = 2;    % Número de neuronas de entrada
nm = 50;   % Número de neuronas intermedias
ns = 2;    % Número de salidas

bias = input('Bias:  SI = 1 : ');
if(bias == 1)
      ne = ne + 1;
      x = [ x ones(N,1) ];   
end

v = 0.25*randn(ne,nm);
w = 0.25*randn(nm,ns);
a = ones(nm,1);

eta = input('eta pesos [0.1]: ');

for iter = 1:3000
JJ = 0;
dJdw = 0;      dJdv = 0;
for k = 1:N   
  in = (x(k,:))';
  m = v'*in; 
  n = 2.0./(1+exp(-m./a)) - 1;     % Sigmoidea Tipo 2
% n = exp(-m.^2);                  % Gaussiana
  out = w'*n;
  y(k,:) = out';
  er = out - (yb(k,:))';
  error(k,:) = er';
  JJ = JJ + 0.5*er'*er;
  dndm = (1 - n.*n)/2;      % Sigmoidea Tipo 2
% dndm = -2.0*(n.*m);       % Gaussiana
  dJdw = dJdw + n*er';
  dJdv  = dJdv + in * (dndm.*(w*er))';

%  w = w - eta*dJdw;
%  v = v - eta*dJdv;
end
  w = w - eta*dJdw/N;
  v = v - eta*dJdv/N;
JJ
J(iter,1) = JJ;
end

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
figure(5);
plot3(x1,x2,y(:,1),'-r',x1,x2,yb(:,1),'-b');
title('Salida y1 en Función de x1 y x2');
figure(6);
plot3(x1,x2,y(:,2),'-r',x1,x2,yb(:,2),'-b');
title('Salida y2 en Función de x1 y x2');

