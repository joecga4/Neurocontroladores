% Control Fuzzy de Motor DC

clear;
clc;
PI = 3.141592;
close all;


xini = input('Introduce Posicion Inicial X : ');
xdeseado = input('Introducir Posicion X deseada : ');

%Define cantidad de divisiones de la variables (PARTICIONES)

kX = 7; %Posicion
kP = 7; %velocidad
kD = 7; %Voltaje


%Define los rangos de cada una de las divisiones
%de X. (X viene a ser el valor de la coordenada en eje X)
%LE LC CE RC RI

Xrango= [-1.2   -0.35
         -0.45  -0.15
         -0.25  -0.00
         -0.02   0.02
          0.00   0.25
          0.15   0.45
          0.35   1.2 ];

%FUNCION DE PERTENENCIA

LE0 = Xrango(1,1);
LE1 = -0.45;
LE2 = Xrango(1,2);
LEC1 = Xrango(2,1);
LEC2 = -0.30;
LEC3 = Xrango(2,2);
LC1 = Xrango(3,1);
LC2 = -0.15;
LC3 = Xrango(3,2);
CE1 = Xrango(4,1);
CE2 = 0;
CE3 = Xrango(4,2);
RC1 = Xrango(5,1);
RC2 = 0.15;
RC3 = Xrango(5,2);
RIC1 = Xrango(6,1);
RIC2 = 0.30;
RIC3 = Xrango(6,2);
RI1 = Xrango(7,1);
RI2 = 0.45;
RI3 = Xrango(7,2);


% Grafico de las funciones de pertenencia de X

Xx = [ LE0 LE1 LE2 LEC1 LEC2 LEC3 LC1 LC2 LC3 CE1 CE2 CE3 RC1 RC2 RC3 RIC1 RIC2 RIC3 RI1 RI2 RI3 ];
Xy = [ 1   1   0   0    1    0    0   1   0   0   1   0   0   1   0   0    1    0    0   1   1 ];                    
figure(1);
subplot(3,1,1);
plot(Xx,Xy,'g');
title('Funciones de Pertenencia');
ylabel('X');
grid;
drawnow


%Define los rangos de cada una de las divisiones
%de P. (P viene a ser el angulo de inclinacion
%de Vehiculo con respecto a la horizontal)
%RB RU RV VE LV LU LB


Prango = [ -0.50    -0.08
           -0.12    -0.04
           -0.06    -0.00
           -0.01    0.01
            0.00    0.06
            0.04    0.12
            0.08    0.50 ];

RB1 = Prango(1,1);
RB2 = -0.10;
RB3 = Prango(1,2);
RU1 = Prango(2,1);
RU2 = -0.08;
RU3 = Prango(2,2);
RV1 = Prango(3,1);
RV2 = -0.03;
RV3 = Prango(3,2);
VE1 = Prango(4,1);
VE2 = 0;
VE3 = Prango(4,2);
LV1 = Prango(5,1);
LV2 = 0.03;
LV3 = Prango(5,2);
LU1 = Prango(6,1);
LU2 = 0.08;
LU3 = Prango(6,2);
LB1 = Prango(7,1);
LB2 = 0.10;
LB3 = Prango(7,2);

Phx = [ RB1 RB2 RB3 RU1 RU2 RU3 RV1 RV2 RV3 VE1 VE2 VE3 LV1 LV2 LV3 LU1 LU2 LU3 LB1 LB2 LB3 ];
Phy = [ 1   1   0   0   1   0   0   1   0   0   1   0   0   1   0   0   1   0   0   1   1   ];

figure(1);
subplot(3,1,2);
plot(Phx,Phy,'r');   
ylabel('Phi');
grid;
drawnow;


%Define los rangos de cada una de las divisiones
%de D. (D viene a ser el angulo de giro
%de las ruedas con respecto al vehiculo)
%NB NM NS ZE PS PM PB 

Drango= [ -40   -8
          -10   -6
          -9    -0
          -1    1
           0    9
           6    10
           8   40 ];

NB0 = Drango(1,1);
NB1 = -15;
NB2 = Drango(1,2);
NM1 = Drango(2,1);
NM2 = -10;
NM3 = Drango(2,2);
NS1 = Drango(3,1);
NS2 = -5;
NS3 = Drango(3,2);
ZE1 = Drango(4,1);
ZE2 = 0;
ZE3 = Drango(4,2);
PS1 = Drango(5,1);
PS2 = 5;
PS3 = Drango(5,2);
PM1 = Drango(6,1);
PM2 = 10;
PM3 = Drango(6,2);
PB1 = Drango(7,1);
PB2 = 15;
PB3 = Drango(7,2);

