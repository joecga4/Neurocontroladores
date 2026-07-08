%% ============================================================================
%  NEUROCONTROLADOR DINÁMICO  -  CARRO-ROBOT (robot móvil tipo carro)
% ============================================================================
%  Objetivo:
%    Entrenar una red neuronal para CONTROLAR la dirección de un carro-robot
%    mediante el algoritmo de RETROPROPAGACIÓN DINÁMICA (BPTT). El controlador
%    se entrena con unas pocas posiciones iniciales y luego es capaz de
%    generalizar a otras. El aprendizaje es incremental en las condiciones
%    iniciales.
%
%  Modelo del carro (cinemática discreta, 2 estados):
%        x1(k+1) = x1 + r*cos(x2)            % avance en la coordenada x1
%        x2(k+1) = x2 - (r/L)*u             % giro de la orientación
%    donde:
%        x1 = posición (coordenada)         x2 = ángulo de orientación (theta)
%        u  = señal de control (dirección/giro)  -- salida de la red
%        r  = paso de avance por iteración  L = distancia entre ejes (batalla)
%
%  Meta de control (regulación):  x1* = 0 ,  x2* = pi/2.
%    El carro debe orientarse a pi/2 y llevar x1 a 0.
%
%  COBERTURA AMPLIA: se entrena para posiciones iniciales x1 en [-15, 15] y
%    orientaciones en TODO el círculo [0, 360°]. Para que 0° y 360° (la misma
%    pose) no produzcan entradas distintas, el error de orientación se ENVUELVE
%    a (−π, π] antes de entrar a la red. El espacio se cubre por CURRÍCULO: se
%    entrena en etapas de cerca a lejos (variable "etapa"), recargando y
%    guardando redcarro11 entre etapas (aprendizaje incremental).
%
%  Particularidad del método (igual que la familia DynamicBPControl2):
%    Es retropropagación DINÁMICA (BPTT): las derivadas del estado respecto de
%    los parámetros se propagan RECURSIVAMENTE en el tiempo a través del
%    jacobiano del lazo cerrado:
%        jacob   = d x(k+1)/d x            (jacobiano de la planta)
%        dxdu    = d x(k+1)/d u            (sensibilidad del estado al control)
%        dudx    = w'*dndm*v'              (sensibilidad del control al estado)
%        jacob_t = dxdu*dudx + jacob       (jacobiano del lazo cerrado)
%        S_p(k+1) = dxdu*du/dp + jacob_t*S_p(k)     (S_p = dx/dp del paso anterior)
%
%  ESCALABILIDAD: el número de condiciones iniciales se deduce de x_ini, y la
%    recursión BPTT está vectorizada (matrices indexadas por estado), por lo que
%    no hay términos dx1/dx2 cableados a mano.
%
%  NOTA: el entrenamiento NO pide parámetros por consola; se configuran en la
%        sección "Parámetros de entrenamiento" de abajo.
% ============================================================================

%% Inicialización del entorno de trabajo
clear;        % Borra todas las variables del espacio de trabajo
clc;          % Limpia la ventana de comandos
close all;    % Cierra todas las figuras abiertas

disp('Entrenamiento del neurocontrolador del carro-robot');

%% Definición del sistema dinámico (la PLANTA: el carro-robot)
r = 0.01;   % Paso de avance por iteración
L = 2;      % Distancia entre ejes (batalla del carro)

% Estado deseado (setpoint): orientación pi/2 y coordenada x1 = 0
out_des = [ 0
    pi/2 ];

%% Parámetros de simulación y condiciones iniciales
% Horizonte amplio: con r=0.01 el avance neto máximo por rollout es ndata*r.
% Para llevar x1 desde ±15 hasta 0 maniobrando hace falta un horizonte largo.
ndata = 6000;   % Número de pasos (horizonte) de cada simulación/rollout

% --- Currículo: el espacio (x1, orientación) se cubre por etapas, de cerca a
% lejos. Entrena ETAPA 1, guarda; cambia a 2 y vuelve a correr (recargando
% redcarro11); luego 3. Cada etapa amplía el rango de x1 y la densidad angular.
etapa = 2;   % <-- EDITAR: 1 (cerca) -> 2 (medio) -> 3 (cobertura completa)

