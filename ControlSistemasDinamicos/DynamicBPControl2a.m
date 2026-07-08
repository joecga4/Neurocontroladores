%% ============================================================================
%  NEUROCONTROLADOR DINÁMICO  -  CONTROL 2a (Planta INESTABLE, realimentación PARCIAL)
% ============================================================================
%  Objetivo:
%    Estabilizar el mismo sistema bilineal INESTABLE de DynamicBPControl2.m,
%    pero con realimentación PARCIAL del estado: la entrada de la red es una
%    salida medida y = C*x, no el estado completo.
%        C = [ 0 1 ]   (mide x2)        C = [ 1 0 ]   (mide x1)
%    Se usa el algoritmo de RETROPROPAGACIÓN DINÁMICA. El aprendizaje es
%    incremental en las condiciones iniciales y en los coeficientes de A.
%
%  Uso para seguimiento (tracking):
%    El neurocontrolador también sirve para llevar el sistema a un setpoint:
%        x1* = 1     x2* = -0.7745     u* = 0.3235
%    cuando A = [ 1.20  0.3; -0.2  1.15 ],  B = [ 0; 0.8 ],
%    G = [ 0.1  0.0; 0.1 -0.1 ].
%
%  Diferencias clave respecto del Control 2:
%    - Realimentación parcial: in_red = C*x - C*r (ne = 1, una sola entrada).
%    - Capa oculta más pequeña (nm = 40).
%    - Sin perturbación externa.
%    - Carga/guarda los pesos en redcontrol2a (C=[0 1]).
%    - Registra el historial del costo (JJ, JJ1, JJ2) y lo grafica.
%
%  Particularidad del método (igual que el Control 2):
%    Retropropagación dinámica (BPTT): las derivadas se propagan recursivamente
%    en el tiempo a través del jacobiano del lazo cerrado jacob_t. La recursión
%    está vectorizada (matrices indexadas por estado) y se actualiza de forma
%    SIMULTÁNEA para todos los estados (regla de la cadena correcta).
% ============================================================================

%% Inicialización del entorno de trabajo
clear;        % Borra todas las variables del espacio de trabajo
clc;          % Limpia la ventana de comandos
close all;    % Cierra todas las figuras abiertas

disp('Hello');

%% Definición del sistema dinámico (la PLANTA a controlar)
%  Modelo discreto bilineal:  x(k+1) = A*x + B*u + (G*x)*u
%  Salida medida:             y = C*x

% Matriz de estado A (sistema INESTABLE). Las alternativas comentadas permiten
% el aprendizaje incremental: empezar con A poco inestable e ir aumentándola.
A = [  1.20    0.3
       -0.2     1.15 ];

A = [  1.15    0.3
      -0.2     1.12 ];

% A = [  1.10    0.3         % (alternativas) distintos grados de inestabilidad
%        -0.2    1.10 ];
%  A = [  1.09    0.3
%        -0.2     1.09 ];
% A = [  1.05    0.3
%       -0.2     1.05 ];
%  A = [  1.03    0.3
%       -0.2     1.03 ];
% A = [  0.99   0.3
%       -0.2   0.99 ];
% A = [  0.96   0.3
%       -0.2    0.96 ];
% A = [  0.92   0.3
%       -0.2    0.92 ];

% Matriz de entrada B (cómo entra el control u al estado)
B = [  0
       0.8 ];

% Matriz de la parte bilineal G (ganancia de entrada dependiente del estado)
G = [   0.1    0.0
        0.1   -0.1 ];

%% Parámetros de simulación y condiciones iniciales
ndata = 500;   % Número de pasos (horizonte) de cada simulación/rollout

% Estados iniciales para el aprendizaje (una COLUMNA por caso). El resto del
% script se adapta automáticamente al número de columnas.
x_ini = [ 0.1   0.1  -0.1  -0.1
          0.1  -0.1   0.1  -0.1 ];

x_ini = 1*x_ini;   % Factor de escala: cambiar para validar con otras CI
xr    = 1*x_ini;   % Referencia de estados (no usada activamente)

nx   = size(x_ini,1);   % Número de estados de la planta
nini = size(x_ini,2);   % Número de condiciones iniciales (deducido de x_ini)

%% Punto de operación deseado (setpoint y control de equilibrio)
% x1ast = 1;             % (alternativa) seguimiento: estado deseado x1*
% x2ast = -0.7745;       % Estado deseado x2* (en la convergencia)
% uast  = 0.3235;        % Control de equilibrio u* (feedforward)
x1ast = 0;       % Primero se entrena con x1* = x2* = u* = 0 (regulación al origen)
x2ast = 0;
uast  = 0;

% Vector de estado deseado (setpoint)
r = [ x1ast
      x2ast ];

