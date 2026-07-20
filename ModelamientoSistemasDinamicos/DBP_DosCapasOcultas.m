% DBP_DosCapasOcultas (original: DynamicBPModelamientoDosIntermedias.m)
% =========================================================================
% Modelamiento de un sistema bilineal de 1 entrada y 2 salidas con una red
% recurrente de DOS capas ocultas (nm = 12 y np = 10 neuronas sigmoideas)
% entrenada con Dynamic BackPropagation. La novedad frente a los scripts
% de una capa es que el jacobiano de la red se encadena a traves de AMBAS
% capas ocultas:
%
%   Red:    n = sigm1( ur' * [y(k); u(k)] )     capa oculta 1 (c1, a1)
%           q = sigm2( v' * n )                  capa oculta 2 (c2, a2)
%           y(k+1) = w' * q
%
%   jacob = w'*dqdp*v'*dndm*(ur(1:ne-1,:))'  =  d y(k+1) / d y(k)
%
% Pipeline:
%   1. Generar u (tren de escalones) y la respuesta z de la planta
%      bilineal:  z1(k+1) = 0.3*z1 - 0.4*z2
%                 z2(k+1) = 0.4*z2 + 0.1*z1*u + 0.5*u
%   2. Simular la red en modo recurrente (x = out_red se realimenta).
%   3. Gradiente dinamico para P en {w, v, ur, c2, a2}:
%        dyIdP_t = dyIdP_s + jacob(I,1).*dy1dP_t + jacob(I,2).*dy2dP_t
%   4. Acumular dJdP_t con los errores ponderados (q1, q2) y actualizar
%      w, v, ur, c2, a2 al final de cada epoca.
%
% Rarezas heredadas del original (NO corregidas, solo documentadas):
%   - dJdu_t NO se divide entre ndata antes de actualizar ur (los demas
%     gradientes si se promedian): ur usa la SUMA cruda del gradiente.
%   - Solo se entrenan centro/pendiente de la SEGUNDA capa (c2, a2);
%     c1 y a1 de la primera capa quedan fijos (0 y 1).
%   - El while usa & (AND elemento a elemento) en vez de && (logico).
%   - dw_old/dv_old/dr_old se asignan pero nunca se usan.
%   - dJdw/dJdv = 0 se inicializan pero no se usan.
%   - erJ = (...).^1 es identico a er (se probaron otros exponentes).
%   - rem(cont,1) == 0 es siempre cierto (vestigio de reportar cada N).
%   - dy2dP_t usa el dy1dP_t YA actualizado en la linea anterior (orden
%     secuencial del original; se conserva tal cual).
%   - Los terminos + 0.0*0.05*randn(nu,1) conservan llamadas a randn
%     anuladas por 0 (no eliminar: consumen numeros del generador).
%   - z1(1:nu) sin coma produce columna igualmente (z1 ya es columna).
%   - outputesc, errorrel y errorreltotal crecen sin preasignar; se dejan
%     asi porque el numero de epocas del while no se conoce por adelantado.

%% Limpieza
clear;
clc;
close all;

%% Senal de entrada u (tren de escalones)
st = [ 1 1 1 1 1 1 ];   % tramo de seis unos
zt = [ 0 0 0 0 0 0 ];   % tramo de seis ceros

u = [st st zt -st -st -0.2*st -0.4*st -0.6*st zt st 0.8*st 0.5*st st 0.2*st zt -st -st -st zt zt zt st st -st -st -st zt zt 0.25*st st 0.75*st st zt zt zt zt zt zt zt -st -st st st -st -st st 0.1*st 0.1*st st -st st -0.3*st 0.3*st st -st -st st st -st -st st st st -st -st -st st st st -st -st -st st st st st -st -st -st -st st st st st -st -st -st -st st st st st st -0.1*st -0.3*st -0.5*st -0.7*st -0.9*st 0.9*st 0.7*st 0.5*st 0.3*st 0.1*st -st -st -st -st -st st st st st st ];

% Trenes de escalones alternativos probados en el curso:
% u = [st st zt -st -st -st -st -st zt st st st st st zt -st -st -st zt zt zt st st -st -st -st zt zt st st st st zt zt zt zt zt zt zt -st -st st st -st -st st st st st -st st -st st st -st -st st st -st -st st st st -st -st -st st st st -st -st -st st st st st -st -st -st -st st st st st -st -st -st -st st st st st st -st -st -st -st -st st st st st st -st -st -st -st -st st st st st st ];
% u = [-0.5*st -0.5*st zt 0.75*st 0.5*st st -0.3*st 0.3*st zt -st -st -0.6*st -0.4*st -0.2*st zt st st st zt zt zt st st st 0.25*st st zt zt -st -0.1*st -0.2*st -st zt zt ];

% Alternativa: entrada senoidal (experimento del curso):
% nu = 700;
% nt = 0:1:(nu-1);
% fre = 3*0.0025;   % menor de 0.01  a  0.0025
% u = 1*sin(2*pi*fre*nt);

u = u';
nu = length(u);

%% Planta real: sistema bilineal de 2 estados a modelar
z1(1,1) = 0.1;
z2(1,1) = 0.2;
for k = 1:nu
    z1(k+1,1) = 0.3*z1(k,1) - 0.4*z2(k,1);
    z2(k+1,1) = 0.4*z2(k,1) + 1*0.1*z1(k,1)*u(k,1) + 0.5*u(k,1);
end

% Recorte a nu muestras; el factor 0.0* anula el ruido pero conserva las
% llamadas a randn (no eliminar: afectan la secuencia aleatoria)
z1 = z1(1:nu) + 0.0*0.05*randn(nu,1) ;
z2 = z2(1:nu) + 0.0*0.05*randn(nu,1) ;
z = [ z1  z2 ];
% z(:,1) = zeros(nu,1);          % experimento: anular la primera salida
ndata = nu;
dataoutesc = z;         % salidas deseadas (sin escalar en este script)

%% Arquitectura de la red (dos capas ocultas)
ne = 3;    % entradas: 2 salidas realimentadas + 1 entrada u (No bias)
nm = 12;   % neuronas de la capa oculta 1 (nm = 10 tambien probado)
np = 10;   % neuronas de la capa oculta 2
ns = 2;    % salidas

% Inicializacion de pesos ur, v, w y de centros/pendientes de sigmoides
ur = 0.1*randn(ne,nm);
v = 0.1*randn(nm,np);
w = 0.1*randn(np,ns);
c1 = zeros(nm,1);       % capa 1: NO se entrenan (quedan fijos)
a1 = ones(nm,1);
c2 = zeros(np,1);       % capa 2: si se entrenan
a2 = ones(np,1);

%% Carga de pesos previos
% OJO: reddbp2int.mat NO existe en el repo (rotura conocida, ver README).
% Para la primera corrida comenta la linea "load reddbp2int;" y ejecuta
% con la inicializacion aleatoria de arriba; el "save reddbp2int ..." del
% final creara el .mat para las corridas siguientes.
load reddbp2int;

%% Parametros de aprendizaje
eta  = input('Introduce learning rate [v w]: ');
etac = input('Introduce learning rate [c: sigmoid center]: ');
etaa = input('Introduce learning rate [a: sigmoid slope]: ');
errormax = input('Introduce maximum value of error function (percentage %) : ');
errormax = errormax/100;
contmax = input('Introduce number of iteration steps: ');

%% Entrenamiento con Dynamic BackPropagation
% Norma de referencia para el error relativo (por salida y total)
outsum2 = sum(dataoutesc.^2);
outsum2 = outsum2';
outsum2total = sum(outsum2);

cont = 1;
erreltotal = 1;
dw_old = 0;             % rareza: se asignan pero nunca se usan
dv_old = 0;
dr_old = 0;
%   da_old = 0;
%   dc_old = 0;

while( (erreltotal > errormax) & (cont < contmax) )   % rareza: & en vez de &&

    % Reinicio de acumuladores de la epoca
    ersum2 = zeros(ns,1);
    dJdw = 0;                       % rareza: no se usan (ver cabecera)
    dJdv = 0;
%    dJda = 0;
%    dJdc = 0;
    dy1dw_t = zeros(np,ns);         % sensibilidades dinamicas dyI/dP
    dy2dw_t = zeros(np,ns);
    dy1dv_t = zeros(nm,np);
    dy2dv_t = zeros(nm,np);
    dy1du_t = zeros(ne,nm);
    dy2du_t = zeros(ne,nm);

    dy1dc2_t = zeros(np,1);
    dy2dc2_t = zeros(np,1);
    dy1da2_t = zeros(np,1);
    dy2da2_t = zeros(np,1);
    dJdw_t  = zeros(np,ns);         % gradientes del costo acumulados
    dJdv_t  = zeros(nm,np);
    dJdu_t = zeros(ne,nm);
    dJdc2_t  = zeros(np,1);
    dJda2_t  = zeros(np,1);

    x = dataoutesc(1,:);   % Initial state
    x = x';

    for k = 1:ndata-1

        % --- Propagacion hacia adelante (dos capas ocultas) --------------
        in_red = [ x
                   u(k,1) ];
        m = ur'*in_red;
        n = 2.0./(1 + exp(-(m-c1)./a1)) - 1;    % capa oculta 1
        p = v'*n;
        q = 2.0./(1 + exp(-(p-c2)./a2)) - 1;    % capa oculta 2
        out_red = w'*q;
        outputesc(k,:) = out_red';

        % --- Derivadas de las activaciones y terminos estaticos ----------
        dndm = diag((1 - n.*n)./(2*a1));
        dqdp = diag((1 - q.*q)./(2*a2));

        %      dndm = diag(ones(nm,1));      % Lineal
        dy1dw_s = [ q   zeros(np,1) ];
        dy2dw_s = [zeros(np,1)    q ];
        dy1dv_s = n*w(:,1)'*dqdp;
        dy2dv_s = n*w(:,2)'*dqdp;
        dy1du_s = in_red*w(:,1)'*dqdp*v'*dndm;   % encadena las dos capas
        dy2du_s = in_red*w(:,2)'*dqdp*v'*dndm;

        dy1dc2_s = w(:,1) .* ((q.*q-1)./(2.0.*a2));
        dy2dc2_s = w(:,2) .* ((q.*q-1)./(2.0.*a2));
        dy1da2_s = w(:,1) .* ((q.*q-1).*(p-c2)./(2*a2.*a2));
        dy2da2_s = w(:,2) .* ((q.*q-1).*(p-c2)./(2*a2.*a2));

        % --- Recursion DBP: jacobiano a traves de ambas capas ------------
        jacob = w'*dqdp*v'*dndm*(ur(1:ne-1,:))';
        dy1dw_t = dy1dw_s + jacob(1,1).*dy1dw_t + jacob(1,2).*dy2dw_t;
        dy2dw_t = dy2dw_s + jacob(2,1).*dy1dw_t + jacob(2,2).*dy2dw_t;
        dy1dv_t  = dy1dv_s  + jacob(1,1).*dy1dv_t  + jacob(1,2).*dy2dv_t;
        dy2dv_t  = dy2dv_s  + jacob(2,1).*dy1dv_t  + jacob(2,2).*dy2dv_t;
        dy1du_t  = dy1du_s  + jacob(1,1).*dy1du_t  + jacob(1,2).*dy2du_t;
        dy2du_t  = dy2du_s  + jacob(2,1).*dy1du_t  + jacob(2,2).*dy2du_t;

        dy1dc2_t  = dy1dc2_s  + jacob(1,1).*dy1dc2_t  + jacob(1,2).*dy2dc2_t;
        dy2dc2_t  = dy2dc2_s  + jacob(2,1).*dy1dc2_t  + jacob(2,2).*dy2dc2_t;
        dy1da2_t  = dy1da2_s  + jacob(1,1).*dy1da2_t  + jacob(1,2).*dy2da2_t;
        dy2da2_t  = dy2da2_s  + jacob(2,1).*dy1da2_t  + jacob(2,2).*dy2da2_t;

        % --- Error y acumulacion del gradiente del costo ------------------
        out_des = dataoutesc(k+1,:);
        out_des = out_des';
        er = (out_red - out_des);
        erJ = (out_red - out_des).^1;   % rareza: .^1 (se probaron otros exponentes)
        %      erJ = (abs(out_red - out_des)).^0.5 .* sign( out_red-out_des );

        q1 = 1;    q2 = 1;       % Both variables are measured
        dJdw_t = dJdw_t + q1*erJ(1,1).*dy1dw_t + q2*erJ(2,1).*dy2dw_t;
        dJdv_t  = dJdv_t  + q1*erJ(1,1).*dy1dv_t  + q2*erJ(2,1).*dy2dv_t;
        dJdu_t  = dJdu_t  + q1*erJ(1,1).*dy1du_t + q2*erJ(2,1).*dy2du_t;
        dJdc2_t  = dJdc2_t  + q1*erJ(1,1).*dy1dc2_t  + q2*erJ(2,1).*dy2dc2_t;
        dJda2_t  = dJda2_t  + q1*erJ(1,1).*dy1da2_t  + q2*erJ(2,1).*dy2da2_t;
        ersum2 = ersum2 + er.^2;

        x = out_red;     % The output turns to be input in the next step
    end

    % --- Actualizacion de pesos al final de la epoca ----------------------
    dJdw_t = dJdw_t/ndata;
    dJdv_t = dJdv_t/ndata;
    dJdc2_t = dJdc2_t/ndata;
    dJda2_t = dJda2_t/ndata;
    w = w - eta*dJdw_t;
    v  = v - eta*dJdv_t;
    ur = ur - eta*dJdu_t;     % rareza: dJdu_t sin dividir entre ndata
    c2 = c2 - etac*dJdc2_t;
    a2 = a2 - etaa*dJda2_t;

    % --- Registro del error relativo de la epoca --------------------------
    ersum2total = sum(ersum2);
    cont = cont + 1;
    if ( rem(cont,1) == 0 )            % rareza: siempre cierto
        errorrel(cont/1,:) = sqrt(ersum2'./outsum2');
        errorreltotal(cont/1,1) = sqrt(ersum2total/outsum2total);
        erreltotal = errorreltotal(cont/1,1);
        cont;
        erreltotal
    end
end

%% Eje de tiempo para las graficas
nt = length(u);
dt = 0.01;
tt = 0:1:(nt-1);
tt = dt*tt';
tt1 = tt(1:nt-1,1);     % la red produce nt-1 muestras (una menos que z)

%% Graficas de resultados
figure(1);
title('Total Error Function');
plot(errorreltotal*100);
figure(2);
title('Error Function per Output');
plot(errorrel*100);
figure(3);
title('Desired Output (red) and Network Output (blue)');
plot(tt,z(:,1),'-r');
hold on;
plot(tt1,outputesc(:,1),'-b');
title('Output State Variable x1');
xlabel('Time [sec]');
axis([ 0 7 -0.6  0.6]);
figure(4);
title('Desired Output (red) and Network Output (blue)');
plot(tt,z(:,2),'-r');
hold on;
plot(tt1,outputesc(:,2),'-b');
title('Output State Variable x2');
xlabel('Time [sec]');
axis([ 0 7 -1  1]);
figure(5);
title('Input Signal');
plot(tt,u,'-b');
title('Input Signal u');
xlabel('Time [sec]');
axis([ 0 7 -1.2 1.2]);

%% Guardado de la red entrenada
% Guarda: numero de neuronas por capa, pesos ur, v, w y
% centros/pendientes de ambas capas ocultas
save reddbp2int ne nm np ns ur v w c1 a1 c2 a2;
