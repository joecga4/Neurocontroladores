% Programa Bien
% Separacion de tres señales a partir de una señal monoaural.
% Señal z1: menor de 5Hz.
% Señal z2: entre 20Hz y 25Hz
% Señal z3: entre 35Hz y 40Hz 

clear;
clc;
close all;

ana = menu('Escoger','Entrenamiento','Validacion');
if(ana == 1)
% Generating input signal
  f1=1.1;      ph1=pi/4;      A1=1;
  f2=2.0;      ph2=-pi/3;     A2=1;
  f3=3.2;      ph3=pi/5;      A3=1;
  f4=4.1;      ph4=pi/2;      A4=1;
  f5=5.0;      ph5=-pi/8;     A5=1; 
  f6=21.5;     ph6=-pi/4;     A6=1;
  f7=22;       ph7=pi/5;      A7=1;
  f8=23.8;     ph8=-pi/8;     A8=1;
  f9=24;       ph9=pi/3;      A9=1;
  f10=25;      ph10=-pi/3;    A10=1;
  f11=35.1;    ph11=pi/4;     A11=1;
  f12=36.4;    ph12=-pi/3;    A12=1;
  f13=37.2;    ph13=pi/5;     A13=1;
  f14=38.8;    ph14=pi/2;     A14=1;
  f15=40.9;    ph15=-pi/8;    A15=1; 
elseif (ana == 2)
% Validacion
 f1=0.4;     ph1=-pi/7;     A1=1.22;
 f2=2.2;     ph2=pi/6;     A2=1.2;
 f3=3.0;     ph3=pi/4;     A3=1.5;
 f4=4.35;     ph4=-pi/9;    A4=1;
 f5=5.2;     ph5=-pi/8;    A5=0.9; 
 f6=21.6;    ph6=-pi/4;    A6=1;
 f7=22.8;    ph7=pi/5;    A7=1;
 f8=23.1;    ph8=pi/2;     A8=0.9;
 f9=24.1;    ph9=-pi/3;    A9=1;
 f10=25.8;   ph10=-pi/3;   A10=1.1;
 f11=35.2;    ph11=pi/4;  A11=1.2;
 f12=36.1;    ph12=pi/3;  A12=1;
 f13=37.9;    ph13=pi/6;   A13=1.4;
 f14=38.1;    ph14=pi/3;  A14=1;
 f15=39.2;    ph15=pi/7;  A15=1.1;
end

ti = 0; dt = 0.0025; tf = 4;
t = ti:dt:tf;    t = t';    nt = length(t);
nt1 = round(6/8*nt);    nt2 = round(7/8*nt);
n12 = nt2 - nt1 + 1;
n23 = nt - nt2 + 1;
z1 = A1*sin(2*pi*1.05*f1*t+ph1+pi/3) + A2*sin(2*pi*f2*t+ph2) + A3*sin(2*pi*f3*t+ph3) + A4*sin(2*pi*f4*t+ph4) + A5*sin(2*pi*f5*t+ph5);
z1 = 1*0.3*z1;
z2 = A6*sin(2*pi*0.98*f6*t+ph6-pi/4) + A7*sin(2*pi*f7*t+ph7) + A8*sin(2*pi*f8*t+ph8) + A9*sin(2*pi*f9*t+ph9) + A10*sin(2*pi*f10*t+ph10);
z2 = 1*0.3*z2;
z3 = A11*sin(2*pi*f11*t+ph11) + A12*sin(2*pi*f12*t+ph12) + A13*sin(2*pi*f13*t+ph13) + A14*sin(2*pi*f14*t+ph14) + A15*sin(2*pi*f15*t+ph15);
z3 = 1*0.3*z3;
z1(nt1:nt2,1) = zeros(n12,1);

uz = z1 + z2 + z3;
u = uz;
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

u = [ u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15];
% u = [ u1 u2 u3 u4 u5 u6 u7 u8 ];

z = [ z1  z2 z3 ];
% z(:,1) = zeros(nu,1); 
ndata = nu; 
dataoutesc = z;

% Number of neurons (input, hidden and output layers)
ne = 18;    % No bias
nm = 200;   % nm = 200
ns = 3;

% Intializing coefficients v, w, sigmoid center and slope 
v = 0.02*randn(ne,nm);
w = 0.02*randn(nm,ns);
c = zeros(nm,1);
a = ones(nm,1);

