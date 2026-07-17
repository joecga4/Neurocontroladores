% Genetic Algorithm
% Find the maximum of a function of two variables with 
% restrictions:   xlimmix < x < xlimmax
clear;
close all;
clc;

for i = 1:61
   x1 = i;
   for j = 1:81
       x2 = j;
       zz(i,j) = exp(-((x1-10)/10).^2 -((x2-20)/10).^2) + 1.0*0.6*exp(-((x1-35)/8).^2 - ((x2-30)/8).^2); 
   end
end
max(max(zz));
mesh(zz);
disp('Press ENTER ');
pause;


xmin = 0;   xmax = 60;
ymin = 0;   ymax = 80;
x1 = xmin:0.1:xmax;
x1 = x1';
x2 = ymin:0.1:ymax;
x2 = x2';
 xlimmin = 5;          % Bounds for x
 xlimmax = 15;
 % xlimmin = 30;    % Bounds for x
 % xlimmax = 40;

np = 30;             % Population
nb = 16;             % Number of bits for x and for y. They will be combined in [ x y ] 
xy = rand(np,2*nb);  % Generation of random bits. Left half for x. Right half for y
xy = round(xy);
d2a = [ 2^(nb-1) 2^14 2^13 2^12 2^11 2^10  2^9 2^8  2^7  2^6  2^5  2^4  2^3  2^2  2^1  2^0 ];

for k = 1:100000
    xx = xy(:,1:nb);
    yy = xy(:,(nb+1):(2*nb));
    x = xx*d2a';                     % Conversion ot decimal
    y = yy*d2a';
    x = x*xmax/(2^(nb-1)-1);   % To the range
    y = y*ymax/(2^(nb-1)-1);
    % zx = ((x < xlimmin) | (x > xlimmax));
    q = 1;     % Weighting factor for the case when variable x is not inside the range
    % zx = fact*zx;
    z = exp(-((x-10)/10).^2 -((y-20)/10).^2) + 1.0*0.6*exp(-((x-35)/8).^2 - ((y-30)/8).^2) - q.*(x-xlimmin).*(x-xlimmax)/25; 
    [x;  y;  z];
    
    maxz = max(z);
    [zorden norden] = sort(z,'descend');
%   Chhose the father among the two most strong individuals
    nn = rand(1,1);    % Generating ranndom number 1 or 2
    nn = 1.999*nn + 0.5;
    nn = round(nn);
    kp = norden(nn,1);
    xy1 = xy(kp,:);     % Father
%   Choose the mother as any individual from the population
    kn = (np-1)*rand(1,1);        kn = round(kn);
    kn = kn + 1;
    xy2 = xy(kn,:);     % Mother
    [ maxz kp kn ];
%   Child 1   
    xyh1 = xy1;
    xyh1(1,5:8) = xy2(1,5:8);
    xyh1(1,13:16) = xy2(1,13:16);
    xyh1(1,21:24) = xy2(1,21:24);
    xyh1(1,29:32) = xy2(1,29:32);
%   Child 2 
    xyh2 = xy2;
    xyh2(1,5:8) = xy1(1,5:8);
    xyh2(1,13:16) = xy1(1,13:16);
    xyh2(1,21:24) = xy1(1,21:24);
    xyh2(1,29:32) = xy1(1,29:32);
%   Child 3    
    xyh3 = xy1;
    xyh3(1,9:16) = xy2(1,9:16);
    xyh3(1,25:32) = xy2(1,25:32);
%   Child 4     
    xyh4 = xy2;
    xyh4(1,9:16) = xy1(1,9:16);
    xyh4(1,25:32) = xy1(1,25:32);
%   The most weak for mutation 
    kn1 = norden(np,1);
    kn2 = norden(np-1,1);
    xy(kn2,:) = xyh1;                         % From reproduction 
    xy(kn1,:) = round(rand(1,2*nb));   % From mutation
% Muutation is important for avoiding local maximum
J(k,1) = maxz; 
maxz
count(k,1) = k;
end

[maxz kz] = max(z);
xxyy = xy(kz,:);
xx = xxyy(:,1:nb); 
yy = xxyy(:,(nb+1):(2*nb));
xsol = xx*d2a';              % Conversion to decimal
ysol = yy*d2a';
xsol = xsol*xmax/(2^(nb-1)-1);   % To the range
ysol = ysol*ymax/(2^(nb-1)-1);
zsol = exp(-((xsol-10)/10).^2 -((ysol-20)/10).^2) + 1.0*0.6*exp(-((xsol-35)/8).^2 - ((ysol-30)/8).^2);
[ xsol ysol zsol ]

figure(2);
plot(count,J);
title('Maximum');


