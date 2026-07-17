% ControlDifusoMamdaniTrailer (original: fuzzytrailerxbueno.m)
% =========================================================================
% Control difuso tipo Mamdani, implementado a mano (sin Fuzzy Toolbox), de
% un camion con remolque (truck-trailer). El vehiculo avanza con paso
% constante r y el controlador decide el angulo del timon delta (limitado
% a +/-50 grados) para llevar el remolque a la coordenada X deseada
% apuntando hacia arriba (Theta2 = 90) y con la articulacion alineada
% (Theta12 = 0).
%
% Pipeline en cada paso de simulacion:
%   1. FUZZIFICACION   grados de pertenencia de X, Theta2 y Theta12 en sus
%                      particiones activas
%   2. INFERENCIA      cada regla de BaseReg (3D) se dispara con
%                      min(muX, muP, muT)
%   3. AGREGACION      la membresia de delta de cada regla se recorta al
%                      nivel de disparo y se combina con max (Mamdani)
%   4. DEFUZZIFICACION centro de gravedad + ganancia + saturacion a +/-50
%   5. CINEMATICA      se actualizan Theta2 (remolque), Theta12
%                      (articulacion) y la posicion (x, y)
%
% Variables linguisticas:
%   X       posicion del remolque en un marco desplazado donde el objetivo
%           queda en 50 (7 particiones):  LE LEC LC CE RC RIC RI
%   Theta2  orientacion del remolque respecto a la horizontal, en grados
%           (7 particiones):  RB RU RV VE LV LU LB
%   Theta12 angulo de articulacion camion-remolque, en grados
%           (3 particiones):  NE ZT PO  (NEgativo, cero, POsitivo)
%   delta   angulo del timon, en grados (7 particiones):
%           NB NM NS ZE PS PM PB  (Neg/Pos + Big/Medium/Small, ZEro)

%% Condiciones iniciales y objetivo
clear; clc; close all;

PI = 3.141592;   % aproximacion de pi del script original; se conserva para
                 % reproducir exactamente los resultados

xini = input('Introduce coordenada inicial  x [20 : 80]: ');
yini = input('Introduce coordenada inicial  y [20 : 30]: ');
Pini = input('Introduce inclinacion inicial Th2 [-90 : 270]: ');
Tini = input('Introduce angulo truck-trailer inicial Th12: [-60 : 60]: ');
xdeseado = input('Introducir coordenada final de x [20 : 80]: ');

%% Particiones de las variables linguisticas
% Cada fila es un trapecio [a b c d]: la pertenencia sube de a a b, vale 1
% entre b y c, y baja de c a d. Con b == c es un triangulo; los extremos
% (a == b o c == d) son "hombros" saturados en 1 hacia afuera. En el caso
% degenerado a == b == c (particion NB de delta) la pertenencia vale 1
% exactamente en t == a y baja de a a d, como en el original.

etiquetasX = {'LE','LEC','LC','CE','RC','RIC','RI'};
Xtrap = [ -50   -50    10    25       % LE : muy a la izquierda (hombro)
           22    30    30    38       % LEC: izquierda
           35    42    42    50       % LC : izquierda, cerca del centro
           49    50    50    51       % CE : centro (objetivo)
           50    58    58    65       % RC : derecha, cerca del centro
           62    70    70    78       % RIC: derecha
           75    90   150   150 ];    % RI : muy a la derecha (hombro)

etiquetasP = {'RB','RU','RV','VE','LV','LU','LB'};
Ptrap = [ -95   -45    -45    10      % RB: tumbado hacia la derecha
          -30    40     40    60      % RU: inclinado a la derecha
           40    60     60    90      % RV: derecha, casi vertical
           60    90     90   120      % VE: vertical (objetivo, 90 grados)
           90   120    120   140      % LV: izquierda, casi vertical
          120   140    140   210      % LU: inclinado a la izquierda
          170   222.5  222.5 275 ];   % LB: tumbado hacia la izquierda

etiquetasT = {'NE','ZT','PO'};
Ttrap = [ -100  -100   -80     0      % NE: articulacion negativa (hombro)
           -30     0     0    30      % ZT: articulacion alineada
             0    80   100   100 ];   % PO: articulacion positiva (hombro)

etiquetasD = {'NB','NM','NS','ZE','PS','PM','PB'};
Dtrap = [ -70   -70    -70   -15      % NB: giro fuerte negativo (degenerado)
          -25   -15.5  -15.5  -6      % NM: giro medio negativo
          -12    -6.5   -6.5  -1      % NS: giro suave negativo
           -2     0      0     2      % ZE: timon recto
            1     6.5    6.5  12      % PS: giro suave positivo
            6    15.5   15.5  25      % PM: giro medio positivo
           15    70     70    70 ];   % PB: giro fuerte positivo

kX = size(Xtrap,1);
kP = size(Ptrap,1);
kT = size(Ttrap,1);

