% DBP_LinealIdentificaMatricesAB (original: DynamicBPLinealmodel2.m)
% =========================================================================
% Identificacion de las matrices A y B de un sistema lineal discreto de
% orden 2 con una red neuronal recurrente LINEAL entrenada con Dynamic
% BackPropagation (DBP). Es el caso DBP mas simple e interpretable.
%
% Idea clave: con activacion identidad (n = m) y capa de salida fija en la
% identidad (w = I), la red es  y(k+1) = v' * [y(k); u(k)], asi que la
% matriz de pesos v contiene DIRECTAMENTE los coeficientes de A (filas 1-2,
% traspuestos) y de B (fila 3). Si el entrenamiento converge, v debe
% acercarse a la planta real:  A = [0.6 0.8; 0.3 -0.1],  B = [0.0; -0.2].
%
% Pipeline:
%   1. Generar la entrada u (tren de escalones) y la respuesta z de la
%      planta real de orden 2 (datos de entrenamiento).
%   2. Simular la red en modo recurrente: la salida out_red se realimenta
%      como entrada x en el paso siguiente (x = out_red).
%   3. Gradiente dinamico: como x depende de los pesos, la sensibilidad se
%      propaga en el tiempo encadenando el jacobiano de la red,
%         dyIdP_t = dyIdP_s + jacob(I,1).*dy1dP_t + jacob(I,2).*dy2dP_t
%      donde dyIdP_s es el termino estatico (red sin recurrencia) y
%      jacob = w'*dndm*(v(1:ne-1,:))'  es  d y(k+1) / d y(k).
%   4. Acumular el gradiente del costo ponderado por el error (q1, q2) y,
%      al cerrar cada epoca, actualizar v. w NO cambia (su paso usa 0*eta).
%
% Rarezas heredadas del original (NO corregidas, solo documentadas):
%   - El while usa & (AND elemento a elemento) en vez de && (logico).
%   - dw_old/dv_old se calculan pero nunca se usan (resto de un momentum).
%   - dJdw = 0 y dJdv = 0 se inicializan pero no se usan (los acumuladores
%     reales son dJdw_t y dJdv_t).
%   - erJ = (...).^1 es identico a er; el .^1 documenta que se probaron
%     otros exponentes (ver la alternativa comentada junto a el).
%   - rem(cont,1) == 0 es siempre cierto (vestigio de reportar cada N).
%   - out_red = v'*in_red recalcula m (con w = I la salida ya es n = m).
%   - dy2dP_t se actualiza usando el dy1dP_t YA actualizado en la linea
%     anterior (orden secuencial del original; se conserva tal cual).
%   - outputesc, errorrel y errorreltotal crecen dentro de los bucles sin
%     preasignar: se dejan asi porque el numero de epocas depende de la
%     condicion de parada del while (no se conoce por adelantado).

%% Limpieza
clear;
clc;
close all;

%% Senal de entrada u (tren de escalones)
st = [ 1 1 1 1 1 1 ];   % tramo de seis unos
zt = [ 0 0 0 0 0 0 ];   % tramo de seis ceros

u = [st st zt -st -st -0.2*st -0.4*st -0.6*st zt st 0.8*st 0.5*st st 0.2*st zt -st -st -st zt zt zt st st st st -st -st -st -st -st -st zt zt 0.25*st st 0.75*st st zt zt zt zt zt zt zt -st -st st st -st -st st 0.1*st 0.1*st st -st st -0.3*st 0.3*st st -st -st st st -st -st st st st st st st-st -st -st st st st st st st -st -st -st st st st st -st -st -st -st st st st st -st -st -st -st st st st st st -0.1*st -0.3*st -0.5*st -0.7*st -0.9*st 0.9*st 0.7*st 0.5*st 0.3*st 0.1*st -st -st -st -st -st st st st st st ];

