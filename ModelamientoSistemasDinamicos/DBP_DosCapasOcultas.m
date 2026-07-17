% Program for training a dynamic neural network for modeling a nonlinear system 
% using the DBP algorithm. 
% The system has 1 input and 2 output signals.


clear;
clc;
close all;

% Generating input signal
st = [ 1 1 1 1 1 1 ];
zt = [ 0 0 0 0 0 0 ];
u = [st st zt -st -st -0.2*st -0.4*st -0.6*st zt st 0.8*st 0.5*st st 0.2*st zt -st -st -st zt zt zt st st -st -st -st zt zt 0.25*st st 0.75*st st zt zt zt zt zt zt zt -st -st st st -st -st st 0.1*st 0.1*st st -st st -0.3*st 0.3*st st -st -st st st -st -st st st st -st -st -st st st st -st -st -st st st st st -st -st -st -st st st st st -st -st -st -st st st st st st -0.1*st -0.3*st -0.5*st -0.7*st -0.9*st 0.9*st 0.7*st 0.5*st 0.3*st 0.1*st -st -st -st -st -st st st st st st ];
% u = [st st zt -st -st -st -st -st zt st st st st st zt -st -st -st zt zt zt st st -st -st -st zt zt st st st st zt zt zt zt zt zt zt -st -st st st -st -st st st st st -st st -st st st -st -st st st -st -st st st st -st -st -st st st st -st -st -st st st st st -st -st -st -st st st st st -st -st -st -st st st st st st -st -st -st -st -st st st st st st -st -st -st -st -st st st st st st ];
% u = [-0.5*st -0.5*st zt 0.75*st 0.5*st st -0.3*st 0.3*st zt -st -st -0.6*st -0.4*st -0.2*st zt st st st zt zt zt st st st 0.25*st st zt zt -st -0.1*st -0.2*st -st zt zt ];

% nu = 700;
% nt = 0:1:(nu-1);
% fre = 3*0.0025;   % menor de 0.01  a  0.0025
% u = 1*sin(2*pi*fre*nt);

u = u';
nu = length(u);

% Generating outputs signals from the system to be modeled
z1(1,1) = 0.1;
z2(1,1) = 0.2;
for k = 1:nu
    z1(k+1,1) = 0.3*z1(k,1) - 0.4*z2(k,1);
    z2(k+1,1) = 0.4*z2(k,1) + 1*0.1*z1(k,1)*u(k,1) + 0.5*u(k,1); 
end
z1 = z1(1:nu) + 0.0*0.05*randn(nu,1) ;
z2 = z2(1:nu) + 0.0*0.05*randn(nu,1) ;
z = [ z1  z2 ];
% z(:,1) = zeros(nu,1); 
ndata = nu;
dataoutesc = z;

% Number of neurons (input, hidden and output layers)
ne = 3;    % No bias
nm = 12;   % nm = 10
np = 10;
ns = 2;

% Intializing coefficients ru, v, w, sigmoid center and slope 
ur = 0.1*randn(ne,nm); 
v = 0.1*randn(nm,np);
w = 0.1*randn(np,ns);
c1 = zeros(nm,1);
a1 = ones(nm,1);
c2 = zeros(np,1);
a2 = ones(np,1);

load reddbp2int;

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
   dr_old = 0;
%   da_old = 0;
%   dc_old = 0;
   
while( (erreltotal > errormax) & (cont < contmax) ) 
   ersum2 = zeros(ns,1);
   dJdw = 0;
   dJdv = 0;