switch etapa
    case 1   % Cerca: x1 modesto, orientaciones cada 90°
        x1set = [-5 0 5];
        thset = (0:90:270)*pi/180;
    case 2   % Medio: x1 hasta ±10, orientaciones cada 45°
        x1set = [-10 -5 0 5 10];
        thset = (0:45:315)*pi/180;
    case 3   % Completa: x1 en [-15,15] cada 5, círculo completo cada 45°
        x1set = -15:5:15;
        thset = (0:45:315)*pi/180;
end

% Producto cartesiano x1set × thset -> una COLUMNA por caso (fila 1 = x1,
% fila 2 = orientación). El resto del script se adapta a cualquier nini.
[X1g, THg] = meshgrid(x1set, thset);
x_ini = [ X1g(:)' ; THg(:)' ];

nx   = size(x_ini,1);   % Número de estados de la planta
nini = size(x_ini,2);   % Número de condiciones iniciales (deducido de x_ini)
fprintf('Etapa %d: %d condiciones iniciales (x1 en [%g, %g]).\n', ...
    etapa, nini, min(x1set), max(x1set));

%% Arquitectura de la red neuronal (el CONTROLADOR)
ne = nx;   % Número de entradas (error de estado x - deseado; sin sesgo)
nm = 50;   % Número de neuronas en la capa oculta
ns = 1;    % Número de salidas (señal de control escalar)

% Escala de NORMALIZACIÓN de la entrada: el error de posición llega a ±15, lo
% que satura las sigmoides (dndm≈0 -> gradiente desvanecido). Se divide cada
% entrada por su escala típica para mantener las activaciones en rango útil.
% La normalización se propaga correctamente al jacobiano dudx (regla de cadena).
inscale = [ 10 ; 1 ];   % [escala x1 ; escala orientación (rad)]

% Semilla del generador aleatorio: hace REPRODUCIBLE la inicialización de los
% pesos (con otras semillas el entrenamiento puede caer en mínimos pobres).
rng(1);

% Inicialización aleatoria de los pesos (arranque desde cero)
v = 0.1*randn(ne,nm);   % Pesos entrada -> capa oculta
w = 0.1*randn(nm,ns);   % Pesos capa oculta -> salida
c = zeros(nm,1);        % Centro de cada sigmoide
a = ones(nm,1);         % Pendiente de cada sigmoide

%% Carga de pesos previamente entrenados (arranque en caliente del currículo)
% La etapa 1 entrena DESDE CERO (la red normalizada es incompatible con pesos
% viejos de escala cruda). Las etapas 2 y 3 recargan los pesos de la etapa
% anterior para el aprendizaje incremental.
load redcarro11_etapa1;   % VALIDACIÓN PARCIAL: arranca del snapshot de la etapa 1

%% Parámetros de entrenamiento (antes solicitados por consola, ahora fijos)
eta  = 0.05;    % Tasa de aprendizaje de v y w
etaa = 0.005;   % Tasa de aprendizaje de la pendiente a de la sigmoide
etac = 0;       % Tasa del centro c (se fija en 0 => c NO se actualiza)

errormax = 5/100;   % Error máximo admitido (criterio de parada, en fracción)
contmax  = 1500;    % Número máximo de iteraciones (épocas)

% Pesos del costo por estado: J = Σ q1*er1² + q2*er2². Como el error de
% posición (x1 hasta 15) aplasta al de orientación (≤π), se pondera más la
% orientación para que ambas se regulen. Poner q=[1;1] recupera el costo plano.
q = [ 1 ; 10 ];

% BPTT TRUNCADO: con horizontes largos (ndata=6000) la recursión S_p crece sin
% cota y el gradiente explota a Inf/NaN. Se resetean los acumuladores cada
% Ttrunc pasos, acotando la profundidad de credit-assignment temporal.
Ttrunc = 200;    % Longitud de la ventana de truncamiento (pasos)

% RECORTE DE GRADIENTE (red de seguridad): si la norma del gradiente de un
% parámetro supera gmax, se reescala. Evita pasos gigantes ante un rollout malo.
gmax = 20;       % Norma máxima permitida del gradiente por parámetro

guardar  = 1;       % 1 = guardar pesos en redcarro11 al terminar; 0 = no guardar

%% Inicialización del bucle de entrenamiento
cont       = 1;   % Contador de iteraciones (épocas)
erreltotal = 1;   % Error relativo (se actualiza cada época; parada si < errormax)

