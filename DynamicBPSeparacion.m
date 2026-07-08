% Programa Bien
% Separacion de dos señales a partir de una señal monoaural.
% Señal z1: menor de 5Hz.
% Señal z2: entre 25Hz y 30Hz

clear;
clc;
close all;

ana = menu('Escoger','Entrenamiento - Alta y Baja Frecuencia','Valida - Alta y Baja Frecuencia','Valida - Baja Frecuencia','Valida - Alta Frecuencia');
if(ana == 1)
% Generating input signal - Baja y Alta Frecuencia
f1=1.1;      ph1=pi/4;      A1=1;
f2=2.0;      ph2=-pi/3;     A2=1;
f3=3.2;      ph3=pi/5;      A3=1;
f4=4.1;      ph4=pi/2;      A4=1;
f5=5.0;      ph5=-pi/8;     A5=1; 
f6=25.5;     ph6=-pi/4;     A6=1;
f7=26;       ph7=pi/5;      A7=1;
f8=27.8;     ph8=-pi/8;     A8=1;
f9=29;       ph9=pi/3;      A9=1;
f10=30;      ph10=-pi/3;    A10=1;
elseif(ana == 2)
% Validacion - Baja y Alta Frecuencia
 f1=1.3;     ph1=-pi/5;      A1=1.4;
 f2=2.9;     ph2=pi/3;       A2=0.85;
 f3=3.2;     ph3=-pi/2;      A3=1.5;
 f4=4.1;     ph4=pi/4;       A4=0.95;
 f5=5.5;     ph5=-pi/9;      A5=1.1; 
 f6=25.8;    ph6=-pi/4;      A6=0.9;
 f7=26.9;    ph7=-pi/5;      A7=1.2;
 f8=27.8;    ph8=pi/8;       A8=1.3;
 f9=31.0;    ph9=-pi/3;      A9=0.8;
 f10=32;     ph10=-pi/3;     A10=1.2;
elseif(ana == 3)
% Validacion - Sólo Baja Frecuencia
 f1=1.3;     ph1=-pi/5;      A1=1.4;
 f2=2.9;     ph2=pi/3;       A2=0.85;
 f3=3.2;     ph3=-pi/2;      A3=1.5;
 f4=4.1;     ph4=pi/4;       A4=0.95;
 f5=5.5;     ph5=-pi/9;      A5=1.1; 
 f6=25.8;    ph6=-pi/4;      A6=0.0;
 f7=26.9;    ph7=-pi/5;      A7=0.0;
 f8=27.8;    ph8=pi/8;       A8=0.0;
 f9=31.0;    ph9=-pi/3;      A9=0.0;
 f10=32;     ph10=-pi/3;     A10=0.0;
elseif(ana == 4)
% Validacion - Sólo Alta Frecuencia 
 f1=1.3;     ph1=-pi/5;      A1=0.0;
 f2=2.9;     ph2=pi/3;       A2=0.0;
 f3=3.2;     ph3=-pi/2;      A3=0.0;
 f4=4.1;     ph4=pi/4;       A4=0.0;
 f5=5.5;     ph5=-pi/9;      A5=0.0; 
 f6=25.8;    ph6=-pi/4;      A6=0.9;
 f7=26.9;    ph7=-pi/5;      A7=1.2;
 f8=27.8;    ph8=pi/8;       A8=1.3;
 f9=31.0;    ph9=-pi/3;      A9=0.8;
 f10=32;     ph10=-pi/3;     A10=1.2;
end
 
ti = 0; dt = 0.0025; tf = 4;
t = ti:dt:tf;    t = t';    nt = length(t);
nt1 = round(6/8*nt);    nt2 = round(7/8*nt);
n12 = nt2 - nt1 + 1;
n23 = nt - nt2 + 1;
z1 = A1*sin(2*pi*f1*t+ph1) + A2*sin(2*pi*f2*t+ph2) + A3*sin(2*pi*f3*t+ph3) + A4*sin(2*pi*f4*t+ph4) + A5*sin(2*pi*f5*t+ph5);
z1 = 1*0.5*z1;
z2 = A6*sin(2*pi*f6*t+ph6) + A7*sin(2*pi*f7*t+ph7) + A8*sin(2*pi*f8*t+ph8) + A9*sin(2*pi*f9*t+ph9) + A10*sin(2*pi*f10*t+ph10);
z2 = 1*0.5*z2;
z1(nt1:nt2,1) = zeros(n12,1);
z2(nt2:nt,1)  = zeros(n23,1);