Dex = [ NB0 NB1 NB2 NM1 NM2 NM3 NS1 NS2 NS3 ZE1 ZE2 ZE3 PS1 PS2 PS3 PM1 PM2 PM3 PB1 PB2 PB3 ];
Dey = [ 1   1   0   0   1   0   0   1   0   0   1   0   0   1   0   0   1   0   0   1   1   ];
figure(1);
subplot(3,1,3);
plot(Dex,Dey,'y');                      
ylabel('Delta');
grid;
drawnow;


%Base de reglas
%El numero dentro de la matriz te indica la  
%region del delta en la cual estamos trabajando
%comenzando del NB=1 al PB=7


BaseReg = [ 7  7  7  4  1  1  1 
            7  7  7  4  1  1  1
            7  7  7  4  1  1  1
            7  7  7  4  1  1  1
            7  7  7  4  1  1  1
            7  7  7  4  1  1  1
            7  7  7  4  1  1  1 ];  



%-----------------------------------------------------------------------------
%
%                 DEFINICION DE MATRICES VALUEX Y VALUEP
%
%-----------------------------------------------------------------------------

%En la primera columna de esta Matriz encontramos el numero asignado a cada
%region que hemos dividido.
%En la segunda columna vamos a colocar posteriormente el valor que toma en
%la funcion de pertenencia

%MOTOR SIN FIN

R = 2*1.1;
L = 1*0.0001;
Kt = 0.0573;
Kb = 0.05665;
I = 4.326e-5;
p = 0.0025;
m = 1.00;
c = 100;
r = 0.01;
alfa = 45*pi/180;

d = m + 2*pi*I*tan(alfa)/(p*r);

a22 = -c/d;
a23 = Kt*tan(alfa)/(r*d);

a32 = -2*pi*Kb/(p*L);
a33 = -R/L;
b31 = 1/L;
w21 = -1/d;

A = [ 0   1   0   
      0  a22 a23 
      0  a32 a33 ];
      
B = [ 0
      0
      b31 ];
 
Wf = [ 0
       w21       
       0 ];
    
dt = 0.002;
ti = 0;
tf = 1*25;
Fseca = 0.75*70;      % 0 - 0.75

[Ak,Bk] = c2d(A,B,dt);
[Ak,Wk] = c2d(A,Wf,dt);
xx(1,1) = xini;
xx(2,1) = 0;
xx(3,1) = 0;

x = xx(1,1);
P = xx(2,1);

count = 1;

for t = ti:dt:tf

%Para determinar a que particion corresponde
xnuevo = xx(1,1) - xdeseado;
numx = 0;
for nx = 1:kX
   rangomin = Xrango(nx,1);
   rangomax = Xrango(nx,2);
   if(  (xnuevo >= rangomin) & (xnuevo <= rangomax) ) 
      numx = numx + 1;  
      valuex(numx,1) = nx;
   end
end


%Para determinar a que particion corresponde
numP = 0;
for nP = 1:kP
   rangomin = Prango(nP,1);
   rangomax = Prango(nP,2);
   if( (P >= rangomin) & (P <= rangomax) ) 
       numP = numP + 1;  
       valueP(numP,1) = nP;
   end
end



%-----------------------------------------------------------------------------
%
%                       FUNCIONES DE PERTENECIA DE X
%
%-----------------------------------------------------------------------------



%Hemos tomado como convencion que siempre que se tengan tres puntos y que cuando 
%y se traten de dividir las zonas respecto a esos puntos, se va tomar asi:
% < y >=


%fpx = funcion de pertenencia
%Halla la funcion de pertenecia construyendo rectas

for nx = 1:numx
vx = valuex(nx,1);
   if(vx == 1)
      if( xnuevo < LE1 )
          fpx = 1;
      elseif( ( xnuevo >= LE1 ) & ( xnuevo <= LE2) )
          fpx = 1 - ((xnuevo - LE1)/(LE2 - LE1)); 
      end

   elseif(vx == 2) 
      if( ( xnuevo < LEC2 ) & ( xnuevo >= LEC1 ) )
         fpx = (xnuevo-LEC1)/(LEC2-LEC1);
      elseif( ( xnuevo >= LEC2 ) & ( xnuevo <= LEC3 ) )
         fpx = 1 - ((xnuevo-LEC2)/(LEC3-LEC2)); 
      end

   elseif(vx == 3)
      if( ( xnuevo < LC2 ) & ( xnuevo >= LC1 ) )
         fpx = (xnuevo-LC1)/(LC2-LC1);
      elseif( ( xnuevo >= LC2 ) & ( xnuevo <= LC3 ) )
         fpx = 1 - ((xnuevo-LC2)/(LC3-LC2)); 
      end

    elseif( vx == 4 )
      if( ( xnuevo < CE2 ) & ( xnuevo >= CE1 ) )
         fpx = (xnuevo-CE1)/(CE2-CE1);
      elseif( ( xnuevo >= CE2 ) &  ( xnuevo <= CE3) )
         fpx = 1 - ((xnuevo-CE2)/(CE3-CE2)); 
      end

    elseif( vx == 5 )
      if( ( xnuevo < RC2 ) & ( xnuevo >= RC1 ) )
         fpx = (xnuevo-RC1)/(RC2-RC1);
      elseif( ( xnuevo >= RC2 ) &  ( xnuevo <= RC3) )
         fpx = 1 - ((xnuevo-RC2)/(RC3-RC2)); 
      end

    elseif( vx == 6 )
      if( ( xnuevo < RIC2 ) & ( xnuevo >= RIC1 ) )
         fpx = (xnuevo-RIC1)/(RIC2-RIC1);
      elseif( ( xnuevo >= RIC2 ) &  ( xnuevo <= RIC3) )
         fpx = 1 - ((xnuevo-RIC2)/(RIC3-RIC2)); 
      end


    elseif( vx == 7 )
      if( ( xnuevo < RI2 ) & ( xnuevo >= RI1 ) )
         fpx = (xnuevo-RI1)/(RI2-RI1);
      elseif( xnuevo >= RI2 )
         fpx = 1; 
      end
    end
    
