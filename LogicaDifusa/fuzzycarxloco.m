%  El angulo del timon delta esta entre 50 y -50 grados

clear;
clc;
PI = 3.141592;
close all;


xini = input('Introduce coordenada inicial  x : ');
yini = input('Introduce coordenada inicial  y : ');
Pini = input('Introduce inclinacion inicial P : ');
xdeseado = input('Introducir coordenada final de x : ');

%Define cantidad de divisiones de la variables

kX = 7;
kP = 7;
kD = 7;

%Define los rangos de cada una de las divisiones
%de X. (X viene a ser el valor de la coordenada en eje X)
%LE LC CE RC RI

Xrango= [-50   25
         22  38
         35  49
         40  60
         51  65
         62  78
         75  150];  %Rango con traslapes

%Vertices de las particiones de X
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
subplot(3,1,1);
plot(Xx,Xy,'r');
title('Funciones de Pertenencia');
ylabel('X');
grid;



%Define los rangos de cada una de las divisiones
%de P. (P viene a ser el angulo de inclinacion
%de Vehiculo con respecto a la horizontal) osea phi
%RB RU RV VE LV LU LB


Prango = [ -95  10
           -10  55
            45  88
            70 110
            92 135
           125 190
           170 275 ];  %Rango con traslapes
%Verticesss...
RB1 = Prango(1,1);
RB2 = -45;
RB3 = Prango(1,2);
RU1 = Prango(2,1);
RU2 = 22.5;
RU3 = Prango(2,2);
RV1 = Prango(3,1);
RV2 = 66.5;
RV3 = Prango(3,2);
VE1 = Prango(4,1);
VE2 = 90;
VE3 = Prango(4,2);
LV1 = Prango(5,1);
LV2 = 113.5;
LV3 = Prango(5,2);
LU1 = Prango(6,1);
LU2 = 157.5;
LU3 = Prango(6,2);
LB1 = Prango(7,1);
LB2 = 222.5;
LB3 = Prango(7,2);

Phx = [ RB1 RB2 RB3 RU1 RU2 RU3 RV1 RV2 RV3 VE1 VE2 VE3 LV1 LV2 LV3 LU1 LU2 LU3 LB1 LB2 LB3 ];
Phy = [ 0   1   0   0   1   0   0   1   0   0   1   0   0   1   0   0   1   0   0   1   0   ];

figure(1);
subplot(3,1,2);
plot(Phx,Phy,'r');   
ylabel('Phi');
grid;



%Define los rangos de cada una de las divisiones
%de D. (D viene a ser el angulo de giro
%de las ruedas con respecto al vehiculo)
%NB NM NS ZE PS PM PB 

Drango= [ -60  -15
          -25   -6
          -12   -1
           -5    5
            1   12
            6   25
           15   60 ];

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
subplot(3,1,3);
plot(Dex,Dey,'r');                      
ylabel('Delta');
grid;



%Base de reglas
%El numero dentro de la matriz te indica la  
%region del delta en la cual estamos trabajando
%comenzando del NB=1 al PB=7


BaseReg = [ 1  1  1  4  7  7  7 
            1  1  1  4  7  7  7
            1  7  7  4  7  7  1
            7  7  7  4  7  7  1
            1  7  7  4  7  7  1
            1  1  1  4  7  7  7
            1  1  1  4  7  7  7 ];  


UU = [ NB0 NM2 NS2 ZE2 PS2 PM2 PB3 ]';


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
P = Pini;
Prad = P*(PI/180);
y = yini;
r = 0.5;


countmax = 600;
%busca en q rango esta x
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

%busca en q rango esta phi
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
          fpP = (P-LB1)/(LB2-LB1); %funcion de pertenencia de Phi
      elseif( ( P >= LB2 ) & ( P <= LB3) )
          fpP = 1 - ((P-LB2)/(LB3-LB2)); 
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
                           


kkd = 1;
for kkx = 1:numx
   for kkP = 1:numP
      Dx = valuex(kkx,1);
      DP = valueP(kkP,1);
      valueD(kkd,1) = BaseReg(DP,Dx);
      valueD(kkd,2) = min(valuex(kkx,2),valueP(kkP,2));
      kkd = kkd + 1;
   end
end
numD = kkd - 1;


dD = 0.1;

nnD = (50 - (-50)) /dD + 1;

Dbase = zeros(kD,nnD);


