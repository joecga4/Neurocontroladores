% ControlDifusoMotorDC (original: fuzzymotor.m)
% =========================================================================
% Control difuso tipo Mamdani, implementado a mano (sin Fuzzy Toolbox), del
% posicionamiento de un motor DC con transmision de tornillo sin fin. El
% modelo lineal de 3 estados (posicion, velocidad, corriente) se discretiza
% con c2d y se perturba con friccion seca (+/-Fseca segun el signo de la
% velocidad). El controlador difuso decide el voltaje aplicado al motor,
% saturado a +/-24 V.
%
% Pipeline en cada paso de simulacion:
%   1. FUZZIFICACION   grados de pertenencia del error de posicion X y de
%                      la velocidad P en sus particiones activas
%   2. INFERENCIA      cada regla de BaseReg se dispara con min(muX, muP)
%   3. AGREGACION      la membresia del voltaje de cada regla se recorta al
%                      nivel de disparo y se combina con max (Mamdani)
%   4. DEFUZZIFICACION centro de gravedad de la curva agregada + saturacion
%   5. DINAMICA        se integra el modelo discreto xx = Ak*xx+Bk*u+Wk*Fs
%
% Variables linguisticas (el original etiqueta P como "Phi" en la grafica,
% pero aqui P es la velocidad del motor):
%   X  error de posicion (posicion actual - deseada), 7 particiones:
%      LE  LEC  LC  CE  RC  RIC  RI   (Left/Right, CEntro)
%   P  velocidad del motor, 7 particiones:  RB  RU  RV  VE  LV  LU  LB
%   D  voltaje de control, 7 particiones:
%      NB  NM  NS  ZE  PS  PM  PB    (Neg/Pos + Big/Medium/Small, ZEro)

%% Condiciones iniciales y objetivo
clear; clc; close all;

PI = 3.141592;   % aproximacion de pi del script original; en este script no
                 % llega a usarse (la planta usa el pi de MATLAB), pero se
                 % conserva por fidelidad con el original

xini = input('Introduce Posicion Inicial X : ');
xdeseado = input('Introducir Posicion X deseada : ');

%% Particiones de las variables linguisticas
% Cada fila es un trapecio [a b c d]: la pertenencia sube de a a b, vale 1
% entre b y c, y baja de c a d. Con b == c es un triangulo; los extremos
% (a == b o c == d) son "hombros" saturados en 1 hacia afuera. El caso
% degenerado a == b == c (particion NM del voltaje) es una rampa
% descendente abierta por la izquierda: vale 0 exactamente en t == a
% (ver gradoPertenencia al final del script).

etiquetasX = {'LE','LEC','LC','CE','RC','RIC','RI'};
Xtrap = [ -1.2   -1.2   -0.45  -0.35      % LE : error muy negativo (hombro)
          -0.45  -0.30  -0.30  -0.15      % LEC: error negativo
          -0.25  -0.15  -0.15  -0.00      % LC : error negativo pequeno
          -0.02   0      0      0.02      % CE : error nulo (objetivo)
           0.00   0.15   0.15   0.25      % RC : error positivo pequeno
           0.15   0.30   0.30   0.45      % RIC: error positivo
           0.35   0.45   1.2    1.2 ];    % RI : error muy positivo (hombro)

etiquetasP = {'RB','RU','RV','VE','LV','LU','LB'};
Ptrap = [ -0.50  -0.50  -0.10  -0.08      % RB: velocidad muy negativa (hombro)
          -0.12  -0.08  -0.08  -0.04      % RU: velocidad negativa
          -0.06  -0.03  -0.03  -0.00      % RV: velocidad negativa pequena
          -0.01   0      0      0.01      % VE: velocidad nula
           0.00   0.03   0.03   0.06      % LV: velocidad positiva pequena
           0.04   0.08   0.08   0.12      % LU: velocidad positiva
           0.08   0.10   0.50   0.50 ];   % LB: velocidad muy positiva (hombro)