%% Grafica de las funciones de pertenencia
figure(1);
universos = { -50:0.5:150, -95:0.5:275, -100:0.5:100, -70:0.5:70 };
trapecios = { Xtrap, Ptrap, Ttrap, Dtrap };
nombres   = { 'X', 'Theta2', 'Theta12', 'Delta' };
etiquetas = { etiquetasX, etiquetasP, etiquetasT, etiquetasD };
for v = 1:4
    subplot(4,1,v); hold on; grid on;
    for i = 1:size(trapecios{v},1)
        plot(universos{v}, gradoPertenencia(universos{v}, trapecios{v}(i,:)), 'r');
        text((trapecios{v}(i,2)+trapecios{v}(i,3))/2, 1.12, etiquetas{v}{i}, ...
             'HorizontalAlignment', 'center');
    end
    ylabel(nombres{v});
    ylim([0 1.3]);
end
subplot(4,1,1); title('Funciones de Pertenencia');

%% Base de reglas (7 x 7 x 3)
% BaseReg(j,i,m): fila j = particion de Theta2, columna i = particion de X,
% capa m = particion de Theta12 (1 = NE, 2 = ZT, 3 = PO). El valor es el
% indice de la particion de delta del consecuente (1 = NB ... 7 = PB).
% Estrategia: si la articulacion esta doblada, primero se endereza
% (Theta12 NE -> siempre NB, Theta12 PO -> siempre PB); solo con la
% articulacion casi alineada (capa ZT) actua la tabla X-Theta2 que dirige
% el remolque hacia el objetivo.

%                   X:  LE LEC LC  CE  RC RIC RI
BaseReg(:,:,1) = [  1   1   1   1   1   1   1      % Theta2: RB  (Theta12 = NE)
                    1   1   1   1   1   1   1      %         RU
                    1   1   1   1   1   1   1      %         RV
                    1   1   1   1   1   1   1      %         VE
                    1   1   1   1   1   1   1      %         LV
                    1   1   1   1   1   1   1      %         LU
                    1   1   1   1   1   1   1 ];   %         LB

BaseReg(:,:,2) = [  7   7   7   7   1   1   1      % Theta2: RB  (Theta12 = ZT)
                    1   1   7   7   7   7   7      %         RU
                    1   1   7   7   7   7   7      %         RV
                    1   1   1   4   7   7   7      %         VE
                    1   1   1   1   1   7   7      %         LV
                    1   1   1   1   1   7   7      %         LU
                    7   7   7   7   1   1   1 ];   %         LB

BaseReg(:,:,3) = [  7   7   7   7   7   7   7      % Theta2: RB  (Theta12 = PO)
                    7   7   7   7   7   7   7      %         RU
                    7   7   7   7   7   7   7      %         RV
                    7   7   7   7   7   7   7      %         VE
                    7   7   7   7   7   7   7      %         LV
                    7   7   7   7   7   7   7      %         LU
                    7   7   7   7   7   7   7 ];   %         LB

%% Simulacion del lazo de control
r  = 0.075;      % avance del vehiculo por paso
L1 = 2.5;        % distancia entre ejes del camion (tractor)
L2 = 6;          % distancia entre ejes del remolque
ganancia = 3*2;  % ganancia aplicada al delta defuzzificado (DxG*3*2)
deltaMax = 50;   % saturacion del timon [grados]

dD = 0.001;
universoD = -70:dD:70;   % universo discretizado de delta para la agregacion

x = xini;
y = yini;
P = Pini;             % Theta2 [grados]
Prad = P*(PI/180);
T = Tini;             % Theta12 [grados]
Trad = T*PI/180;

countmax = 10000;
xx    = zeros(countmax,1);   % historia de x
yy    = zeros(countmax,1);   % historia de y
ffi2  = zeros(countmax,1);   % historia de Theta2 [rad]
ffi12 = zeros(countmax,1);   % historia de Theta12 [rad]
ffi1  = zeros(countmax,1);   % historia de Theta1 = Theta2 + Theta12 [rad]
delta = zeros(countmax,1);   % historia del timon [rad]

