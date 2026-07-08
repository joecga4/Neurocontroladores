%% ============================================================================
%  ENTRENAMIENTO ESTÁTICO DE UN NEUROCONTROLADOR  -  MODELO 0 (Entrenamiento)
% ============================================================================
%  Objetivo:
%    Entrenar una red neuronal que actúe como controlador para mejorar la
%    respuesta de un sistema ESTABLE (problema de REGULACIÓN). Partiendo de
%    un estado inicial, se busca que los estados del sistema converjan a cero.
%
%  Esquema:
%    - La red se entrena para CUATRO condiciones iniciales distintas.
%    - Luego puede validarse con otras condiciones iniciales (cambiando el
%      factor que multiplica a x_ini).
%    - Permite comparar la respuesta del sistema controlado (u = red) frente
%      al no controlado (u = 0).
%
%  Particularidad del método:
%    No es retropropagación clásica sobre un conjunto de datos estático. El
%    gradiente del costo se propaga A TRAVÉS de la dinámica de la planta,
%    usando la sensibilidad analítica del estado siguiente al control:
%        dxdu = B + G*x      (derivada de x(k+1) respecto de u)
%    encadenada con las derivadas de la salida de la red respecto de sus
%    parámetros (w, v, c, a).
% ============================================================================

%% Inicialización del entorno de trabajo
clear;        % Borra todas las variables del espacio de trabajo
clc;          % Limpia la ventana de comandos
close all;    % Cierra todas las figuras abiertas

disp('Hello');

%% Definición del sistema dinámico (la PLANTA a controlar)
%  Modelo discreto bilineal:  x(k+1) = A*x + B*u + (G*x)*u
%  donde el término (G*x)*u introduce una ganancia de entrada que depende
%  del estado (no linealidad bilineal).

% Matriz de estado A (sistema ESTABLE: autovalores dentro del círculo unitario)
A = [  0.98   0.18
    -0.10   0.98 ];
% A = 1.1*A;                 % (alternativa) escalar A para hacerla menos estable

% A = [  1.02   0.18         % (alternativa) sistema ligeramente inestable
%      -0.10   1.02 ];

% Matriz de entrada B (cómo entra el control u al estado)
B = [  0
    0.8 ];

% Matriz de la parte bilineal G (ganancia de entrada dependiente del estado)
G = [   0.1    0.0
    0.1   -0.1 ];

% Vector de acoplamiento de perturbación externa (no se usa en este script)
W = [ 1
    0 ];

% Modelo de referencia deseado (Am). Aquí se anula con 0*Am más abajo, es
% decir, el estado deseado es CERO (regulación pura al origen).
Am = [  0.99  0
    0     0.99 ];

%% Parámetros de simulación y condiciones iniciales
ndata = 800;   % Número de pasos (horizonte) de cada simulación/rollout

% Estados iniciales para el aprendizaje (una COLUMNA por caso). El resto del
% script se adapta automáticamente al número de columnas.
x_ini = [ 0.1   0.1  -0.1  -0.1
    0.1  -0.1   0.1  -0.1 ];

x_ini = 1*x_ini;   % Factor de escala: cambiar (p.ej. 2*) para validar
xr    = 0*x_ini;   % Referencia de estados (no usada activamente)

nx   = size(x_ini,1);   % Número de estados de la planta
nini = size(x_ini,2);   % Número de condiciones iniciales (deducido de x_ini)

% Vector de estado deseado (setpoint). Aquí el origen -> regulación.
r = [ 0.0
    0.0 ];

% Pesos relativos de cada estado en el costo (q1, q2)
q = [ 1
    1 ];

%% Arquitectura de la red neuronal (el CONTROLADOR)
%  Red de una capa oculta:
%    entrada (ne) -> capa oculta (nm neuronas, sigmoide bipolar) -> salida (ns)
ne = 2;    % Número de entradas (= estado actual; sin sesgo/bias)
nm = 50;   % Número de neuronas en la capa oculta
ns = 1;    % Número de salidas (señal de control escalar u)

