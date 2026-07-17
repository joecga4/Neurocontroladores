% ControlDifusoCarroPosicionX (original: fuzzycarxloco.m)
% =========================================================================
% Control difuso tipo Mamdani, implementado a mano (sin Fuzzy Toolbox), de
% un robot movil tipo carro. El carro avanza con paso constante r y el
% controlador decide el angulo del timon (delta, limitado a +/-50 grados)
% para llegar a la coordenada X deseada apuntando hacia arriba (phi = 90).
%
% Pipeline en cada paso de simulacion:
%   1. FUZZIFICACION   grados de pertenencia de X y de phi en sus
%                      particiones activas (triangulos/hombros con traslape)
%   2. INFERENCIA      cada regla de BaseReg se dispara con min(muX, muPhi)
%   3. AGREGACION      la membresia de delta de cada regla se recorta al
%                      nivel de disparo y se combina con max (Mamdani)
%   4. DEFUZZIFICACION centro de gravedad de la curva agregada
%   5. CINEMATICA      se actualiza la pose (x, y, phi) del carro
%
% Variables linguisticas (7 particiones cada una):
%   X     posicion en el eje X, en un marco desplazado donde el objetivo
%         queda en 50:   LE  LEC  LC  CE  RC  RIC  RI   (Left/Right, CEntro)
%   phi   inclinacion del carro respecto a la horizontal, en grados:
%         RB  RU  RV  VE  LV  LU  LB   (Right/Left + Below/Upper/Vertical)
%   delta angulo del timon, en grados:
%         NB  NM  NS  ZE  PS  PM  PB   (Neg/Pos + Big/Medium/Small, ZEro)

%% Condiciones iniciales y objetivo
clear; clc; close all;

PI = 3.141592;   % aproximacion de pi del script original; se conserva para
                 % reproducir exactamente los resultados

xini = input('Introduce coordenada inicial  x : ');
yini = input('Introduce coordenada inicial  y : ');
Pini = input('Introduce inclinacion inicial P : ');
xdeseado = input('Introducir coordenada final de x : ');

%% Particiones de las variables linguisticas
% Cada fila es un trapecio [a b c d]: la pertenencia sube de a a b, vale 1
% entre b y c, y baja de c a d. Con b == c es un triangulo; los extremos
% (a == b o c == d) son "hombros" saturados en 1 hacia afuera.

etiquetasX = {'LE','LEC','LC','CE','RC','RIC','RI'};
Xtrap = [ -50   -50    10    25       % LE : muy a la izquierda (hombro)
           22    30    30    38       % LEC: izquierda
           35    42    42    49       % LC : izquierda, cerca del centro
           46    50    50    54       % CE : centro (objetivo)
           51    58    58    65       % RC : derecha, cerca del centro
           62    70    70    78       % RIC: derecha
           75    90   150   150 ];    % RI : muy a la derecha (hombro)

etiquetasP = {'RB','RU','RV','VE','LV','LU','LB'};
Ptrap = [ -95   -45    -45    10      % RB: tumbado hacia la derecha
          -10    22.5   22.5  55      % RU: inclinado a la derecha
           45    66.5   66.5  88      % RV: derecha, casi vertical
           80    90     90   100      % VE: vertical (objetivo, 90 grados)
           92   113.5  113.5 135      % LV: izquierda, casi vertical
          125   157.5  157.5 190      % LU: inclinado a la izquierda
          170   222.5  222.5 275 ];   % LB: tumbado hacia la izquierda

etiquetasD = {'NB','NM','NS','ZE','PS','PM','PB'};
Dtrap = [ -60   -60    -60   -15      % NB: giro fuerte negativo (hombro)
          -25   -15.5  -15.5  -6      % NM: giro medio negativo
          -12    -6.5   -6.5  -1      % NS: giro suave negativo
           -5     0      0     5      % ZE: timon recto
            1     6.5    6.5  12      % PS: giro suave positivo
            6    15.5   15.5  25      % PM: giro medio positivo
           15    60     60    60 ];   % PB: giro fuerte positivo (hombro)

kX = size(Xtrap,1);
kP = size(Ptrap,1);

%% Grafica de las funciones de pertenencia
figure(1);
universos = { -50:0.5:150, -95:0.5:275, -60:0.5:60 };
trapecios = { Xtrap, Ptrap, Dtrap };
nombres   = { 'X', 'Phi', 'Delta' };
etiquetas = { etiquetasX, etiquetasP, etiquetasD };
for v = 1:3
    subplot(3,1,v); hold on; grid on;
    for i = 1:7
        plot(universos{v}, gradoPertenencia(universos{v}, trapecios{v}(i,:)), 'r');
        text(trapecios{v}(i,2), 1.12, etiquetas{v}{i}, 'HorizontalAlignment', 'center');
    end
    ylabel(nombres{v});
    ylim([0 1.3]);
end
subplot(3,1,1); title('Funciones de Pertenencia');

%% Base de reglas (7 x 7)
% BaseReg(j,i): fila j = particion de phi, columna i = particion de X.
% El valor es el indice de la particion de delta del consecuente
% (1 = NB ... 4 = ZE ... 7 = PB).
% Estrategia: lejos del objetivo, inclinarse hacia el (RB/RU giran
% antihorario, LU/LB horario); cerca de la vertical los consecuentes
% son graduales para enderezar suavemente y evitar sobrepaso.
%
%        X:  LE LEC LC  CE  RC RIC RI
BaseReg = [  1   1   1   1   1   1   1       % phi: RB
             1   1   1   1   1   1   1       %      RU
             7   6   4   2   1   1   1       %      RV
             7   6   5   4   3   2   1       %      VE
             7   7   7   6   4   2   1       %      LV
             7   7   7   7   7   7   7       %      LU
             7   7   7   7   7   7   7 ];    %      LB

