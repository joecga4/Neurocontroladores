% DBP_TresSalidas (original: DynamicBPModelamiento3v.m)
% =========================================================================
% Modelamiento de un sistema de 1 entrada y 3 salidas con una red neuronal
% recurrente entrenada con Dynamic BackPropagation. Extension del caso de
% 2 salidas: ahora hay 3 sensibilidades por parametro (dy1, dy2, dy3) y el
% jacobiano de la red es de 3x3.
%
% Configuracion vigente del original:
%   - La entrada efectiva es la SENOIDAL: hay dos trenes de escalones
%     activos que se sobreescriben entre si y luego el bloque senoidal
%     (nu = 400, fre = 0.005) vuelve a sobreescribir u. Se conservan las
%     tres asignaciones en el mismo orden por fidelidad.
%   - La activacion vigente es LINEAL (n = m); la sigmoide esta comentada.
%     Aun asi c y a se "entrenan" con formulas de la sigmoide: como la
%     activacion lineal no usa c ni a, esas actualizaciones no afectan la
%     salida de la red (resto del experimento sigmoideo; se conserva).
%   - q3 = 0: la tercera salida NO pondera en el costo (no se mide), pero
%     su sensibilidad dy3dP_t si participa en la recursion del jacobiano.
%
% Pipeline:
%   1. Generar u (senoidal) y la respuesta z (3 estados) de la planta.
%   2. Simular la red en modo recurrente (x = out_red se realimenta).
%   3. Gradiente dinamico para cada parametro P en {w, v, c, a}:
%        dyIdP_t = dyIdP_s + jacob(I,1).*dy1dP_t + jacob(I,2).*dy2dP_t
%                          + jacob(I,3).*dy3dP_t
%      con jacob = w'*dndm*(v(1:ne-1,:))'  =  d y(k+1) / d y(k)  (3x3).
%   4. Acumular dJdP_t con los errores ponderados (q1, q2, q3) y
%      actualizar w, v, c, a al final de cada epoca.
%
% Rarezas heredadas del original (NO corregidas, solo documentadas):
%   - El while usa & (AND elemento a elemento) en vez de && (logico).
%   - dw_old/dv_old/da_old/dc_old se asignan pero nunca se usan.
%   - dJdw/dJdv/dJda/dJdc = 0 se inicializan pero no se usan.
%   - erJ = (...).^1 es identico a er (se probaron otros exponentes).
%   - rem(cont,1) == 0 es siempre cierto (vestigio de reportar cada N).
%   - nt = nt es una linea sin efecto del original (se conserva).
%   - dy2dP_t y dy3dP_t usan los dyIdP_t YA actualizados en las lineas
%     anteriores (orden secuencial del original; se conserva tal cual).
%   - Los terminos + 0*0.05*randn(nu,1) conservan llamadas a randn
%     anuladas por 0 (no eliminar: consumen numeros del generador).
%   - outputesc, errorrel y errorreltotal crecen sin preasignar; se dejan
%     asi porque el numero de epocas del while no se conoce por adelantado.

%% Limpieza
clear;
clc;
close all;

%% Senal de entrada u
st = [ 1 1 1 1 1 1 ];   % tramo de seis unos
zt = [ 0 0 0 0 0 0 ];   % tramo de seis ceros