% Registro de la respuesta para graficar (preasignado por eficiencia)
estado = zeros(ndata-1, nx, nini);   % estado(k,:,j) = estado en el paso k del caso j
u      = zeros(ndata-1, nini);       % señal de control por paso y caso

%% Bucle principal de entrenamiento (una iteración = una época de descenso de gradiente)
while( (erreltotal > errormax) && (cont < contmax) )

    % --- Acumuladores que se reinician en cada época ---
    ersum2 = zeros(nx,1);    % Suma del error cuadrático de la época

    % Derivadas RECURSIVAS del estado respecto de cada parámetro.
    % Convención: la última dimensión (columna/hoja) indexa el estado x_i.
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
    % Nota: los acumuladores recursivos S*_t NO se reinician aquí (se arrastran
    % entre casos y solo se resetean por época), conservando el comportamiento.
    for j = 1:nini

        x = x_ini(:,j);   % Estado inicial del caso j

        % --- Simulación (rollout) de ndata pasos para el caso j ---
        for k = 1:ndata-1

            % ---------- Propagación hacia adelante de la red (cálculo de u) ----------
            % Entrada = error de estado. El error de ORIENTACIÓN se ENVUELVE a
            % (−π, π] para que poses idénticas (p. ej. 0° y 360°) den la misma
            % entrada. La derivada del wrap es 1 salvo en la discontinuidad, así
            % que el jacobiano BPTT (dudx) no cambia.
            err2   = mod(x(2,1) - out_des(2,1) + pi, 2*pi) - pi;   % error de orientación envuelto
            in_red = [ x(1,1) - out_des(1,1) ; err2 ] ./ inscale;   % entrada normalizada
            m = v'*in_red;                % Activación lineal de la capa oculta
            n = 2.0./(1 + exp(-(m-c)./a)) - 1;   % Sigmoide BIPOLAR (salida en [-1,1])
            %           n = m;                        % (alternativa) capa oculta lineal
            out_red = w'*n;               % Salida de la red

            u(k,j) = out_red';            % Señal de control
            estado(k,:,j) = x';           % Se guarda el estado para graficar

            % ---------- Jacobianos de la planta y dinámica ----------
            % jacob = d x(k+1)/d x. La derivada exacta de r*cos(x2) respecto de
            % x2 es -r*sin(x2).
            jacob = [ 1   -r*sin(x(2,1))
                0    1 ];
            dxdu  = [ 0          % d x(k+1)/d u
                -r/L ];

            % Actualización del estado (cinemática del carro)
            z(1,1) = x(1,1) + r*cos(x(2,1));
            z(2,1) = x(2,1) - r/L*u(k,j);
            x = z;

            % ---------- Derivadas de la salida de la red respecto de sus parámetros ----------
            dndm = diag((1 - n.*n)./(2*a));   % Derivada de la sigmoide bipolar
            %           dndm = diag(ones(nm,1));
            dudw_s = n;                       % du/dw
            dudv_s = in_red*w'*dndm;          % du/dv
            dudc_s = w .* ((n.*n-1)./(2.0.*a));            % du/dc
            duda_s = w .* ((n.*n-1).*(m-c)./(2*a.*a));     % du/da

            % Sensibilidad del control al estado d u/d x. Incluye la regla de la
            % cadena de la normalización de entrada (in_red = err./inscale).
            dudx = (w'*dndm*v')./inscale';

            % ---------- Regla de la cadena DINÁMICA (recursiva en el tiempo, vectorizada) ----------
            % jacob_t = jacobiano del lazo cerrado. La actualización es SIMULTÁNEA
            % para todos los estados (regla de la cadena correcta): el lado derecho
            % usa S*_t del paso anterior antes de sobrescribirlo.
            %   S_p(k+1) = du/dp * dxdu' + S_p(k) * jacob_t'
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
            % Error de seguimiento del estado YA actualizado. La orientación se
            % envuelve igual que en la entrada para no perseguir la vuelta larga.
            er = [ x(1,1) - out_des(1,1)
                mod(x(2,1) - out_des(2,1) + pi, 2*pi) - pi ];
            erq = q.*er;                 % Error ponderado por estado (q1, q2)
            dJdw_t = dJdw_t + Sw_t*erq;  % sum_i q_i*er_i * dx_i/dw
            dJdc_t = dJdc_t + Sc_t*erq;
            dJda_t = dJda_t + Sa_t*erq;
            for i = 1:nx
                dJdv_t = dJdv_t + erq(i,1).*Sv_t(:,:,i);
            end

            ersum2 = ersum2 + q.*(er.^2);   % Costo ponderado: q_i * error² acumulado

            % ---------- Truncamiento de la recursión BPTT ----------
            % Cada Ttrunc pasos se "desconecta" el historial recursivo poniendo
            % a cero los acumuladores S_p, evitando que crezcan sin cota sobre
            % el horizonte largo. El gradiente ya acumulado en dJd*_t se conserva.
            if( mod(k, Ttrunc) == 0 )
                Sw_t = zeros(nm,nx);
                Sc_t = zeros(nm,nx);
                Sa_t = zeros(nm,nx);
                Sv_t = zeros(ne,nm,nx);
            end

            % Corte de seguridad: si la POSICIÓN diverge, se interrumpe el
            % rollout. Solo se vigila x1 (la orientación es un ángulo y puede
            % girar varias vueltas durante la maniobra). El límite supera el
            % rango inicial (±15) dejando margen de sobrepaso.
            if( abs(x(1,1)) > 25 )
                break;
            end

        end
        ktot = ktot + k;   % Acumula los pasos de este caso
    end

    % --- Actualización de los parámetros (descenso de gradiente por lotes) ---
    % Gradiente promediado sobre todos los pasos y RECORTADO por norma (gmax).
    gw = dJdw_t/ktot;  nrm = norm(gw(:));  if( nrm > gmax ), gw = gw*gmax/nrm; end
    gv = dJdv_t/ktot;  nrm = norm(gv(:));  if( nrm > gmax ), gv = gv*gmax/nrm; end
    ga = dJda_t/ktot;  nrm = norm(ga(:));  if( nrm > gmax ), ga = ga*gmax/nrm; end
    w = w - eta *gw;
    v = v - eta *gv;
    c = c - etac*dJdc_t/ktot;   % etac = 0 => c no cambia
    a = a - etaa*ga;

    ersum2total = sum(ersum2);   % Costo total de la época

    % --- Criterio de parada por error relativo al costo inicial ---
    if( cont == 1 )
        J0 = ersum2total;        % Costo de referencia (primera época)
        if( J0 == 0 ), J0 = 1; end
    end
    erreltotal = ersum2total/J0; % Se detiene cuando cae por debajo de errormax

    % Mostrar el progreso cada 100 iteraciones (y en la primera)
    if( mod(cont,100) == 0 || cont == 1 )
        fprintf('Iteracion %5d   Costo = %g   ErrRel = %g\n', cont, ersum2total, erreltotal);
    end

    % CHECKPOINT: guardado periódico para poder validar sin esperar al final
    if( mod(cont,200) == 0 )
        save redcarro11_etapa2 nm v w c a;
        fprintf('  [checkpoint] redcarro11_etapa2.mat guardado en iteracion %d\n', cont);
    end
    cont = cont + 1;

end

fprintf('Entrenamiento finalizado en %d iteraciones. Costo final = %g\n', cont-1, ersum2total);

%% Guardado de los pesos entrenados (sin preguntar por consola)
if( guardar == 1 )
    save redcarro11_etapa2 nm v w c a;
    disp('Pesos guardados en redcarro11_etapa2.mat');
end

%% Visualización de resultados
%  Con muchas condiciones iniciales (hasta decenas) se SUPERPONEN todas las
%  trayectorias en dos figuras: posición x1 (-> 0) y orientación x2 (-> pi/2).
return; figure(1);
plot(squeeze(estado(:,1,:)));
hold on; yline(out_des(1,1), 'k--');   % objetivo x1* = 0
title(sprintf('Posición x1 (todas las condiciones, etapa %d)', etapa));
xlabel('Learning Steps'); ylabel('x1'); grid;

return; figure(2);
plot(squeeze(estado(:,2,:)));
hold on; yline(out_des(2,1), 'k--');   % objetivo x2* = pi/2
title(sprintf('Orientación x2 (todas las condiciones, etapa %d)', etapa));
xlabel('Learning Steps'); ylabel('x2 [rad]'); grid;