etiquetasD = {'NB','NM','NS','ZE','PS','PM','PB'};
Dtrap = [ -40    -40    -15    -8         % NB: voltaje fuerte negativo (hombro)
          -10    -10    -10    -6         % NM: rampa abierta en -10 (degenerada)
           -9     -5     -5    -0         % NS: voltaje suave negativo
           -1      0      0     1         % ZE: voltaje nulo
            0      5      5     9         % PS: voltaje suave positivo
            6     10     10    10         % PM: rampa que termina en 10
            8     15     40    40 ];      % PB: voltaje fuerte positivo (hombro)

kX = size(Xtrap,1);
kP = size(Ptrap,1);

%% Grafica de las funciones de pertenencia
figure(1);
universos = { -1.2:0.005:1.2, -0.5:0.005:0.5, -40:0.5:40 };
trapecios = { Xtrap, Ptrap, Dtrap };
nombres   = { 'X', 'Phi', 'Delta' };     % ylabels del original
colores   = { 'g', 'r', 'y' };
etiquetas = { etiquetasX, etiquetasP, etiquetasD };
for v = 1:3
    subplot(3,1,v); hold on; grid on;
    for i = 1:size(trapecios{v},1)
        plot(universos{v}, gradoPertenencia(universos{v}, trapecios{v}(i,:)), colores{v});
        text((trapecios{v}(i,2)+trapecios{v}(i,3))/2, 1.12, etiquetas{v}{i}, ...
             'HorizontalAlignment', 'center');
    end
    ylabel(nombres{v});
    ylim([0 1.3]);
end
subplot(3,1,1); title('Funciones de Pertenencia');

%% Base de reglas (7 x 7)
% BaseReg(j,i): fila j = particion de P (velocidad), columna i = particion
% de X (error). El valor es el indice de la particion de voltaje del
% consecuente (1 = NB ... 4 = ZE ... 7 = PB).
% Todas las filas son iguales: la velocidad no cambia la decision, solo el
% error de posicion (error negativo -> voltaje PB, error nulo -> ZE,
% error positivo -> NB).
%
%        X:  LE LEC LC  CE  RC RIC RI
BaseReg = [  7   7   7   4   1   1   1       % P: RB
             7   7   7   4   1   1   1       %    RU
             7   7   7   4   1   1   1       %    RV
             7   7   7   4   1   1   1       %    VE
             7   7   7   4   1   1   1       %    LV
             7   7   7   4   1   1   1       %    LU
             7   7   7   4   1   1   1 ];    %    LB

%% Modelo del motor DC con tornillo sin fin
R  = 2*1.1;        % resistencia de armadura
L  = 1*0.0001;     % inductancia de armadura
Kt = 0.0573;       % constante de torque
Kb = 0.05665;      % constante de fuerza contraelectromotriz
I  = 4.326e-5;     % inercia del rotor
p  = 0.0025;       % paso del tornillo sin fin
m  = 1.00;         % masa desplazada
c  = 100;          % friccion viscosa
r  = 0.01;         % radio del tornillo
alfa = 45*pi/180;  % angulo de la helice (usa el pi de MATLAB, como el original)

d = m + 2*pi*I*tan(alfa)/(p*r);   % masa equivalente reflejada

a22 = -c/d;
a23 = Kt*tan(alfa)/(r*d);
a32 = -2*pi*Kb/(p*L);
a33 = -R/L;
b31 = 1/L;
w21 = -1/d;

% Estados: [posicion; velocidad; corriente]
A = [ 0   1    0
      0  a22  a23
      0  a32  a33 ];

B = [ 0
      0
      b31 ];

Wf = [ 0          % entrada de perturbacion: friccion seca
       w21
       0 ];

dt = 0.002;       % paso de integracion [s]
ti = 0;
tf = 1*25;        % tiempo final [s]
Fseca = 0.75*70;      % 0 - 0.75

[Ak,Bk] = c2d(A,B,dt);    % discretizacion exacta de la planta
[Ak,Wk] = c2d(A,Wf,dt);   % misma Ak; Wk discretiza la entrada de friccion

%% Simulacion del lazo de control
dD = 0.02;
universoD = -40:dD:40;   % universo discretizado del voltaje para la agregacion