% Inicialización aleatoria de los pesos y parámetros de las sigmoides
v = 0.1*randn(ne,nm);   % Pesos entrada -> capa oculta
w = 0.1*randn(nm,ns);   % Pesos capa oculta -> salida
c = zeros(nm,1);        % Centro de cada sigmoide
a = ones(nm,1);         % Pendiente de cada sigmoide

%% Carga de pesos previamente entrenados (arranque en caliente)
%  NOTA: el archivo .mat debe existir; si no, esta línea falla. Sobrescribe
%  la inicialización aleatoria anterior con los pesos ya guardados.
load redcontrolestatico0;     % Arranque en caliente: continúa desde los pesos guardados
% load redcontrolestatico00;

%% Parámetros de entrenamiento (fijados en el código, ya NO por consola)
%  Edita directamente estos valores para cambiar el entrenamiento.
eta   = 2.0;    % Tasa de aprendizaje de v y w (más agresiva para romper la meseta)
etaa  = 0.2;    % Tasa de aprendizaje de la pendiente a
etac  = 0;      % Tasa del centro c (0 => c NO se actualiza)
alpha = 0.95;   % Momentum: fracción del paso anterior que se reaprovecha

% Criterio de parada por CONVERGENCIA: se detiene cuando la mejora relativa
% del costo entre épocas cae por debajo de errormax (en fracción).
errormax = 1e-4;       % Mejora relativa mínima en % (criterio de parada)
errormax = errormax/100;                          % Se convierte de % a fracción
contmax  = 5000;       % Máx. de iteraciones (épocas) de aprendizaje

%% Inicialización del bucle de entrenamiento
cont       = 1;   % Contador de iteraciones (épocas)
erreltotal = 1;   % Error relativo (no se actualiza: la parada efectiva es cont<contmax)
dw_old = 0;       % Memorias de gradientes previos (reservadas, p.ej. para momentum)
dv_old = 0;
dc_old = 0;
da_old = 0;

% Registro de la respuesta para graficar (preasignado por eficiencia)
estado  = zeros(ndata-1, nx, nini);
deseado = zeros(ndata-1, nx, nini);
u       = zeros(ndata-1, nini);

JJold = 1e30;   % Costo de la iteración anterior (para detectar si empeora)

JJbest = 1e30;  % Mejor (menor) costo visto hasta ahora
wbest = w;  vbest = v;  cbest = c;  abest = a;   % Mejores pesos asociados

