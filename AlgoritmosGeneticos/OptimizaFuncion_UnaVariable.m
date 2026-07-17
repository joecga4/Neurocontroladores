% Genetic Algorithm
% Find the maximum (local) of a function with two maximums

clear;
close all;
clc;

x = 0:0.01:63;
x = x';
y = exp(-((x-10)/6).^2) + 0.8*exp(-((x-35)/10).^2);
plot(x,y);  grid;

xmin = 0;   xmax = 63;      % Range of x
np = 12;          % Population 
nb = 16;          % Number of bits for every individual (chromosome)
z = rand(np,nb);  % Generation of random bits
z = round(z);
d2a = [ 2^(nb-1) 2^14 2^13 2^12 2^11 2^10  2^9 2^8  2^7  2^6  2^5  2^4  2^3  2^2  2^1  2^0 ];
disp('Press ENTER');
pause;

for k = 1:5000
    x = z*d2a';                   % Conversion to decimal
    x = x*63/(2^(nb-1)-1);   % To the decimal range
    y = exp(-((x-10)/6).^2) + 1*0.8*exp(-((x-35)/10).^2);
    maxy = max(y);
    [yorden norden] = sort(y,'descend');
%   Choose the father between the two strongest 
    nn = rand(1,1);    % Random number 1 or 2
    nn = 1.999*nn + 0.5;
    nn = round(nn);
    kp = norden(nn,1);
    zp1 = z(kp,:);     % Padre
%   Choose the mother as any member of the population
    kn = (np-1)*rand(1,1);        kn = round(kn);
    kn = kn + 1;
    zp2 = z(kn,:);     
    [ maxy kp kn ];
%   Child 1   (Crossover) 
    zh1 = zp1;
    zh1(1,5:8) = zp2(1,5:8);
    zh1(1,13:16) = zp2(1,13:16);
%   Child 2   (Crossover)
    zh2 = zp2;
    zh2(1,5:8) = zp1(1,5:8);
    zh2(1,13:16) = zp1(1,13:16);
%   Child 3   (Crossover)    
    zh3 = zp1;
    zh3(1,3:4) = zp2(1,3:4);
    zh3(1,7:8) = zp2(1,7:8);
    zh3(1,11:12) = zp2(1,11:12);
    zh3(1,15:16) = zp2(1,15:16);
%   Child 4   (Crossver)    
    zh4 = zp2;
    zh4(1,3:4) = zp1(1,3:4);
    zh4(1,7:8) = zp1(1,7:8);
    zh4(1,11:12) = zp1(1,11:12);
    zh4(1,15:16) = zp1(1,15:16); 
%   Choose th most weak members for mutation 
    kn1 = norden(np,1);
    kn2 = norden(np-1,1);
    kn3 = norden(np-2,1); 
    kn4 = norden(np-3,1);
    kn5 = norden(np-4,1);
    kn6 = norden(np-5,1);   
    z(kn6,:) = zh4;
    z(kn5,:) = zh3;     
    z(kn4,:) = zh2;       
    z(kn3,:) = zh1;   
    z(kn2,:) = round(rand(1,nb));  
    z(kn1,:) = round(rand(1,nb));    
% Mutation is important to avoid local maximum    
J(k,1) = maxy; 
maxy
count(k,1) = k;
end
nxopt = norden(1,1);
[ x(nxopt,1)  y(nxopt,1) ]


xx = 0:0.01:63;
xx = xx';
yy = exp(-((xx-10)/6).^2) + 0.8*exp(-((xx-35)/10).^2);
figure(1);
plot(xx,yy);   grid;
figure(2);
plot(count,J);
title('Value of Maximum');
