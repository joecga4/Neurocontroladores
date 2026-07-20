% ModeloMotor_SieteEntradasRetardos (original: MotorNeuroEstatico.m)
% =========================================================================
% Identificacion NARX de un motor DC con tornillo sin fin usando una red
% neuronal ESTATICA de 7 entradas: voltaje v(k) y las posiciones
% retardadas x(k-1) ... x(k-6). Version con MAS memoria que el script de
% 4 entradas (ModeloMotor_CuatroEntradasRetardos). Entrenamiento batch
% clasico (backpropagation estatico, sin recursion en el tiempo).
%
% Pipeline:
%   1. Plantear el motor DC de 3 estados [posicion; velocidad; corriente]
%      y discretizarlo con c2d (dt = 0.0075 s).
%   2. Generar la senal de excitacion vv (perfiles v1..v4 de voltaje,
%      saturados a +/-24 V) y simular la planta para obtener pos(k).
%   3. Construir la matriz NARX xb = [volt, pos(k-1), ..., pos(k-6)]
%      (cada columna xN es la anterior retardada un paso, con 0 inicial)
%      y escalar entradas y salida a +/-1 con max(abs(.)).
%   4. Entrenar la red 7-20-1 (sigmoide bipolar en la capa oculta, salida
%      lineal) en batch: acumular dJdw y dJdv sobre todo el lote y
%      actualizar una vez por iteracion.
%
% Configuracion vigente del original:
%   - vv = v1 (perfil de ENTRENAMIENTO); v2/v3/v4 comentados.
%   - El estado inicial x se asigna DOS veces; vale la segunda:
%     [-0.1; 0.1; 0.2].
%   - Friccion seca anulada (Fseca = 0*100) y ruido anulado (nruido = 0),
%     pero la llamada a randn se conserva (consume numeros del generador).
%
% Rarezas heredadas del original (NO corregidas, solo documentadas):
%   - Kt, Kb, I se asignan dos veces; vale la SEGUNDA (parametros
%     ajustados; la primera asignacion queda como referencia historica).
%   - "load motorred" ocurre DESPUES de pedir bias y de escalar: los
%     bias/factx/facty cargados PISAN a los recien calculados (solo
%     afectan al save final; xesc ya quedo escalado con los locales).
%   - pot (potencia) se calcula pero no se usa.
%   - La variable "error" enmascara la funcion error() de MATLAB.
%   - a = ones(nm,1) deja la pendiente sigmoidea fija en 1 (no se entrena).
%   - yesc usa facty(:,1) en vez de facty(1,1) (facty es escalar: igual).
%   - JJ sin punto y coma imprime el costo en cada iteracion (progreso).
%   - pos, vel, amp, t, volt, pot, xesc, yesc, y, error, J crecen sin
%     preasignar; se dejan asi por fidelidad con el original.
%   - Titulos normalizados a ASCII ("Posicion" sin tilde).

%% Limpieza
clear;
clc;
close all;

%% Parametros del motor DC con tornillo sin fin
R = 1.1;           % resistencia de armadura
L = 0.0001;        % inductancia de armadura
Kt = 0.0573;       % constante de torque (valor original)
Kt = 0.0815;       % ... ajustado: vale este
Kb = 0.05665;      % constante contraelectromotriz (valor original)
Kb = 0.0715;       % ... ajustado: vale este
I = 4.326e-5;      % inercia del rotor (valor original)
I = 15.865E-5;     % ... ajustado: vale este
p = 0.0025;        % paso del tornillo sin fin
m = 30.0;          % masa desplazada
c = 200;           % friccion viscosa
r = 0.01;          % radio del tornillo
alfa = 45*pi/180;  % angulo de la helice

d = m + 2*pi*I*tan(alfa)/(p*r);   % masa equivalente reflejada

a22 = -c/d;
a23 = Kt*tan(alfa)/(r*d);

a32 = -2*pi*Kb/(p*L);
a33 = -R/L;
b31 = 1/L;
w21 = -1/d;

% Estados: [posicion; velocidad; corriente]
A = [ 0   1   0
      0  a22 a23
      0  a32 a33 ];