voltMax = 24;   % saturacion del voltaje; el comentario del original decia
                % "+/-30" pero el codigo satura en +/-24 (se conserva 24)

xx = [xini; 0; 0];   % estado inicial [posicion; velocidad; corriente]
P = xx(2,1);         % velocidad: segunda entrada del controlador difuso

tiempos = ti:dt:tf;
numPasos = numel(tiempos);
pos    = zeros(numPasos,1);
vel    = zeros(numPasos,1);
amp    = zeros(numPasos,1);
volt   = zeros(numPasos,1);
tiempo = zeros(numPasos,1);

for paso = 1:numPasos

    % --- 1. Fuzzificacion ------------------------------------------------
    xnuevo = xx(1,1) - xdeseado;   % error de posicion
    muX = zeros(kX,1);
    for i = 1:kX
        muX(i) = gradoPertenencia(xnuevo, Xtrap(i,:));
    end
    muP = zeros(kP,1);
    for j = 1:kP
        muP(j) = gradoPertenencia(P, Ptrap(j,:));
    end

    % --- 2. Inferencia (min) y 3. agregacion Mamdani (max) ---------------
    agregada = zeros(1, numel(universoD));
    for i = find(muX' > 0)
        for j = find(muP' > 0)
            regla = BaseReg(j,i);              % consecuente: particion de voltaje
            disparo = min(muX(i), muP(j));     % AND difuso de los antecedentes
            recortada = min(gradoPertenencia(universoD, Dtrap(regla,:)), disparo);
            agregada = max(agregada, recortada);
        end
    end

    % --- 4. Defuzzificacion por centro de gravedad + saturacion ----------
    % Como en el original NO hay guardia para AreaD == 0: si ninguna regla
    % se activa (error o velocidad fuera de todo rango) el cociente produce
    % NaN y se propaga (comportamiento heredado del original).
    AreaD = sum(agregada) * dD;
    voltaje = ((dD.*agregada) * universoD') / AreaD;
    if voltaje > voltMax
        voltaje = voltMax;
    end
    if voltaje < -voltMax
        voltaje = -voltMax;
    end

    pos(paso)    = xx(1,1);
    vel(paso)    = xx(2,1);
    amp(paso)    = xx(3,1);
    volt(paso)   = voltaje;
    tiempo(paso) = tiempos(paso);

    % --- 5. Dinamica discreta del motor ----------------------------------
    if xx(2,1) >= 0          % friccion seca opuesta al movimiento
        Fs = Fseca;
    elseif xx(2,1) < 0
        Fs = -Fseca;
    end

    xx = Ak*xx + Bk*voltaje + Wk*Fs;

    P = xx(2,1);    % velocidad para el siguiente paso
end

%% Graficas de resultados
figure(2)
plot(tiempo,pos);
title('POSICION');   grid;

figure(3)
plot(tiempo,volt);
title('VOLTAJE');   grid;

%% Funciones locales
function mu = gradoPertenencia(t, trap)
% Pertenencia trapezoidal [a b c d]; t puede ser escalar o vector.
% Sube linealmente de a a b, vale 1 entre b y c, baja de c a d, 0 fuera.
% Las formulas y los bordes (< vs <=) replican el if/elseif del original:
% subida (t-a)/(b-a) en [a,b) y bajada 1 - ((t-c)/(d-c)) en (c,d].
a = trap(1);  b = trap(2);  c = trap(3);  d = trap(4);
mu = zeros(size(t));
mu(t >= b & t <= c) = 1;
if b > a
    sube = (t >= a & t < b);
    mu(sube) = (t(sube) - a)/(b - a);
end
if d > c
    baja = (t > c & t <= d);
    mu(baja) = 1 - (t(baja) - c)/(d - c);
end
if a == b && b == c
    % Caso degenerado (particion NM del voltaje): en el original la rama
    % "tD <= NM1 -> 0" tiene prioridad sobre la rama descendente, asi que
    % el vertice t == a NO pertenece al conjunto (rampa abierta por la
    % izquierda). Se replica para conservar la exactitud bit a bit.
    mu(t == b) = 0;
end
end
