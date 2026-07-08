% Entrenamiento Patron con/sin bias
% Los pesos v y w se trabajan cada uno como matrix (en bloque).
% Probar con:
% (a) Cantidad de neuronas en la capa intermedia nm
% (b) Valor inicial de los pesos v y w
% (c) Tipo de funci�n de activaci�n (y su derivada)
% (d) Neurona bias


clear;
clc;
close all;

a = 1;
b = 2;

x = -2:0.05:3;
x = x';
N = length(x);
yb = a*x + b + 0.2*randn(N,1);

ne = 1;     % N�mero de entradas
nm = 20;    % N�mero de neuronas intermedias

bias = 1;  % SI = 1 : Se agrega neurona bias;
if(bias == 1)
    ne = ne + 1;
    x = [ x  0.5*ones(N,1) ];
end
v = 1*0.05*randn(ne,nm);   % Valor inicial de coeficientes v (matricial)
w = 1*0.05*randn(nm,1);    % Valor inicial de coeficientes w (matricial)
Jold = 1e15;   % Valor grande de funci�n de costo (error) al principio
errorporc = 0.5*0.075;    % M�ximo error porcentual
eta = 0.05;   % Tasa de aprendizaje

for iter = 1:50000
    w11(iter,1) = w(1,1);
    v12(iter,1) = v(1,2);
    dJdw = 0;    dJdv = 0;
    for k = 1:N
        in = (x(k,:))';
        m = v'*in;
        n = 1.0./(1+exp(-m));          % Sigmoidea 1
        % n = 2.0./(1+exp(-m)) - 1;    % Sigmoidea 2
        % n = exp(-m.^2);              % Gaussiana
        out = w'*n;
        y(k,1) = out;
        er = out - yb(k,1);
        error(k,1) = er;
        dndm = n.*(1-n);       % Sigmoidea 1
        % dndm = (1 - n.*n)/2;   % Sigmoidea 2
        % dndm = -2.0*(n.*m);    % Gaussiana
        dJdw = er.*n;
        dJdv = er.*in*(w.*dndm)';

        w = w - eta*dJdw;
        v = v - eta*dJdv;
    end
    % w = w - eta*dJdw/N;
    % v = v - eta*dJdv/N;
    JJ = 0.5*sum(error.*error)/N
    dJ = abs(JJ - Jold);
    dJpor = sqrt(dJ/JJ)*100;
    if(dJpor < errorporc)    % Porcentual
        break;
    end
    J(iter,1) = JJ;
    Jold = JJ;
end

figure(1);
plot(x(:,1),y,x(:,1),yb,'*');
title('Gr�fico de los Datos y la Funci�n de la Red Neuronal X-Y');
figure(2);
subplot(3,1,1);  plot(J);      title('Funci�n de Costo J en cada Iteraci�n');
subplot(3,1,2);  plot(w11);    title('Coeficiente w11 en cada Iteraci�n');
subplot(3,1,3);  plot(v12);    title('Coeficiente v12 en cada Iteraci�n');