B = [ 0
      0
      b31 ];

Wf = [ 0           % entrada de perturbacion: friccion seca
       w21
       0 ];

%% Senales de excitacion (perfiles de voltaje)
dt = 0.0075;                 % paso de muestreo [s]
t05 = 0:dt:0.5;              % tramos de 0.5, 1, 2 y 3 segundos
t05 = t05';
nt05 = length(t05);
ones05 = ones(nt05,1);
t1 = 0:dt:1;
t1 = t1';
nt1 = length(t1);
ones1 = ones(nt1,1);
t2 = 0:dt:2;
t2 = t2';
nt2 = length(t2);
ones2 = ones(nt2,1);
t3 = 0:dt:3;
t3 = t3';
nt3 = length(t3);
ones3 = ones(nt3,1);

vmax = 24;                   % voltaje maximo [V]

v1 = [  vmax*sin(2*pi*0.5*t3)      % perfil de ENTRENAMIENTO
       -0.75*vmax*ones1
       0.5*vmax*ones1
       vmax*ones1
        vmax*sin(2*pi*1*t3)
        0*ones1;
        -vmax*ones1
        -vmax*ones1
        -vmax*ones1
        vmax*sin(2*pi*2*t2)
        vmax*ones1
        0*ones1 ];

v2 = [  vmax*ones2                 % perfil de validacion 1
      -vmax*ones2
      -vmax*ones2
       vmax*ones1
       0*ones1;
      -vmax*ones1
       vmax*ones1
       vmax*ones1
       0*ones1 ];

v3 = [ vmax*ones05                 % perfil de validacion 2
      -vmax*ones05
       0*ones1 ];

v4 = [  vmax*sin(2*pi*2*t3)        % perfil de validacion 3 (2*vmax
       -1.0*vmax*ones1             % excede la saturacion a proposito)
       -0.5*vmax*ones1
        2*vmax*ones1
        -vmax*sin(2*pi*1*t3) ];

vv = v1;    % Entrenamiento
% vv = v2;    % Validacion
% vv = v3;    % Validacion
% vv = v4;    % Validacion

nv = length(vv);

%% Simulacion de la planta discreta
Fseca = 0*100;        % friccion seca anulada (Factor 1.0 - 2.0)

[Ak,Bk] = c2d(A,B,dt);       % discretizacion exacta de la planta
[Ak,Wk] = c2d(A,Wf,dt);      % misma Ak; Wk discretiza la friccion

x(1,1) = 0.1;                % estado inicial (primer intento, se pisa)
x(2,1) = -0.1;
x(3,1) = 0;

x(1,1) = -0.1;               % estado inicial EFECTIVO [pos; vel; corriente]
x(2,1) = 0.1;
x(3,1) = 0.2;


for k = 1:nv
    pos(k,1) = x(1,1);
    vel(k,1) = x(2,1);
    amp(k,1) = x(3,1);
    t(k,1) = dt*(k-1);
    u = vv(k,1);
    if( u > 24)              % saturacion del voltaje a +/-24 V
        u = 24;
    elseif( u < -24 )
        u = -24;
    end
    volt(k,1) = u;
    pot(k,1) = u*x(3,1);     % rareza: potencia calculada pero no usada
    if(x(2,1) >= 0)          % friccion seca opuesta al movimiento
        Ff = Fseca*1;
    elseif(x(2,1) < 0)
        Ff = -Fseca*1;
    end
    x = Ak*x + Bk*u + Wk*Ff;
end

% Ruido de medicion anulado (nruido = 0); la llamada a randn se conserva
nruido = 0;
pos = pos + nruido*0.002*randn(nv,1);

%% Graficas de la planta simulada
figure(1);
plot(t,volt);
title('Voltaje v');
figure(2);
plot(t,pos);
title('Posicion m');