for count = 1:countmax

    % --- 1. Fuzzificacion ------------------------------------------------
    xnuevo = x + 50 - xdeseado;   % marco del universo: el objetivo queda en 50
    muX = zeros(kX,1);
    for i = 1:kX
        muX(i) = gradoPertenencia(xnuevo, Xtrap(i,:));
    end
    muP = zeros(kP,1);
    for j = 1:kP
        muP(j) = gradoPertenencia(P, Ptrap(j,:));
    end
    muT = zeros(kT,1);
    for n = 1:kT
        muT(n) = gradoPertenencia(T, Ttrap(n,:));
    end

    % --- 2. Inferencia (min) y 3. agregacion Mamdani (max) ---------------
    agregada = zeros(1, numel(universoD));
    for i = find(muX' > 0)
        for j = find(muP' > 0)
            for n = find(muT' > 0)
                regla = BaseReg(j,i,n);        % consecuente: particion de delta
                disparo = min(min(muX(i), muP(j)), muT(n));   % AND difuso
                recortada = min(gradoPertenencia(universoD, Dtrap(regla,:)), disparo);
                agregada = max(agregada, recortada);
            end
        end
    end

    % --- 4. Defuzzificacion por centroide + ganancia + saturacion --------
    % Como en el original NO hay guardia para AreaD == 0: si ninguna regla
    % se activa el cociente produce NaN y se propaga (comportamiento
    % heredado del original).
    AreaD = sum(agregada) * dD;
    DxG = ((dD.*agregada) * universoD') / AreaD;
    DxG = DxG*ganancia;
    if DxG > deltaMax
        DxG = deltaMax;
    end
    if DxG < -deltaMax
        DxG = -deltaMax;
    end

    % Historiales (pose y control ANTES de actualizar la dinamica)
    xx(count,1)    = x;
    yy(count,1)    = y;
    ffi2(count,1)  = P*PI/180;
    ffi12(count,1) = T*PI/180;
    ffi1(count,1)  = (P+T)*PI/180;
    delta(count,1) = DxG*PI/180;

    % --- 5. Cinematica del truck-trailer ---------------------------------
    % Theta2 se actualiza con el Theta12 del paso anterior; luego Theta12
    % usa tambien su valor anterior (mismo orden que el original).
    Prad = Prad - (r/L2)* sin(Trad);
    if Prad > (3*PI/2)
        Prad = Prad - 2*PI;    % mantiene Theta2 en (-90, 270] grados
    end
    if Prad < -PI/2
        Prad = Prad + 2*PI;
    end
    P = Prad*180/PI;

    Trad = Trad + (r/L2)*sin(Trad) - r/L1*tan(PI/180*DxG);
    if Trad > (2*PI)
        Trad = Trad - 2*PI;
    end
    if Trad < -2*PI
        Trad = Trad + 2*PI;
    end
    T = Trad*180/PI;

    x = x + r*cos(Trad)*cos(Prad);
    y = y + r*cos(Trad)*sin(Prad);

    if y > 100   % llego a la fila superior
        break;
    end
end

numPasos = count;
xx    = xx(1:numPasos);
yy    = yy(1:numPasos);
ffi2  = ffi2(1:numPasos);
ffi12 = ffi12(1:numPasos);
ffi1  = ffi1(1:numPasos);
delta = delta(1:numPasos);

%% Graficas de resultados
disp('  ');
disp('Animacion Start.   Presione una tecla');
pause;

figure(2);
plot(xx,yy);
title('Trayectoria X-Y');

figure(3);
angulos = { ffi2, ffi12, delta };
titulos = { 'Angulo Theta 2', 'Angulo Theta 12', 'Angulo del Timon Delta' };
for v = 1:3
    subplot(3,1,v);
    plot(angulos{v}*180/PI);
    title(titulos{v});
end

%% Animacion del truck-trailer
% Camion (azul) y remolque (rojo) dibujados como rectangulos de ancho La:
% (x,y) es el eje trasero del remolque, (x1,y1) la articulacion y (x2,y2)
% el eje delantero del camion.
La = 1.5*L1;    % ancho del vehiculo

hf = figure(6);
set(hf,'Position',[300 50 750 620]);
axis([-50 150 -50 100]);
title('Trayectoria del Robot Truck-Trailer')
hold on;

for k = 1:15*6:numPasos
    xk  = xx(k);     yk  = yy(k);
    fi1 = ffi1(k);   fi2 = ffi2(k);
    x1 = xk - L2*cos(fi2);    y1 = yk - L2*sin(fi2);   % articulacion
    x2 = x1 - L1*cos(fi1);    y2 = y1 - L1*sin(fi1);   % frente del camion

    dx1 = (La/2)*sin(fi1);   dy1 = (La/2)*cos(fi1);    % semiancho segun Theta1
    dx2 = (La/2)*sin(fi2);   dy2 = (La/2)*cos(fi2);    % semiancho segun Theta2

    xcab  = [ x2-dx1; x2+dx1; x1+dx1; x1-dx1; x2-dx1 ];   % camion
    ycab  = [ y2+dy1; y2-dy1; y1-dy1; y1+dy1; y2+dy1 ];
    xtrai = [ x1-dx2; x1+dx2; xk+dx2; xk-dx2; x1-dx2 ];   % remolque
    ytrai = [ y1+dy2; y1-dy2; yk-dy2; yk+dy2; y1+dy2 ];

    plot(xcab,ycab,'-b','Linewidth',2);
    plot(xtrai,ytrai,'-r','Linewidth',2);
    pause(0.4);
end
grid;

%% Funciones locales
function mu = gradoPertenencia(t, trap)
% Pertenencia trapezoidal [a b c d]; t puede ser escalar o vector.
% Sube linealmente de a a b, vale 1 entre b y c, baja de c a d, 0 fuera.
% Las formulas y los bordes (< vs <=) replican el if/elseif del original:
% subida (t-a)/(b-a) en [a,b) y bajada 1 - ((t-c)/(d-c)) en (c,d].
% En el caso degenerado a == b == c (particion NB de delta) la rama plana
% da 1 en t == a, igual que la rama descendente del original en ese punto.
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
end