% Referencia de salida replicada en el horizonte (estado deseado por paso)
dataoutesc = ones(ndata,2) * diag(r);

% Pesos relativos de cada estado en el costo (q1, q2)
q = [ 1
      1 ];

%% Arquitectura de la red neuronal (el CONTROLADOR)
ne = 1;    % Número de entradas (= salida medida y = C*x; realimentación parcial)
nm = 40;   % Número de neuronas en la capa oculta
ns = 1;    % Número de salidas (señal de control escalar)

% Inicialización aleatoria (se sobrescribe con el load siguiente)
v = 0.1*randn(ne,nm);   % Pesos entrada -> capa oculta
w = 0.1*randn(nm,ns);   % Pesos capa oculta -> salida
c = zeros(nm,1);        % Centro de cada sigmoide
a = ones(nm,1);         % Pendiente de cada sigmoide

%% Carga de pesos previamente entrenados (arranque en caliente)
 load redcontrol2a;   C = [ 0 1 ]   % Matriz de salida: se mide x2
% load redcontrol2;    C = [ 1 0 ]   % (alternativa) medir x1: NO CONTROLA

%% Parámetros de entrenamiento (solicitados por consola)
eta  = input('Learning rate of v and w: ');           % Tasa de aprendizaje de v y w
etaa = input('Learning rate of sigmoid slope a : ');  % Tasa de aprendizaje de la pendiente a
% etac = input('Learning rate of sigmoid center c : ');
etac = 0;   % La tasa del centro c se fija en 0 => c NO se actualiza

errormax = input('Input maximum error (%) : ');   % Error máximo admitido (criterio de parada)
errormax = errormax/100;                          % Se convierte de % a fracción
contmax  = input('Input maximum number of iterations for learning: ');  % Máx. de iteraciones

% Energía de la referencia (para una eventual normalización del error relativo)
outsum2 = sum(dataoutesc.^2);
outsum2 = outsum2';
outsum2total = sum(outsum2);

%% Inicialización del bucle de entrenamiento
cont       = 1;   % Contador de iteraciones (épocas)
erreltotal = 1;   % Error relativo (se actualiza cada época; parada si < errormax)

% Registro de la respuesta para graficar (preasignado por eficiencia)
estado = zeros(ndata-1, nx, nini);
u      = zeros(ndata-1, nini);

JJold = 1e30;   % Costo de la iteración anterior (para detectar si empeora)

%% Bucle principal de entrenamiento (una iteración = una época de descenso de gradiente)
while( (erreltotal > errormax) && (cont < contmax) )

    % --- Acumuladores que se reinician en cada época ---
    ersum2 = zeros(nx,1);    % Suma del error cuadrático de la época

    % Derivadas RECURSIVAS del estado respecto de cada parámetro.
    % Convención: la última dimensión (columna/hoja) indexa el estado x_i.
    % (En este script se resetean por época, NO por condición inicial.)
    Sw_t = zeros(nm,nx);     % dx_i/dw   (columna i = dx_i/dw)
    Sc_t = zeros(nm,nx);     % dx_i/dc
    Sa_t = zeros(nm,nx);     % dx_i/da
    Sv_t = zeros(ne,nm,nx);  % dx_i/dv   (hoja i = dx_i/dv)

    % Gradiente acumulado del costo respecto de cada parámetro
    dJdw_t = zeros(nm,ns);
    dJdv_t = zeros(ne,nm);
    dJdc_t = zeros(nm,1);
    dJda_t = zeros(nm,1);

    ktot = 0;   % Total de pasos acumulados (para promediar el gradiente)

    % --- Recorrido sobre las condiciones iniciales ---
    for j = 1:nini

        x = x_ini(:,j);   % Estado inicial del caso j

        % --- Simulación (rollout) de ndata pasos para el caso j ---
        for k = 1:ndata-1

            % ---------- Propagación hacia adelante de la red (cálculo de u) ----------
            in_red = C*x - C*r;                  % Entrada = salida medida menos su referencia (matriz C)
            m = v'*in_red;                       % Activación lineal de la capa oculta
            n = 2.0./(1 + exp(-(m-c)./a)) - 1;   % Sigmoide BIPOLAR (salida en [-1,1])
%           n = m;                               % (alternativa) capa oculta lineal
            out_red = w'*n;                      % Salida de la red
            u(k,j) = out_red' + uast;            % Control = salida de la red + feedforward u*
            estado(k,:,j) = x';          % Se guarda el estado para graficar

            % ---------- Jacobianos de la planta y dinámica ----------
            jacob = A + u(k,j).*G;   % Jacobiano de la planta respecto del estado: d x(k+1)/d x
            dxdu  = B + G*x;         % Sensibilidad del estado siguiente al control: d x(k+1)/d u

            x = A*x + B*u(k,j) + (G*x)*u(k,j);   % Actualización del estado de la planta

            % ---------- Derivadas de la salida de la red respecto de sus parámetros ----------
            dndm = diag((1 - n.*n)./(2*a));   % Derivada de la sigmoide bipolar respecto de su argumento