%    dJda = 0;
%    dJdc = 0;
   dy1dw_t = zeros(np,ns);        
   dy2dw_t = zeros(np,ns);
   dy1dv_t = zeros(nm,np);
   dy2dv_t = zeros(nm,np);
   dy1du_t = zeros(ne,nm);
   dy2du_t = zeros(ne,nm);
 
   dy1dc2_t = zeros(np,1);
   dy2dc2_t = zeros(np,1);
   dy1da2_t = zeros(np,1);
   dy2da2_t = zeros(np,1);  
   dJdw_t  = zeros(np,ns);
   dJdv_t  = zeros(nm,np); 
   dJdu_t = zeros(ne,nm);
   dJdc2_t  = zeros(np,1);
   dJda2_t  = zeros(np,1); 
   
   x = dataoutesc(1,:);   % Initial state
   x = x';
   for k = 1:ndata-1
      in_red = [ x
                 u(k,1) ];
      m = ur'*in_red;
      n = 2.0./(1 + exp(-(m-c1)./a1)) - 1;    
      p = v'*n;
      q = 2.0./(1 + exp(-(p-c2)./a2)) - 1;    
      out_red = w'*q;
      outputesc(k,:) = out_red';
      dndm = diag((1 - n.*n)./(2*a1));  
      dqdp = diag((1 - q.*q)./(2*a2));  
      
      
      %      dndm = diag(ones(nm,1));      % Lineal
     dy1dw_s = [ q   zeros(np,1) ];
     dy2dw_s = [zeros(np,1)    q ]; 
     dy1dv_s = n*w(:,1)'*dqdp;
     dy2dv_s = n*w(:,2)'*dqdp;     
     dy1du_s = in_red*w(:,1)'*dqdp*v'*dndm;
     dy2du_s = in_red*w(:,2)'*dqdp*v'*dndm;
      
      dy1dc2_s = w(:,1) .* ((q.*q-1)./(2.0.*a2));
      dy2dc2_s = w(:,2) .* ((q.*q-1)./(2.0.*a2));
      dy1da2_s = w(:,1) .* ((q.*q-1).*(p-c2)./(2*a2.*a2));
      dy2da2_s = w(:,2) .* ((q.*q-1).*(p-c2)./(2*a2.*a2));

      jacob = w'*dqdp*v'*dndm*(ur(1:ne-1,:))';
      dy1dw_t = dy1dw_s + jacob(1,1).*dy1dw_t + jacob(1,2).*dy2dw_t;   
      dy2dw_t = dy2dw_s + jacob(2,1).*dy1dw_t + jacob(2,2).*dy2dw_t;   
      dy1dv_t  = dy1dv_s  + jacob(1,1).*dy1dv_t  + jacob(1,2).*dy2dv_t;   
      dy2dv_t  = dy2dv_s  + jacob(2,1).*dy1dv_t  + jacob(2,2).*dy2dv_t;  
      dy1du_t  = dy1du_s  + jacob(1,1).*dy1du_t  + jacob(1,2).*dy2du_t;   
      dy2du_t  = dy2du_s  + jacob(2,1).*dy1du_t  + jacob(2,2).*dy2du_t;  
      
      dy1dc2_t  = dy1dc2_s  + jacob(1,1).*dy1dc2_t  + jacob(1,2).*dy2dc2_t;   
      dy2dc2_t  = dy2dc2_s  + jacob(2,1).*dy1dc2_t  + jacob(2,2).*dy2dc2_t;
      dy1da2_t  = dy1da2_s  + jacob(1,1).*dy1da2_t  + jacob(1,2).*dy2da2_t;   
      dy2da2_t  = dy2da2_s  + jacob(2,1).*dy1da2_t  + jacob(2,2).*dy2da2_t;

      out_des = dataoutesc(k+1,:);
      out_des = out_des';
      er = (out_red - out_des);
      erJ = (out_red - out_des).^1;
      %      erJ = (abs(out_red - out_des)).^0.5 .* sign( out_red-out_des );  

      q1 = 1;    q2 = 1;       % Both variables are measured
      dJdw_t = dJdw_t + q1*erJ(1,1).*dy1dw_t + q2*erJ(2,1).*dy2dw_t;
      dJdv_t  = dJdv_t  + q1*erJ(1,1).*dy1dv_t  + q2*erJ(2,1).*dy2dv_t;
      dJdu_t  = dJdu_t  + q1*erJ(1,1).*dy1du_t + q2*erJ(2,1).*dy2du_t;
      dJdc2_t  = dJdc2_t  + q1*erJ(1,1).*dy1dc2_t  + q2*erJ(2,1).*dy2dc2_t;
      dJda2_t  = dJda2_t  + q1*erJ(1,1).*dy1da2_t  + q2*erJ(2,1).*dy2da2_t;
      ersum2 = ersum2 + er.^2;
      x = out_red;     % The output turns to be input in the next step
  end
      dJdw_t = dJdw_t/ndata;
      dJdv_t = dJdv_t/ndata;  
      dJdc2_t = dJdc2_t/ndata;
      dJda2_t = dJda2_t/ndata;
      w = w - eta*dJdw_t;
      v  = v - eta*dJdv_t;
      ur = ur - eta*dJdu_t; 
      c2 = c2 - etac*dJdc2_t;
      a2 = a2 - etaa*dJda2_t;

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
plot(tt,z(:,1),'-r');
hold on;
plot(tt1,outputesc(:,1),'-b');
title('Output State Variable x1');
xlabel('Time [sec]');
axis([ 0 7 -0.6  0.6]);
figure(4);
title('Desired Output (red) and Network Output (blue)');
plot(tt,z(:,2),'-r');
hold on;
plot(tt1,outputesc(:,2),'-b');
title('Output State Variable x2');
xlabel('Time [sec]');
axis([ 0 7 -1  1]);
figure(5);
title('Input Signal');
plot(tt,u,'-b');
title('Input Signal u');
xlabel('Time [sec]');
axis([ 0 7 -1.2 1.2]);

% Saving: number of input, hidden and output neurons,  coefficients v and
% w, center c, and slope c
save reddbp2int ne nm np ns ur v w c1 a1 c2 a2;   