% Trenes de escalones alternativos probados en el curso:
% u = [st st zt -st -st -st -st -st zt st st st st st zt -st -st -st zt zt zt st st -st -st -st zt zt st st st st zt zt zt zt zt zt zt -st -st st st -st -st st st st st -st st -st st st -st -st st st -st -st st st st -st -st -st st st st -st -st -st st st st st -st -st -st -st st st st st -st -st -st -st st st st st st -st -st -st -st -st st st st st st -st -st -st -st -st st st st st st ];
% u = [-0.5*st -0.5*st zt 0.75*st 0.5*st st -0.3*st 0.3*st zt -st -st -0.6*st -0.4*st -0.2*st zt st st st zt zt zt st st st 0.25*st st zt zt -st -0.1*st -0.2*st -st zt zt ];

% Alternativa: entrada senoidal o constante (experimentos del curso):
% nu = 400;
% nt = 0:1:(nu-1);
% nt = nt;
% fre = 0.01;   % menor de 0.1  a  0.005
% u = 1*sin(2*pi*fre*nt);
% u = ones(1,nu);

u = u';
nu = length(u);

%% Planta real: sistema lineal de orden 2 a identificar
% z(k+1) = A*z(k) + B*u(k)  con  A = [0.6 0.8; 0.3 -0.1] y B = [0.0; -0.2]
z1(1,1) = 0;
z2(1,1) = 0;
for k = 1:nu
    z1(k+1,1) = 0.6*z1(k,1) + 0.8*z2(k,1) + 0.0*u(k,1);
    z2(k+1,1) = 0.3*z1(k,1) - 0.1*z2(k,1) - 0.2*u(k,1);
end
z = [ z1  z2 ];
z = z(1:nu,:);          % se descarta la muestra extra nu+1

plot(z)                 % vista rapida de los datos de entrenamiento

ndata = nu;
dataoutesc = z;         % salidas deseadas (sin escalar en este script)

%% Arquitectura de la red (lineal)
ne = 3;    % entradas: 2 salidas realimentadas + 1 entrada u (No bias)
nm = 2;    % Igual que las salidas (activacion identidad)
ns = 2;    % salidas

v = 0.1*randn(ne,ns);  % Las matrices A y B aparecen aqui
w = diag([ 1  1 ]);    % Identidad. Se mantiene constante en todo el entrenamiento
% v = [ a11  a21       % Elementos de A y B
%       a12  a22
%        b1   b2 ];

%% Carga de pesos previos
% OJO: zz1v.mat NO existe en el repo (rotura conocida, ver README). Para la
% primera corrida comenta la linea "load zz1v;" y ejecuta con la
% inicializacion aleatoria de arriba; el "save zz1v v w;" del final creara
% el .mat para las corridas siguientes.
% load zzz2;
% load zz3;
% load zz3v;   % Algunos coeficientes 1, 0
load zz1v;
 % v(2,1) =  0.8;      % experimento: fijar coeficientes conocidos
 % v(2,2) = -0.1;
 % v(3,1) =  0.0;

%% Parametros de aprendizaje
eta  = input('Introducir ratio de aprendizaje : ');

errormax = input('Introducir el valor maximo del error (%) : ');
errormax = errormax/100;
contmax = input('Introducir el maximo numero de etapas de aprendizaje : ');

%% Entrenamiento con Dynamic BackPropagation
% Norma de referencia para el error relativo (por salida y total)
outsum2 = sum(dataoutesc.^2);
outsum2 = outsum2';
outsum2total = sum(outsum2);

cont = 1;
erreltotal = 1;
dw_old = 0;             % rareza: se asignan pero nunca se usan
dv_old = 0;

