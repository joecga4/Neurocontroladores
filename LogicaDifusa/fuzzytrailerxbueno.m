%  El angulo del timon delta esta entre 50 y -50 grados

clear;
clc;
PI = 3.141592;
close all;


xini = input('Introduce coordenada inicial  x [20 : 80]: ');
yini = input('Introduce coordenada inicial  y [20 : 30]: ');
Pini = input('Introduce inclinacion inicial Th2 [-90 : 270]: ');
Tini = input('Introduce angulo truck-trailer inicial Th12: [-60 : 60]: ');
xdeseado = input('Introducir coordenada final de x [20 : 80]: ');

%Define cantidad de divisiones de la variables

kX = 7;
kP = 7;
kT = 3;
kD = 7;

%Define los rangos de cada una de las divisiones
%de X. (X viene a ser el valor de la coordenada en eje X)
%LE LC CE RC RI

Xrango= [-50   25
         22  38
         35  50
         49  51
         50  65
         62  78
         75  150];


LE0 = Xrango(1,1);
LE1 = 10;
LE2 = Xrango(1,2);
LEC1 = Xrango(2,1);
LEC2 = 30;
LEC3 = Xrango(2,2);
LC1 = Xrango(3,1);
LC2 = 42;
LC3 = Xrango(3,2);
CE1 = Xrango(4,1);
CE2 = 50;
CE3 = Xrango(4,2);
RC1 = Xrango(5,1);
RC2 = 58;
RC3 = Xrango(5,2);
RIC1 = Xrango(6,1);
RIC2 = 70;
RIC3 = Xrango(6,2);
RI1 = Xrango(7,1);
RI2 = 90;
RI3 = Xrango(7,2);


% Grafico de las funciones de pertenencia de X

Xx = [ LE0 LE1 LE2 LEC1 LEC2 LEC3 LC1 LC2 LC3 CE1 CE2 CE3 RC1 RC2 RC3 RIC1 RIC2 RIC3 RI1 RI2 RI3 ];
Xy = [ 1   1   0   0    1    0    0   1   0   0   1   0   0   1   0   0    1    0    0   1   1 ];                    
figure(1);
subplot(4,1,1);
plot(Xx,Xy,'r');
title('Funciones de Pertenencia');
ylabel('X');
grid;



%Define los rangos de cada una de las divisiones
%de P. (P viene a ser el angulo de inclinacion
%de Vehiculo con respecto a la horizontal)
%RB RU RV VE LV LU LB

Prango = [ -95  10
           -30  60
            40  90
            60  120
            90 140
           120 210
           170 275 ];

RB1 = Prango(1,1);
RB2 = -45;
RB3 = Prango(1,2);
RU1 = Prango(2,1);
RU2 = 40;
RU3 = Prango(2,2);
RV1 = Prango(3,1);
RV2 = 60;
RV3 = Prango(3,2);
VE1 = Prango(4,1);
VE2 = 90;
VE3 = Prango(4,2);
LV1 = Prango(5,1);
LV2 = 120;
LV3 = Prango(5,2);
LU1 = Prango(6,1);
LU2 = 140;
LU3 = Prango(6,2);
LB1 = Prango(7,1);
LB2 = 222.5;
LB3 = Prango(7,2);

Phx = [ RB1 RB2 RB3 RU1 RU2 RU3 RV1 RV2 RV3 VE1 VE2 VE3 LV1 LV2 LV3 LU1 LU2 LU3 LB1 LB2 LB3 ];
Phy = [ 0   1   0   0   1   0   0   1   0   0   1   0   0   1   0   0   1   0   0   1   0   ];

figure(1);
subplot(4,1,2);
plot(Phx,Phy,'r');   
ylabel('Theta2');
grid;


Trango = [ -100  0
           -30   30
            0   100 ];

NE1 = Trango(1,1);
NE2 = -80;
NE3 = Trango(1,2);
ZT1 = Trango(2,1);
ZT2 = 0;
ZT3 = Trango(2,2);
PO1 = Trango(3,1);
PO2 = 80;
PO3 = Trango(3,2);

Tx = [ NE1 NE2 NE3 ZT1 ZT2 ZT3 PO1 PO2 PO3 ];
Ty = [  1   1   0   0   1   0   0   1   1 ];  

figure(1);
subplot(4,1,3);
plot(Tx,Ty,'r');   
ylabel('Theta12');
grid;



%Define los rangos de cada una de las divisiones
%de D. (D viene a ser el angulo de giro
%de las ruedas con respecto al vehiculo)
%NB NM NS ZE PS PM PB 

Drango= [ -70  -15
          -25   -6
          -12   -1
           -2    2
            1   12
            6   25
           15   70 ];

NB0 = Drango(1,1);
NB1 = Drango(1,1);
NB2 = Drango(1,2);
NM1 = Drango(2,1);
NM2 = -15.5;
NM3 = Drango(2,2);
NS1 = Drango(3,1);
NS2 = -6.5;
NS3 = Drango(3,2);
ZE1 = Drango(4,1);
ZE2 = 0;
ZE3 = Drango(4,2);
PS1 = Drango(5,1);
PS2 = 6.5;
PS3 = Drango(5,2);
PM1 = Drango(6,1);
PM2 = 15.5;
PM3 = Drango(6,2);
PB1 = Drango(7,1);
PB2 = Drango(7,2);
PB3 = Drango(7,2);