% OJO: estas dos asignaciones de u estan ACTIVAS en el original pero seran
% sobreescritas por el bloque senoidal de mas abajo (se conservan tal cual)
u = [st st zt -st -st -0.2*st -0.4*st -0.6*st zt st 0.8*st 0.5*st st 0.2*st zt -st -st -st zt zt zt st st -st -st -st zt zt 0.25*st st 0.75*st st zt zt zt zt zt zt zt -st -st st st -st -st st 0.1*st 0.1*st st -st st -0.3*st 0.3*st st -st -st st st -st -st st st st -st -st -st st st st -st -st -st st st st st -st -st -st -st st st st st -st -st -st -st st st st st st -0.1*st -0.3*st -0.5*st -0.7*st -0.9*st 0.9*st 0.7*st 0.5*st 0.3*st 0.1*st -st -st -st -st -st st st st st st ];
u = [st st zt -st -st -st -st -st zt st st st st st zt -st -st -st zt zt zt st st -st -st -st zt zt st st st st zt zt zt zt zt zt zt -st -st st st -st -st st st st st -st st -st st st -st -st st st -st -st st st st -st -st -st st st st -st -st -st st st st st -st -st -st -st st st st st -st -st -st -st st st st st st -st -st -st -st -st st st st st st -st -st -st -st -st st st st st st ];
% u = [-0.5*st -0.5*st zt 0.75*st 0.5*st st -0.3*st 0.3*st zt -st -st -0.6*st -0.4*st -0.2*st zt st st st zt zt zt st st st 0.25*st st zt zt -st -0.1*st -0.2*st -st zt zt ];

% Entrada senoidal EFECTIVA (sobreescribe los trenes de escalones)
nu = 400;
nt = 0:1:(nu-1);
nt = nt;                    % rareza: linea sin efecto del original
fre = 1*0.005;   % menor de 0.1  a  0.005
u = 1*sin(2*pi*fre*nt);

u = u';
nu = length(u);

%% Planta real: sistema lineal de 3 estados a modelar
z1(1,1) = 0.1;
z2(1,1) = 0;
z3(1,1) = 0.2;
for k = 1:nu
    % Variante bilineal probada en el curso (productos z*u):
    % z1(k+1,1) = 0.35*z1(k,1) - 0.4*z2(k,1) + 0.5*z3(k,1);
    % z2(k+1,1) = 0.4*z2(k,1) + 0.5*0.15*z1(k,1)*u(k,1) + 0.5*u(k,1);
    % z3(k+1,1) = 0.5*0.1*z2(k,1)*u(k,1) + 0.2*z3(k,1) + 0.5*u(k,1);
    z1(k+1,1) = 0.35*z1(k,1) - 0.4*z2(k,1) + 0.5*z3(k,1);
    z2(k+1,1) = 0.4*z1(k,1) + 0.5*0.15*z2(k,1) + 0.5*u(k,1);
    z3(k+1,1) = 0.5*0.4*z2(k,1) + 0.2*z3(k,1) + 0.5*u(k,1);

end

% Recorte a nu muestras; el factor 0* anula el ruido pero conserva las
% llamadas a randn (no eliminar: afectan la secuencia aleatoria)
z1 = z1(1:nu,1) + 0*0.05*randn(nu,1) ;
z2 = z2(1:nu,1) + 0*0.05*randn(nu,1) ;
z3 = z3(1:nu,1) + 0*0.05*randn(nu,1) ;
z = [ z1  z2 z3 ];
ndata = nu;
dataoutesc = z;         % salidas deseadas (sin escalar en este script)

%% Arquitectura de la red
ne = 4;    % entradas: 3 salidas realimentadas + 1 entrada u (No bias)
nm = 60;   % neuronas ocultas (nm = 10 tambien probado)
ns = 3;    % salidas

% Inicializacion de pesos v, w y de centro c y pendiente a de la sigmoide
v = 0.1*randn(ne,nm);
w = 0.1*randn(nm,ns);
c = zeros(nm,1);
a = ones(nm,1);

%% Carga de pesos previos
% OJO: reddbp1v1.mat NO existe en el repo (rotura conocida, ver README).
% Para la primera corrida comenta la linea "load reddbp1v1;" y ejecuta con
% la inicializacion aleatoria de arriba; el "save reddbp1v1 ..." del final
% creara el .mat para las corridas siguientes.
load reddbp1v1;

%% Parametros de aprendizaje
eta  = input('Introduce learning rate [v w] 0.05: ');
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
da_old = 0;
dc_old = 0;