%           dndm = diag(ones(nm,1));
            dudw_s = n;                       % du/dw
            dudv_s = in_red*w'*dndm;          % du/dv
            dudc_s = w .* ((n.*n-1)./(2.0.*a));            % du/dc
            duda_s = w .* ((n.*n-1).*(m-c)./(2*a.*a));     % du/da

            dudx = w'*dndm*v';   % Sensibilidad del control a la entrada de la red

            % ---------- Regla de la cadena DINÁMICA (recursiva en el tiempo, vectorizada) ----------
            % jacob_t = jacobiano del lazo cerrado. Actualización SIMULTÁNEA de todos
            % los estados:  S_p(k+1) = du/dp * dxdu' + S_p(k) * jacob_t'
            jacob_t = dxdu*dudx + jacob;
            Sw_t = dudw_s*dxdu' + Sw_t*jacob_t';
            Sc_t = dudc_s*dxdu' + Sc_t*jacob_t';
            Sa_t = duda_s*dxdu' + Sa_t*jacob_t';
            Sv_new = zeros(ne,nm,nx);
            for i = 1:nx
                inc = dxdu(i,1).*dudv_s;
                for jj = 1:nx
                    inc = inc + jacob_t(i,jj).*Sv_t(:,:,jj);
                end
                Sv_new(:,:,i) = inc;
            end
            Sv_t = Sv_new;

            % ---------- Costo y acumulación del gradiente ----------
            out_des = dataoutesc(k+1,:)';   % Estado deseado en el paso siguiente
            er  = (x - out_des);            % Error de seguimiento (estado - deseado)
            erq = q .* er;                  % Error ponderado por estado (q1, q2)
            dJdw_t = dJdw_t + Sw_t*erq;     % sum_i q_i*er_i*dx_i/dw
            dJdc_t = dJdc_t + Sc_t*erq;
            dJda_t = dJda_t + Sa_t*erq;
            for i = 1:nx
                dJdv_t = dJdv_t + erq(i,1).*Sv_t(:,:,i);
            end

            ersum2 = ersum2 + er.^2;   % Costo: error cuadrático acumulado
        end
        ktot = ktot + k;   % Acumula los pasos de este caso
    end

    % --- Costo de la época y registro del historial ---
    ersum2total = sum(ersum2)   % Costo total de la época (mostrado en consola)
    if( ersum2total > JJold)               % Aviso si el costo empieza a crecer
        disp('Cost function increasing')
%       break;                             % (alternativa) parada anticipada
    end

    JJ(cont,1)  = ersum2total;   % Historial del costo total
    JJ1(cont,1) = ersum2(1,1);   % Historial del costo del estado x1
    JJ2(cont,1) = ersum2(2,1);   % Historial del costo del estado x2

    JJold = ersum2total;

    % --- Criterio de parada por error relativo al costo inicial ---
    if( cont == 1 )
        J0 = ersum2total;        % Costo de referencia (primera época)
        if( J0 == 0 ), J0 = 1; end
    end
    erreltotal = ersum2total/J0; % Se detiene cuando cae por debajo de errormax

    % --- Actualización de los parámetros (descenso de gradiente por lotes) ---
    w = w - eta *dJdw_t/ktot;   % Gradiente promediado sobre todos los pasos
    v = v - eta *dJdv_t/ktot;
    c = c - etac*dJdc_t/ktot;   % etac = 0 => c no cambia
    a = a - etaa*dJda_t/ktot;

    cont = cont + 1;
end

%% Visualización de resultados
%  Una figura por condición inicial: estados (arriba) y control (abajo).
for j = 1:nini
    figure(j);
    subplot(2,1,1);
    plot(estado(:,:,j));   title(sprintf('States - Initial %d', j));
    subplot(2,1,2);
    plot(u(:,j));          title('Control input');
end

%  Figura del costo: total (JJ) y por estado (JJ1, JJ2).
figure(nini+1);
plot(JJ);
hold on;
plot(JJ1);
plot(JJ2);
title('Cost: JJ (total), JJ1 (x1), JJ2 (x2)');

%% Guardado de los pesos entrenados
ana = input('Save [1]: ');          % Preguntar si se desea guardar
if( ana == 1)
% save redcontrol2 v w c a nm;     %  C = [ 1  0 ]
 save redcontrol2a v w c a nm;     %  C = [ 0  1 ]
end
