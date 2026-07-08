% Entrenamiento batch con/sin bias de función cúbica.
% Analizar problema de escalamiento: Cambiar el factor que modifica
% la magnitud de la salida deseada.

clear;
clc;
close all;

a3 = 0.8*2;
a2 = 0.3*4;
a1 = -0.8*25;
a0 = -0*30;

x = -4:0.1:4;
x = x';
nx = length(x);

FACTOR = 1;       % Probar
yb = a3*x.^3 + a2*x.^2 + a1*x.^1 + a0;
yb = FACTOR*0.075*yb;
yb = yb + 1*0.2*randn(nx,1);

ne = 1;    % Número de entradas
nm = 25;   % Número de intermedias
bias = input('Bias:  SI = 1 : ');
if(bias == 1)
   ne = ne + 1;
   x = [ x ones(nx,1) ];   
end
v = 0.15*randn(ne,nm);
w = 0.15*randn(nm,1);

eta = input('eta [0.1]: ')
for iter = 1:20000
dJdw = 0;
dJdv = 0;
for k = 1:nx   
in = (x(k,:))';
m = v'*in; 
n = 2.0./(1+exp(-m)) - 1;     % Sigmoidea Tipo 2
%n = exp(-m.^2);              % Gaussiana
out = w'*n;
y(k,1) = out;
er = out - yb(k,1);
error(k,1) = er;
dndm = (1 - n.*n)/2;        % Sigmoidea Tipo 2
%dndm = -2.0*(n.*m);        % Gaussiana
dydw = n; 
dJdw = dJdw + er.*dydw;
dydv = in*(w.*dndm)';
dJdv = dJdv + er.*dydv;
end
w = w - eta*dJdw/nx;
v = v - eta*dJdv/nx;
JJ = 0.5*sum(error.*error)
J(iter,1) = JJ;
end

figure(1);
plot(x(:,1),y,x(:,1),yb,'*');
title('Salida - Datos Deseados y Red Neuronal');
figure(2);
plot(J);
title('Función de Costo - Iteración');


