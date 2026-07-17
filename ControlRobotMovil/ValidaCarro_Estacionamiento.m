%% ============================================================================
%  VALIDACIÓN DEL NEUROCONTROLADOR DEL CARRO  -  ESTACIONAMIENTO / PARKING
% ============================================================================
%  Objetivo:
%    VALIDAR (sin reentrenar) la red entrenada en DynamicBPCarro.m haciendo que
%    el carro parta de posiciones iniciales ARBITRARIAS y alcance la posición
%    final deseada (estacionarse). La red fue entrenada para regular:
%        x* = 0 (aquí generalizado a un x* = xast elegido)   y   phi* = pi/2.
%
%  Modelo del carro (cinemática discreta, 3 estados para la simulación 2D):
%        x1(k+1) = x1 + r*cos(phi)        % coordenada X
%        x2(k+1) = x2 + r*sin(phi)        % coordenada Y (avance hacia el parking)
%        phi(k+1) = phi - (r/L)*u         % orientación
%    La red usa SOLO el error de X y de phi como entrada (ne = 2); la Y se
%    integra para dibujar la trayectoria hacia la fila de estacionamiento.
%
%  Este script NO entrena: carga los pesos guardados, simula el lazo cerrado
%  hasta llegar a la fila de parking (y = ymax) y grafica la trayectoria y el
%  ángulo de dirección. No modifica ni guarda los pesos.
% ============================================================================

%% Inicialización del entorno de trabajo
clear;        % Borra todas las variables del espacio de trabajo
clc;          % Limpia la ventana de comandos
close all;    % Cierra todas las figuras abiertas

%% Carga de los pesos entrenados (trae v, w, c, a, nm; ne = 2)
%  Antes se encadenaban varios load (redcarro10/12/13/14) pero solo el último
%  tenía efecto y esos .mat no existen. Se usa una sola red; cambia el nombre
%  para validar otra.
load redcarro11_etapa1;   % pesos de la ETAPA 1 del currículo (x1 hasta ±5)
% load redcarro11;          % (alternativa) red final del currículo (ya completo)
% load redcarro22;          % (alternativa) otra red entrenada

% NORMALIZACIÓN de entrada: DEBE coincidir con la usada al entrenar
% (DynamicBPCarro.m). La red espera in_red = error ./ inscale.
inscale = [ 10 ; 1 ];   % [escala x1 ; escala orientación (rad)]

%% Parámetros del carro y de la simulación
r = 0.01;   % Paso de avance por iteración
L = 2;      % Distancia entre ejes (batalla del carro)

ymax  = 100;     % Coordenada Y de la fila de estacionamiento (fin de la simulación)
kmax  = 100000;  % Tope de pasos: evita un bucle infinito si nunca alcanza ymax

deltamax = 45;                   % Ángulo de dirección máximo (grados)
umax     = tan(deltamax*pi/180); % Saturación equivalente sobre u = tan(delta)

% R = 20;  tandeltaast = L/R;    % (alternativa) seguimiento de trayectoria circular

%% Punto de operación deseado y condiciones iniciales (por consola)
%fiast       = pi/2;   % Orientación deseada al estacionar (pi/2 = mirando "arriba")
%fiast     = pi/4;   % (alternativa)
tandeltaast = 0;      % Feedforward de dirección (0 = sin sesgo de giro)

disp('Coordenadas del estacionamiento (zona libre): X en [-20 20], Y en [0 50]');
xini   = input('Coordenada inicial x [-15 15] : ');
yini   = input('Coordenada inicial y [5 15]   : ');
phiini = input('Inclinacion inicial phi (grados, -90 a 270) : ');
phiini = phiini*pi/180;
%xast   = input('Coordenada x deseada (centro de la plaza) : ');

x_ini = [ xini      % coordenada X
          yini      % coordenada Y
          phiini ]; % ángulo phi

%% Simulación del lazo cerrado (solo validación, sin entrenamiento)
% Preasignación al tope de pasos; al final se recorta a la longitud real.
posX = zeros(kmax,1);   % Trayectoria en X
posY = zeros(kmax,1);   % Trayectoria en Y
phi  = zeros(kmax,1);   % Orientación
u    = zeros(kmax,1);   % Señal de control (tan del ángulo de dirección)

x = x_ini;
xast = 0;
k = 1;
while( (x(2,1) < ymax) && (k <= kmax) )

    % ---------- Propagación hacia adelante de la red (cálculo de u) ----------
    % Mismo preprocesamiento que en el entrenamiento: error de orientación
    % ENVUELTO a (−π,π] y entrada NORMALIZADA por inscale.
    err2   = mod(x(3,1) - fiast + pi, 2*pi) - pi;   % error de orientación envuelto
    in_red = [ x(1,1) - xast ; err2 ] ./ inscale;   % entrada normalizada
    m = v'*in_red;                            % Activación lineal de la capa oculta
    n = 2.0./(1 + exp(-(m-c)./a)) - 1;        % Sigmoide BIPOLAR (salida en [-1,1])
    out_red = w'*n;                           % Salida de la red

    % Saturación del control al ángulo de dirección máximo (+/- umax)
    out_red = max(-umax, min(umax, out_red));

    % ---------- Registro y dinámica de la planta (cinemática del carro) ----------
    u(k,1)    = out_red + tandeltaast;   % Control aplicado
    posX(k,1) = x(1,1);
    posY(k,1) = x(2,1);
    phi(k,1)  = x(3,1);

    x(1,1) = x(1,1) + r*cos(x(3,1));
    x(2,1) = x(2,1) + r*sin(x(3,1));
    x(3,1) = x(3,1) - r/L*u(k,1);
    xast = 0.5*(x(1,1)+x(2,1));

    k = k + 1;
end

% Recorte a la longitud realmente simulada
N    = k - 1;
posX = posX(1:N);
posY = posY(1:N);
phi  = phi(1:N);
u    = u(1:N);

if( x(2,1) < ymax )
    warning('No se alcanzó ymax=%g en %d pasos (y final = %.3f).', ymax, kmax, x(2,1));
end

%% Visualización: trayectoria del carro hacia la plaza de estacionamiento
figure(1);
%axis([ -20 20 0 50 ]);
axis([0 100 0 100]);
hold on;

% % Fila de estacionamiento con una plaza libre de ancho 3 centrada en xast
% yy = [ 47 50 50 47 47 ];
% fill([ -20  -20  -1.5+xast  -1.5+xast  -20 ], yy, [ .8 .8 .8 ]);   % bloque izquierdo
% fill([ 1.5+xast  1.5+xast  20  20  1.5+xast ], yy, [ .8 .8 .8 ]);  % bloque derecho

% Animación de la trayectoria (un punto cada 20 pasos)
for idx = 1:20:N
    plot(posX(idx,1), posY(idx,1), 'ob', 'Linewidth', 3);
    pause(0.02);
end

xlabel('Coordenada X');
ylabel('Coordenada Y');
title('Trayectoria del robot');
grid on;
grid minor;

%% Visualización: ángulo de dirección a lo largo del recorrido
delta = atan(u) * 180/pi;   % u = tan(delta)  =>  delta en grados
figure(2);
plot(delta);
grid on;
title('Ángulo de dirección');
xlabel('Paso k');
ylabel('Grados');
grid minor;
