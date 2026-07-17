% NeuroDifusoEvasionDosObstaculos (original: neurofuzzyObstacle2.m)
% =========================================================================
% Control neuro-difuso tipo Sugeno de orden cero (mismo nucleo que
% NeuroDifusoCarroPosicion.m) de un robot movil tipo carro que evade DOS
% obstaculos rectangulares siguiendo un camino de referencia por tramos
% (poligonal de 6 waypoints, 5 tramos mas un tramo final vertical).
%
% A diferencia del Mamdani de ControlDifusoCarroPosicionX.m (inferencia
% min, agregacion max y defuzzificacion por centro de gravedad), aqui el
% consecuente de cada regla es una constante numerica y la salida es un
% promedio ponderado normalizado.
%
% Pipeline en cada paso de simulacion:
%   0. REFERENCIA      el tramo activo del camino define xdeseado (por
%                      proyeccion de la posicion actual) y Pdeseado
%   1. FUZZIFICACION   grados de pertenencia de x y phi; campanas
%                      gaussianas exp(-((x-c)/a).^2) en el interior del
%                      universo y sigmoides 1/(1+exp(+/-(x-c)/a)) como
%                      hombros saturados en los bordes de x
%   2. PESO DE REGLAS  cada regla (i,j) se activa con el PRODUCTO
%                      w = muX(i)*muPhi(j)   (AND difuso)
%   3. CONSECUENTES    delta numerico constante por regla (deltanf)
%   4. SALIDA          promedio ponderado DxG = deltanf'*(w/sum(w)),
%                      luego ganancia 5 y saturacion a +/-30 grados
%   5. CINEMATICA      actualizacion de la pose (x, y, phi) del carro
%
% El universo de X esta desplazado de modo que el objetivo instantaneo
% queda en 50 (xnuevo = x + 50 - xdeseado) y el de phi de modo que el
% rumbo deseado queda en 90 (Pnuevo = P + 90 - Pdeseado).

%% Condiciones iniciales y objetivo
clear;
close all;
clc;

PI = 3.141592;   % aproximacion de pi del script original; se conserva
                 % para reproducir exactamente los resultados

disp('Obstacle 1:   X:25-75 ... Y:30-35');
disp('Obstacle 2:   X:25-75 ... Y:60-65');
xini = input('Input intial coordinate  x [10 to 90]: ');
yini = input('Input initial coordinate y [10 to 60]: ');
Pini = input('Input initial inclination angle fi [-90 to 270]: ');
xdeseado = input('Input desired coordinate x [20 - 80]: ');
% (el xdeseado ingresado es sobrescrito en cada paso por el generador de
% camino; el tramo final siempre apunta a x = 50)

%% Particiones de las variables linguisticas
% Cada fila es [centro c, ancho a]. Para X la particion 1 es una sigmoide
% descendente y la 7 una sigmoide ascendente (hombros saturados); las
% intermedias son campanas gaussianas. Para phi las 7 son gaussianas.
% (El original ademas evaluaba las curvas sobre universos densos
% x = -50:0.01:150 y phi = -95:0.01:275 solo para graficarlas; ese
% trazado estaba comentado y aqui se omite.)

kX = 7;      % particiones de x
kP = 7;      % particiones de phi
kD = 7;      % particiones de delta (consecuentes)

%          c      a       forma                 zona (objetivo en 50)
Xmem = [ 13.5    1.5      % sigmoide descend.   muy a la izquierda
         23.5    7.0      % gaussiana           izquierda
         39.0    6.0      % gaussiana           izquierda, cerca
         50.0    2.0      % gaussiana           centro (objetivo)
         61.0    6.0      % gaussiana           derecha, cerca
         76.5    7.0      % gaussiana           derecha
         86.5    1.5 ];   % sigmoide ascend.    muy a la derecha

%           c      a      forma                 zona (objetivo en 90)
Pmem = [ -45.0   25.0     % gaussiana           tumbado a la derecha
          21.5   15.0     % gaussiana           inclinado a la derecha
          65.0   12.0     % gaussiana           derecha, casi vertical
          90.0    3.0     % gaussiana           vertical (objetivo)
         115.0   12.0     % gaussiana           izquierda, casi vertical
         158.5   15.0     % gaussiana           inclinado a la izquierda
         225.0   25.0 ];  % gaussiana           tumbado a la izquierda

%% Base de reglas y consecuentes (Sugeno de orden cero)
% BaseReg(j,i): fila j = particion de phi, columna i = particion de X.
% El valor es el delta (en grados) del consecuente de la regla.
% El original definia primero una version por indices de particion
% (1 = NB ... 7 = PB), sustituida de inmediato por la numerica activa:
%   BaseReg = [ 1  1  1  1  7  7  7
%               5  5  5  1  1  1  1
%               6  6  5  2  1  1  1
%               7  7  7  4  1  1  1
%               7  7  7  6  3  2  2
%               7  7  7  7  3  3  3
%               1  1  1  7  7  7  7 ];