while( (erreltotal > errormax) & (cont < contmax) )   % rareza: & en vez de &&

    % Reinicio de acumuladores de la epoca
    ersum2 = zeros(ns,1);
    dJdw = 0;                       % rareza: no se usan (ver cabecera)
    dJdv = 0;
    dJda = 0;
    dJdc = 0;
    dy1dw_t = zeros(nm,ns);         % sensibilidades dinamicas dyI/dP
    dy2dw_t = zeros(nm,ns);
    dy3dw_t = zeros(nm,ns);
    dy1dv_t = zeros(ne,nm);
    dy2dv_t = zeros(ne,nm);
    dy3dv_t = zeros(ne,nm);
    dy1dc_t = zeros(nm,1);
    dy2dc_t = zeros(nm,1);
    dy3dc_t = zeros(nm,1);
    dy1da_t = zeros(nm,1);
    dy2da_t = zeros(nm,1);
    dy3da_t = zeros(nm,1);
    dJdw_t  = zeros(nm,ns);         % gradientes del costo acumulados
    dJdv_t  = zeros(ne,nm);
    dJdc_t  = zeros(nm,1);
    dJda_t  = zeros(nm,1);

    x = z(1,:);   % Initial state
    x = x';

    for k = 1:ndata-1

        % --- Propagacion hacia adelante (recurrente) ---------------------
        in_red = [ x
                   u(k,1) ];
        m = v'*in_red;
%       n = 2.0./(1 + exp(-(m-c)./a)) - 1;
        n = m;        % Lineal
        out_red = w'*n;
        outputesc(k,:) = out_red';

        % --- Derivada de la activacion y terminos estaticos --------------
