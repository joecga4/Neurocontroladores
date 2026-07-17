% Genetic algorithm.
% Set of ten cards:   1  2  3  4  5  6  7  8  9  10
% Separate a set of 10 cards into two groups of 5 cards each.
% The cards in one group must sum 36 (27) (32).
% The product of the cards in the second group must be 360 (2880) (1260).
% Coding: ten bits (five 0s and five 1s).
% Bit 0 corresponds to cards for sum.
% Bit 1 corresponds to cards for multiplication.

clear;
close all;
clc;
suma = 32;
producto = 1260;
nb = 10;    % Bits
np = 12;    % Number of individuals

% Generation of initial random population
% np rows of nb bits (five 0s and five 1s).
% Bit 0 is for sum
% Bit 1 is for multiplication
for p = 1:np
  x = 1:1:10;
  y = x;
  nx = length(x);  
  for k = 1:5
     n = rand(1);
     kn = 9.999 - (k-1);
     n = kn*n + 0.5;
     n = round(n);
     nn(k,1) = x(1,n);
     if(n == 1)
         x = x(1,2:nx);
     elseif(n == nx)
         x = x(1,1:(nx-1));
     else
         x = [ x(1,1:(n-1))  x(1,(n+1):nx) ];
     end
     nx = nx - 1;
     no = nn(k,1);
     z(p,no) = 1;
  end
end
z
disp('Pause');
pause;

% z is contains the initila population of np individuals each one of 10bits
% (five 0s, five 1s)

d = [ 1 2 3 4 5 6 7 8 9 10 ];    % Ten cards

for k = 1:1500
    for kp = 1:np
       sumz(kp,1) = sum(abs((z(kp,:)-1)).*d);   % Sum of 5 cards (bit 0s)
       pro = z(kp,:).*d;
       pro = pro + abs(z(kp,:)-1);
       prodz(kp,1) = prod(pro);    % Product of 5 cards (bit 1s)
       errsum = (sumz-suma).^2/(suma^2);
       errprod = (prodz-producto).^2/(producto^2);
       fitness = 10000*errsum + errprod;      % Weighting coefficient for sum
    end
    min(fitness) 
    [fitorden norden] = sort(fitness,'ascend');  

% Choose the father between the two most strong individuals
    nn = rand(1,1);    % Generar numero aletorio entre 1 y 2
    nn = 1.999*nn + 0.5;
    nn = round(nn);
    kp = norden(nn,1);
    z1 = z(kp,:);     % Father
% Choose the mother randomly from the rest of the population
    kn = (np-1)*rand(1,1);        kn = round(kn);
    kn = kn + 1;
    z2 = z(kn,:);     % Mother
%   Child 1 
    zh1 = z1;
    zh1(1,3:4) = z2(1,3:4);
    zh1(1,7:8) = z2(1,7:8);
%   Child 2
    zh2 = z2;
    zh2(1,3:4) = z1(1,3:4);
    zh2(1,7:8) = z1(1,7:8);
%   Child 3    
    z3 = z1;
    zh3(1,6:10) = z2(1,6:10);
%   Child 4    
    zh4 = z2;
    zh4(1,6:10) = z1(1,6:10);
%   Choose the most weak individuals 
    kn1 = norden(np,1);
    kn2 = norden(np-1,1);
% The penultimate individual will turn to be one the children
    z(kn2,:) = zh2;      % It could child1, child2, child3, child4 
% The last individual mutates. For that, it is generated a random individual with 10 bits: 
% five 0s and five 1s.
    x = 1:1:10;
    nx = length(x); 
    z(kn1,:) = zeros(1,10);
    for kk = 1:5
       n = rand(1);
       kn = 9.999 - (kk-1);
       n = kn*n + 0.5;
       n = round(n);
       nn(kk,1) = x(1,n);
       if(n == 1)
          x = x(1,2:nx);
       elseif(n == nx)
          x = x(1,1:(nx-1));
       else
          x = [ x(1,1:(n-1))  x(1,(n+1):nx) ];
       end
       nx = nx - 1;
       no = nn(kk,1);
       z(kn1,no) = 1;       % Mutation
    end
J(k,1) = min(fitness); 
J(k,1)
count(k,1) = k;
%pause;
end

sumafactores = abs((z(1,:)-1)).*d; 
sumz = sum(sumafactores)
productofactores = z(1,:).*d;
pro = productofactores + abs(z(1,:)-1);
prodz = prod(pro)
[ sumafactores
  productofactores ]

figure(1);
plot(count,J);
title('Fitness function');
