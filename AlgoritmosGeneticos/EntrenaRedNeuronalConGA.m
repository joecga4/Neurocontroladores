% Entrenamienrto de red neuronal con una
% entrada y una salida y una neurona bias

clear;
clc;
close all;

bias = 1;
x = -2:0.05:2;
x = x';
nx = length(x);
yb = 2*x + 1 + 0.5*randn(nx,1);

nv = 10;      % Cantidad de coeficientes v
nw = 10;      % Cantidad de coeficinetes w
vwmin = -4;   % Límites del valor de v y w
vwmax = 4;
nbvw = 8;     % Cantidad de bits por cada coeficiente
nb = (nv+nv+nw)*nbvw;   % Todas de bis para todos v1, v2 y w 
np = 20;             % Población
d = [ 128 64 32  16  8  4  2  1 ]';    % Conversion binario a decimal
z = round(rand(np,nb));

for count = 1:8000

for k = 1:nv
  k1 = 1 + (k-1)*nbvw;
  k2 = k1 + nbvw - 1;
  vb1(:,k) = z(:,k1:k2)*d;
  v1 = vb1./(2^nbvw -1)*(vwmax-vwmin)+vwmin;
end
for k = 1:nv     % Bias
  k1 = nv+1 + (k-1)*nbvw;
  k2 = k1 + nbvw - 1;
  vb2(:,k) = z(:,k1:k2)*d;
  v2 = vb2./(2^nbvw -1)*(vwmax-vwmin)+vwmin;
end
for k = 1:nw
  k1 = nv+nv+1 + (k-1)*nbvw;
  k2 = k1 + nbvw - 1;
  wb(:,k) = z(:,k1:k2)*d;
  w = wb./(2^nbvw -1)*(vwmax-vwmin)+vwmin;
end

for k = 1:np
  for c = 1:nx
    m = (v1(k,:))'.*x(c,1) + (v2(k,:))'.*bias;
    n = 1.0./(1+exp(-m));
    y(c,1) = w(k,:)*n; 
  end
  err(k,1) = sum((y-yb).^2); 
end
    minerr = min(err)
    JJ(count,1) = minerr;
    [errorden norden] = sort(err,'ascend');
%   Escoger al padre entre los dos mas fuertes
    nn = rand(1,1);    % Generar numero aletorio entre 1 y 2
    nn = 1.999*nn + 0.5;
    nn = round(nn);
    kp = norden(nn,1);
    zp1 = z(kp,:);     % Padre
%   Escoger a la madre aleatoria entre cualquiera de la población
    kn = (np-1)*rand(1,1);        kn = round(kn);
    kn = kn + 1;
    zp2 = z(kn,:);     % Madre aleatoria (2)
%    [ maxy kp kn ];
%   Hijo 1   (Potencial) 
    zh1 = zp1;
    zh1(1,nb/4:nb/2) = zp2(1,nb/4:nb/2);
    zh1(1,3*nb/4:nb) = zp2(1,3*nb/4:nb);
%   Hijo 2   (Potencial)
    zh2 = zp2;
    zh2(1,nb/4:nb/2) = zp1(1,nb/4:nb/2);
    zh2(1,3*nb/4:nb) = zp1(1,3*nb/4:nb);   
%   Hijo 3   (Potencial)    
    zh3 = zp1;
    zh3(1,1:nb/2) = zp2(1,1:nb/2);
%   Hijo 4   (Potencial)    
    zh4 = zp2;
    zh4(1,1:nb/2) = zp1(1,1:nb/2);    
%   Escoger los dos más débiles para hacer cambio 
    kn1 = norden(np,1);
    kn2 = norden(np-1,1);
    kn3 = norden(np-2,1); 
    kn4 = norden(np-3,1);
    kn5 = norden(np-4,1);
    kn6 = norden(np-5,1);   
    z(kn6,:) = zh1;     
    z(kn5,:) = zh2;
    z(kn4,:) = zh3;     
    z(kn3,:) = zh4;                 % De la reproducción 
    z(kn2,:) = round(rand(1,nb));   % Un elemento aleatorio que reemplaza al último
    z(kn1,:) = round(rand(1,nb));   % Elemento importante para evitar minimo local
end

figure(1);
plot(JJ);

v1 = v1(1,:);
v2 = v2(1,:);
w = w(1,:);
for c = 1:nx
    m = v1'.*x(c,1) + v2'*bias;
    n = 1.0./(1+exp(-m));
    y(c,1) = w*n; 
end
figure(2);
plot(x,yb,'or',x,y,'-b');
grid;
  
  