valuex(nx,2) = fpx;
end     


%----------------------------------------------------------------------------
%
%                  SE DEFINE LAS FUNCIONES DE PERTENENCIA DE P
%
%-----------------------------------------------------------------------------

for nP = 1:numP
vP = valueP(nP,1);
   if( vP == 1)
      if( ( P >= RB1 ) & ( P < RB2 ) )
          fpP = 1;
      elseif( ( P >= RB2 ) & ( P <= RB3 ) )
          fpP = 1 - ((P-RB2)/(RB3-RB2));
      end
   elseif( vP == 2 )
      if( ( P >= RU1 ) & ( P < RU2) )
          fpP = (P-RU1)/(RU2-RU1);
      elseif( ( P >= RU2 ) & ( P <= RU3) )
          fpP = 1 - ((P-RU2)/(RU3-RU2)); 
      end
   elseif( vP == 3 )
      if( ( P >= RV1 ) & ( P < RV2 ) )
          fpP = (P-RV1)/(RV2-RV1);
      elseif( ( P >= RV2 ) & ( P <= RV3 ) )
          fpP = 1 - ((P-RV2)/(RV3-RV2)); 
      end
   elseif( vP == 4 )
      if( ( P >= VE1 ) & ( P < VE2) )
          fpP = (P-VE1)/(VE2-VE1);
      elseif( ( P >= VE2 ) & ( P <= VE3) )
          fpP = 1 - ((P-VE2)/(VE3-VE2)); 
      end
   elseif( vP == 5 )
      if( ( P >= LV1 ) & ( P < LV2) )
          fpP = (P-LV1)/(LV2-LV1);
      elseif( ( P >= LV2 ) & ( P <= LV3) )
          fpP = 1 - ((P-LV2)/(LV3-LV2)); 
      end
   elseif( vP == 6 )
      if( ( P >= LU1 ) & ( P < LU2 ) )
          fpP = (P-LU1)/(LU2-LU1);
      elseif( ( P >= LU2 ) & ( P <= LU3 ) )
          fpP = 1 - ((P-LU2)/(LU3-LU2)); 
      end
   elseif( vP == 7 )
      if( ( P >= LB1 ) & ( P < LB2) )
          fpP = (P-LB1)/(LB2-LB1);
      elseif( ( P >= LB2 ) & ( P <= LB3) )
          fpP = 1; 
      end
   end
   
valueP(nP,2) = fpP;
end


%Define el valueD
%En el valueD se utiliza la primera columna con la base de reglas
%mediante el uso de la combinacion de las primeras columnas del
%valuex y el valueP.
%En la segunda columna se coloca el minimo valor de cada una de
%las combinaciones
                           

%identifica la regla
kkd = 1;
for kkx = 1:numx
   for kkP = 1:numP
      Dx = valuex(kkx,1);
      DP = valueP(kkP,1);
      valueD(kkd,1) = BaseReg(DP,Dx);		%numero de figura
      valueD(kkd,2) = min(valuex(kkx,2),valueP(kkP,2));	%grado de pertenencia
      kkd = kkd + 1;
   end
end
numD = kkd - 1;


dD = 0.02;

nnD = (40 - (-40)) /dD + 1; %Para encontrar el Area

Dbase = zeros(kD,nnD);


