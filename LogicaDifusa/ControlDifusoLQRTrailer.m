% ControlDifusoLQRTrailer (original: fuzzytrailerLQ.m)
% =========================================================================
% Control hibrido difuso-LQR, tipo Takagi-Sugeno, de un camion con
% remolque (truck-trailer). El camion empuja al remolque marcha atras
% para estacionarlo en la ranura entre dos obstaculos (centrada en
% y = yast, avanzando hacia x = 80). Al final genera el video
% trailer4.avi con la animacion de la maniobra.
%
% Pose del robot: (x, y) extremo delantero del remolque, fi2 orientacion
% del remolque, fi1 orientacion del camion, fi12 = fi1 - fi2 angulo de
% articulacion. Para el control solo se usa el vector [ y  fi2  fi12 ].
%
% Controlador central (LQR):
%   El modelo no lineal se linealiza alrededor de la posicion final
%   deseada (y = 0, fi2 = 0, fi12 = 0, aproximando sin(fi12) ~ fi12):
%       d/dt [ y; fi2; fi12 ] = A*[ y; fi2; fi12 ] + B*u,   u = tan(delta)
%   y la ganancia de la ley lineal u = -K*x se obtiene resolviendo la
%   ecuacion algebraica de Riccati (funcion are).
%
% Esquema difuso (tipo Sugeno, NO Mamdani):
%   Para que fi12 no crezca hacia la posicion de navaja ("jack-knife"),
%   se definen 3 membresias triangulares sobre fi12 en (-90, 90) grados
%   y se pondera entre tres controladores:
%       SI fi12 es NEGATIVO  ->  u = -tanmax   (timon a tope)
%       SI fi12 es CERO      ->  u = ley LQR
%       SI fi12 es POSITIVO  ->  u = +tanmax
%   (mirando la ecuacion de fi12_punto se deducen los controladores de
%   las particiones extremas). La salida es el promedio ponderado de
%   consecuentes nitidos (crisp): a diferencia del esquema Mamdani de
%   ControlDifusoCarroPosicionX.m, aqui no hay recorte ni agregacion de
%   conjuntos de salida ni defuzzificacion por centro de gravedad.

%% Funciones de membresia de fi12
clear; close all; clc;

% El universo (-90, 90) grados se discretiza en np puntos; las membresias
% se tabulan en fdp1/fdp2/fdp3 y en el lazo se consultan por indice.
np  = 2000;          % puntos de muestreo entre -90 y +90 (probar otros)
np1 = round(np/20);  % fin de la meseta de fdp1 / inicio de su rampa
np2 = np/2;          % centro del universo (fi12 = 0)
np3 = np - np1;      % inicio de la meseta de fdp3 (simetrico a np1)
% Alternativas para np1 probadas en el original:
%   round(np/4), round(np/3), 1, round(2*np/15)

np12 = ((np1+1):np2)';   % indices del tramo izquierda -> centro
np23 = ((np2+1):np3)';   % indices del tramo centro -> derecha

% fdp1: fi12 NEGATIVO (meseta en 1 hasta np1, baja a 0 en el centro)
% fdp2: fi12 CERO     (triangulo con vertice en el centro np2)
% fdp3: fi12 POSITIVO (sube desde el centro, meseta en 1 desde np3)
fdp1 = [ ones(np1,1);  rampa(np12,np2,np1); zeros(np-np2,1) ];
fdp2 = [ zeros(np1,1); rampa(np12,np1,np2); rampa(np23,np3,np2); zeros(np-np3,1) ];
fdp3 = [ zeros(np2,1); rampa(np23,np2,np3); ones(np-np3,1) ];