%       dndm = diag((1 - n.*n)./(2*a));
        dndm = diag(ones(nm,1));      % Lineal
        dy1dw_s = [ n   zeros(nm,1)  zeros(nm,1)];
        dy2dw_s = [ zeros(nm,1)   n  zeros(nm,1)];
        dy3dw_s = [ zeros(nm,1)   zeros(nm,1)   n];
        dy1dv_s = in_red*w(:,1)'*dndm;
        dy2dv_s = in_red*w(:,2)'*dndm;
        dy3dv_s = in_red*w(:,3)'*dndm;
        dy1dc_s = w(:,1) .* ((n.*n-1)./(2.0.*a));
        dy2dc_s = w(:,2) .* ((n.*n-1)./(2.0.*a));
        dy3dc_s = w(:,3) .* ((n.*n-1)./(2.0.*a));
        dy1da_s = w(:,1) .* ((n.*n-1).*(m-c)./(2*a.*a));
        dy2da_s = w(:,2) .* ((n.*n-1).*(m-c)./(2*a.*a));
        dy3da_s = w(:,3) .* ((n.*n-1).*(m-c)./(2*a.*a));

        % --- Recursion DBP: encadena el jacobiano 3x3 --------------------
        jacob = w'*dndm*(v(1:ne-1,:))';
        dy1dw_t = dy1dw_s + jacob(1,1).*dy1dw_t + jacob(1,2).*dy2dw_t + jacob(1,3).*dy3dw_t;
        dy2dw_t = dy2dw_s + jacob(2,1).*dy1dw_t + jacob(2,2).*dy2dw_t + jacob(2,3).*dy3dw_t;
        dy3dw_t = dy3dw_s + jacob(3,1).*dy1dw_t + jacob(3,2).*dy2dw_t + jacob(3,3).*dy3dw_t;
        dy1dv_t = dy1dv_s + jacob(1,1).*dy1dv_t + jacob(1,2).*dy2dv_t + jacob(1,3).*dy3dv_t;
        dy2dv_t = dy2dv_s + jacob(2,1).*dy1dv_t + jacob(2,2).*dy2dv_t + jacob(2,3).*dy3dv_t;
        dy3dv_t = dy3dv_s + jacob(3,1).*dy1dv_t + jacob(3,2).*dy2dv_t + jacob(3,3).*dy3dv_t;
        dy1dc_t = dy1dc_s + jacob(1,1).*dy1dc_t + jacob(1,2).*dy2dc_t + jacob(1,3).*dy3dc_t;
        dy2dc_t = dy2dc_s + jacob(2,1).*dy1dc_t + jacob(2,2).*dy2dc_t + jacob(2,3).*dy3dc_t;
        dy3dc_t = dy3dc_s + jacob(3,1).*dy1dc_t + jacob(3,2).*dy2dc_t + jacob(3,3).*dy3dc_t;
        dy1da_t = dy1da_s + jacob(1,1).*dy1da_t + jacob(1,2).*dy2da_t + jacob(1,3).*dy3da_t;
        dy2da_t = dy2da_s + jacob(2,1).*dy1da_t + jacob(2,2).*dy2da_t + jacob(2,3).*dy3da_t;
        dy3da_t = dy3da_s + jacob(3,1).*dy1da_t + jacob(3,2).*dy2da_t + jacob(3,3).*dy3da_t;

        % --- Error y acumulacion del gradiente del costo ------------------
        out_des = z(k+1,:);
        out_des = out_des';
        er = (out_red - out_des);
        erJ = (out_red - out_des).^1;   % rareza: .^1 (se probaron otros exponentes)
        q1 = 1;    % qq = 0 >> solo se mide la primera variable
        q2 = 1;
        q3 = 0;    % rareza: la salida 3 NO pondera en el costo
        dJdw_t = dJdw_t + q1*erJ(1,1).*dy1dw_t + q2*erJ(2,1).*dy2dw_t + q3*erJ(3,1).*dy3dw_t;
        dJdv_t = dJdv_t + q1*erJ(1,1).*dy1dv_t + q2*erJ(2,1).*dy2dv_t + q3*erJ(3,1).*dy3dv_t;
        dJdc_t = dJdc_t + q1*erJ(1,1).*dy1dc_t + q2*erJ(2,1).*dy2dc_t + q3*erJ(3,1).*dy3dc_t;
        dJda_t = dJda_t + q1*erJ(1,1).*dy1da_t + q2*erJ(2,1).*dy2da_t + q3*erJ(3,1).*dy3da_t ;
        ersum2 = ersum2 + er.^2;

        x = out_red;     % output turns to be input for the next step
    end

    % --- Gradientes promedio de la epoca ----------------------------------
    dJdw_t = dJdw_t/ndata;
    dJdv_t = dJdv_t/ndata;
    dJdc_t = dJdc_t/ndata;
    dJda_t = dJda_t/ndata;
    dw = dJdw_t;
    dv = dJdv_t;
    dc = dJdc_t;
    da = dJda_t;

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

    % --- Actualizacion de pesos (despues del registro, como el original) --
    w = w - eta*dw;
    v = v - eta*dv;
    c = c - etac*dc;      % sin efecto en la salida (activacion lineal)
    a = a - etaa*da;      % sin efecto en la salida (activacion lineal)
    dw_old = dw;          % rareza: nunca se leen
    dv_old = dv;
end

%% Graficas de resultados
figure(1);
title('Total Error Function');
plot(errorreltotal*100);
figure(2);
title('Error Function per Output');
plot(errorrel*100);
figure(3);
title('Desired Output (red) and Network Output (blue)');
plot(z(:,1),'-r');
hold on;
plot(outputesc(:,1),'-b');
figure(4);
title('Desired Output (red) and Network Output (blue)');
plot(z(:,2),'-r');
hold on;
plot(outputesc(:,2),'-b');
figure(5);
title('Desired Output (red) and Network Output (blue)');
plot(z(:,3),'-r');
hold on;
plot(outputesc(:,3),'-b');
figure(6);
title('Input Signal');
plot(u,'-b');
title('Input Signal u');
xlabel('Time [sec]');

%% Guardado de la red entrenada
% Guarda: numero de neuronas de entrada/oculta/salida, pesos v y w,
% centro c y pendiente a de las sigmoides
% save reddbp3v6 ne nm ns v w c a;
% save reddbp2v1 ne nm ns v w c a;
save reddbp1v1 ne nm ns v w c a;
