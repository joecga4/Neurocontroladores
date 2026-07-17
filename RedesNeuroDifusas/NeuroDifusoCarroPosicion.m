% NeuroDifusoCarroPosicion (original: neurofuzzy1.m)
% =========================================================================
% Control neuro-difuso tipo Sugeno de orden cero, implementado a mano (sin
% Fuzzy Toolbox), de un robot movil tipo carro. El carro avanza con paso
% constante r y el controlador calcula el angulo del timon DxG (saturado a
% +/-30 grados) para llegar a la coordenada X deseada apuntando hacia
% arriba (phi = 90), donde estan los cajones de estacionamiento.
%
% A diferencia del Mamdani de ControlDifusoCarroPosicionX.m (inferencia
% min, agregacion max y defuzzificacion por centro de gravedad sobre las
% membresias del consecuente), aqui el consecuente de cada regla es una
% constante numerica y la salida es un promedio ponderado normalizado
% (red neuro-difusa equivalente a Sugeno de orden cero).
%
% Pipeline en cada paso de simulacion:
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
% El universo de X esta desplazado de modo que el objetivo queda en 50
% (xnuevo = x + 50 - xdeseado); phi se mide en grados respecto a la
% horizontal y su objetivo es 90 (vertical).

%% Condiciones iniciales y objetivo
clear;
close all;
clc;

PI = 3.141592;   % aproximacion de pi del script original; se conserva
                 % para reproducir exactamente los resultados

xini = input('Input intial coordinate  x [10 to 90]: ');
yini = input('Input initial coordinate y [10 to 60]: ');
Pini = input('Input initial inclination angle fi [-90 to 270]: ');
xdeseado = input('Input desired coordinate x [20 - 80]: ');

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

    if ( y > 100)   % llego a la fila de estacionamiento
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
A = 6;    % ancho del carro y de cada cajon de estacionamiento
E = 3;    % separacion entre cajones

figure(2);
hold on;
axis([ 0 100 0 100 ]);
xp = [ 0  100  100    0   0 ]';           % campo de trabajo
yp = [ 0    0  100  100   0 ]';
zp = [ 0  xdeseado  xdeseado    0   0 ]'; % rectangulo hasta x deseado
wp = [ 0    0  100  100   0 ]';
plot(xp,yp,zp,wp,'k');   % como en el original: el primer par queda con el
                         % color por defecto y solo el segundo en negro

% Cajones de estacionamiento en la fila superior (y entre 99-L y 99),
% alrededor del objetivo: 5 a la izquierda y 4 a la derecha, dejando
% libre el cajon del objetivo. Cada cajon se dibuja con 4 contornos
% anidados (margenes 0, 0.25, 0.5, 0.75) para simular un borde grueso.
% El original definia tambien cajones extra a la derecha (1+4*(A+E) y
% 3+(6:15)*(A+E)) pero su trazado estaba comentado y aqui se omite.
bordes = [ 1 - (5:-1:1)*(A+E), ...   % cajones a la izquierda del objetivo
           1 + (0:3)*(A+E) ];        % cajones a la derecha
for x0 = bordes + xdeseado - 50
    for margen = [0 0.25 0.5 0.75]
        plot([x0+margen, x0+A-margen, x0+A-margen, x0+margen, x0+margen], ...
             [99-L+margen, 99-L+margen, 99-margen, 99-margen, 99-L+margen], 'b');
    end
end

axis([ 0 100 0 100 ]);
plot(xp,yp,'k',zp,wp,'k');   % contornos redibujados, ahora ambos en negro

% Arco de circunferencia de radio 50 centrado en (100,0): referencia
% visual de una posible trayectoria circular hacia la meta
xcirc = 50:0.01:100;
xcirc = xcirc';
ycirc = sqrt(50*50 - (xcirc-100).*(xcirc-100));
plot(xcirc,ycirc,'k');

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
plot(dd,'-b');
grid;
axis([ 0 1000 -35 35 ]);

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