u = z1 + z2;
uz = u;
nu = length(u);
u1 = u;
u2(1,1) = 0;
u2(2:nu,1) = u(1:nu-1,1);
u3(1,1) = 0;
u3(2:nu,1) = u2(1:nu-1,1);
u4(1,1) = 0;
u4(2:nu,1) = u3(1:nu-1,1);
u5(1,1) = 0;
u5(2:nu,1) = u4(1:nu-1,1);
u6(1,1) = 0;
u6(2:nu,1) = u5(1:nu-1,1);
u7(1,1) = 0;
u7(2:nu,1) = u6(1:nu-1,1);
u8(1,1) = 0;
u8(2:nu,1) = u7(1:nu-1,1);
u9(1,1) = 0;
u9(2:nu,1) = u8(1:nu-1,1);
u10(1,1) = 0;
u10(2:nu,1) = u9(1:nu-1,1);
u11(1,1) = 0;
u11(2:nu,1) = u10(1:nu-1,1);
u12(1,1) = 0;
u12(2:nu,1) = u11(1:nu-1,1);
u13(1,1) = 0;
u13(2:nu,1) = u12(1:nu-1,1);
u14(1,1) = 0;
u14(2:nu,1) = u13(1:nu-1,1);
u15(1,1) = 0;
u15(2:nu,1) = u14(1:nu-1,1);
u16(1,1) = 0;
u16(2:nu,1) = u15(1:nu-1,1);
u17(1,1) = 0;
u17(2:nu,1) = u16(1:nu-1,1);
u18(1,1) = 0;
u18(2:nu,1) = u17(1:nu-1,1);
u19(1,1) = 0;
u19(2:nu,1) = u18(1:nu-1,1);
u20(1,1) = 0;
u20(2:nu,1) = u19(1:nu-1,1);
u21(1,1) = 0;
u21(2:nu,1) = u20(1:nu-1,1);
u22(1,1) = 0;
u22(2:nu,1) = u21(1:nu-1,1);
u23(1,1) = 0;
u23(2:nu,1) = u22(1:nu-1,1);
u24(1,1) = 0;
u24(2:nu,1) = u23(1:nu-1,1);
u25(1,1) = 0;
u25(2:nu,1) = u24(1:nu-1,1);
u26(1,1) = 0;
u26(2:nu,1) = u25(1:nu-1,1);
u27(1,1) = 0;
u27(2:nu,1) = u26(1:nu-1,1);
u28(1,1) = 0;
u28(2:nu,1) = u27(1:nu-1,1);
u29(1,1) = 0;
u29(2:nu,1) = u28(1:nu-1,1);
u30(1,1) = 0;
u30(2:nu,1) = u29(1:nu-1,1);

u = [ u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20 u21 u22 u23 u24 u25 u26 u27 u28 u29 u30 ];

z = [ z1  z2 ];
% z(:,1) = zeros(nu,1); 
ndata = nu; 
dataoutesc = z;

% Number of neurons (input, hidden and output layers)
ne = 32;    % No bias
nm = 150;   % nm = 10
ns = 2;

% Intializing coefficients v, w, sigmoid center and slope 
v = 0.1*randn(ne,nm);
w = 0.1*randn(nm,ns);
c = zeros(nm,1);
a = ones(nm,1);

load dbpseparation20u;       % 150 intermedias. Demoró 4 horas

% Introducing learning parameters
eta  = input('Introduce learning rate [v w]: ');
etac = input('Introduce learning rate [c: sigmoid center]: ');
etaa = input('Introduce learning rate [a: sigmoid slope]: ');
errormax = input('Introduce maximum value of error function (percentage %) : ');
errormax = errormax/100;
contmax = input('Introduce number of iteration steps: ');

% Training
outsum2 = sum(dataoutesc.^2);
outsum2 = outsum2';
outsum2total = sum(outsum2);
cont = 1;
erreltotal = 1;
   dw_old = 0;  
   dv_old = 0;
   da_old = 0;
   dc_old = 0;
   

