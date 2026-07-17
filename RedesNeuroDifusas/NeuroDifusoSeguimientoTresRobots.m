% NeuroDifusoSeguimientoTresRobots (original: neurofuzzy72.m)
% =========================================================================
% Control neuro-difuso tipo Sugeno de orden cero (consecuentes constantes),
% implementado a mano (sin Fuzzy Toolbox), para TRES robots moviles tipo
% carro en cadena lider-seguidor:
%   Robot 1 (lider)      sigue la recta deseada y = tan(P1deseado)*x + b1
%                        (aqui P1deseado = 90 y b1 = 5)
%   Robot 2 (seguidor)   persigue al robot 1: rumbo deseado con atan2
%                        apuntando al lider y velocidad r2 regulada por la
%                        distancia d12
%   Robot 3 (seguidor)   persigue al robot 2 con la misma logica (rumbo
%                        por atan2 y velocidad r3 segun d23)
%
% Pipeline de UN robot en cada paso (funcion local deltaTimonRobot):
%   1. CAMBIO DE MARCO  la posicion se proyecta sobre la recta deseada y
%                       se traslada para que el objetivo quede en
%                       xnuevo = 50; el rumbo se refiere a la recta para
%                       que el objetivo quede en Pnuevo = 90
%   2. FUZZIFICACION    7 membresias en X (sigmoide + 5 gaussianas +
%                       sigmoide) y 7 gaussianas en phi
%   3. INFERENCIA       49 reglas Sugeno de orden cero: el disparo de cada
%                       regla es el producto muX(i)*muPhi(j) y su
%                       consecuente es una constante (-30, 0 o +30 grados)
%   4. DEFUZZIFICACION  promedio ponderado de los consecuentes,
%                       delta = ganancia*(c'*w)/sum(w), saturado a +-45
%   5. CINEMATICA       modelo tipo carro (funcion local pasoCinematica)
%
% Por que hay DOS bases de reglas (BaseRegP90 / BaseRegM90): el cambio de
% marco del paso 1 depende del signo del rumbo deseado. Si el rumbo
% deseado apunta hacia +y (fact = +1, Pdeseado en [0, 180)) se usa
% BaseRegP90 con los centros de phi originales; si apunta hacia -y
% (fact = -1) los centros de phi se desplazan -180 (termino
% (1-fact)/2*180) y se usa BaseRegM90, la version espejada de BaseRegP90.
% El lider siempre cae en BaseRegP90 (P1deseado = 90 > 0); los seguidores
% alternan segun hacia donde quede su robot guia.
%
% Diferencias con NeuroDifusoSeguimientoDosRobots (neurofuzzy71.m):
%   - aqui 3 robots en cadena y condiciones iniciales hardcodeadas (los
%     input() estaban comentados en el original); alla 2 robots con
%     input()
%   - velocidad nominal 2*0.05 aqui vs 1.75*0.05 alla; los seguidores solo
%     se detienen (no retroceden) y el umbral inferior es 3.5*L
%   - b1 = 5 aqui (alla quedaba en 0)
%   - en la seccion (comentada) de graficas de membresias el original
%     desplazaba el universo phi y los centros en -180, es decir,
%     graficaba las membresias del caso fact = -1

%% Condiciones iniciales
% Hardcodeadas: los input() del original estaban comentados
clear;
close all;
clc;

PI = 3.141592;   % aproximacion de pi del script original (se usa en el
                 % avance x-y y en el dibujo); se conserva para
                 % reproducir exactamente los resultados

x1ini = 25;   y1ini = 22;   P1ini = 12;
x2ini = 35;   y2ini = 12;   P2ini = 42;
x3ini = 40;   y3ini = 40;   P3ini = 12;

% Recta deseada del lider:  y = tan(P1deseado)*x + b1
P1deseado = 90;
b1 = 5;

%% Parametros de las membresias (7 regiones por variable linguistica)
% X: posicion proyectada en el marco desplazado (objetivo en 50)
%   region     1       2      3      4      5      6      7
%   tipo       sigm-   gauss  gauss  gauss  gauss  gauss  sigm+
%   centro c   13.5    23.5   39.0   50.0   61.0   76.5   86.5
%   ancho  a    1.5     7.0    6.0    2.0    6.0    7.0    1.5
% phi: rumbo relativo a la recta deseada, en grados (objetivo en 90);
% con fact = -1 los centros se desplazan -180
%   region     1       2      3      4      5      6      7
%   tipo       gauss   gauss  gauss  gauss  gauss  gauss  gauss
%   centro c  -45.0    21.5   65.0   90.0  115.0  158.5  225.0
%   ancho  a   25.0    15.0   12.0    3.0   12.0   15.0   25.0

cX = [ 13.5   23.5  39.0  50.0   61.0  76.5   86.5 ];
aX = [  1.5    7.0   6.0   2.0    6.0   7.0    1.5 ];
cP = [ -45.0  21.5  65.0  90.0  115.0  158.5  225.0 ];
aP = [ 25.0   15.0  12.0   3.0   12.0  15.0   25.0 ];

kX = numel(cX);   % 7 regiones en X
kP = numel(cP);   % 7 regiones en phi
% El original definia ademas kD = 7 (regiones de delta), sin uso en el
% esquema Sugeno, y calculaba las curvas de las membresias sobre universos
% discretizados (con phi y centros desplazados -180) solo para unas
% graficas que estaban comentadas; ese codigo muerto se elimino. Las
% formulas estan en las funciones locales membresiasX / membresiasPhi.

%% Bases de reglas Sugeno de orden cero
% BaseReg*(j,i): fila j = region de phi, columna i = region de X; el valor
% es el consecuente constante (angulo de timon en grados) de la regla.
%   BaseRegP90: rumbo deseado hacia +y (fact = +1)
%   BaseRegM90: rumbo deseado hacia -y (fact = -1), version espejada
% (El original definia ademas una base "BaseReg" con indices 1..7 estilo
% Mamdani que nunca se usaba en el calculo; se elimino en esta version.)

%           X:   1      2      3      4      5      6      7
BaseRegP90 = [ -30.0  -30.0  -30.0  -30.0   30.0   30.0   30.0     % phi: 1
                30.0   30.0   30.0  -30.0  -30.0  -30.0  -30.0     %      2
                30.0   30.0   30.0  -30.0  -30.0  -30.0  -30.0     %      3
                30.0   30.0   30.0    0.0  -30.0  -30.0  -30.0     %      4
                30.0   30.0   30.0   30.0  -30.0  -30.0  -30.0     %      5
                30.0   30.0   30.0   30.0  -30.0  -30.0  -30.0     %      6
               -30.0  -30.0  -30.0   30.0   30.0   30.0   30.0 ];  %      7

BaseRegM90 = [  30.0   30.0   30.0  -30.0  -30.0  -30.0  -30.0     % phi: 1
               -30.0  -30.0  -30.0  -30.0   30.0   30.0   30.0     %      2
               -30.0  -30.0  -30.0  -30.0   30.0   30.0   30.0     %      3
               -30.0  -30.0  -30.0    0.0   30.0   30.0   30.0     %      4
               -30.0  -30.0  -30.0   30.0   30.0   30.0   30.0     %      5
               -30.0  -30.0  -30.0   30.0   30.0   30.0   30.0     %      6
                30.0   30.0   30.0   30.0  -30.0  -30.0  -30.0 ];  %      7

% Parametros del controlador agrupados para las funciones locales.
% Los consecuentes se aplanan en orden columna, deltanf(k) con
% k = (i-1)*kP + j: el mismo orden en que deltaTimonRobot aplana los
% disparos fpxP (equivale al doble bucle del original).
nf.cX = cX;
nf.aX = aX;
nf.cP = cP;
nf.aP = aP;
nf.deltanfP90 = BaseRegP90(:);
nf.deltanfM90 = BaseRegM90(:);

%% Estado inicial y parametros de simulacion
x1 = x1ini;   y1 = y1ini;   P1 = P1ini;
x2 = x2ini;   y2 = y2ini;   P2 = P2ini;
x3 = x3ini;   y3 = y3ini;   P3 = P3ini;

r1n = 2*0.05;   % velocidad nominal (avance por paso) del robot 1
r2n = 2*0.05;   % velocidad nominal del robot 2
r3n = 2*0.05;   % velocidad nominal del robot 3
r1 = r1n;
r2 = r2n;
r3 = r3n;
L = 2.50;       % distancia entre ejes de los robots

ganancia1 = 3;  % ganancia del delta del lider
ganancia2 = 5;  % ganancia del delta de los seguidores (mas agresivos)
ganancia3 = 5;

% Rumbo deseado del lider llevado al rango (-180, 180) y su signo
if((P1deseado >= 180) && (P1deseado <= 270))
    P1deseado = P1deseado - 360;
end
fact1deseado = 1;
if(P1deseado < 0)
    fact1deseado = -1;
end
cosPdes1 = cos(P1deseado*pi/180);
sinPdes1 = sin(P1deseado*pi/180);

%% Lazo de simulacion
countmax = 2500;

% Historiales preallocados (el original los hacia crecer paso a paso)
xx1 = zeros(countmax,1);     % posiciones y rumbo del robot 1
yy1 = zeros(countmax,1);
PP1 = zeros(countmax,1);
dd1 = zeros(countmax,1);     % delta de timon del robot 1
xx2 = zeros(countmax,1);     % posiciones y rumbo del robot 2
yy2 = zeros(countmax,1);
PP2 = zeros(countmax,1);
dd2 = zeros(countmax,1);     % delta de timon del robot 2
xx3 = zeros(countmax,1);     % posiciones y rumbo del robot 3
yy3 = zeros(countmax,1);
PP3 = zeros(countmax,1);
dd3 = zeros(countmax,1);     % delta de timon del robot 3
P2des = zeros(countmax,1);   % rumbo deseado del robot 2
P3des = zeros(countmax,1);   % rumbo deseado del robot 3

for count = 1:countmax

    % --- Robot 1 (lider): delta para seguir la recta deseada -------------
    [DxG1, P1, x1deseado] = deltaTimonRobot(x1, y1, P1, b1, P1deseado, ...
        fact1deseado, cosPdes1, sinPdes1, ganancia1, nf);

    % --- Robot 2: rumbo deseado apuntando al robot 1 ---------------------
    [P2deseado, fact2deseado, cosPdes2, sinPdes2, b2, P2desReg] = ...
        rumboPersecucion(x1, y1, x2, y2);
    P2des(count) = P2desReg;

    [DxG2, P2] = deltaTimonRobot(x2, y2, P2, b2, P2deseado, ...
        fact2deseado, cosPdes2, sinPdes2, ganancia2, nf);

    % Velocidad del robot 2 segun la distancia al robot 1
    d12 = sqrt((x1-x2)^2+(y1-y2)^2);
    if(d12 > 5*L)
        r2 = 1.5*r2n;
    elseif((d12 > 3.5*L) && (d12 <= 5*L))
        r2 = r2n;
    elseif(d12 < 3.5*L)
        r2 = 0*r2n;   % detenido
    end

    % --- Robot 3: rumbo deseado apuntando al robot 2 ---------------------
    [P3deseado, fact3deseado, cosPdes3, sinPdes3, b3, P3desReg] = ...
        rumboPersecucion(x2, y2, x3, y3);
    P3des(count) = P3desReg;

    [DxG3, P3] = deltaTimonRobot(x3, y3, P3, b3, P3deseado, ...
        fact3deseado, cosPdes3, sinPdes3, ganancia3, nf);

    % Velocidad del robot 3 segun la distancia al robot 2
    d23 = sqrt((x2-x3)^2+(y2-y3)^2);
    if(d23 > 5*L)
        r3 = 1.5*r3n;
    elseif((d23 > 3.5*L) && (d23 <= 5*L))
        r3 = r3n;
    elseif(d12 < 3.5*L)   % OJO: el original compara d12 (no d23) en esta
        r3 = 0*r3n;       % rama; probable bug, se conserva tal cual para
    end                   % no alterar el resultado numerico

    % --- Historiales -----------------------------------------------------
    xx1(count) = x1;
    yy1(count) = y1;
    PP1(count) = P1;
    dd1(count) = DxG1;
    xx2(count) = x2;
    yy2(count) = y2;
    PP2(count) = P2;
    dd2(count) = DxG2;
    xx3(count) = x3;
    yy3(count) = y3;
    PP3(count) = P3;
    dd3(count) = DxG3;

    % --- Cinematica de los tres robots -----------------------------------
    [x1, y1, P1] = pasoCinematica(x1, y1, P1, r1, L, DxG1, PI);
    [x2, y2, P2] = pasoCinematica(x2, y2, P2, r2, L, DxG2, PI);
    [x3, y3, P3] = pasoCinematica(x3, y3, P3, r3, L, DxG3, PI);

    if (y3 > 100) || (y3 < -100)   % el ultimo robot salio del campo
        break;
    end
end

numPasos = count;
xx1 = xx1(1:numPasos);
yy1 = yy1(1:numPasos);
PP1 = PP1(1:numPasos);
dd1 = dd1(1:numPasos);
xx2 = xx2(1:numPasos);
yy2 = yy2(1:numPasos);
PP2 = PP2(1:numPasos);
dd2 = dd2(1:numPasos);
xx3 = xx3(1:numPasos);
yy3 = yy3(1:numPasos);
PP3 = PP3(1:numPasos);
dd3 = dd3(1:numPasos);
P2des = P2des(1:numPasos);
P3des = P3des(1:numPasos);

%% Animacion de las trayectorias
disp('  ');
disp('Animacion Start.   Presione una tecla');
pause;

L = 12;   % OJO: se reutiliza L como alto de los cajones dibujados (el
          % original tambien lo sobreescribia despues de la simulacion)
A = 6;    % ancho del robot y de cada cajon de estacionamiento
E = 3;    % separacion entre cajones

xdeseado = x1deseado;   % ultima proyeccion deseada del lider (ubica
                        % cajones y linea vertical)

figure(2);
hold on;
axis([ -50  50   0   100 ]);
xp = [ -50  50  50    -50   -50 ]';
yp = [ 0   0   100   100  0 ]';
zp = [ 0   xdeseado  xdeseado     0   0 ]';
wp = [ 0    0  200  200   0 ]';
plot(xp,yp,zp,wp,'k');   % campo de trabajo y linea vertical en xdeseado

% Cajones de estacionamiento decorativos en la fila superior (y entre
% 99-L y 99); cada cajon se dibuja con 4 contornos anidados (margenes 0 a
% 0.75) para simular borde grueso. En el original este bloque eran ~120
% lineas repetidas (xcm5..xc15).
bordes = [ 1 - (5:-1:1)*(A+E), ...   % 5 cajones "extras negativos"
           1 + (0:4)*(A+E), ...      % 5 cajones centrales
           3 + (6:15)*(A+E) ];       % 10 cajones "extras positivos"
for x0 = bordes + xdeseado - 50
    for margen = [0 0.25 0.5 0.75]
        plot([x0+margen, x0+A-margen, x0+A-margen, x0+margen, x0+margen], ...
             [99-L+margen, 99-L+margen, 99-margen, 99-margen, 99-L+margen], 'b');
    end
end

% Robots dibujados cada 10 pasos (largo L/2): robot 1 rojo, robot 2 azul,
% robot 3 verde; se repintan en blanco para simular movimiento
for count = 1:10:numPasos
    [xr1, yr1] = contornoRobot(xx1(count), yy1(count), (PI/180)*PP1(count), A, L/2);
    [xr2, yr2] = contornoRobot(xx2(count), yy2(count), (PI/180)*PP2(count), A, L/2);
    [xr3, yr3] = contornoRobot(xx3(count), yy3(count), (PI/180)*PP3(count), A, L/2);
    plot(xr1,yr1,'r',xr2,yr2,'b',xr3,yr3,'g','Linewidth',3);
    pause(1/10);
    plot(xr1,yr1,'w',xr2,yr2,'w',xr3,yr3,'w','Linewidth',3);
end

% Recta deseada del lider
hold on;
xxx1 = -200:1:200;   xxx1 = xxx1';
yyy1 = tan(P1deseado*pi/180)*xxx1 + b1;
plot(xxx1,yyy1);

figure(3)
plot(dd1);   title('Steering Angle 1');
figure(4)
plot(dd2);   title('Steering Angle 2');
figure(5)
plot(dd3);   title('Steering Angle 3');

%% Funciones locales

function [DxG, P, xdeseado] = deltaTimonRobot(x, y, P, b, Pdeseado, fact, ...
                                              cosPdes, sinPdes, ganancia, nf)
% Delta de timon de UN robot con inferencia Sugeno de orden cero.
% Reproduce, con las mismas formulas y el mismo orden de operaciones, el
% bloque que el script original repetia para cada robot.
% Devuelve tambien P porque, cuando fact = -1, el rumbo se renormaliza
% antes de fuzzificar (efecto lateral presente en el original).

% 1. Cambio de marco: proyeccion sobre la recta deseada (objetivo en 50)
xdeseado = cosPdes*(x*cosPdes + (y-b)*sinPdes);
xnuevo = x + 50 - xdeseado;

% Rumbo relativo a la recta deseada (objetivo en 90)
if(fact == 1)
    Pnuevo = P + fact*90 - Pdeseado;
elseif(fact == -1)
    if((P > 90) && (P <= 270))
        P = P - 360;   % renormaliza el rumbo para el caso "hacia abajo"
    end
    Pnuevo = P + fact*90 - Pdeseado;
end

% 2. Fuzzificacion
fpx = membresiasX(xnuevo, nf.cX, nf.aX);
fpp = membresiasPhi(Pnuevo, nf.cP, nf.aP, fact);

% 3. Disparo de las 49 reglas: producto de pertenencias, aplanado en orden
% columna (i externo sobre X, j interno sobre phi), el mismo orden con que
% se aplanaron las bases de reglas
kX = numel(fpx);
kP = numel(fpp);
fpxP = zeros(kX*kP,1);
k = 1;
for i = 1:kX
    for j = 1:kP
        fpxP(k,1) = fpx(i,1) * fpp(j,1);
        k = k + 1;
    end
end

% 4. Promedio ponderado de los consecuentes constantes
sumfpxP = sum(fpxP);
fpxP = fpxP./sumfpxP;
if(fact == 1)
    deltanf = nf.deltanfP90;
elseif(fact == -1)
    deltanf = nf.deltanfM90;
end
DxG = deltanf'*fpxP;
DxG = ganancia*DxG;

% Saturacion del timon
if( DxG > 45 )
    DxG = 45;
end
if( DxG < -45 )
    DxG = -45;
end
end

function fpx = membresiasX(t, cX, aX)
% Grados de pertenencia de las 7 regiones de X evaluados en t (escalar).
% Region 1: sigmoide decreciente; regiones 2 a 6: gaussianas; region 7:
% sigmoide creciente. Mismas formulas y constantes del original.
kX = numel(cX);
fpx = zeros(kX,1);
fpx(1,1) = 1.0./(1+exp((t-cX(1))./aX(1)));
for i = 2:kX-1
    fpx(i,1) = exp(-((t-cX(i))./aX(i)).^2);
end
fpx(kX,1) = 1.0./(1+exp(-(t-cX(kX))./aX(kX)));
end

function fpp = membresiasPhi(t, cP, aP, fact)
% Grados de pertenencia de las 7 regiones de phi (todas gaussianas)
% evaluados en t (escalar). Con fact = -1 los centros se desplazan -180
% para cubrir los rumbos deseados que apuntan hacia -y.
kP = numel(cP);
fpp = zeros(kP,1);
for j = 1:kP
    cpj = cP(j) - (1-fact)/2*180;
    fpp(j,1) = exp(-((t-cpj)./aP(j)).^2);
end
end

function [Pdeseado, fact, cosPdes, sinPdes, b, PdesReg] = rumboPersecucion(xl, yl, xs, ys)
% Rumbo deseado del seguidor en (xs, ys): apuntar a su guia en (xl, yl).
% Devuelve el rumbo normalizado a (-180, 180), su signo fact, coseno y
% seno, y la ordenada b de la recta seguidor-guia. PdesReg es el rumbo
% antes de la segunda normalizacion (es el valor que guarda el historial).
Pdeseado = atan2(yl-ys, xl-xs)*180/pi;
if((Pdeseado <= -90) && (Pdeseado >= -180))
    Pdeseado = Pdeseado + 360;
end
PdesReg = Pdeseado;

b = yl - (ys-yl)/(xs-xl)*xl;   % ordenada en el origen de la recta

if((Pdeseado >= 180) && (Pdeseado <= 270))
    Pdeseado = Pdeseado - 360;
end
fact = 1;
if(Pdeseado < 0)
    fact = -1;
end
cosPdes = cos(Pdeseado*pi/180);
sinPdes = sin(Pdeseado*pi/180);
end

function [x, y, P] = pasoCinematica(x, y, P, r, L, DxG, PI)
% Avanza un paso la cinematica tipo carro con avance r, distancia entre
% ejes L y angulo de timon DxG; renormaliza P al rango (-90, 270].
% Nota: el original usa pi de MATLAB para el giro y la constante
% PI = 3.141592 para el avance x-y; se conserva tal cual.
P = P - r/L*tan(DxG*pi/180) * 180/pi;
if( P > 270 )
    P = P - 360;
end
if( P < -90 )
    P = P + 360;
end
x = x + r * cos( (PI/180)*P);
y = y + r * sin( (PI/180)*P);
end

function [xc, yc] = contornoRobot(xz, yz, Pz, A, largo)
% Contorno rectangular (ancho A, largo "largo") del robot con eje
% delantero en (xz, yz) y rumbo Pz en radianes. Solo para el dibujo.
x1 = xz + (A/2)*sin(Pz);   y1 = yz - (A/2)*cos(Pz);   % esquinas delanteras
x2 = xz - (A/2)*sin(Pz);   y2 = yz + (A/2)*cos(Pz);
xF = xz - largo*cos(Pz);   yF = yz - largo*sin(Pz);   % punto trasero
x3 = xF - (A/2)*sin(Pz);   y3 = yF + (A/2)*cos(Pz);   % esquinas traseras
x4 = xF + (A/2)*sin(Pz);   y4 = yF - (A/2)*cos(Pz);
xc = [ x1  x2  x3  x4  x1 ]';
yc = [ y1  y2  y3  y4  y1 ]';
end