while( (erreltotal > errormax) & (cont < contmax) )   % rareza: & en vez de &&

    % Reinicio de acumuladores de la epoca
    ersum2 = zeros(ns,1);
    dJdw = 0;                       % rareza: no se usan (ver cabecera)
    dJdv = 0;
    dy1dw_t = zeros(nm,ns);         % sensibilidades dinamicas dyI/dP
    dy2dw_t = zeros(nm,ns);
    dy1dv_t = zeros(ne,nm);
    dy2dv_t = zeros(ne,nm);
    dJdw_t  = zeros(nm,ns);         % gradientes del costo acumulados
    dJdv_t  = zeros(ne,nm);

    x = dataoutesc(1,:);   % Solo al principio como estado inicial
    x = x';

    for k = 1:ndata-1

        % --- Propagacion hacia adelante (recurrente) ---------------------
        in_red = [ x
                   u(k,1) ];
        m = v'*in_red;
%       n = 2.0./(1 + exp(-(m-c)./a)) - 1;
        n = m;        % Lineal
        out_red = v'*in_red;            % rareza: recalcula m (w = I)
        outputesc(k,:) = out_red';

        % --- Derivada de la activacion y terminos estaticos --------------
%       dndm = diag((1 - n.*n)./(2*a));
        dndm = diag(ones(nm,1));      % Lineal
        dy1dw_s = [ n   zeros(nm,1) ];
        dy2dw_s = [ zeros(nm,1)   n ];
        dy1dv_s = in_red*w(:,1)'*dndm;
        dy2dv_s = in_red*w(:,2)'*dndm;

        % --- Recursion DBP: encadena el jacobiano d y(k+1)/d y(k) --------
        jacob = w'*dndm*(v(1:ne-1,:))';
        dy1dw_t = dy1dw_s + jacob(1,1).*dy1dw_t + jacob(1,2).*dy2dw_t;
        dy2dw_t = dy2dw_s + jacob(2,1).*dy1dw_t + jacob(2,2).*dy2dw_t;
        dy1dv_t = dy1dv_s + jacob(1,1).*dy1dv_t + jacob(1,2).*dy2dv_t;
        dy2dv_t = dy2dv_s + jacob(2,1).*dy1dv_t + jacob(2,2).*dy2dv_t;

        % --- Error y acumulacion del gradiente del costo ------------------
        out_des = dataoutesc(k+1,:);
        out_des = out_des';
        er = (out_red - out_des);
        erJ = (out_red - out_des).^1;   % rareza: .^1 (se probaron otros exponentes)
        %      erJ = (abs(out_red - out_des)).^0.5 .* sign( out_red-out_des );
        q1 = 1;    q2 = 1;              % peso de cada salida en el costo
        dJdw_t = dJdw_t + q1*erJ(1,1).*dy1dw_t + q2*erJ(2,1).*dy2dw_t;
        dJdv_t = dJdv_t + q1*erJ(1,1).*dy1dv_t + q2*erJ(2,1).*dy2dv_t;
        ersum2 = ersum2 + er.^2;

        x = out_red;     % Notar que la salida se convierte en entrada
    end

    % --- Actualizacion de pesos al final de la epoca ----------------------
    dJdw_t = dJdw_t/ndata;
    dJdv_t = dJdv_t/ndata;
    dw = dJdw_t;
    dv = dJdv_t;
    w = w - 0*eta*dw;     % No cambia
    v = v - eta*dv;
 % v(2,1) =  0.8;         % experimento: reimponer coeficientes conocidos
 % v(2,2) = -0.1;
 % v(3,1) =  0.0;
    dw_old = dw;          % rareza: nunca se leen
    dv_old = dv;

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

%% Guardado de pesos entrenados
% save zzz2 v w;
% save zz3 v w;
% save zz3v  v w;
save zz1v v w;

%% Graficas de resultados
figure(1);
plot(errorreltotal*100);            % error relativo total [%] por epoca
figure(2);
plot(errorrel*100);                 % error relativo por salida [%]
figure(3);
plot(z(2:nu,1),'-r');               % salida deseada 1 (rojo)
hold on;
plot(outputesc(:,1),'--b');         % salida de la red 1 (azul)
figure(4);
plot(z(2:nu,2),'-r');               % salida deseada 2 (rojo)
hold on;
plot(outputesc(:,2),'--b');         % salida de la red 2 (azul)