while( (erreltotal > errormax) & (cont < contmax) ) 
   ersum2 = zeros(ns,1);
   dJdw = 0;
   dJdv = 0;
   dJda = 0;
   dJdc = 0;
   dy1dw_t = zeros(nm,ns);        
   dy2dw_t = zeros(nm,ns);
   dy1dv_t = zeros(ne,nm);
   dy2dv_t = zeros(ne,nm);
   dy1dc_t = zeros(nm,1);
   dy2dc_t = zeros(nm,1);
   dy1da_t = zeros(nm,1);
   dy2da_t = zeros(nm,1);  
   dJdw_t  = zeros(nm,ns);
   dJdv_t  = zeros(ne,nm); 
   dJdc_t  = zeros(nm,1);
   dJda_t  = zeros(nm,1); 
   
   x = dataoutesc(1,:);   % Initial state
   x = x';
   for k = 1:ndata-1
      in_red = [ x
                 (u(k,:))' ];
      m = v'*in_red;
       n = 2.0./(1 + exp(-(m-c)./a)) - 1;    
%      n = m;        % Lineal
      out_red = w'*n;
      output(k,:) = out_red';
      dndm = diag((1 - n.*n)./(2*a));  
%      dndm = diag(ones(nm,1));      % Lineal
      dy1dw_s = [ n   zeros(nm,1) ]; 
      dy2dw_s = [ zeros(nm,1)   n ]; 
      dy1dv_s = in_red*w(:,1)'*dndm;
      dy2dv_s = in_red*w(:,2)'*dndm;
      dy1dc_s = w(:,1) .* ((n.*n-1)./(2.0.*a));
      dy2dc_s = w(:,2) .* ((n.*n-1)./(2.0.*a));
      dy1da_s = w(:,1) .* ((n.*n-1).*(m-c)./(2*a.*a));
      dy2da_s = w(:,2) .* ((n.*n-1).*(m-c)./(2*a.*a));
      jacob = w'*dndm*(v(1:ne-1,:))';
      dy1dw_t = dy1dw_s + jacob(1,1).*dy1dw_t + jacob(1,2).*dy2dw_t;   
      dy2dw_t = dy2dw_s + jacob(2,1).*dy1dw_t + jacob(2,2).*dy2dw_t;   
      dy1dv_t  = dy1dv_s  + jacob(1,1).*dy1dv_t  + jacob(1,2).*dy2dv_t;   
      dy2dv_t  = dy2dv_s  + jacob(2,1).*dy1dv_t  + jacob(2,2).*dy2dv_t;  
      dy1dc_t  = dy1dc_s  + jacob(1,1).*dy1dc_t  + jacob(1,2).*dy2dc_t;   
      dy2dc_t  = dy2dc_s  + jacob(2,1).*dy1dc_t  + jacob(2,2).*dy2dc_t;
      dy1da_t  = dy1da_s  + jacob(1,1).*dy1da_t  + jacob(1,2).*dy2da_t;   
      dy2da_t  = dy2da_s  + jacob(2,1).*dy1da_t  + jacob(2,2).*dy2da_t;

      out_des = dataoutesc(k+1,:);
      out_des = out_des';
      er = (out_red - out_des);
      erJ = (out_red - out_des).^1;
      %      erJ = (abs(out_red - out_des)).^0.5 .* sign( out_red-out_des );  

      q1 = 4;    q2 = 1;       % Both variables are measured
      dJdw_t = dJdw_t + q1*erJ(1,1).*dy1dw_t + q2*erJ(2,1).*dy2dw_t + (erJ(1,1)+erJ(2,1))*(dy1dw_t+dy2dw_t);  % Se minimiza z1, z2 y (z1+z2) 
      dJdv_t  = dJdv_t  + q1*erJ(1,1).*dy1dv_t  + q2*erJ(2,1).*dy2dv_t + (erJ(1,1)+erJ(2,1))*(dy1dv_t+dy2dv_t);  
      dJdc_t  = dJdc_t  + q1*erJ(1,1).*dy1dc_t  + q2*erJ(2,1).*dy2dc_t + (erJ(1,1)+erJ(2,1))*(dy1dc_t+dy2dc_t); 
      dJda_t  = dJda_t  + q1*erJ(1,1).*dy1da_t  + q2*erJ(2,1).*dy2da_t + (erJ(1,1)+erJ(2,1))*(dy1da_t+dy2da_t);
      ersum2 = ersum2 + er.^2;
      x = out_red;     % The output turns to be input in the next step
  end
      dJdw_t = dJdw_t/ndata;
      dJdv_t = dJdv_t/ndata;  
      dJdc_t = dJdc_t/ndata;
      dJda_t = dJda_t/ndata;
      dw = dJdw_t;
      dv = dJdv_t;
      dc = dJdc_t;
      da = dJda_t;
      w = w - eta*dw;
      v = v - eta*dv;
      c = c - etac*dc;
      a = a - etaa*da;
      dw_old = dw;
      dv_old = dv;
  ersum2total = sum(ersum2);
  cont = cont + 1;
  if ( rem(cont,1) == 0 )
      errorrel(cont/1,:) = sqrt(ersum2'./outsum2');
      errorreltotal(cont/1,1) = sqrt(ersum2total/outsum2total);
      erreltotal = errorreltotal(cont/1,1);
      cont;
      erreltotal    
  end
end  
nt = length(u);
dt = 0.01;
tt = 0:1:(nt-1);
tt = dt*tt';
tt1 = tt(1:nt-1,1);

ner = length(errorreltotal);
errorreltotal = errorreltotal(2:ner,1);
errorrel = errorrel(2:ner,1);

figure(1);
title('Total Error Function');
plot(errorreltotal*100);
figure(2);
title('Error Function per Output');
plot(errorrel*100);

figure(3);
plot(tt1,z(2:nt,1),'-r');
hold on;
plot(tt1,output(:,1),'-b');
title('Separated Signal 1 - Desired Output (red) and Network Output (blue)');
xlabel('Time [sec]');

figure(4);
plot(tt1,z(2:nt,2),'-r');
hold on;
plot(tt1,output(:,2),'-b');
xlabel('Time [sec]');
title('Separated Signal 2 - Desired Output (red) and Network Output (blue)');

figure(5);
plot(tt,uz,'-b');
xlabel('Time [sec]');
title('Input Mixed Signal');
% Saving: number of input, hidden and output neurons,  coefficients v and
% w, center c, and slope c
% save dbpseparation16u ne nm ns v w c a;
% save dbpseparation19u ne nm ns v w c a;   
save dbpseparation20u ne nm ns v w c a; 


