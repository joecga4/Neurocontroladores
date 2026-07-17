% NeuroDifusoEvasionMapaObstaculos (original: neurofuzzyObstacle3.m)
% =========================================================================
% Control neuro-difuso tipo Sugeno de orden cero (mismo nucleo que
% NeuroDifusoCarroPosicion.m) de un robot movil tipo carro que cruza un
% mapa complejo de obstaculos siguiendo un camino de referencia por
% tramos, y graba la animacion en el video RobotPlantObstacleX.mp4.
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
%                      luego ganancia 4 y saturacion a +/-30 grados
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

xini = input('Input initial coordinate x [0 to 100]: ');
yini = -5;       % el carro siempre parte de y = -5 ...
Pini = 90;       % ... apuntando hacia arriba
xfin = input('Input final coordinate x [0 to 100 ]:  ');

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

%% Camino por tramos a traves del mapa
% El carro parte de (xini, -5) apuntando hacia arriba y sigue una
% poligonal que cruza el mapa por el corredor libre:
%
%   W1 = (105,-5) si xini >= 50, o (-5,-5) si xini < 50   (entrada)
%   W2 = (55,-1)   punto de reunion de ambas entradas
%   W3 = (40,80)   diagonal larga por el corredor central del mapa
%   W4 = (38,95)   tramo corto superior (cuidado con cambiarlo, ya que
%                  define el ultimo tramo)
%
% Tramo final horizontal en y >= 95 hacia xfin: alf4 = pi si xfin <= 38
% (avanza hacia la izquierda) o alf4 = 0 si xfin > 38 (hacia la
% derecha); al alcanzar xfin se conmuta Pdeseado = 90 para terminar
% apuntando hacia arriba.
%
% Cada tramo k tiene inclinacion alfk = atan(pendiente), mas pi cuando el
% tramo "regresa" en x. La conversion a grados y de vuelta a radianes del
% original se conserva por exactitud bit a bit. En cada paso se proyecta
% la posicion actual sobre el tramo activo (segun la banda de y) para
% obtener xdeseado, y Pdeseado = alfk en grados.

if( xini >= 50 )
    xw1 = 105;   yw1 = -5;
    xw2 = 55;    yw2 = -1;
    alf1 = 180/pi*(pi+atan((yw2-yw1)/(xw2-xw1)));   % tramo 1 (regresa en x)
    alf1 = alf1*pi/180;
elseif( xini < 50 )
    xw1 = -5;    yw1 = -5;
    xw2 = 55;    yw2 = -1;
    alf1 = 180/pi*atan((yw2-yw1)/(xw2-xw1));        % tramo 1
    alf1 = alf1*pi/180;
end
xw3 = 40;   yw3 = 80;
xw4 = 38;   yw4 = 95;
alf2 = 180/pi*(pi+atan((yw3-yw2)/(xw3-xw2)));       % tramo 2 (regresa en x)
alf2 = alf2*pi/180;
alf3 = 180/pi*(pi+atan((yw4-yw3)/(xw4-xw3)));       % tramo 3 (regresa en x)
alf3 = alf3*pi/180;
if( xfin <= xw4 )
    alf4 = pi;   % tramo final hacia la izquierda
elseif( xfin > xw4 )
    alf4 = 0;    % tramo final hacia la derecha
end

%% Simulacion del lazo de control
r = 0.2;        % avance del carro por paso
L = 2.5;        % distancia entre ejes del carro
R = 50;         % radio de giro de un timon de referencia alternativo
deltades = 0;   % pre-alimentacion del timon; el original calculaba
                % 180/pi*atan(L/R) y de inmediato la dejaba en cero

x = xini;
y = yini;
P = Pini;
Pdeseado = 90;

countmax = 2000;
xx = zeros(countmax,1);   % historiales preallocados
yy = zeros(countmax,1);
PP = zeros(countmax,1);
dd = zeros(countmax,1);
fpxP = zeros(kX*kP,1);    % pesos de las 49 reglas