for nD = 1:numD
  k = 1;
  vD = valueD(nD,1); 
  minD = valueD(nD,2);
    for tD = -50:dD:50
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
DD = -50:dD:50;
DxG = ( (dD.*maxDbase) * DD') / AreaD ;
DxG = DxG*1.5;
if( DxG > 50 )
   DxG = 50;
end
if( DxG < -50 )
    DxG = -50;
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

xx(count,1) = x;
yy(count,1) = y;
PP(count,1) = P;
dd(count,1) = DxG;

L=12;
Prad = Prad - (r/L)* tan((PI/180)*(DxG));

%P = P + DxG;
if( Prad > (3*PI/2) )
   Prad = Prad - 2*PI;
end
if( Prad < -PI/2 )
   Prad = Prad + 2*PI;
end
P = Prad*180/PI;

x = x + r * cos(Prad);
y = y + r * sin(Prad);


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
hold on;
axis([ -50 150 -50 100 ]);
xp = [ 0  100  100     0   0 ]';
yp = [ 0    0  100   100   0 ]';
zp = [ xdeseado  xdeseado ]';
wp = [ 0    100 ]';
plot(xp,yp,'r',zp,wp,'--c');
title('Trayectoria de Robot Movil');

xcm5  =  [ 1-5*A-5*E+xdeseado-50       1-5*E-4*A+xdeseado-50     1-5*E-4*A+xdeseado-50     1-5*A-5*E+xdeseado-xnuevo      1-5*A-5*E+xdeseado-xnuevo ]';
ycm5  =  [          99-L                              99-L                            99                            99                 99-L   ]';

xcm5a0 = [ 1+0.25-5*A-5*E+xdeseado-50       1-0.25-5*E-4*A+xdeseado-50    1-0.25-5*E-4*A+xdeseado-50      1+0.25-5*A-5*E+xdeseado-50     1+0.25-5*A-5*E+xdeseado-50 ]';
ycm5a0 = [     99-L+0.25           99-L+0.25         99-0.25              99-0.25            99-L+0.25   ]';
xcm5a1 = [ 1+0.5-5*A-5*E+xdeseado-50      1-0.5-5*E-4*A+xdeseado-50    1-0.5-5*E-4*A+xdeseado-50      1+0.5-5*A-5*E+xdeseado-50     1+0.5-5*A-5*E+xdeseado-50 ]';
ycm5a1 = [          99-L+0.5          99-L+0.5           99-0.5              99-0.5          99-L+0.5   ]';
xcm5a2 = [ 1+0.75-5*A-5*E+xdeseado-50      1-0.75-5*E-4*A+xdeseado-50    1-0.75-5*E-4*A+xdeseado-50      1+0.75-5*A-5*E+xdeseado-50     1+0.75-5*A-5*E+xdeseado-50 ]';
ycm5a2 = [      99-L+0.75         99-L+0.75           99-0.75              99-0.75           99-L+0.75   ]';

xcm4  =  [ 1-4*A-4*E+xdeseado-50       1-4*E-3*A+xdeseado-50     1-4*E-3*A+xdeseado-50     1-4*A-4*E+xdeseado-50      1-4*A-4*E+xdeseado-50 ]';
ycm4  =  [    99-L           99-L            99           99             99-L   ]';

xcm4a0 = [ 1+0.25-4*A-4*E+xdeseado-50       1-0.25-4*E-3*A+xdeseado-50    1-0.25-4*E-3*A+xdeseado-50      1+0.25-4*A-4*E+xdeseado-50     1+0.25-4*A-4*E+xdeseado-50 ]';
ycm4a0 = [     99-L+0.25           99-L+0.25          99-0.25             99-0.25           99-L+0.25    ]';
xcm4a1 = [ 1+0.5-4*A-4*E+xdeseado-50      1-0.5-4*E-3*A+xdeseado-50    1-0.5-4*E-3*A+xdeseado-50      1+0.5-4*A-4*E+xdeseado-50     1+0.5-4*A-4*E+xdeseado-50 ]';
ycm4a1 = [      99-L+0.5           99-L+0.5          99-0.5              99-0.5           99-L+0.5  ]';
xcm4a2 = [ 1+0.75-4*A-4*E+xdeseado-50      1-0.75-4*E-3*A+xdeseado-50    1-0.75-4*E-3*A+xdeseado-50      1+0.75-4*A-4*E+xdeseado-50     1+0.75-4*A-4*E+xdeseado-50 ]';
ycm4a2 = [      99-L+0.75          99-L+0.75          99-0.75              99-0.75           99-L+0.75   ]';

xcm3  =  [ 1-3*A-3*E+xdeseado-50       1-3*E-2*A+xdeseado-50     1-3*E-2*A+xdeseado-50     1-3*A-3*E+xdeseado-50      1-3*A-3*E+xdeseado-50 ]';
ycm3  =  [    99-L            99-L          99            99             99-L   ]';

xcm3a0 = [ 1+0.25-3*A-3*E+xdeseado-50       1-0.25-3*E-2*A+xdeseado-50    1-0.25-3*E-2*A+xdeseado-50      1+0.25-3*A-3*E+xdeseado-50     1+0.25-3*A-3*E+xdeseado-50 ]';
ycm3a0 = [     99-L+0.25            99-L+0.25          99-0.25             99-0.25           99-L+0.25   ]';
xcm3a1 = [ 1+0.5-3*A-3*E+xdeseado-50      1-0.5-3*E-2*A+xdeseado-50    1-0.5-3*E-2*A+xdeseado-50      1+0.5-3*A-3*E+xdeseado-50     1+0.5-3*A-3*E+xdeseado-50 ]';
ycm3a1 = [      99-L+0.5          99-L+0.5          99-0.5               99-0.5          99-L+0.5   ]';
xcm3a2 = [ 1+0.75-3*A-3*E+xdeseado-50      1-0.75-3*E-2*A+xdeseado-50    1-0.75-3*E-2*A+xdeseado-50      1+0.75-3*A-3*E+xdeseado-50     1+0.75-3*A-3*E+xdeseado-50 ]';
ycm3a2 = [      99-L+0.75         99-L+0.75          99-0.75              99-0.75            99-L+0.75   ]';

xcm2  =  [ 1-2*A-2*E+xdeseado-50       1-2*E-A+xdeseado-50     1-2*E-A+xdeseado-50     1-2*A-2*E+xdeseado-50      1-2*A-2*E+xdeseado-50 ]';
ycm2  =  [    99-L           99-L         99           99            99-L   ]';

xcm2a0 = [ 1+0.25-2*A-2*E+xdeseado-50       1-0.25-2*E-A+xdeseado-50    1-0.25-2*E-A+xdeseado-50      1+0.25-2*A-2*E+xdeseado-50     1+0.25-2*A-2*E+xdeseado-50 ]';
ycm2a0 = [     99-L+0.25           99-L+0.25         99-0.25           99-0.25           99-L+0.25   ]';
xcm2a1 = [ 1+0.5-2*A-2*E+xdeseado-50      1-0.5-2*E-A+xdeseado-50    1-0.5-2*E-A+xdeseado-50      1+0.5-2*A-2*E+xdeseado-50     1+0.5-2*A-2*E+xdeseado-50 ]';
ycm2a1 = [      99-L+0.5          99-L+0.5        99-0.5             99-0.5          99-L+0.5   ]';
xcm2a2 = [ 1+0.75-2*A-2*E+xdeseado-50      1-0.75-2*E-A+xdeseado-50    1-0.75-2*E-A+xdeseado-50      1+0.75-2*A-2*E+xdeseado-50     1+0.75-2*A-2*E+xdeseado-50 ]';
ycm2a2 = [      99-L+0.75         99-L+0.75         99-0.75              99-0.75         99-L+0.75   ]';

xcm1  =  [ 1-A-E+xdeseado-50       1-E+xdeseado-50     1-E+xdeseado-50     1-A-E+xdeseado-50      1-A-E+xdeseado-50 ]';
ycm1  =  [  99-L       99-L     99       99        99-L ]';

xcm1a0 = [ 1+0.25-A-E+xdeseado-50       1-0.25-E+xdeseado-50    1-0.25-E+xdeseado-50      1+0.25-A-E+xdeseado-50     1+0.25-A-E+xdeseado-50 ]';
ycm1a0 = [   99-L+0.25       99-L+0.25    99-0.25        99-0.25       99-L+0.25 ]';
xcm1a1 = [ 1+0.5-A-E+xdeseado-50      1-0.5-E+xdeseado-50    1-0.5-E+xdeseado-50      1+0.5-A-E+xdeseado-50     1+0.5-A-E+xdeseado-50 ]';
ycm1a1 = [    99-L+0.5      99-L+0.5    99-0.5        99-0.5       99-L+0.5 ]';
xcm1a2 = [ 1+0.75-A-E+xdeseado-50      1-0.75-E+xdeseado-50    1-0.75-E+xdeseado-50      1+0.75-A-E+xdeseado-50     1+0.75-A-E+xdeseado-50 ]';
ycm1a2 = [   99-L+0.75       99-L+0.75   99-0.75         99-0.75       99-L+0.75 ]';

xc1  =  [ 1+xdeseado-50       A+1+xdeseado-50     A+1+xdeseado-50     1+xdeseado-50      1+xdeseado-50 ]';
yc1  =  [ 99-L    99-L     99     99   99-L]';

xc1a0 = [ 1+0.25+xdeseado-50       A+1-0.25+xdeseado-50    A+1-0.25+xdeseado-50      1+0.25+xdeseado-50     1+0.25+xdeseado-50 ]';
yc1a0 = [ 99-L+0.25    99-L+0.25     99-0.25     99-0.25   99-L+0.25]';
xc1a1 = [ 1+0.5+xdeseado-50      A+1-0.5+xdeseado-50    A+1-0.5+xdeseado-50      1+0.5+xdeseado-50     1+0.5+xdeseado-50 ]';
yc1a1 = [ 99-L+0.5    99-L+0.5     99-0.5     99-0.5   99-L+0.5]';
xc1a2 = [ 1+0.75+xdeseado-50      A+1-0.75+xdeseado-50    A+1-0.75+xdeseado-50      1+0.75+xdeseado-50     1+0.75+xdeseado-50 ]';
yc1a2 = [ 99-L+0.75    99-L+0.75     99-0.75     99-0.75   99-L+0.75]';

xc2  =  [ 1+A+E+xdeseado-50   1+2*A+E+xdeseado-50    1+2*A+E+xdeseado-50   1+A+E+xdeseado-50    1+A+E+xdeseado-50 ]';
yc2  =  [  99-L     99-L        99       99      99-L ]';

xc2a0 = [ 1+A+E+0.25+xdeseado-50   1+2*A+E-0.25+xdeseado-50   1+2*A+E-0.25+xdeseado-50   1+A+E+0.25+xdeseado-50   1+A+E+0.25+xdeseado-50 ]';
yc2a0 = [  99-L+0.25     99-L+0.25        99-0.25      99-0.25     99-L+0.25 ]';
xc2a1 = [ 1+A+E+0.5+xdeseado-50   1+2*A+E-0.5+xdeseado-50    1+2*A+E-0.5+xdeseado-50   1+A+E+0.5+xdeseado-50    1+A+E+0.5+xdeseado-50 ]';
yc2a1 = [  99-L+0.5     99-L+0.5       99-0.5        99-0.5      99-L+0.5 ]';
xc2a2 = [ 1+A+E+0.75+xdeseado-50   1+2*A+E-0.75+xdeseado-50   1+2*A+E-0.75+xdeseado-50   1+A+E+0.75+xdeseado-50    1+A+E+0.75+xdeseado-50 ]';
yc2a2 = [  99-L+0.75     99-L+0.75       99-0.75      99-0.75      99-L+0.75  ]';

xc3  =  [ 1+2*A+2*E+xdeseado-50   1+3*A+2*E+xdeseado-50    1+3*A+2*E+xdeseado-50   1+2*A+2*E+xdeseado-50    1+2*A+2*E+xdeseado-50 ]';
yc3  =  [    99-L         99-L         99           99          99-L  ]';

xc3a0 = [ 1+2*A+2*E+0.25+xdeseado-50   1+3*A+2*E-0.25+xdeseado-50    1+3*A+2*E-0.25+xdeseado-50   1+2*A+2*E+0.25+xdeseado-50    1+2*A+2*E+0.25+xdeseado-50 ]';
yc3a0 = [   99-L+0.25        99-L+0.25          99-0.25           99-0.25           99-L+0.25  ]';
xc3a1 = [ 1+2*A+2*E+0.5+xdeseado-50   1+3*A+2*E-0.5+xdeseado-50    1+3*A+2*E-0.5+xdeseado-50   1+2*A+2*E+0.5+xdeseado-50    1+2*A+2*E+0.5+xdeseado-50 ]';
yc3a1 = [    99-L+0.5        99-L+0.5          99-0.5           99-0.5          99-L+0.5  ]';
xc3a2 = [ 1+2*A+2*E+0.75+xdeseado-50   1+3*A+2*E-0.75+xdeseado-50    1+3*A+2*E-0.75+xdeseado-50   1+2*A+2*E+0.75+xdeseado-50    1+2*A+2*E+0.75+xdeseado-50 ]';
yc3a2 = [    99-L+0.75        99-L+0.75          99-0.75          99-0.75           99-L+0.75  ]';

xc4  =  [ 1+3*A+3*E+xdeseado-50   1+4*A+3*E+xdeseado-50    1+4*A+3*E+xdeseado-50   1+3*A+3*E+xdeseado-50    1+3*A+3*E+xdeseado-50 ]';
yc4  =  [    99-L         99-L         99           99          99-L  ]';

xc4a0 = [ 1+3*A+3*E+0.25+xdeseado-50   1+4*A+3*E-0.25+xdeseado-50    1+4*A+3*E-0.25+xdeseado-50   1+3*A+3*E+0.25+xdeseado-50    1+3*A+3*E+0.25+xdeseado-50 ]';
yc4a0 = [   99-L+0.25        99-L+0.25          99-0.25           99-0.25            99-L+0.25 ]';
xc4a1 = [ 1+3*A+3*E+0.5+xdeseado-50   1+4*A+3*E-0.5+xdeseado-50    1+4*A+3*E-0.5+xdeseado-50   1+3*A+3*E+0.5+xdeseado-50    1+3*A+3*E+0.5+xdeseado-50 ]';
yc4a1 = [   99-L+0.5         99-L+0.5          99-0.5          99-0.5           99-L+0.5  ]';
xc4a2 = [ 1+3*A+3*E+0.75+xdeseado-50   1+4*A+3*E-0.75+xdeseado-50    1+4*A+3*E-0.75+xdeseado-50   1+3*A+3*E+0.75+xdeseado-50    1+3*A+3*E+0.75+xdeseado-50 ]';
yc4a2 = [   99-L+0.75        99-L+0.75          99-0.75           99-0.75            99-L+0.75 ]';

xc5  =  [ 1+4*A+4*E+xdeseado-50   1+5*A+4*E+xdeseado-50    1+5*A+4*E+xdeseado-50   1+4*A+4*E+xdeseado-50    1+4*A+4*E+xdeseado-50 ]';
yc5  =  [    99-L         99-L         99           99          99-L  ]';

xc5a0 = [ 1+4*A+4*E+0.25+xdeseado-50   1+5*A+4*E-0.25+xdeseado-50    1+5*A+4*E-0.25+xdeseado-50   1+4*A+4*E+0.25+xdeseado-50    1+4*A+4*E+0.25+xdeseado-50 ]';
yc5a0 = [   99-L+0.25        99-L+0.25          99-0.25           99-0.25            99-L+0.25 ]';
xc5a1 = [ 1+4*A+4*E+0.5+xdeseado-50   1+5*A+4*E-0.5+xdeseado-50    1+5*A+4*E-0.5+xdeseado-50   1+4*A+4*E+0.5+xdeseado-50    1+4*A+4*E+0.5+xdeseado-50 ]';
yc5a1 = [   99-L+0.5        99-L+0.5          99-0.5           99-0.5            99-L+0.5 ]';
xc5a2 = [ 1+4*A+4*E+0.75+xdeseado-50   1+5*A+4*E-0.75+xdeseado-50    1+5*A+4*E-0.75+xdeseado-50   1+4*A+4*E+0.75+xdeseado-50    1+4*A+4*E+0.75+xdeseado-50 ]';
yc5a2 = [   99-L+0.75        99-L+0.75          99-0.75           99-0.75            99-L+0.75 ]';

xc6  =  [ 3+6*A+6*E+xdeseado-50   3+7*A+6*E+xdeseado-50    3+7*A+6*E+xdeseado-50   3+6*A+6*E+xdeseado-50    3+6*A+6*E+xdeseado-50 ]';
yc6  =  [    99-L         99-L         99           99          99-L  ]';

xc6a0 = [ 3+6*A+6*E+0.25+xdeseado-50   3+7*A+6*E-0.5+xdeseado-50    3+7*A+6*E-0.25+xdeseado-50   3+6*A+6*E+0.25+xdeseado-50    3+6*A+6*E+0.25+xdeseado-50 ]';
yc6a0 = [           99-L+0.25                         99-L+0.25                             99-0.25                        99-0.25                        99-L+0.25            ]';
xc6a1 = [ 3+6*A+6*E+0.5+xdeseado-50   3+7*A+6*E-0.5+xdeseado-50    3+7*A+6*E-0.5+xdeseado-50   3+6*A+6*E+0.5+xdeseado-50    3+6*A+6*E+0.5+xdeseado-50 ]';
yc6a1 = [       99-L+0.5                     99-L+0.5                     99-0.5                   99-0.5                  99-L+0.5         ]';
xc6a2 = [ 3+6*A+6*E+0.75+xdeseado-50   3+7*A+6*E-0.75+xdeseado-50    3+7*A+6*E-0.75+xdeseado-50   3+6*A+6*E+0.75+xdeseado-50    3+6*A+6*E+0.75+xdeseado-50 ]';
yc6a2 = [       99-L+0.75                    99-L+0.75                    99-0.75                    99-0.75            99-L+0.75 ]';

xc7  =  [ 3+7*A+7*E+xdeseado-50   3+8*A+7*E+xdeseado-50    3+8*A+7*E+xdeseado-50   3+7*A+7*E+xdeseado-50    3+7*A+7*E+xdeseado-50 ]';
yc7  =  [    99-L         99-L         99           99          99-L  ]';																																																				

xc7a0 = [ 3+7*A+7*E+0.25+xdeseado-50   3+8*A+7*E-0.25+xdeseado-50    3+8*A+7*E-0.25+xdeseado-50   3+7*A+7*E+0.25+xdeseado-50    3+7*A+7*E+0.25+xdeseado-50 ]';
yc7a0 = [   99-L+0.25        99-L+0.25          99-0.25           99-0.25            99-L+0.25 ]';

xc7a1 = [ 3+7*A+7*E+0.5+xdeseado-50   3+8*A+7*E-0.5+xdeseado-50    3+8*A+7*E-0.5+xdeseado-50   3+7*A+7*E+0.5+xdeseado-50    3+7*A+7*E+0.5+xdeseado-50 ]';
yc7a1 = [   99-L+0.5        99-L+0.5          99-0.5           99-0.5            99-L+0.5 ]';
xc7a2 = [ 3+7*A+7*E+0.75+xdeseado-50   3+8*A+7*E-0.75+xdeseado-50    3+8*A+7*E-0.75+xdeseado-50   3+7*A+7*E+0.75+xdeseado-50    3+7*A+7*E+0.75+xdeseado-50 ]';
yc7a2 = [   99-L+0.75        99-L+0.75          99-0.75           99-0.75            99-L+0.75 ]';

xc8  =  [ 3+8*A+8*E+xdeseado-50   3+9*A+8*E+xdeseado-50    3+9*A+8*E+xdeseado-50   3+8*A+8*E+xdeseado-50    3+8*A+8*E+xdeseado-50 ]';
yc8  =  [    99-L         99-L         99           99          99-L  ]';

xc8a0 = [ 3+8*A+8*E+0.25+xdeseado-50   3+9*A+8*E-0.25+xdeseado-50    3+9*A+8*E-0.25+xdeseado-50   3+8*A+8*E+0.25+xdeseado-50    3+8*A+8*E+0.25+xdeseado-50 ]';
yc8a0 = [   99-L+0.25        99-L+0.25          99-0.25           99-0.25            99-L+0.25 ]';
xc8a1 = [ 3+8*A+8*E+0.5+xdeseado-50   3+9*A+8*E-0.5+xdeseado-50    3+9*A+8*E-0.5+xdeseado-50   3+8*A+8*E+0.5+xdeseado-50    3+8*A+8*E+0.5+xdeseado-50 ]';
yc8a1 = [   99-L+0.5        99-L+0.5          99-0.5           99-0.5            99-L+0.5 ]';
xc8a2 = [ 3+8*A+8*E+0.75+xdeseado-50   3+9*A+8*E-0.75+xdeseado-50    3+9*A+8*E-0.75+xdeseado-50   3+8*A+8*E+0.75+xdeseado-50    3+8*A+8*E+0.75+xdeseado-50 ]';
yc8a2 = [   99-L+0.75        99-L+0.75          99-0.75           99-0.75            99-L+0.75 ]';

xc9  =  [ 3+9*A+9*E+xdeseado-50   3+10*A+9*E+xdeseado-50    3+10*A+9*E+xdeseado-50   3+9*A+9*E+xdeseado-50    3+9*A+9*E+xdeseado-50 ]';
yc9  =  [    99-L         99-L         99            99           99-L  ]';							

xc9a0 = [ 3+9*A+9*E+0.25+xdeseado-50   3+10*A+9*E-0.25+xdeseado-50    3+10*A+9*E-0.25+xdeseado-50   3+9*A+9*E+0.25+xdeseado-50    3+9*A+9*E+0.25+xdeseado-50 ]';
yc9a0 = [   99-L+0.25        99-L+0.25            99-0.25           99-0.25            99-L+0.25 ]';
xc9a1 = [ 3+9*A+9*E+0.5+xdeseado-50   3+10*A+9*E-0.5+xdeseado-50    3+10*A+9*E-0.5+xdeseado-50   3+9*A+9*E+0.5+xdeseado-50    3+9*A+9*E+0.5+xdeseado-50 ]';
yc9a1 = [   99-L+0.5        99-L+0.5           99-0.5            99-0.5            99-L+0.5 ]';
xc9a2 = [ 3+9*A+9*E+0.75+xdeseado-50   3+10*A+9*E-0.75+xdeseado-50    3+10*A+9*E-0.75+xdeseado-50   3+9*A+9*E+0.75+xdeseado-50    3+9*A+9*E+0.75+xdeseado-50 ]';
yc9a2 = [   99-L+0.75        99-L+0.75           99-0.75            99-0.75            99-L+0.75 ]';

xc10 =  [ 3+10*A+10*E+xdeseado-50   3+11*A+10*E+xdeseado-50    3+11*A+10*E+xdeseado-50   3+10*A+10*E+xdeseado-50    3+10*A+10*E+xdeseado-50 ]';
yc10 =  [     99-L          99-L            99            99            99-L    ]';

xc10a0 = [ 3+10*A+10*E+0.25+xdeseado-50   3+11*A+10*E-0.25+xdeseado-50    3+11*A+10*E-0.25+xdeseado-50   3+10*A+10*E+0.25+xdeseado-50    3+10*A+10*E+0.25+xdeseado-50 ]';
yc10a0 = [    99-L+0.25         99-L+0.25              99-0.25             99-0.25             99-L+0.25  ]';
xc10a1 = [ 3+10*A+10*E+0.5+xdeseado-50   3+11*A+10*E-0.5+xdeseado-50    3+11*A+10*E-0.5+xdeseado-50   3+10*A+10*E+0.5+xdeseado-50    3+10*A+10*E+0.5+xdeseado-50 ]';
yc10a1 = [    99-L+0.5          99-L+0.5             99-0.5              99-0.5             99-L+0.5 ]';
xc10a2 = [ 3+10*A+10*E+0.75+xdeseado-50   3+11*A+10*E-0.75+xdeseado-50    3+11*A+10*E-0.75+xdeseado-50   3+10*A+10*E+0.75+xdeseado-50    3+10*A+10*E+0.75+xdeseado-50 ]';
yc10a2 = [    99-L+0.75         99-L+0.75            99-0.75             99-0.75               99-L+0.75  ]';

xc11 =  [ 3+11*A+11*E+xdeseado-50   3+12*A+11*E+xdeseado-50    3+12*A+11*E+xdeseado-50   3+11*A+11*E+xdeseado-50    3+11*A+11*E+xdeseado-50 ]';
yc11 =  [     99-L          99-L            99             99             99-L  ]';

xc11a0 = [ 3+11*A+11*E+0.25+xdeseado-50   3+12*A+11*E-0.25+xdeseado-50    3+12*A+11*E-0.25+xdeseado-50   3+11*A+11*E+0.25+xdeseado-50    3+11*A+11*E+0.25+xdeseado-50 ]';
yc11a0 = [   99-L+0.25          99-L+0.25             99-0.25              99-0.25             99-L+0.25  ]';
xc11a1 = [ 3+11*A+11*E+0.5+xdeseado-50   3+12*A+11*E-0.5+xdeseado-50    3+12*A+11*E-0.5+xdeseado-50   3+11*A+11*E+0.5+xdeseado-50    3+11*A+11*E+0.5+xdeseado-50 ]';
yc11a1 = [    99-L+0.5          99-L+0.5             99-0.5             99-0.5              99-L+0.5 ]';
xc11a2 = [ 3+11*A+11*E+0.75+xdeseado-50   3+12*A+11*E-0.75+xdeseado-50    3+12*A+11*E-0.75+xdeseado-50   3+11*A+11*E+0.75+xdeseado-50    3+11*A+11*E+0.75+xdeseado-50 ]';
yc11a2 = [   99-L+0.75          99-L+0.75            99-0.75             99-0.75              99-L+0.75   ]';

xc12 =  [ 3+12*A+12*E+xdeseado-50   3+13*A+12*E+xdeseado-50    3+13*A+12*E+xdeseado-50   3+12*A+12*E+xdeseado-50    3+12*A+12*E+xdeseado-50 ]';
yc12 =  [     99-L          99-L           99             99             99-L   ]';

xc12a0 = [ 3+12*A+12*E+0.25+xdeseado-50   3+13*A+12*E-0.25+xdeseado-50    3+13*A+12*E-0.25+xdeseado-50   3+12*A+12*E+0.25+xdeseado-50    3+12*A+12*E+0.25+xdeseado-50 ]';
yc12a0 = [   99-L+0.25          99-L+0.25            99-0.25             99-0.25             99-L+0.25    ]';
xc12a1 = [ 3+12*A+12*E+0.5+xdeseado-50   3+13*A+12*E-0.5+xdeseado-50    3+13*A+12*E-0.5+xdeseado-50   3+12*A+12*E+0.5+xdeseado-50    3+12*A+12*E+0.5+xdeseado-50 ]';
yc12a1 = [   99-L+0.5           99-L+0.5            99-0.5             99-0.5            99-L+0.5    ]';
xc12a2 = [ 3+12*A+12*E+0.75+xdeseado-50   3+13*A+12*E-0.75+xdeseado-50    3+13*A+12*E-0.75+xdeseado-50   3+12*A+12*E+0.75+xdeseado-50    3+12*A+12*E+0.75+xdeseado-50 ]';
yc12a2 = [   99-L+0.75          99-L+0.75            99-0.75            99-0.75              99-L+0.75    ]';

xc13 =  [ 3+13*A+13*E+xdeseado-50   3+14*A+13*E+xdeseado-50    3+14*A+13*E+xdeseado-50   3+13*A+13*E+xdeseado-50    3+13*A+13*E+xdeseado-50 ]';
yc13 =  [     99-L          99-L           99             99            99-L    ]';

xc13a0 = [ 3+13*A+13*E+0.25+xdeseado-50   3+14*A+13*E-0.25+xdeseado-50    3+14*A+13*E-0.25+xdeseado-50   3+13*A+13*E+0.25+xdeseado-50    3+13*A+13*E+0.25+xdeseado-50 ]';
yc13a0 = [   99-L+0.25           99-L+0.25             99-0.25            99-0.25            99-L+0.25    ]';
xc13a1 = [ 3+13*A+13*E+0.5+xdeseado-50   3+14*A+13*E-0.5+xdeseado-50    3+14*A+13*E-0.5+xdeseado-50   3+13*A+13*E+0.5+xdeseado-50    3+13*A+13*E+0.5+xdeseado-50 ]';
yc13a1 = [   99-L+0.5            99-L+0.5             99-0.5            99-0.5            99-L+0.5   ]';
xc13a2 = [ 3+13*A+13*E+0.75+xdeseado-50   3+14*A+13*E-0.75+xdeseado-50    3+14*A+13*E-0.75+xdeseado-50   3+13*A+13*E+0.75+xdeseado-50    3+13*A+13*E+0.75+xdeseado-50 ]';
yc13a2 = [   99-L+0.75           99-L+0.75             99-0.75             99-0.75            99-L+0.75   ]';

xc14 =  [ 3+14*A+14*E+xdeseado-50   3+15*A+14*E+xdeseado-50    3+15*A+14*E+xdeseado-50   3+14*A+14*E+xdeseado-50    3+14*A+14*E+xdeseado-50 ]';
yc14 =  [     99-L          99-L            99            99             99-L   ]';

xc14a0 = [ 3+14*A+14*E+0.25+xdeseado-50   3+15*A+14*E-0.25+xdeseado-50    3+15*A+14*E-0.25+xdeseado-50   3+14*A+14*E+0.25+xdeseado-50    3+14*A+14*E+0.25+xdeseado-50 ]';
yc14a0 = [   99-L+0.25           99-L+0.25             99-0.25            99-0.25            99-L+0.25    ]';
xc14a1 = [ 3+14*A+14*E+0.5+xdeseado-50   3+15*A+14*E-0.5+xdeseado-50    3+15*A+14*E-0.5+xdeseado-50   3+14*A+14*E+0.5+xdeseado-50    2+14*A+14*E+0.5+xdeseado-50 ]';
yc14a1 = [   99-L+0.5           99-L+0.5              99-0.5            99-0.5            99-L+0.5   ]';
xc14a2 = [ 3+14*A+14*E+0.75+xdeseado-50   3+15*A+14*E-0.75+xdeseado-50    3+15*A+14*E-0.75+xdeseado-50   3+14*A+14*E+0.75+xdeseado-50    3+14*A+14*E+0.75+xdeseado-50 ]';
yc14a2 = [   99-L+0.75           99-L+0.75             99-0.75             99-0.75            99-L+0.75   ]';

xc15 =  [ 3+15*A+15*E+xdeseado-50   3+16*A+15*E+xdeseado-50    3+16*A+15*E+xdeseado-50   3+15*A+15*E+xdeseado-50    3+15*A+15*E+xdeseado-50 ]';
yc15 =  [    99-L           99-L            99             99            99-L   ]';

xc15a0 = [ 3+15*A+15*E+0.25+xdeseado-50   3+16*A+15*E-0.25+xdeseado-50    3+16*A+15*E-0.25+xdeseado-50   3+15*A+15*E+0.25+xdeseado-50    3+15*A+15*E+0.25+xdeseado-50 ]';
yc15a0 = [   99-L+0.25           99-L+0.25             99-0.25            99-0.25             99-L+0.25   ]';
xc15a1 = [ 3+15*A+15*E+0.5+xdeseado-50   3+16*A+15*E-0.5+xdeseado-50    3+16*A+15*E-0.5+xdeseado-50   3+15*A+15*E+0.5+xdeseado-50    3+15*A+15*E+0.5+xdeseado-50 ]';
yc15a1 = [   99-L+0.5            99-L+0.5             99-0.5             99-0.5             99-L+0.5 ]';
xc15a2 = [ 3+15*A+15*E+0.75+xdeseado-50   3+16*A+15*E-0.75+xdeseado-50    3+16*A+15*E-0.75+xdeseado-50   3+15*A+15*E+0.75+xdeseado-50    3+15*A+15*E+0.75+xdeseado-50 ]';
yc15a2 = [   99-L+0.75          99-L+0.75            99-0.75             99-0.75            99-L+0.75     ]';


plot(xcm5,ycm5,'b',xcm5a0,ycm5a0,'b',xcm5a1,ycm5a1,'b',xcm5a2,ycm5a2,'b');   %
plot(xcm4,ycm4,'b',xcm4a0,ycm4a0,'b',xcm4a1,ycm4a1,'b',xcm4a2,ycm4a2,'b');   %
plot(xcm3,ycm3,'b',xcm3a0,ycm3a0,'b',xcm3a1,ycm3a1,'b',xcm3a2,ycm3a2,'b');   %         EXTRAS
plot(xcm2,ycm2,'b',xcm2a0,ycm2a0,'b',xcm2a1,ycm2a1,'b',xcm2a2,ycm2a2,'b');   %        NEGATIVOS
plot(xcm1,ycm1,'b',xcm1a0,ycm1a0,'b',xcm1a1,ycm1a1,'b',xcm1a2,ycm1a2,'b');   %
plot(xc1,yc1,'b',xc1a0,yc1a0,'b',xc1a1,yc1a1,'b',xc1a2,yc1a2,'b'); 
plot(xc2,yc2,'b',xc2a0,yc2a0,'b',xc2a1,yc2a1,'b',xc2a2,yc2a2,'b'); 
plot(xc3,yc3,'b',xc3a0,yc3a0,'b',xc3a1,yc3a1,'b',xc3a2,yc3a2,'b'); 
plot(xc4,yc4,'b',xc4a0,yc4a0,'b',xc4a1,yc4a1,'b',xc4a2,yc4a2,'b'); 
plot(xc5,yc5,'b',xc5a0,yc5a0,'b',xc5a1,yc5a1,'b',xc5a2,yc5a2,'b');
plot(xc6,yc6,'b',xc6a0,yc6a0,'b',xc6a1,yc6a1,'b',xc6a2,yc6a2,'b');
plot(xc7,yc7,'b',xc7a0,yc7a0,'b',xc7a1,yc7a1,'b',xc7a2,yc7a2,'b');
plot(xc8,yc8,'b',xc8a0,yc8a0,'b',xc8a1,yc8a1,'b',xc8a2,yc8a2,'b');
plot(xc9,yc9,'b',xc9a0,yc9a0,'b',xc9a1,yc9a1,'b',xc9a2,yc9a2,'b');
plot(xc10,yc10,'b',xc10a0,yc10a0,'b',xc10a1,yc10a1,'b',xc10a2,yc10a2,'b');
plot(xc11,yc11,'b',xc11a0,yc11a0,'b',xc11a1,yc11a1,'b',xc11a2,yc11a2,'b');   %
plot(xc12,yc12,'b',xc12a0,yc12a0,'b',xc12a1,yc12a1,'b',xc12a2,yc12a2,'b');   %
plot(xc13,yc13,'b',xc13a0,yc13a0,'b',xc13a1,yc13a1,'b',xc13a2,yc13a2,'b');   %         EXTRAS
plot(xc14,yc14,'b',xc14a0,yc14a0,'b',xc14a1,yc14a1,'b',xc14a2,yc14a2,'b');   %        POSITIVOS
plot(xc15,yc15,'b',xc15a0,yc15a0,'b',xc15a1,yc15a1,'b',xc15a2,yc15a2,'b');   %


countmax = count;
for count = 1:3:countmax
   xz = xx(count,1);
   yz = yy(count,1);
   Pz = (PI/180) * PP(count,1);
   x1 = xz + (A/2)*sin(Pz);
   y1 = yz - (A/2)*cos(Pz);
   x2 = xz - (A/2)*sin(Pz);
   y2 = yz + (A/2)*cos(Pz);
   xF = xz - (L/2)*cos(Pz);
   yF = yz - (L/2)*sin(Pz);
   x3 = xF - (A/2)*sin(Pz);
   y3 = yF + (A/2)*cos(Pz);
   x4 = xF + (A/2)*sin(Pz);
   y4 = yF - (A/2)*cos(Pz);
   xc = [ x1  x2  x3  x4  x1 ]';
   yc = [ y1  y2  y3  y4  y1 ]';
   plot(xc,yc,'r'); 
   pause(1/4);
end

figure(3);
plot(dd);
grid;
title('Angulo del timon [grados]');