%% Bucle principal de entrenamiento (una iteración = una época de descenso de gradiente)
while( (erreltotal > errormax) && (cont < contmax) )

    % --- Acumuladores que se reinician en cada época ---
    ersum2 = zeros(nx,1);     % Suma del error cuadrático de la época
    dJdw_t = zeros(nm,ns);    % Gradiente acumulado del costo respecto de cada parámetro
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
            in_red = x + 0*0.015*randn(2,1) - r;   % Entrada a la red = error de estado (ruido desactivado por el 0*)
            m = v'*in_red;                         % Activación lineal de la capa oculta
            n = 2.0./(1 + exp(-(m-c)./a)) - 1;     % Sigmoide BIPOLAR (salida en [-1,1])
            %     n = m;                                 % (alternativa) capa oculta lineal
            out_red = w'*n;                        % Salida de la red
            %     out_red = 0;
            u(k,j) = out_red' + 0;                 % Señal de control aplicada
            %     u(k,j) = 0;                            % (alternativa) sin control, para comparar

            % ---------- Dinámica de la planta y estado deseado ----------
            dxdu = B + G*x;        % Sensibilidad del estado siguiente al control: d x(k+1)/d u

            out_des = 0*Am*x;      % Estado deseado (0*Am => deseado = 0 => regulación)

            x = A*x + B*u(k,j) + (G*x)*u(k,j);   % Actualización del estado de la planta

            estado(k,:,j)  = x';        % Se guarda el estado para graficar
            deseado(k,:,j) = out_des';  % Se guarda el deseado para graficar

            % ---------- Derivadas de la salida de la red respecto de sus parámetros ----------
            dndm = diag((1 - n.*n)./(2*a));   % Derivada de la sigmoide bipolar respecto de su argumento
            %     dndm = diag(ones(nm,1));
            dudw_s = n;                       % du/dw
            dudv_s = in_red*w'*dndm;          % du/dv
            dudc_s = w .* ((n.*n-1)./(2.0.*a));            % du/dc
            duda_s = w .* ((n.*n-1).*(m-c)./(2*a.*a));     % du/da

            % ---------- Costo y acumulación del gradiente (estático, vectorizado) ----------
            % Caso ESTÁTICO: d x_i/d p = dxdu(i)*du/dp (sin recursión temporal). El
            % gradiente comparte un mismo coeficiente escalar para los 4 parámetros:
            %     g = (q.*er)'*dxdu + R*u   (error retropropagado por dxdu + esfuerzo)
            er  = (x - out_des);        % Error de seguimiento (estado - deseado)
            R   = 1*0.05;               % Peso de penalización del esfuerzo de control
            erq = q .* er;              % Error ponderado por estado (q1, q2)
            g   = erq'*dxdu + R*u(k,j); % Coeficiente escalar retropropagado

            dJdw_t = dJdw_t + g*dudw_s;
            dJdv_t = dJdv_t + g*dudv_s;
            dJdc_t = dJdc_t + g*dudc_s;
            dJda_t = dJda_t + g*duda_s;

            ersum2 = ersum2 + er.^2 + R*u(k,j)^2;   % Costo: error cuadrático + esfuerzo de control

        end
        ktot = ktot + k;   % Acumula los pasos de este caso
    end

    % --- Actualización de los parámetros (descenso por lotes con MOMENTUM) ---
    %  Cada paso = gradiente actual + alpha * paso anterior (acelera el descenso).
    dw_old = eta*dJdw_t/ktot  + alpha*dw_old;
    dv_old = eta*dJdv_t/ktot  + alpha*dv_old;
    dc_old = etac*dJdc_t/ktot + alpha*dc_old;   % etac = 0 => c no cambia
    da_old = etaa*dJda_t/ktot + alpha*da_old;

    w = w - dw_old;
    v = v - dv_old;
    c = c - dc_old;
    a = a - da_old;

    ersum2total = sum(ersum2)   % Costo total de la época (mostrado en consola)
    JJ(cont,1) = ersum2total;   % Historial del costo

    % --- Seguimiento de los MEJORES pesos vistos hasta ahora ---
    %  Con momentum/eta alto el costo puede oscilar; nos quedamos con el mínimo.
    if( ersum2total < JJbest)
        JJbest = ersum2total;
        wbest = w;  vbest = v;  cbest = c;  abest = a;
    end

    % Mejora relativa del costo respecto de la época anterior (criterio de parada)
    erreltotal = abs(JJold - ersum2total)/abs(ersum2total);

    % Guardia de DIVERGENCIA tolerante: corta solo si el costo se dispara o es NaN
    if( ~isfinite(ersum2total) || ersum2total > 2*JJbest)
        disp('Cost function diverging -> stop.')
        break;
    end
    JJold = ersum2total;

    cont = cont + 1;
end

% --- Se restauran los mejores pesos encontrados durante el entrenamiento ---
w = wbest;  v = vbest;  c = cbest;  a = abest;
fprintf('Mejor costo alcanzado: %.6f\n', JJbest);

%% Visualización de resultados
%  Una figura por condición inicial: estados (+ deseado) arriba, control abajo.
%  Figura final: evolución del costo JJ a lo largo de las iteraciones.
for j = 1:nini
    figure(j);
    subplot(2,1,1);
    plot(estado(:,:,j)); hold on; plot(deseado(:,:,j));
    title(sprintf('States - Initial %d', j));
    subplot(2,1,2);
    plot(u(:,j));   title('Control input');
end
figure(nini+1);
plot(JJ);   title('Costo JJ por iteración');

%% Guardado de los pesos entrenados
% ana = 1;    % 1 => guardar los pesos; 0 => no guardar (ya no se pregunta por consola)
% if(ana == 1)
%     save redcontrolestatico0 v w c a nm;    % Guardado "oficial" (solo si ana==1)
% end
% 
% % save redcontrolestatico0 v w c a nm;
% 
% save redcontrolestatico00 v w c a nm;       % Respaldo automático (siempre se guarda)