for count = 1:countmax

    % --- 0. Referencia del tramo activo (segun la banda de y) ------------
    % Solo el tramo 1 distingue el lado de entrada; los demas son comunes.
    if( (y >= yw1) && (y < yw2) )
        if( xini >= 50 )
            xdeseado = xRefCotangente(x, y, xw1, yw1, alf1);
        else
            xdeseado = xRefPendiente(x, y, xw1, yw1, alf1);
        end
        Pdeseado = 180/pi*alf1;
    elseif( (y >= yw2) && (y < yw3) )
        xdeseado = xRefCotangente(x, y, xw2, yw2, alf2);
        Pdeseado = 180/pi*alf2;
    elseif( (y >= yw3) && (y < yw4) )
        xdeseado = xRefCotangente(x, y, xw3, yw3, alf3);
        Pdeseado = 180/pi*alf3;
    elseif( y >= yw4 )
        xdeseado = xRefCotangente(x, y, xw4, yw4, alf4);
        Pdeseado = 180/pi*alf4;
        if( (x >= xfin) && (xw4 <= xfin) )   % llego a xfin por la derecha
            Pdeseado = 90;
        end
        if( (x <= xfin) && (xw4 >= xfin) )   % llego a xfin por la izquierda
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
    DxG = 4*DxG;               % ganancia del controlador
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
    % (a diferencia de los otros scripts de la familia, aqui el original
    % NO normaliza P al rango (-90, 270]: ese ajuste estaba comentado)
    P = P - r/L*tan(DxG*pi/180) * 180/pi;
    x = x + r * cos( (PI/180)*P);
    y = y + r * sin( (PI/180)*P);

    if ( y > 110 )   % salio del campo de trabajo por arriba
        break;
    end

end

numPasos = count;
xx = xx(1:numPasos);
yy = yy(1:numPasos);
PP = PP(1:numPasos);
dd = dd(1:numPasos);

%% Mapa de obstaculos (figura 2)
disp('  ');
disp('Animation Start.   Press ENTER');
pause;

L = 12;   % largo del carro para el dibujo (el original reusa la variable)
A = 6;    % ancho del carro
E = 3;    % separacion entre cajones (no usada en este script)

figure(2);
hold on;

% Los obstaculos fueron digitalizados en coordenadas "de imagen" (pix) y
% se llevan al plano de trabajo con la transformacion lineal
%   u = ax*px + bx,   v = ay*py + by
ax = 6/95;    bx = -178/19 + 5;
ay = 2/32;    by = -2 + 12;
d  = 100;     % desplazamiento vertical aplicado a algunos poligonos

% Obstaculos rectangulares [px py ancho alto] (en pixeles digitalizados);
% se dibujan en el orden del original
rectsPix = [ 1100      0    600   100
             1260    135    160   115
             1480    125    140    85
             1480    220    180   100 ];
for k = 1:size(rectsPix,1)
    rectangle('Position',[rectsPix(k,1)*ax+bx, rectsPix(k,2)*ay+by, ...
                          rectsPix(k,3)*ax,    rectsPix(k,4)*ay], ...
              'Facecolor',[0.8 0.8 0.8]);
end
hold on;

% Obstaculos poligonales de 4 vertices (en pixeles digitalizados), en el
% orden de dibujo del original. El original usaba patch() en el poligono
% 11 de esta lista (y en el ultimo, mas abajo) y fill() en el resto;
% ambos producen el mismo parche gris con borde, asi que aqui se usa
% fill() para todos.
polysPixX = [ 1350  1480  1460  1330
              1485  1665  1640  1460
              1265  1390  1550  1425
              1065  1190  1270  1145
               935  1115  1065   885
              1090  1220  1205  1075
               535   715   690   510
               505   655   630   485
               800   930  1010   885
               895  1020  1100   975
               375   620   640   530
                25   270   355   125 ];
polysPixY = [  385        420        540        510
               390        430        580        540
               732        620        816        928
               932        820        918       1030
               390        430        730        690
               320        355        445        412
               430+d      470+d      630+d      590+d
               615+d      650+d      785+d      750+d
              1080        975       1085       1195
              1212       1100       1198       1310
              -120+d+50  -120+d+50   200+d+50   210+d+50
               -60+d     -120+d      270+d      330+d ];
for k = 1:size(polysPixX,1)
    fill(polysPixX(k,:)'*ax+bx, polysPixY(k,:)'*ay+by, [0.8 0.8 0.8]);
end

% Ultimo rectangulo y ultimo poligono (patch en el original)
rectangle('Position',[200*ax+bx, (800+d+50)*ay+by, 400*ax, 150*ay], ...
          'Facecolor',[0.8 0.8 0.8]);
fill([ 90 310 270 10 ]'*ax+bx, [ 680+d 680+d 310+d 370+d ]'*ay+by, ...
     [0.8 0.8 0.8]);

% Contorno del campo de trabajo
xbox = [ -10  110  110  -10  -10 ]';
ybox = [ -10  -10  110  110  -10 ]';
plot(xbox,ybox,'-k');

grid;
axis([ -10 110 -10 110]);

%% Animacion de la trayectoria y grabacion del video
writerObj = VideoWriter('RobotPlantObstacleX.mp4','MPEG-4');
writerObj.FrameRate = 15;
open(writerObj);

% Carro dibujado como rectangulo (ancho A, largo L/2) cada 6 pasos;
% cada cuadro dibujado se agrega al video
for count = 1:6:numPasos
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
    frame = getframe(gcf);
    writeVideo(writerObj,frame);
end
close(writerObj);

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
