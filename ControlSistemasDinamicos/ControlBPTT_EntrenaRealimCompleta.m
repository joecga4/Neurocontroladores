%% ============================================================================
%  NEUROCONTROLADOR DINÁMICO  -  CONTROL 2 (Planta INESTABLE, realimentación completa)
% ============================================================================
%  Objetivo:
%    Entrenar una red neuronal para ESTABILIZAR un sistema bilineal INESTABLE
%    mediante el algoritmo de RETROPROPAGACIÓN DINÁMICA. El controlador debe
%    estabilizar el sistema partiendo de condiciones iniciales en el rango:
%        -1.0 < x1 < 1.0        -1.0 < x2 < 1.0
%    El aprendizaje es incremental tanto en las condiciones iniciales como en
%    los coeficientes de la matriz A (se va aumentando la inestabilidad).
%
%  Uso para seguimiento (tracking):
%    El neurocontrolador también sirve para llevar el sistema a un setpoint:
%        x1* = 1     x2* = -0.7745     u* = 0.3235
%    cuando A = [ 1.20  0.3; -0.2  1.15 ],  B = [ 0; 0.8 ],
%    G = [ 0.1  0.0; 0.1 -0.1 ].
%
%  Particularidad del método (DIFERENCIA con los scripts EstaticoModelo*):
%    Aquí SÍ es retropropagación dinámica (BPTT): las derivadas del estado
%    respecto de los parámetros se propagan RECURSIVAMENTE en el tiempo a
%    través del jacobiano del lazo cerrado:
%        jacob   = A + u*G                 (jacobiano de la planta d x(k+1)/d x)
%        dudx    = w'*dndm*v'              (sensibilidad del control al estado)
%        jacob_t = dxdu*dudx + jacob       (jacobiano del lazo cerrado)
%        S_p(k+1) = dxdu*du/dp + jacob_t*S_p(k)     (S_p = dx/dp del paso anterior)
%    En los Modelo* solo se usa el término instantáneo dxdu*du/dp.
%
%  ESCALABILIDAD: el número de condiciones iniciales se deduce de x_ini y la
%    recursión BPTT está vectorizada (matrices indexadas por estado); no hay
%    términos dx1/dx2 cableados a mano. La actualización recursiva es SIMULTÁNEA
%    para todos los estados (regla de la cadena correcta).
%
%  IMPORTANTE: Considerar uast1 cuando la referencia r es variable.
% ============================================================================

%% Inicialización del entorno de trabajo
clear;        % Borra todas las variables del espacio de trabajo
clc;          % Limpia la ventana de comandos
close all;    % Cierra todas las figuras abiertas

disp('Hello');

%% Definición del sistema dinámico (la PLANTA a controlar)
%  Modelo discreto bilineal:  x(k+1) = A*x + B*u + (G*x)*u + W*perturbación

% Matriz de estado A (sistema INESTABLE). Las alternativas comentadas permiten
% el aprendizaje incremental: empezar con A poco inestable e ir aumentándola.
A = [  1.20    0.3
      -0.2     1.15 ];

% A = [  1.15    0.3         % (alternativas) distintos grados de inestabilidad
%       -0.2     1.15 ];
%  A = [  1.10    0.3
%        -0.2     1.10 ];
% A = [  1.05    0.3
%       -0.2     1.05 ];
% A = [  1.0   0.3
%       -0.2   1.0 ];
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

% Vector de acoplamiento de la perturbación externa
W = [ 0
      0.01 ];

pert = 1*0.05;    % Amplitud de la perturbación externa (activada)

%% Parámetros de simulación y condiciones iniciales
ndata = 400;   % Número de pasos (horizonte) de cada simulación/rollout

% Estados iniciales para el aprendizaje (una COLUMNA por caso). El resto del
% script se adapta automáticamente al número de columnas.
x_ini = [ 0.1   0.1  -0.1  -0.1
          0.1  -0.1   0.1  -0.1 ];

x_ini = 1*x_ini;   % Factor de escala: cambiar para validar con otras CI
xr    = 1*x_ini;   % Referencia de estados (no usada activamente)

nx   = size(x_ini,1);   % Número de estados de la planta
nini = size(x_ini,2);   % Número de condiciones iniciales (deducido de x_ini)

%% Punto de operación deseado (setpoint y control de equilibrio)
% x1ast = 1;          % (alternativa) seguimiento: estado deseado x1*
% x2ast = -0.7745;    % Estado deseado x2* (en la convergencia)
% uast  = 0.3235;     % Control de equilibrio u* (feedforward)  IMPORTANTE: CAMBIAR uast1
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
ne = 2;    % Número de entradas (= estado actual; realimentación completa, sin sesgo)
nm = 50;   % Número de neuronas en la capa oculta
ns = 1;    % Número de salidas (señal de control escalar)

% Inicialización aleatoria (se sobrescribe con el load siguiente)
v = 0.1*randn(ne,nm);   % Pesos entrada -> capa oculta
w = 0.1*randn(nm,ns);   % Pesos capa oculta -> salida
c = zeros(nm,1);        % Centro de cada sigmoide
a = ones(nm,1);         % Pendiente de cada sigmoide

%% Carga de pesos previamente entrenados (arranque en caliente)
% load redcontrol201;    % (alternativa) realimentación completa de estado
load redcontrol202;

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
erreltotal = 1;   % Error relativo (no se actualiza: la parada efectiva es cont<contmax)