%% Construccion de las entradas NARX (voltaje + 6 retardos de posicion)
x1 = volt;                   % v(k)
x2(1,1) = 0;                 % pos retardada 1 paso
x2(2:nv,1) = pos(1:nv-1,1);
x3(1,1) = 0;                 % pos retardada 2 pasos
x3(2:nv,1) = x2(1:nv-1,1);
x4(1,1) = 0;                 % pos retardada 3 pasos
x4(2:nv,1) = x3(1:nv-1,1);
x5(1,1) = 0;                 % pos retardada 4 pasos
x5(2:nv,1) = x4(1:nv-1,1);
x6(1,1) = 0;                 % pos retardada 5 pasos
x6(2:nv,1) = x5(1:nv-1,1);
x7(1,1) = 0;                 % pos retardada 6 pasos
x7(2:nv,1) = x6(1:nv-1,1);

xb = [ x1  x2  x3  x4  x5  x6  x7 ];   % lote de entrenamiento
yb = pos;                    % salida deseada: posicion actual
nx = length(xb);

%% Arquitectura de la red estatica
ne = 7;    % entradas (8 si se agrega bias)
nm = 20;   % neuronas ocultas sigmoideas
ns = 1;    % salida: posicion

%% Escalamiento de entradas y salida a +/-1
factx = max(abs(xb));
facty = max(abs(yb));

xesc(:,1) = xb(:,1)./factx(1,1);
xesc(:,2) = xb(:,2)./factx(1,2);
xesc(:,3) = xb(:,3)./factx(1,3);
xesc(:,4) = xb(:,4)./factx(1,4);
xesc(:,5) = xb(:,5)./factx(1,5);
xesc(:,6) = xb(:,6)./factx(1,6);
xesc(:,7) = xb(:,7)./factx(1,7);
yesc(:,1) = yb(:,1)./facty(:,1);   % rareza: facty(:,1) (escalar: igual)

bias = input('Bias:  SI = 1 : ');
if(bias == 1)
    ne = ne + 1;
    xesc = [ xesc ones(nx,1) ];
end

%% Inicializacion y carga de pesos previos
v = 0.25*randn(ne,nm);
w = 0.25*randn(nm,ns);
a = ones(nm,1);              % pendiente sigmoidea fija (no se entrena)

% OJO: motorred.mat NO existe en el repo (rotura conocida, ver README).
% Para la primera corrida comenta la linea "load motorred;" y ejecuta con
% la inicializacion aleatoria; el "save motorred ..." del final creara el
% .mat. Ademas el load PISA bias/factx/facty calculados arriba (rareza).
load motorred;    % Incluye pesos y factores de escalamiento
% load motorredsinbias;
% load motorredsinbiasruido;

%% Parametros de aprendizaje
eta = input('eta pesos : ');
niter = input('Introducir numero de iteraciones : ');

%% Entrenamiento batch (backpropagation estatico)
for iter = 1:niter
    JJ = 0;
    dJdw = 0;
    dJdv = 0;
    for k = 1:nx
        in = (xesc(k,:))';
        m = v'*in;
        n = 2.0./(1+exp(-m./a)) - 1;    % sigmoide bipolar
%       n = exp(-m.^2);                 % alternativa: gaussiana
%       n = m;                          % alternativa: lineal
        out = w'*n;
        y(k,:) = out';
        er = out - (yesc(k,:))';
        error(k,:) = er';               % rareza: enmascara error() de MATLAB
        JJ = JJ + 0.5*er'*er;
        dndm = (1 - n.*n)/2;
%       dndm = -2.0*(n.*m);             % derivada de la gaussiana
%       dndm = 1;                       % derivada lineal
        dJdw = dJdw + n*er';
        dJdv = dJdv + in * (dndm.*(w*er))';
    end
    w = w - eta*dJdw/nx;     % actualizacion batch (gradiente promedio)
    v = v - eta*dJdv/nx;
    JJ                       % muestra el costo de la iteracion
    J(iter,1) = JJ;
end

%% Graficas de resultados
figure(3);
plot(y(:,1),'-r');           % salida de la red (rojo)
hold on;
plot(yesc(:,1),'-b');        % salida deseada escalada (azul)
title('Salida y1');

figure(4);
plot(J);
title('Funcion de costo J');

%% Guardado de la red entrenada
save motorred v w bias factx facty;
% save motorredsinbias v w bias factx facty;
% save motorredsinbiasruido v w bias factx facty;
