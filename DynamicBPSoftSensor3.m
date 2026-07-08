% Validacion del Soft Sensor.
% Se usa la data generada con el programa DynamicBPSoftSensor1.m 
% Se usa la red neuronal dinámica generada en el programa
% DynamicBPSoftSensor2.m

clear;
clc;
close all;

% Generating input signal
% load motordata1;    % Motor data: v1 en programa de generacion de data 
% load motordata2;
% load motordata5;     % Motor data: v5 
% load motordata6;    % Motor data: v5 con fricción
% load motordata7;    % Motor data: v5 con mayor fricción
% load motordata8;

ana = menu('Choose','Training Results','Validation with Noise and Friction');
if(ana == 1)
   load motordata1;  
   ampnoise = 0;
elseif(ana == 2)
   load motordata5;
   load motordata7;
   ampnoise = 3;
end
ny = length(volt);
ndata = ny;

load redsoftsensor;   % Neural network data (del programa DynamicBPSoftSensor2.m)

volt = volt/kfactvolt;
amp  = amp/kfactamp;

% Adding measurement noise;
 amp  = amp  + ampnoise*0.01*randn(ny,1);   % Noisy ampermeter
 volt = volt + ampnoise*0.01*randn(ny,1);   % Noisy voltmeter

   x = 0;   % Initial state. No secocncie. Igual a cero
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
      x = out_red;
   end
volt = kfactvolt*volt;
amp  = kfactamp*amp;
outputred = kfactvel*outputred;
   
dt = 0.001;
tt = 0:1:(ny-1);
tt = dt*tt';
tt1 = tt(1:ny-1,1);

figure(1);
subplot(2,1,1); 
plot(tt,volt,'-b');  title('Input Voltage');
subplot(2,1,2); 
plot(tt,amp,'-b');   title('Input Current');
xlabel('Time [sec]');
figure(2);
plot(tt1,outputred,'-r');
hold on;
plot(tt1,vel(2:ny,1),'-b');
legend('Estimated Velocity','Actual Velocity');
title('Linear Velocity')

% title('Output State Variable x1');
% xlabel('Time [sec]');