%% Simulacion del lazo de control
r = 0.5;         % avance del carro por paso
L = 12;          % distancia entre ejes del carro
ganancia = 1.5;  % ganancia aplicada al delta defuzzificado
deltaMax = 50;   % saturacion del timon [grados]

dD = 0.1;
universoD = -50:dD:50;   % universo discretizado de delta para la agregacion

x = xini;
y = yini;
P = Pini;
Prad = P*(PI/180);
deltaTimon = 0;

pasosMax = 600;
xx = zeros(pasosMax,1);
yy = zeros(pasosMax,1);
PP = zeros(pasosMax,1);
dd = zeros(pasosMax,1);

for paso = 1:pasosMax

    % --- 1. Fuzzificacion ------------------------------------------------
    xRel = x + 50 - xdeseado;   % marco del universo: el objetivo queda en 50
    muX = zeros(kX,1);
    for i = 1:kX
        muX(i) = gradoPertenencia(xRel, Xtrap(i,:));
    end
    muP = zeros(kP,1);
    for j = 1:kP
        muP(j) = gradoPertenencia(P, Ptrap(j,:));
    end

    % --- 2. Inferencia (min) y 3. agregacion Mamdani (max) ---------------
    agregada = zeros(1, numel(universoD));
    for i = find(muX' > 0)
        for j = find(muP' > 0)
            regla = BaseReg(j,i);              % consecuente: particion de delta
            disparo = min(muX(i), muP(j));     % AND difuso de los antecedentes
            recortada = min(gradoPertenencia(universoD, Dtrap(regla,:)), disparo);
            agregada = max(agregada, recortada);
        end
    end

    % --- 4. Defuzzificacion por centro de gravedad -----------------------
    if any(agregada)
        AreaD = sum(agregada) * dD;
        deltaTimon = ((dD.*agregada) * universoD') / AreaD;
        deltaTimon = deltaTimon*ganancia;
        deltaTimon = min(max(deltaTimon, -deltaMax), deltaMax);
    end   % si ninguna regla se activa (x o phi fuera de todo rango) se
          % conserva el delta del paso anterior

    xx(paso) = x;
    yy(paso) = y;
    PP(paso) = P;
    dd(paso) = deltaTimon;

    % --- 5. Cinematica del carro -----------------------------------------
    Prad = Prad - (r/L)*tan((PI/180)*deltaTimon);
    if Prad > 3*PI/2
        Prad = Prad - 2*PI;    % mantiene phi en (-90, 270] grados
    end
    if Prad < -PI/2
        Prad = Prad + 2*PI;
    end
    P = Prad*180/PI;

    x = x + r*cos(Prad);
    y = y + r*sin(Prad);

    if y > 100   % llego a la fila de estacionamiento
        break;
    end
end

numPasos = paso;
xx = xx(1:numPasos);
yy = yy(1:numPasos);
PP = PP(1:numPasos);
dd = dd(1:numPasos);

%% Animacion de la trayectoria
disp('  ');
disp('Animacion Start.   Presione una tecla');
pause;

A = 6;   % ancho del carro y de cada cajon de estacionamiento
E = 3;   % separacion entre cajones

figure(2); hold on;
axis([-50 150 -50 100]);
plot([0 100 100 0 0], [0 0 100 100 0], 'r');   % campo de trabajo
plot([xdeseado xdeseado], [0 100], '--c');     % linea vertical del objetivo
title('Trayectoria de Robot Movil');

% Cajones de estacionamiento en la fila superior (y entre 99-L y 99),
% dejando libre el cajon del objetivo (alrededor de x = xdeseado).
% Cada cajon se dibuja con 4 contornos anidados para simular borde grueso.
bordes = [ 1 - (1:5)*(A+E), ...        % cajones a la izquierda del objetivo
           1 + (0:4)*(A+E), ...        % cajones a la derecha, primer grupo
           3 + (6:15)*(A+E) ];         % segundo grupo, tras el cajon libre
for x0 = bordes + xdeseado - 50
    for margen = [0 0.25 0.5 0.75]
        plot([x0+margen, x0+A-margen, x0+A-margen, x0+margen, x0+margen], ...
             [99-L+margen, 99-L+margen, 99-margen, 99-margen, 99-L+margen], 'b');
    end
end

% Carro dibujado como rectangulo (ancho A, largo L/2) cada 3 pasos
for paso = 1:3:numPasos
    xz = xx(paso);
    yz = yy(paso);
    Pz = (PI/180)*PP(paso);
    x1 = xz + (A/2)*sin(Pz);   y1 = yz - (A/2)*cos(Pz);   % esquinas delanteras
    x2 = xz - (A/2)*sin(Pz);   y2 = yz + (A/2)*cos(Pz);
    xF = xz - (L/2)*cos(Pz);   yF = yz - (L/2)*sin(Pz);   % punto trasero
    x3 = xF - (A/2)*sin(Pz);   y3 = yF + (A/2)*cos(Pz);   % esquinas traseras
    x4 = xF + (A/2)*sin(Pz);   y4 = yF - (A/2)*cos(Pz);
    plot([x1 x2 x3 x4 x1], [y1 y2 y3 y4 y1], 'r');
    pause(1/4);
end

figure(3);
plot(dd);
grid on;
title('Angulo del timon [grados]');
xlabel('Paso de simulacion');

%% Funciones locales
function mu = gradoPertenencia(t, trap)
% Pertenencia trapezoidal [a b c d]; t puede ser escalar o vector.
% Sube linealmente de a a b, vale 1 entre b y c, baja de c a d, 0 fuera.
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