BaseReg = [ -30.0   -30.0   -30.0   -30.0    30.0    30.0    30.0
              5.5     5.5     5.5   -30.0   -30.0   -30.0   -30.0
             14.0    14.0     5.5   -14.0   -30.0   -30.0   -30.0
             30.0    30.0    30.0     0.0   -30.0   -30.0   -30.0
             30.0    30.0    30.0    14.0    -5.5   -14.0   -14.0
             30.0    30.0    30.0    30.0    -5.5    -5.5    -5.5
            -30.0   -30.0   -30.0    30.0    30.0    30.0    30.0 ];

% Consecuentes como vector columna: el indice k = (i-1)*kP + j recorre
% BaseReg columna por columna (j de phi varia mas rapido), en el mismo
% orden en que se calculan los pesos fpxP dentro del lazo.
deltanf = zeros(kX*kP,1);
k = 1;
for i = 1:kX
    for j = 1:kP
        deltanf(k,1) = BaseReg(j,i);
        k = k + 1;
    end
end

%% Camino por tramos para evadir los dos obstaculos
% Obstaculo 1: franja X:25-75, Y:30-35. Obstaculo 2: X:25-75, Y:60-65.
% El camino de referencia es una poligonal de 6 vertices que zigzaguea
% por el costado de ambos y termina en un tramo vertical hacia x = 50:
%
%   entrada por la derecha (xini >= 50):    entrada por la izquierda:
%     W1 = (80, 0)   inicio                   vertices reflejados
%     W2 = (70,12)   se acerca al borde       respecto de x = 50:
%     W3 = (88,35)   esquiva el obstaculo 1   xk' = 2*50 - xk
%     W4 = (75,48)   retorna entre obstaculos
%     W5 = (85,70)   esquiva el obstaculo 2
%     W6 = (75,75)   retorna tras el obstaculo 2
%     y >= 75: tramo final vertical hacia (50, arriba)
%
% Cada tramo k tiene inclinacion alfk = atan(pendiente), mas pi cuando el
% tramo "regresa" en x. La conversion a grados y de vuelta a radianes del
% original se conserva por exactitud bit a bit. En cada paso se proyecta
% la posicion actual sobre el tramo activo (segun la banda de y) para
% obtener xdeseado, y Pdeseado = alfk en grados.

if( xini < 50 )
    x1 = 2*50 - 80;   y1 = 0;    % vertices reflejados respecto de x = 50
    x2 = 2*50 - 70;   y2 = 12;
    x3 = 2*50 - 88;   y3 = 35;
    x4 = 2*50 - 75;   y4 = 48;
    x5 = 2*50 - 85;   y5 = 70;
    x6 = 2*50 - 75;   y6 = 75;
    alf1 = 180/pi*atan((y2-y1)/(x2-x1));        % tramo 1
    alf1 = alf1*pi/180;
    alf2 = 180/pi*(pi+atan((y3-y2)/(x3-x2)));   % tramo 2 (regresa en x)
    alf2 = alf2*pi/180;
    alf3 = 180/pi*atan((y4-y3)/(x4-x3));        % tramo 3
    alf3 = alf3*pi/180;
    alf4 = 180/pi*(pi+atan((y5-y4)/(x5-x4)));   % tramo 4 (regresa en x)
    alf4 = alf4*pi/180;
    alf5 = 180/pi*atan((y6-y5)/(x6-x5));        % tramo 5
    alf5 = alf5*pi/180;
elseif( xini >= 50 )
    x1 = 80;   y1 = 0;
    x2 = 70;   y2 = 12;
    x3 = 88;   y3 = 35;
    x4 = 75;   y4 = 48;
    x5 = 85;   y5 = 70;
    x6 = 75;   y6 = 75;
    alf1 = 180/pi*(pi+atan((y2-y1)/(x2-x1)));   % tramo 1 (regresa en x)
    alf1 = alf1*pi/180;
    alf2 = 180/pi*atan((y3-y2)/(x3-x2));        % tramo 2
    alf2 = alf2*pi/180;
    alf3 = 180/pi*(pi+atan((y4-y3)/(x4-x3)));   % tramo 3 (regresa en x)
    alf3 = alf3*pi/180;
    alf4 = 180/pi*atan((y5-y4)/(x5-x4));        % tramo 4
    alf4 = alf4*pi/180;
    alf5 = 180/pi*(pi+atan((y6-y5)/(x6-x5)));   % tramo 5 (regresa en x)
    alf5 = alf5*pi/180;
end