Dex = [ NB0 NB1 NB2 NM1 NM2 NM3 NS1 NS2 NS3 ZE1 ZE2 ZE3 PS1 PS2 PS3 PM1 PM2 PM3 PB1 PB2 PB3 ];
Dey = [ 1   1   0   0   1   0   0   1   0   0   1   0   0   1   0   0   1   0   0   1   1   ];
figure(1);
subplot(4,1,4);
plot(Dex,Dey,'r');                      
ylabel('Delta');
grid;



%Base de reglas
%El numero dentro de la matriz te indica la  
%region del delta en la cual estamos trabajando
%comenzando del NB=1 al PB=7


BaseReg(:,:,1) = [ 1  1  1  1  1  1  1 
            1  1  1  1  1  1  1
            1  1  1  1  1  1  1
            1  1  1  1  1  1  1
            1  1  1  1  1  1  1
            1  1  1  1  1  1  1
            1  1  1  1  1  1  1 ]; 

      
BaseReg(:,:,2) = [  7  7  7  7  1  1  1 
                    1  1  7  7  7  7  7
                    1  1  7  7  7  7  7
                    1  1  1  4  7  7  7
                    1  1  1  1  1  7  7
                    1  1  1  1  1  7  7
                    7  7  7  7  1  1  1 ]; 

        

BaseReg(:,:,3) = [ 7  7  7  7  7  7  7 
            7  7  7  7  7  7  7
            7  7  7  7  7  7  7
            7  7  7  7  7  7  7
            7  7  7  7  7  7  7
            7  7  7  7  7  7  7
            7  7  7  7  7  7  7 ];      



%-----------------------------------------------------------------------------
%
%                 DEFINICION DE MATRICES VALUEX Y VALUEP
%
%-----------------------------------------------------------------------------

%En la primera columna de esta Matriz encontramos el numero asignado a cada
%region que hemos dividido.
%En la segunda columna vamos a colocar posteriormente el valor que toma en
%la funcion de pertenencia


x = xini;
y = yini;
P = Pini;
Prad = P*(PI/180);
T = Tini;
Trad = T*PI/180;
r = 0.075;
L1 = 2.5;
L2 = 6;

countmax = 10000;

for count = 1:countmax

    
xnuevo = x + 50 - xdeseado;

numx = 0;
for nx = 1:kX
   rangomin = Xrango(nx,1);
   rangomax = Xrango(nx,2);
   if(  (xnuevo >= rangomin) & (xnuevo <= rangomax) ) 
      numx = numx + 1;  
      valuex(numx,1) = nx;
   end
end

% pause;


numP = 0;
for nP = 1:kP
   rangomin = Prango(nP,1);
   rangomax = Prango(nP,2);
   if( (P >= rangomin) & (P <= rangomax) ) 
       numP = numP + 1;  
       valueP(numP,1) = nP;
   end
end


numT = 0;
for nT = 1:kT
   rangomin = Trango(nT,1);
   rangomax = Trango(nT,2);
   if( (T >= rangomin) & (T <= rangomax) ) 
       numT = numT + 1;  
       valueT(numT,1) = nT;
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
          fpP = (P-RB1)/(RB2-RB1);
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
          fpP = 1 - ((P-LB2)/(LB3-LB2)); 
      end
   end
   valueP(nP,2) = fpP;
end



%----------------------------------------------------------------------------
%
%                  SE DEFINE LAS FUNCIONES DE PERTENENCIA DE T
%
%-----------------------------------------------------------------------------

for nT = 1:numT
vT = valueT(nT,1);
   if(vT == 1)
      if( T < NE2 )
          fpT = 1;
      elseif( ( T >= NE2 ) & ( T <= NE3) )
          fpT = 1 - ((T - NE2)/(NE3 - NE2)); 
      end

   elseif(vT == 2) 
      if( ( T < ZT2 ) & ( T >= ZT1 ) )
         fpT = (T-ZT1)/(ZT2-ZT1);
      elseif( ( T >= ZT2 ) & ( T <= ZT3 ) )
         fpT = 1 - ((T-ZT2)/(ZT3-ZT2)); 
      end

   elseif( vT == 3 )
      if( ( T < PO2 ) & ( T >= PO1 ) )
         fpT = (T-PO1)/(PO2-PO1);
      elseif( T >= PO2 )
         fpT = 1; 
      end
    end
    valueT(nT,2) = fpT;
end     


%Define el valueD
%En el valueD se utiliza la primera columna con la base de reglas
%mediante el uso de la combinacion de las primeras columnas del
%valuex y el valueP.
%En la segunda columna se coloca el minimo valor de cada una de
%las combinaciones
    

