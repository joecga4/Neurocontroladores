% Programa para generar data de entrenamiento para un Soft Sensor
% para entrenar una red neuronal dinamica del programa DynamicBPSoftSensor2.m
% La data de entrenamiento se genera con vv = v1;
% La data de validación se genera con otros vv.
% También se puede validar con data generada con otra intensidad de fricción.

clear;
clc;
close all;

R = 1.1;
L = 0.0001;
Kt = 0.0573;
Kt = 0.0815;
Kb = 0.05665;
Kb = 0.0715;
I = 4.326e-5;
I = 15.865E-5;
p = 0.0025;
m = 30.0;
c = 200;
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
    
dt = 0.0075;
t05 = 0:dt:0.5;
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

vmax = 24;
     
v1 = [  vmax*sin(2*pi*0.5*t3)
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
    
v2 = [  vmax*ones2
      -vmax*ones2
      -vmax*ones2
       vmax*ones1
       0*ones1;
      -vmax*ones1
       vmax*ones1
       vmax*ones1
       0*ones1 ];         
     
v3 = [ vmax*ones05
      -vmax*ones05
       0*ones1 ];
    
v4 = [ vmax*ones3
       vmax*ones3
       vmax*ones3 ];
   
v5 = [  vmax*sin(2*pi*2*t3)
       -1.0*vmax*ones1
       -0.5*vmax*ones1
        2*vmax*ones1
        -vmax*sin(2*pi*1*t3) ]; 
       
vv = v1;    % Entrenamiento
% vv = v2;    % Validacion
% vv = v3;    % Validacion
% vv = v4;    % Validacion
% vv = v5;    % Validacion

nv = length(vv);    
    
Fseca = 0*0.5*10;    % Se puede cambiar a 3 para mas fricción

[Ak,Bk] = c2d(A,B,dt);
[Ak,Wk] = c2d(A,Wf,dt);

x(1,1) = 0;
x(2,1) = 0;
x(3,1) = 0;

for k = 1:nv
   pos(k,1) = x(1,1);
   vel(k,1) = x(2,1);
   amp(k,1) = x(3,1);
   t(k,1) = dt*(k-1);
   u = vv(k,1);
   if( u > 24)
      u = 24;            
   elseif( u < -24 )
      u = -24;
   end      
   volt(k,1) = u;
   pot(k,1) = u*x(3,1);
   if(x(2,1) >= 0)
      Ff = Fseca*1;
   elseif(x(2,1) < 0)
      Ff = -Fseca*1;
   end   
   acelx = a22*x(2,1) + a23*x(3,1) + Wk(2,1)*Ff;
   Facelx(k,1) = m*acelx;
   Fcxp(k,1) = c*x(2,1);    
   x = Ak*x + Bk*u + Wk*Ff;
end


% save motordata8.mat volt amp vel;
save motordata1 volt amp vel;     % Data para vv = v1;
% save motordata2 volt amp vel;
%  save motordata5 volt amp vel;   % Data para vv = v5;
% save motordata6 volt amp vel;   % Dara para vv = v5 y fricción
% save motordata7 volt amp vel;   % Data para vv = v5 y fricción más alta

figure(1);
subplot(3,1,1);
plot(t,volt);  title('Voltage');
subplot(3,1,2);
plot(t,amp);   title('Current');
subplot(3,1,3);
plot(t,vel);   title('Speed');
xlabel('Time [sec]');