% Registro de la respuesta para graficar (preasignado por eficiencia)
estado = zeros(ndata-1, nx, nini);
u      = zeros(ndata-1, nini);

%% Bucle principal de entrenamiento (una iteración = una época de descenso de gradiente)
while( (erreltotal > errormax) && (cont < contmax) )

    % --- Acumuladores que se reinician en cada época ---
    ersum2 = zeros(nx,1);    % Suma del error cuadrático de la época
    dJdw_t = zeros(nm,ns);   % Gradiente acumulado del costo respecto de cada parámetro
    dJdv_t = zeros(ne,nm);
    dJdc_t = zeros(nm,1);
    dJda_t = zeros(nm,1);

    ktot = 0;   % Total de pasos acumulados (para promediar el gradiente)

    % --- Recorrido sobre las condiciones iniciales ---
    for j = 1:nini

        % Reinicio de las derivadas RECURSIVAS al empezar cada condición inicial
        % (las derivadas dinámicas no se arrastran entre casos en este script).
        % Convención: la última dimensión (columna/hoja) indexa el estado x_i.
        Sw_t = zeros(nm,nx);     % dx_i/dw   (columna i = dx_i/dw)
        Sc_t = zeros(nm,nx);     % dx_i/dc
        Sa_t = zeros(nm,nx);     % dx_i/da
        Sv_t = zeros(ne,nm,nx);  % dx_i/dv   (hoja i = dx_i/dv)

        x = x_ini(:,j);   % Estado inicial del caso j

        % --- Simulación (rollout) de ndata pasos para el caso j ---
        for k = 1:ndata-1
            % --- (alternativa) referencia variable: setpoint en la 1a mitad, origen en la 2a ---
            % if( k <= ndata/2)
            %    r = [ x1ast; x2ast ];   uast1 = uast;
            % else
            %    r = [ 0*x1ast; 0*x2ast ];   uast1 = 0*uast;
            % end

            % ---------- Propagación hacia adelante de la red (cálculo de u) ----------
            in_red = x + 0.0*0.001*randn(2,1) - r;   % Entrada = error de estado (ruido desactivado por el 0.0*)
            m = v'*in_red;                           % Activación lineal de la capa oculta
            n = 2.0./(1 + exp(-(m-c)./a)) - 1;       % Sigmoide BIPOLAR (salida en [-1,1])
%           n = m;                                   % (alternativa) capa oculta lineal
            out_red = w'*n;                          % Salida de la red
%           u(k,j) = out_red' + uast1;   % Cambiar para r variable (uast1)  IMPORTANTE !!!!
            u(k,j) = out_red' + uast;                % Control = salida de la red + feedforward u*
            estado(k,:,j) = x';          % Se guarda el estado para graficar

            % ---------- Jacobianos de la planta y dinámica ----------
            jacob = A + u(k,j).*G;   % Jacobiano de la planta respecto del estado: d x(k+1)/d x
            dxdu  = B + G*x;         % Sensibilidad del estado siguiente al control: d x(k+1)/d u

            % Actualización del estado, incluyendo la perturbación senoidal externa
            x = A*x + B*u(k,j) + (G*x)*u(k,j) + W*pert*sin(2*pi*1*k*0.01);

            % ---------- Derivadas de la salida de la red respecto de sus parámetros ----------
            dndm = diag((1 - n.*n)./(2*a));   % Derivada de la sigmoide bipolar respecto de su argumento
%           dndm = diag(ones(nm,1));
            dudw_s = n;                       % du/dw
            dudv_s = in_red*w'*dndm;          % du/dv
            dudc_s = w .* ((n.*n-1)./(2.0.*a));            % du/dc
            duda_s = w .* ((n.*n-1).*(m-c)./(2*a.*a));     % du/da

            dudx = w'*dndm*v';   % Sensibilidad del control al estado: d u/d x

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
%           if( any(abs(x) > 10) )     % (alternativa) cortar si diverge
%               break;
%           end

        end
        ktot = ktot + k;   % Acumula los pasos de este caso
    end

    % --- Actualización de los parámetros (descenso de gradiente por lotes) ---
    w = w - eta *dJdw_t/ktot;   % Gradiente promediado sobre todos los pasos
    v = v - eta *dJdv_t/ktot;
    c = c - etac*dJdc_t/ktot;   % etac = 0 => c no cambia
    a = a - etaa*dJda_t/ktot;

    ersum2total = sum(ersum2)   % Costo total de la época (mostrado en consola)

    % --- Criterio de parada por error relativo al costo inicial ---
    if( cont == 1 )
        J0 = ersum2total;        % Costo de referencia (primera época)
        if( J0 == 0 ), J0 = 1; end
    end
    erreltotal = ersum2total/J0; % Se detiene cuando cae por debajo de errormax

    cont = cont + 1;
end

%% Visualización de resultados
%  Una figura por condición inicial: estados (arriba) y control (abajo),
%  recortados a los primeros nplot pasos.
nplot = min(100, ndata-1);
for j = 1:nini
    figure(j);
    subplot(2,1,1);
    plot(estado(1:nplot,:,j));   title(sprintf('States - Initial %d', j));
    subplot(2,1,2);
    plot(u(1:nplot,j));          title('Control input');
end

%% Guardado de los pesos entrenados
% save redcontrol201 v w c a nm;
ana = input('Save [1]: ')          % Preguntar si se desea guardar
if(ana == 1)
    save redcontrol202 v w c a nm;
end
