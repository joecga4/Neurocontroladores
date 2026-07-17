% Determinacion de la matriz A y B de un sistema lineal
% de orden 2.
% Determina los coeficientes de las matrices A y B
% La matriz de pesos V contiene los coeficientes de A y B
% La matriz de pesos W se mantiene constante e igual a la identidad

clear;
clc;
close all;

st = [ 1 1 1 1 1 1 ];
zt = [ 0 0 0 0 0 0 ];

u = [st st zt -st -st -0.2*st -0.4*st -0.6*st zt st 0.8*st 0.5*st st 0.2*st zt -st -st -st zt zt zt st st st st -st -st -st -st -st -st zt zt 0.25*st st 0.75*st st zt zt zt zt zt zt zt -st -st st st -st -st st 0.1*st 0.1*st st -st st -0.3*st 0.3*st st -st -st st st -st -st st st st st st st-st -st -st st st st st st st -st -st -st st st st st -st -st -st -st st st st st -st -st -st -st st st st st st -0.1*st -0.3*st -0.5*st -0.7*st -0.9*st 0.9*st 0.7*st 0.5*st 0.3*st 0.1*st -st -st -st -st -st st st st st st ];
% u = [st st zt -st -st -st -st -st zt st st st st st zt -st -st -st zt zt zt st st -st -st -st zt zt st st st st zt zt zt zt zt zt zt -st -st st st -st -st st st st st -st st -st st st -st -st st st -st -st st st st -st -st -st st st st -st -st -st st st st st -st -st -st -st st st st st -st -st -st -st st st st st st -st -st -st -st -st st st st st st -st -st -st -st -st st st st st st ];
% u = [-0.5*st -0.5*st zt 0.75*st 0.5*st st -0.3*st 0.3*st zt -st -st -0.6*st -0.4*st -0.2*st zt st st st zt zt zt st st st 0.25*st st zt zt -st -0.1*st -0.2*st -st zt zt ];

% nu = 400;
% nt = 0:1:(nu-1);
% nt = nt;
% fre = 0.01;   % menor de 0.1  a  0.005
% u = 1*sin(2*pi*fre*nt);
% u = ones(1,nu);

u = u';
nu = length(u);

z1(1,1) = 0;
z2(1,1) = 0;
for k = 1:nu
    z1(k+1,1) = 0.6*z1(k,1) + 0.8*z2(k,1) + 0.0*u(k,1);
    z2(k+1,1) = 0.3*z1(k,1) - 0.1*z2(k,1) - 0.2*u(k,1); 
end
z = [ z1  z2 ];
z = z(1:nu,:);

plot(z)

ndata = nu;
dataoutesc = z;

ne = 3;    % No bias
nm = 2;    % Igual que las salidas
ns = 2;

v = 0.1*randn(ne,ns);  % Las matrices A y B aparecen aqui
w = diag([ 1  1 ]);    % Identidad. Se mantiene constante en todo el entrenamiento
% v = [ a11  a21       % Elementos de A y B
%       a12  a22
%        b1   b2 ];  

% load zzz2;
% load zz3;     
% load zz3v;   % Algunos coeficientes 1, 0
load zz1v;
 % v(2,1) =  0.8;
 % v(2,2) = -0.1;
 % v(3,1) =  0.0;

eta  = input('Introducir ratio de aprendizaje : ');

errormax = input('Introducir el valor maximo del error (%) : ');
errormax = errormax/100;
contmax = input('Introducir el maximo numero de etapas de aprendizaje : ');

outsum2 = sum(dataoutesc.^2);
outsum2 = outsum2';
outsum2total = sum(outsum2);

cont = 1;
erreltotal = 1;
   dw_old = 0;  
   dv_old = 0;

while( (erreltotal > errormax) & (cont < contmax) ) 
   ersum2 = zeros(ns,1);
   dJdw = 0;
   dJdv = 0;
   dy1dw_t = zeros(nm,ns);        
   dy2dw_t = zeros(nm,ns);
   dy1dv_t = zeros(ne,nm);
   dy2dv_t = zeros(ne,nm);
   dJdw_t  = zeros(nm,ns);
   dJdv_t  = zeros(ne,nm); 
   
   x = dataoutesc(1,:);   % Solo al principio como estado inicial
   x = x';
   for k = 1:ndata-1
      in_red = [ x
                 u(k,1) ];
      m = v'*in_red;
%      n = 2.0./(1 + exp(-(m-c)./a)) - 1;    
      n = m;        % Lineal
      out_red = v'*in_red;
      outputesc(k,:) = out_red';
%      dndm = diag((1 - n.*n)./(2*a));  
      dndm = diag(ones(nm,1));      % Lineal
      dy1dw_s = [ n   zeros(nm,1) ]; 
      dy2dw_s = [ zeros(nm,1)   n ]; 
      dy1dv_s = in_red*w(:,1)'*dndm;
      dy2dv_s = in_red*w(:,2)'*dndm;
      jacob = w'*dndm*(v(1:ne-1,:))';
      dy1dw_t = dy1dw_s + jacob(1,1).*dy1dw_t + jacob(1,2).*dy2dw_t;   
      dy2dw_t = dy2dw_s + jacob(2,1).*dy1dw_t + jacob(2,2).*dy2dw_t;   
      dy1dv_t = dy1dv_s + jacob(1,1).*dy1dv_t + jacob(1,2).*dy2dv_t;   
      dy2dv_t = dy2dv_s + jacob(2,1).*dy1dv_t + jacob(2,2).*dy2dv_t;  

      out_des = dataoutesc(k+1,:);
      out_des = out_des';
      er = (out_red - out_des);
      erJ = (out_red - out_des).^1;
      %      erJ = (abs(out_red - out_des)).^0.5 .* sign( out_red-out_des );  
      q1 = 1;    q2 = 1;
      dJdw_t = dJdw_t + q1*erJ(1,1).*dy1dw_t + q2*erJ(2,1).*dy2dw_t;
      dJdv_t = dJdv_t + q1*erJ(1,1).*dy1dv_t + q2*erJ(2,1).*dy2dv_t;
      ersum2 = ersum2 + er.^2;
      x = out_red;     % Notar que la salida se convierte en entrada
  end
      dJdw_t = dJdw_t/ndata;
      dJdv_t = dJdv_t/ndata;  
      dw = dJdw_t;
      dv = dJdv_t;
      w = w - 0*eta*dw;     % No cambia
      v = v - eta*dv;  
 % v(2,1) =  0.8;
 % v(2,2) = -0.1;
 % v(3,1) =  0.0;
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

% save zzz2 v w;
% save zz3 v w;
% save zz3v  v w;
save zz1v v w;
 
figure(1);
plot(errorreltotal*100);
figure(2);
plot(errorrel*100);
figure(3);
plot(z(2:nu,1),'-r');
hold on;
plot(outputesc(:,1),'--b');
figure(4);
plot(z(2:nu,2),'-r');
hold on;
plot(outputesc(:,2),'--b');