%Centro de Gravedad
for nD = 1:numD
  k = 1;
  vD = valueD(nD,1); 
  minD = valueD(nD,2);
    for tD = -40:dD:40  %Rango del Voltaje
        if( vD == 1 )
            if( tD < NB1 )
                Dbase(nD,k) = 1;
            elseif( (tD >= NB1)  &  (tD < NB2)  )            
                Dbase(nD,k) = 1 - ((tD-NB1)/(NB2-NB1));     
            elseif( tD >=NB2 ) 
                Dbase(nD,k) = 0;
            end
            if( Dbase(nD,k) > minD )
                Dbase(nD,k) = minD;
            end
         elseif( vD == 2 )
            if( tD <= NM1 )
                Dbase(nD,k) = 0;
            elseif( (tD > NM1) & (tD <= NM2) )
                Dbase(nD,k) = (tD-NM1)/(NM2-NM1);
            elseif( (tD > NM2) & ( tD <= NM3) )            
                Dbase(nD,k) = 1 - ((tD-NM2)/(NM3-NM2));     
            elseif( tD > NM3 )
                Dbase(nD,k) = 0;
            end
            if( Dbase(nD,k) > minD )
              Dbase(nD,k) = minD;
            end
        elseif( vD == 3 )
            if( tD <= NS1 )
                Dbase(nD,k) = 0;
            elseif( (tD > NS1) & (tD <= NS2) )
                Dbase(nD,k) = (tD-NS1)/(NS2-NS1);
            elseif( (tD > NS2) & ( tD <= NS3) )            
                Dbase(nD,k) = 1 - ((tD-NS2)/(NS3-NS2));     
            elseif( tD > NS3 )
                Dbase(nD,k) = 0;
            end
            if( Dbase(nD,k) > minD )
                Dbase(nD,k) = minD;
            end
        elseif( vD == 4 )
            if( tD <= ZE1 )
                Dbase(nD,k) = 0;
            elseif( (tD > ZE1) & (tD <= ZE2) )
                Dbase(nD,k) = (tD-ZE1)/(ZE2-ZE1);
            elseif( (tD > ZE2) & ( tD <= ZE3) )            
                Dbase(nD,k) = 1 - ((tD-ZE2)/(ZE3-ZE2));     
            elseif( tD > ZE3 )
                Dbase(nD,k) = 0;
            end
            if( Dbase(nD,k) > minD )
                Dbase(nD,k) = minD;
            end
        elseif( vD == 5 )
            if( tD <= PS1 )
                Dbase(nD,k) = 0;
            elseif( (tD > PS1) & (tD <= PS2) )
                Dbase(nD,k) = (tD-PS1)/(PS2-PS1);
            elseif( (tD > PS2) && ( tD <= PS3) )            
                Dbase(nD,k) = 1 - ((tD-PS2)/(PS3-PS2));     
            elseif( tD > PS3 )
                Dbase(nD,k) = 0;
            end
            if( Dbase(nD,k) > minD )
                Dbase(nD,k) = minD;
            end
        elseif( vD == 6 )
            if( tD <= PM1 )
                Dbase(nD,k) = 0;
            elseif( (tD > PM1) & (tD <= PM2) )
                Dbase(nD,k) = (tD-PM1)/(PM2-PM1);
            elseif( (tD > PM2) & ( tD <= PM3) )            
                Dbase(nD,k) = 1 - ((tD-PM2)/(PM3-PM2));     
            elseif( tD > PM3 )
                Dbase(nD,k) = 0;
            end
            if( Dbase(nD,k) > minD )
                Dbase(nD,k) = minD;
            end
        elseif( vD == 7 )
            if( tD <= PB1 )
                Dbase(nD,k) = 0;
            elseif( (tD > PB1) & (tD <= PB2) )
                Dbase(nD,k) = (tD-PB1)/(PB2-PB1);
            elseif( tD > PB2 )            
                Dbase(nD,k) = 1;     
            end
            if( Dbase(nD,k) > minD )
                Dbase(nD,k) = minD;
            end
        end
        k = k + 1;
    end
end

maxDbase = max(Dbase);

AreaD = sum(maxDbase) * dD;
DD = -40:dD:40;
DxG = ( (dD.*maxDbase) * DD') / AreaD;
%saturacion +/-30
if( DxG > 24 )
   DxG = 24;
end
if( DxG < -24 )
    DxG = -24;
end


pos(count,1) = xx(1,1);
vel(count,1) = xx(2,1);
amp(count,1) = xx(3,1);
volt(count,1) = DxG;
tiempo(count,1) = t;

%Integrando el Sistema (calcula el siguiente X)
if(xx(2,1) >= 0)
    Fs = Fseca;
elseif(xx(2,1) < 0)
    Fs = -Fseca;
end

xx = Ak*xx + Bk*DxG + Wk*Fs;

P = xx(2,1);    %velocidad

count = count+1;

end

figure(2)
plot(tiempo,pos);
title('POSICION');   grid;

figure(3)
plot(tiempo,volt);
title('VOLTAJE');   grid;


