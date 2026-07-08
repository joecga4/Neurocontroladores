% Programa para entrenar una red dinámica como Soft Sensor para estimar
% la velocidad de un motor DC.
% Se usa la data generada en el programa DynamicBPSoftSensor1.m: motordata1.mat. 
% Escalamiento simple. 

clear;
clc;
close all;

% Generating input signal
load motordata1;
kfactvolt = max(abs(volt));
kfactamp  = max(abs(amp));
kfactvel  = max(abs(vel));
volt = volt/kfactvolt;
amp  = amp/kfactamp;
vel  = vel/kfactvel;

y = vel;
ny = length(y);
ndata = ny;
out_des = y;

% Number of neurons (input, hidden and output layers)
ne = 3;     % No bias
nm = 50;   % nm = 10
ns = 1;

% Intializing coefficients v, w, sigmoid center and slope 
v = 0.2*randn(ne,nm);
w = 0.2*randn(nm,ns);
c = zeros(nm,1);
a = ones(nm,1);
load redsoftsensor;

% Introducing learning parameters
eta  = input('Introduce learning rate [v w] [0.1]: ');
etac = input('Introduce learning rate [c: sigmoid center [0.08]: ');
etaa = input('Introduce learning rate [a: sigmoid slope [0.08]: ');
errormax = input('Introduce maximum value of error function (percentage %) [1, 2, 3] : ');
errormax = errormax/100;
contmax = input('Introduce number of iteration steps [> 2]: ');

% Training
outsum2 = sum(out_des.^2);
outsum2 = outsum2';
outsum2total = sum(outsum2);
cont = 1;
erreltotal = 1;
   

while( (erreltotal > errormax) & (cont < contmax) ) 
   ersum2 = zeros(ns,1);
   dJdw = 0;
   dJdv = 0;
   dJda = 0;
   dJdc = 0;
   dy1dw_t = zeros(nm,ns);        
   dy1dv_t = zeros(ne,nm);
   dy1dc_t = zeros(nm,1);
   dy1da_t = zeros(nm,1);
   dJdw_t  = zeros(nm,ns);
   dJdv_t  = zeros(ne,nm); 
   dJdc_t  = zeros(nm,1);
   dJda_t  = zeros(nm,1); 
   
   x = out_des(1,1);   % Initial state
   for k = 1:ndata-1
      in_red = [ x
                 volt(k,1)
                 amp(k,1) ];    %bias
      m = v'*in_red;
      n = 2.0./(1 + exp(-(m-c)./a)) - 1; 
%      n = 1.0./(1+exp(-m));
%      n = exp(-m.*m);
%      n = m;        % Lineal
      out_red = w'*n;
      outputred(k,1) = out_red;
%      dndm = diag((1 - n.*n)./(2*a));  
      dndm = (1 - n.*n)./(2*a);
%      dndm = -2*m.*n;
      %      dndm = n.*(1-n);
%      dndm = diag(ones(nm,1));      % Lineal
      dy1dw_s = n; 
      dy1dv_s = [ in_red(1,1).*(w.*dndm)'
                  in_red(2,1).*(w.*dndm)' 
                  in_red(3,1).*(w.*dndm)' ];
      dy1dc_s = w.* ((n.*n-1)./(2.0.*a));
      dy1da_s = w.* ((n.*n-1).*(m-c)./(2*a.*a));
      jacob = (w.*dndm)'*(v(1:ne-2,:))';
      dy1dw_t  = dy1dw_s  + jacob.*dy1dw_t;   
      dy1dv_t  = dy1dv_s  + jacob.*dy1dv_t;   
      dy1dc_t  = dy1dc_s  + jacob.*dy1dc_t;   
      dy1da_t  = dy1da_s  + jacob.*dy1da_t;   
      er = out_red - out_des(k+1,1);

      dJdw_t  = dJdw_t  + er.*dy1dw_t;
      dJdv_t  = dJdv_t  + er.*dy1dv_t;
      dJdc_t  = dJdc_t  + er.*dy1dc_t;
      dJda_t  = dJda_t  + er.*dy1da_t;
      ersum2 = ersum2 + er.^2;
      x = out_red;     % The output turns to be input in the next step
  end
      dJdw_t = dJdw_t/ndata;
      dJdv_t = dJdv_t/ndata;  
      dJdc_t = dJdc_t/ndata;
      dJda_t = dJda_t/ndata;
      w = w - eta*dJdw_t;
      v = v - eta*dJdv_t;
      c = c - etac*dJdc_t;
      a = a - etaa*dJda_t;
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
dt = 0.01;
tt = 0:1:(ny-1);
tt = dt*tt';
tt1 = tt(1:ny-1,1);

figure(1);
title('Total Error Function');
plot(errorreltotal*100);
figure(2);
title('Error Function per Output');
plot(errorrel*100);
figure(3);
subplot(2,1,1); 
plot(tt,volt);   title('Scale Input Voltage');
subplot(2,1,2); 
plot(tt,amp);   title('Scale Input Current');
xlabel('Time [sec]');
figure(4);

plot(tt,y,'-r');
hold on;
plot(tt1,outputred,'-b');
xlabel('Time [sec]');
title('Desired Output (red) and Network Output (blue)');

% Saving network learned parameters
save redsoftsensor ne nm ns v w a c kfactvolt kfactamp kfactvel;


