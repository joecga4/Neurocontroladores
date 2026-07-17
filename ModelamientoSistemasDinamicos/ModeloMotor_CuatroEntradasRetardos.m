% Entrenamiento batch
% Solo 4 entradas: v, x(k), x(k-1), x(k-2)

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
    
v4 = [  vmax*sin(2*pi*2*t3)
       -1.0*vmax*ones1
       -0.5*vmax*ones1
         vmax*ones1
        -vmax*sin(2*pi*1*t3) ]; 
       
vv = v1;    % Entrenamiento
vv = v2;    % Validacion 
vv = v3;    % Validacion
vv = v4;    % Validacion

nv = length(vv);    
    
Fseca = 0*100;   % 0 - 1

[Ak,Bk] = c2d(A,B,dt);
[Ak,Wk] = c2d(A,Wf,dt);

x(1,1) = 0.1;
x(2,1) = -0.1;
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
   x = Ak*x + Bk*u + Wk*Ff;
end

nruido = 0;   %1
pos = pos + nruido*0.0012*randn(nv,1);


figure(1);
plot(t,pos);
title('Posición m');
figure(2);
plot(t,vel);
title('Velocidad m/s');
figure(3);
plot(t,volt);
title('Voltaje v');
figure(4);
plot(t,amp);
title('Corriente A');

x1 = volt;
x2(1,1) = 0;
x2(2:nv,1) = pos(1:nv-1,1);
x3(1,1) = 0;
x3(2:nv,1) = x2(1:nv-1,1);
x4(1,1) = 0;
x4(2:nv,1) = x3(1:nv-1,1);

xb = [ x1  x2  x3  x4 ];
yb = pos;
nx = length(xb);

ne = 4;
nm = 20;
ns = 1;

% Escalamiento
factx = max(abs(xb));
facty = max(abs(yb));

bias = input('Bias:  SI = 1 : ');

xesc(:,1) = xb(:,1)./factx(1,1);
xesc(:,2) = xb(:,2)./factx(1,2);
xesc(:,3) = xb(:,3)./factx(1,3);
xesc(:,4) = xb(:,4)./factx(1,4);
yesc(:,1) = yb(:,1)./facty(1,1);

if(bias == 1)
      ne = ne + 1;
      xesc = [ xesc ones(nx,1) ];   
end

v = 0.25*randn(ne,nm);
w = 0.25*randn(nm,ns);
a = ones(nm,1);

load motorred1;    % Sin bias. Incluye pesos y factores de escalamiento
% load motorred2;    % Con bias

eta = input('eta pesos : ');
niter = input('Introducir numero de iteraciones : ');

for iter = 1:niter
JJ = 0;
dJdw = 0;
dJdv = 0;
for k = 1:nx   
  in = (xesc(k,:))';
  m = v'*in;
  n = 2.0./(1+exp(-m./a)) - 1;
%  n = exp(-m.^2);
%  n = m; 
  out = w'*n;
  y(k,:) = out';
  er = out - (yesc(k,:))';
  error(k,:) = er';
  JJ = JJ + 0.5*er'*er;
  dndm = (1 - n.*n)/2;
%  dndm = -2.0*(n.*m);
%  dndm = ones(nm,1);
  dJdw = dJdw + n*er';
  dJdv = dJdv + in * (dndm.*(w*er))';
end
w = w - eta*dJdw/nx;
v = v - eta*dJdv/nx;
JJ
J(iter,1) = JJ;
end

figure(8);
plot(y(:,1),'-r');
hold on;
plot(yesc(:,1),'-b');
title('Salida y1');

figure(9);
plot(J);
title('Funcion de costo J');

save motorred1 v w bias factx facty;
% save motorred2 v w bias factx facty;