kkd = 1;
for kkx = 1:numx
   for kkP = 1:numP
      for kkT = 1:numT 
        Dx = valuex(kkx,1);
        DP = valueP(kkP,1);
        DT = valueT(kkT,1);
        valueD(kkd,1) = BaseReg(DP,Dx,DT);
        minvaluexP = min(valuex(kkx,2),valueP(kkP,2));
        valueD(kkd,2) = min(minvaluexP,valueT(kkT,2));       
        kkd = kkd + 1;
      end
   end
end

numD = kkd - 1;
dD = 0.001;

nnD = (70 - (-70)) /dD + 1;

Dbase = zeros(kD,nnD);


for nD = 1:numD
  k = 1;
  vD = valueD(nD,1); 
  minD = valueD(nD,2);
    for tD = -70:dD:70
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
            elseif( (tD > PS2) & ( tD <= PS3) )            
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
DD = -70:dD:70;
DxG = ( (dD.*maxDbase) * DD') / AreaD ;
DxG = DxG*3*2;
if( DxG > 50 )
   DxG = 50;
end
if( DxG < -50 )
    DxG = -50;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

xx(count,1) = x;
yy(count,1) = y;
ffi2(count,1) = P*PI/180;
ffi12(count,1) = T*PI/180;
ffi1(count,1) = (P+T)*PI/180;
delta(count,1) = DxG*PI/180;

Prad = Prad - (r/L2)* sin(Trad);
if( Prad > (3*PI/2) )
   Prad = Prad - 2*PI;
end
if( Prad < -PI/2 )
   Prad = Prad + 2*PI;
end
P = Prad*180/PI;

Trad = Trad + (r/L2)*sin(Trad) - r/L1*tan(PI/180*DxG);
if( Trad > (2*PI) )
   Trad = Trad - 2*PI;
end
if( Trad < -2*PI )
   Trad = Trad + 2*PI;
end
T = Trad*180/PI;

x = x + r*cos(Trad)*cos(Prad);
y = y + r*cos(Trad)*sin(Prad);

% [Dx DP DT DxG P T x y ]
% disp('Pause');
% pause;

if ( y > 100)
  break;
end

end

disp('  ');
disp('Animacion Start.   Presione una tecla');
pause;


L = 12;
A = 6;
E = 3;

figure(2);
plot(xx,yy);
title('Trayectoria X-Y');
figure(3);
subplot(3,1,1);
plot(ffi2*180/PI);   title('Ángulo Theta 2');
subplot(3,1,2);
plot(ffi12*180/PI);  title('Ángulo Theta 12');
subplot(3,1,3);
plot(delta*180/PI);  title('Ángulo del Timón Delta');


figure(6);
La = 1.5*L1;    % Ancho del trailer
Lt = L1;      % Longitud de rueda
nk = length(xx);
hf = figure(6);
set(hf,'Position',[300 50 750 620]);
axis([-50 150 -50 100]);
title('Trayectoria del Robot Truck-Trailer')
hold on;

for k = 1:15*6:nk
  x = xx(k,1);   y = yy(k,1);  
  fi1 = ffi1(k,1);  fi2 = ffi2(k,1);
  x1 = x - L2*cos(fi2);     y1 = y - L2*sin(fi2);
  x2 = x1 - L1*cos(fi1);    y2 = y1 - L1*sin(fi1); 

  xA = x2 - La/2*sin(fi1);
  yA = y2 + La/2*cos(fi1);
  xB = x2 + La/2*sin(fi1);
  yB = y2 - La/2*cos(fi1);
  xC = x1 + La/2*sin(fi1);
  yC = y1 - La/2*cos(fi1); 
  xD = x1 - La/2*sin(fi1);
  yD = y1 + La/2*cos(fi1); 
  xE = x1 - La/2*sin(fi2);
  yE = y1 + La/2*cos(fi2);
  xF = x1 + La/2*sin(fi2);
  yF = y1 - La/2*cos(fi2);
  xG = x + La/2*sin(fi2);
  yG = y - La/2*cos(fi2); 
  xH = x - La/2*sin(fi2);
  yH = y + La/2*cos(fi2); 
  xcab  = [ xA; xB; xC; xD; xA ];
  ycab  = [ yA; yB; yC; yD; yA ]; 
  xtrai = [ xE; xF; xG; xH; xE ];
  ytrai = [ yE; yF; yG; yH; yE ];  
  dfi1 = delta(k,1) + fi1 - pi/2;
  xT1 = xB - Lt/2*sin(dfi1); 
  yT1 = yB + Lt/2*cos(dfi1);
  xT2 = xB + Lt/2*sin(dfi1); 
  yT2 = yB - Lt/2*cos(dfi1);
  xT3 = xA - Lt/2*sin(dfi1); 
  yT3 = yA + Lt/2*cos(dfi1);
  xT4 = xA + Lt/2*sin(dfi1); 
  yT4 = yA - Lt/2*cos(dfi1); 
  xTB = [ xT1; xT2 ];
  yTB = [ yT1; yT2 ];
  xTA = [ xT3; xT4 ];
  yTA = [ yT3; yT4 ]; 

  plot(xcab,ycab,'-b','Linewidth',2);
  plot(xtrai,ytrai,'-r','Linewidth',2);

  pause(0.4);

  k = k + 1;  
end
grid;