%% Simulacion del lazo de control
r = 0.1;        % avance del carro por paso
L = 2.5;        % distancia entre ejes del carro
R = 50;         % radio de giro de un timon de referencia alternativo
deltades = 0;   % pre-alimentacion del timon; el original calculaba
                % 180/pi*atan(L/R) y de inmediato la dejaba en cero

x = xini;
y = yini;
P = Pini;
Pdeseado = 90;

countmax = 1500;
xx = zeros(countmax,1);   % historiales preallocados
yy = zeros(countmax,1);
PP = zeros(countmax,1);
dd = zeros(countmax,1);
fpxP = zeros(kX*kP,1);    % pesos de las 49 reglas

for count = 1:countmax

    % --- 0. Referencia del tramo activo (segun la banda de y) ------------
    if( xini < 50 )
        if( (y >= y1) && (y < y2) )
            xdeseado = xRefPendiente(x, y, x1, y1, alf1);
            Pdeseado = 180/pi*alf1;
        elseif( (y >= y2) && (y < y3) )
            xdeseado = xRefCotangente(x, y, x2, y2, alf2);
            Pdeseado = 180/pi*alf2;
        elseif( (y >= y3) && (y < y4) )
            xdeseado = xRefPendiente(x, y, x3, y3, alf3);
            Pdeseado = 180/pi*alf3;
        elseif( (y >= y4) && (y < y5) )
            xdeseado = xRefCotangente(x, y, x4, y4, alf4);
            Pdeseado = 180/pi*alf4;
        elseif( (y >= y5) && (y < y6) )
            xdeseado = xRefPendiente(x, y, x5, y5, alf5);
            Pdeseado = 180/pi*alf5;
        elseif( y >= y6 )
            xdeseado = 50;    % tramo final: vertical hacia x = 50
            Pdeseado = 90;
        end
    elseif( xini >= 50 )
        if( (y >= y1) && (y < y2) )
            xdeseado = xRefCotangente(x, y, x1, y1, alf1);
            Pdeseado = 180/pi*alf1;
        elseif( (y >= y2) && (y < y3) )
            xdeseado = xRefPendiente(x, y, x2, y2, alf2);
            Pdeseado = 180/pi*alf2;
        elseif( (y >= y3) && (y < y4) )
            xdeseado = xRefCotangente(x, y, x3, y3, alf3);
            Pdeseado = 180/pi*alf3;
        elseif( (y >= y4) && (y < y5) )
            xdeseado = xRefPendiente(x, y, x4, y4, alf4);
            Pdeseado = 180/pi*alf4;
        elseif( (y >= y5) && (y < y6) )
            xdeseado = xRefCotangente(x, y, x5, y5, alf5);
            Pdeseado = 180/pi*alf5;
        elseif( y >= y6 )
            xdeseado = 50;    % tramo final: vertical hacia x = 50
            Pdeseado = 90;
        end
    end

    % --- 1. Fuzzificacion (marco desplazado: objetivos en 50 y 90) -------
    xnuevo = x + 50 - xdeseado;
    Pnuevo = P + 90 - Pdeseado;
    fpx = gradosPertenenciaX(xnuevo, Xmem);
    fpp = gradosPertenenciaPhi(Pnuevo, Pmem);

    % --- 2. Peso de cada regla: producto de las membresias ---------------
    k = 1;
    for i = 1:kX
        for j = 1:kP
            fpxP(k,1) = fpx(i,1) * fpp(j,1);
            k = k + 1;
        end
    end

    % --- 3-4. Promedio ponderado de los consecuentes ---------------------
    sumfpxP = sum(fpxP);
    fpxP = fpxP./sumfpxP;      % normalizacion de los pesos
    DxG = deltanf'*fpxP;       % salida Sugeno de orden cero
    DxG = 5*DxG;               % ganancia del controlador
    if( DxG > 30 )
        DxG = 30;
    end
    if( DxG < -30 )
        DxG = -30;
    end
    DxG = DxG + deltades;

    xx(count,1) = x;
    yy(count,1) = y;
    PP(count,1) = P;
    dd(count,1) = DxG;

    % --- 5. Cinematica del carro -----------------------------------------
    P = P - r/L*tan(DxG*pi/180) * 180/pi;
    if( P > 270 )
        P = P - 360;
    end
    if( P < -90 )
        P = P + 360;
    end
    x = x + r * cos( (PI/180)*P);
    y = y + r * sin( (PI/180)*P);

    if ( x > 100)   % salio del campo de trabajo por la derecha
        break;
    end

end

numPasos = count;
xx = xx(1:numPasos);
yy = yy(1:numPasos);
PP = PP(1:numPasos);
dd = dd(1:numPasos);

%% Animacion de la trayectoria
disp('  ');
disp('Animation Start.   Press ENTER');
pause;

L = 12;   % largo del carro para el dibujo (el original reusa la variable)
A = 6;    % ancho del carro
E = 3;    % separacion entre cajones (no usada en este script)