fi12fuz = ((1:np)'-1)/(np-1)*180 - 90;   % universo de fi12 en grados

figure(1); hold on;
plot(fi12fuz, fdp1, 'Linewidth', 1.25);
plot(fi12fuz, fdp2, 'Linewidth', 1.25);
plot(fi12fuz, fdp3, 'Linewidth', 1.25);
title('Funciones de membresia de fi12');
axis([-90 90 0 1.4]);

%% Parametros del robot y de la simulacion
v  = 3;        % velocidad de avance
L1 = 2;        % distancia entre ejes del camion
L2 = 4;        % longitud del remolque
dt = 0.0025;   % paso de integracion [s]
ti = 0;        % tiempo inicial [s]
tf = 40;       % tiempo final [s]
tanmax = tan(45*pi/180);   % saturacion de u = tan(delta): deltamax = 45 grados

%% Diseno del controlador LQR (linealizacion + Riccati)
% Sistema linealizado alrededor de y = 0, fi2 = 0, fi12 = 0
A = [ 0   v    0
      0   0  -v/L2
      0   0   v/L2 ];
B = [ 0
      0
     -v/L1 ];

% Peso q1 segun la coordenada inicial y (el original probaba varios
% valores y dejaba activo solo el ultimo):
%   yini =  0  ->  q1 = 20*8*4*2
%   yini =  5  ->  q1 = 10*8*4*2
%   yini = 10  ->  q1 = 2*8*4*2      (valor activo)
%   yini = 20  ->  q1 = 0.3*8*4*2
%   yini = 30  ->  q1 = 0.075*8*4*2
q1 = 2*8*4*2;
q2 = 1*100;
q3 = 15*200;
Q  = diag([ q1 q2 q3 ]);

P = are(A, B*B', Q);   % solucion de la ecuacion algebraica de Riccati
K = B'*P;              % ganancia de la ley lineal u = -K*x
k1 = K(1,1);   k2 = K(1,2);   k3 = K(1,3);

%% Condiciones iniciales del robot
x    = input('Coordenada inicial x [30 a 40] : ');
y    = input('Coordenada inicial y [-10 a 10]: ');
fi1  = input('Angulo inicial fi1 (grados) [-180 a 180]: ');
fi2  = input('Angulo inicial fi2 (grados) [-180 a 180]: ');
yast = input('Coordenada y deseada [-10 a 10]: ');

fi12 = fi1 - fi2;
if fi12 > 180        % llevar fi12 al rango (-180, 180]
    fi12 = fi12 - 360;
elseif fi12 < -180
    fi12 = fi12 + 360;
end
fi1  = fi1*pi/180;
fi2  = fi2*pi/180;
fi12 = fi12*pi/180;

%% Simulacion del lazo de control
fi2ast  = 0;   % orientacion deseada del remolque
fi12ast = 0;   % articulacion deseada

vt   = ti:dt:tf;   % instantes de simulacion
nMax = numel(vt);
xx    = zeros(nMax,1);
yy    = zeros(nMax,1);
ffi1  = zeros(nMax,1);
ffi2  = zeros(nMax,1);
ffi12 = zeros(nMax,1);
delta = zeros(nMax,1);
t     = zeros(nMax,1);

for k = 1:nMax
    xx(k)    = x;
    yy(k)    = y;
    ffi1(k)  = fi1;
    ffi2(k)  = fi2;
    ffi12(k) = fi12;
    t(k)     = vt(k);

    % --- Controlador central: ley LQR con saturacion ---------------------
    tand = -k1*(y-yast) - k2*(fi2-fi2ast) - k3*(fi12-fi12ast);
    if tand > tanmax
        tand = tanmax;
    elseif tand < -tanmax
        tand = -tanmax;
    end

    % --- Ponderacion difusa tipo Sugeno de los tres controladores --------
    kfi12 = round((fi12 - pi/2)/pi*(np-1) + np);   % indice de fi12 en las
                                                   % tablas (valido si
                                                   % |fi12| < 90 grados)
    ffdp1 = fdp1(kfi12,1);
    ffdp2 = fdp2(kfi12,1);
    ffdp3 = fdp3(kfi12,1);
    % Normalizacion secuencial, tal cual el original: cada peso se divide
    % entre una suma que ya incluye los pesos previos renormalizados (no
    % es la normalizacion simultanea clasica; se conserva para reproducir
    % exactamente los resultados)
    ffdp1 = ffdp1/(ffdp1+ffdp2+ffdp3);
    ffdp2 = ffdp2/(ffdp1+ffdp2+ffdp3);
    ffdp3 = ffdp3/(ffdp1+ffdp2+ffdp3);
    tand  = ffdp1*(-tanmax) + ffdp2*tand + ffdp3*(tanmax);
    delta(k) = atan(tand);   % angulo del timon aplicado

    % --- Modelo no lineal del robot (integracion de Euler) ---------------
    xp   = v*cos(fi12)*cos(fi2);
    yp   = v*cos(fi12)*sin(fi2);
    fi1p = -v/L1*tand;
    fi2p = -v/L2*sin(fi12);
    x    = x + xp*dt;
    y    = y + yp*dt;
    fi1  = fi1 + fi1p*dt;
    fi2  = fi2 + fi2p*dt;
    fi12 = fi1 - fi2;
    if fi12 > pi         % mantener fi12 en (-pi, pi]
        fi12 = fi12 - 2*pi;
    elseif fi12 < -pi
        fi12 = fi12 + 2*pi;
    end

    if x > 80   % limite del area de trabajo
        break;
    end
end

nk    = k;   % pasos simulados (si hubo break, se descarta la cola no usada)
xx    = xx(1:nk);
yy    = yy(1:nk);
ffi1  = ffi1(1:nk);
ffi2  = ffi2(1:nk);
ffi12 = ffi12(1:nk);
delta = delta(1:nk);
t     = t(1:nk);

%% Graficas de resultados
% (se conserva la numeracion de figuras del original: no existe figura 4)
lineaCero = [ 0 40 ];   % linea de referencia horizontal en cero
nivelCero = [ 0  0 ];

figure(2);
subplot(2,1,1); plot(xx); title('Coordenada x');
subplot(2,1,2); plot(yy); title('Coordenada y');

figure(3);
senales = { ffi1, ffi2, ffi12, delta };
titulos = { 'Angulo fi1', 'Angulo fi2', 'Angulo fi12', 'Angulo del timon delta' };
rangosY = [ -200 200; -200 200; -60 60; -50 50 ];
for s = 1:4
    subplot(4,1,s);
    plot(t, 180/pi*senales{s}, '-b', 'Linewidth', 1.25);
    axis([0 40 rangosY(s,:)]);
    title(titulos{s});
    hold on;
    plot(lineaCero, nivelCero, ':b');
end

figure(5);
plot(xx, yy); grid;
title('Trayectoria X-Y');
axis([ 0 100 -50 50 ]);

%% Animacion y video (trailer4.avi)
disp(' ');
disp('Presione ENTER para la animacion');
pause;

La = 1.0*L1;   % ancho del camion y del remolque (solo para el dibujo)

hf = figure(6);
set(hf, 'Position', [300 50 750 620]);
axis([0 80 -40 40]);
hold on;

% Ranura de estacionamiento: dos obstaculos junto al borde derecho que
% dejan libre la franja  yast-3 < y < yast+3
xct   = [ 0 80 ];   yct = [ yast yast ];   % linea guia hacia la ranura
xobs1 = [ 75      75      80      80      75 ];
yobs1 = [ 40    yast+3  yast+3    40      40 ];
xobs2 = [ 75      75      80      80      75 ];
yobs2 = [ yast-3  -40     -40   yast-3  yast-3 ];
plot(xct, yct, ':b');
fill(xobs1, yobs1, 'c');
fill(xobs2, yobs2, 'c');

writeObj = VideoWriter('trailer4.avi');
writeObj.FrameRate = 20;
open(writeObj);

for k = 1:100:nk    % un cuadro cada 100 pasos de simulacion
    x   = xx(k);    y   = yy(k);
    fi1 = ffi1(k);  fi2 = ffi2(k);
    % Puntos del eje longitudinal: (x1,y1) enganche camion-remolque,
    % (x2,y2) parte trasera del camion
    x1 = x  - L2*cos(fi2);   y1 = y  - L2*sin(fi2);
    x2 = x1 - L1*cos(fi1);   y2 = y1 - L1*sin(fi1);

    [xcab,  ycab ] = rectanguloCuerpo(x2, y2, x1, y1, fi1, La);   % camion
    [xtrai, ytrai] = rectanguloCuerpo(x1, y1, x,  y,  fi2, La);   % remolque

    plot(xct, yct, ':');
    plot(xcab,  ycab,  '-b', 'Linewidth', 2);
    plot(xtrai, ytrai, '-r', 'Linewidth', 2);

    frame = getframe(gcf);
    writeVideo(writeObj, frame);
    pause(0.1);

    plot(xcab,  ycab,  '-w', 'Linewidth', 2);   % borra el cuadro pintando
    plot(xtrai, ytrai, '-w', 'Linewidth', 2);   % encima en blanco
end
close(writeObj);

% Deja dibujada la ultima pose y el marco del area de trabajo
plot(xcab,  ycab,  '-b', 'Linewidth', 2);
plot(xtrai, ytrai, '-r', 'Linewidth', 2);
xbox = [  0  80  80   0   0 ];
ybox = [ -40 -40  40  40 -40 ];
plot(xbox, ybox, '-k');

%% Funciones locales
function f = rampa(indices, iCero, iUno)
% Tramo lineal de una membresia sobre el vector de indices dado: vale 0
% en el indice iCero y 1 en iUno. Es la misma formula del original,
% (indices - iCero)/(iUno - iCero), para reproducir sus valores exactos.
f = (indices - iCero)/(iUno - iCero);
end

function [xs, ys] = rectanguloCuerpo(xa, ya, xb, yb, ang, ancho)
% Poligono cerrado del rectangulo cuyo eje longitudinal va de (xa,ya) a
% (xb,yb), con orientacion ang y ancho total dado (para la animacion).
xs = [ xa - ancho/2*sin(ang)
       xa + ancho/2*sin(ang)
       xb + ancho/2*sin(ang)
       xb - ancho/2*sin(ang) ];
ys = [ ya + ancho/2*cos(ang)
       ya - ancho/2*cos(ang)
       yb - ancho/2*cos(ang)
       yb + ancho/2*cos(ang) ];
xs = [ xs; xs(1) ];
ys = [ ys; ys(1) ];
end