load dbpseparation3v;     

% Introducing learning parameters
eta  = input('Introduce learning rate [v w]: ');
etac = input('Introduce learning rate [c: sigmoid center]: ');
etaa = input('Introduce learning rate [a: sigmoid slope]: ');
errormax = input('Introduce maximum value of error function (percentage %) : ');
errormax = errormax/100;
contmax = input('Introduce number of iteration steps [ > 2 ]: ');

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
   dydw_tt = zeros(nm,ns,ns);        
   dydv_tt = zeros(ne,nm,ns);
   dydc_tt = zeros(nm,1,ns);
   dyda_tt = zeros(nm,1,ns);  
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
       
      dydw_ss = zeros(nm,ns,ns);
      for bi = 1:ns
          dydw_ss(:,bi,bi) = n; 
      end
      for bi = 1:ns
          dydv_ss(:,:,bi) = in_red*w(:,bi)'*dndm; 
      end
      for bi = 1:ns
          dydc_ss(:,:,bi) = w(:,bi) .* ((n.*n-1)./(2.0.*a));
      end
      for bi = 1:ns
          dyda_ss(:,:,bi) = w(:,bi) .* ((n.*n-1).*(m-c)./(2*a.*a));
      end

      jacob = w'*dndm*(v(1:ne-1,:))';

      for bi = 1:ns
        for bj = 1:ns
           dydw_tt(:,:,bi) =  dydw_tt(:,:,bi) + jacob(bi,bj).*dydw_tt(:,:,bj);
        end
        dydw_tt(:,:,bi) = dydw_tt(:,:,bi) + dydw_ss(:,:,bi);
      end

      for bi = 1:ns
        for bj = 1:ns
           dydv_tt(:,:,bi) = dydv_tt(:,:,bi) + jacob(bi,bj).*dydv_tt(:,:,bj);
        end
        dydv_tt(:,:,bi) = dydv_tt(:,:,bi) + dydv_ss(:,:,bi);
      end

      for bi = 1:ns
        for bj = 1:ns
           dydc_tt(:,:,bi) = dydc_tt(:,:,bi) + jacob(bi,bj).*dydc_tt(:,:,bj);
        end
        dydc_tt(:,:,bi) = dydc_tt(:,:,bi) + dydc_ss(:,:,bi);
      end

      for bi = 1:ns
        for bj = 1:ns
           dyda_tt(:,:,bi) = dyda_tt(:,:,bi) + jacob(bi,bj).*dyda_tt(:,:,bj);
        end
        dyda_tt(:,:,bi) = dyda_tt(:,:,bi) + dyda_ss(:,:,bi);
      end

      out_des = dataoutesc(k+1,:);
      out_des = out_des';
      er = (out_red - out_des);
      erJ = (out_red - out_des).^1;
      qq = 1;    % qq = 0 >> solo se mide la primera variable
      qr = 1;

     for bi = 1:ns
         dJdw_t = dJdw_t + erJ(bi,1).*dydw_tt(:,:,bi); 
         dJdv_t = dJdv_t + erJ(bi,1).*dydv_tt(:,:,bi);
         dJdc_t = dJdc_t + erJ(bi,1).*dydc_tt(:,:,bi); 
         dJda_t = dJda_t + erJ(bi,1).*dyda_tt(:,:,bi); 
     end
      ersum2 = ersum2 + er.^2;
      x = out_red;     % output turns to be input for the next step
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

figure(1);
title('Total Error Function');
plot(errorreltotal*100);
figure(2);
title('Error Function per Output');
plot(errorrel*100);
figure(3);
title('Desired Output (red) and Network Output (blue)');
plot(z(2:nu,1),'-r');
hold on;
plot(output(:,1),'-b');
figure(4);
title('Desired Output (red) and Network Output (blue)');
plot(z(2:nu,2),'-r');
hold on;
plot(output(:,2),'-b');
figure(5);
title('Desired Output (red) and Network Output (blue)');
plot(z(2:nu,3),'-r');
hold on;
plot(output(:,3),'-b');
figure(6);
plot(uz);
title('Original Mixed Signal');


% Saving: number of input, hidden and output neurons,  coefficients v and
% w, center c, and slope c
% save dbpseparation16u ne nm ns v w c a;
save dbpseparation3v ne nm ns v w c a;   