figure(2);
hold on;

% Fila superior de "estacionamiento": dos franjas grises con hueco de
% entrada en x = 45..55
xxfondo1 = [ -10  45  45 -10 ];
yyfondo1 = [ 104 104 110 110 ];
fill(xxfondo1,yyfondo1,[0.8 0.8 0.8]);
xxfondo2 = [ 55  110  110  55 ];
yyfondo2 = [ 104 104  110 110 ];
fill(xxfondo2,yyfondo2,[0.8 0.8 0.8]);

% Obstaculos rectangulares
obsminx1 = 25;   obsmaxx1 = 75;   obsminy1 = 30;   obsmaxy1 = 35;
xxobs1 = [ obsminx1 obsmaxx1 obsmaxx1 obsminx1 ]';
yyobs1 = [ obsminy1 obsminy1 obsmaxy1 obsmaxy1 ]';
fill(xxobs1,yyobs1,[0.8 0.8 0.8]);
obsminx2 = 25;   obsmaxx2 = 75;   obsminy2 = 60;   obsmaxy2 = 65;
xxobs2 = [ obsminx2 obsmaxx2 obsmaxx2 obsminx2 ]';
yyobs2 = [ obsminy2 obsminy2 obsmaxy2 obsmaxy2 ]';
fill(xxobs2,yyobs2,[0.8 0.8 0.8]);

axis([ -10 110 -10 110 ]);
xp = [ -10  110  110  -10  -10 ]';   % contorno del campo de trabajo
yp = [ -10  -10  110  110  -10 ]';
plot(xp,yp,'-k');

% Carro dibujado como rectangulo (ancho A, largo L/2) cada 8 pasos
for count = 1:8:numPasos
    xz = xx(count,1);
    yz = yy(count,1);
    Pz = (PI/180) * PP(count,1);
    x1 = xz + (A/2)*sin(Pz);   y1 = yz - (A/2)*cos(Pz);   % esquinas delanteras
    x2 = xz - (A/2)*sin(Pz);   y2 = yz + (A/2)*cos(Pz);
    xF = xz - (L/2)*cos(Pz);   yF = yz - (L/2)*sin(Pz);   % punto trasero
    x3 = xF - (A/2)*sin(Pz);   y3 = yF + (A/2)*cos(Pz);   % esquinas traseras
    x4 = xF + (A/2)*sin(Pz);   y4 = yF - (A/2)*cos(Pz);
    plot([ x1  x2  x3  x4  x1 ]', [ y1  y2  y3  y4  y1 ]', 'r');
    pause(1/50);
end

figure(3)
plot(dd);
title('Steering angle delta');

%% Funciones locales
function fp = gradosPertenenciaX(xv, Xmem)
% Grados de pertenencia de la posicion (en el marco desplazado) en las 7
% particiones de X. Formulas identicas a las del script original:
%   hombro izquierdo   1/(1+exp((x-c)/a))     (sigmoide descendente)
%   interior           exp(-((x-c)/a).^2)     (campana gaussiana)
%   hombro derecho     1/(1+exp(-(x-c)/a))    (sigmoide ascendente)
fp = zeros(7,1);
fp(1,1) = 1.0./(1+exp((xv-Xmem(1,1))./Xmem(1,2)));
for i = 2:6
    fp(i,1) = exp(-((xv-Xmem(i,1))./Xmem(i,2)).^2);
end
fp(7,1) = 1.0./(1+exp(-(xv-Xmem(7,1))./Xmem(7,2)));
end

function fp = gradosPertenenciaPhi(Pv, Pmem)
% Grados de pertenencia de la inclinacion (en el marco desplazado) en las
% 7 particiones de phi, todas campanas gaussianas exp(-((phi-c)/a).^2).
fp = zeros(7,1);
for j = 1:7
    fp(j,1) = exp(-((Pv-Pmem(j,1))./Pmem(j,2)).^2);
end
end

function xd = xRefPendiente(x, y, xi, yi, alfa)
% Proyeccion de la posicion (x,y) sobre el tramo que pasa por (xi,yi) con
% inclinacion alfa, escrita con la pendiente tan(alfa). Formula identica
% a la del original (tramos con pendiente moderada).
xd = (x + xi*tan(alfa)*tan(alfa) + (y-yi)*tan(alfa)) / (1 + tan(alfa)*tan(alfa));
end

function xd = xRefCotangente(x, y, xi, yi, alfa)
% Igual que xRefPendiente pero reescrita con cotangentes (tan(alfa-pi/2)
% y tan(pi-alfa)), como usa el original en los tramos casi verticales o
% recorridos "de regreso" en x.
xd = (yi - y + x*tan(alfa-pi/2) + xi*tan(pi-alfa))/(tan(alfa-pi/2) + tan(pi-alfa));
end
