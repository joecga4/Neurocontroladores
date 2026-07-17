% Genetic Algortihm.
% From numbers 1, 2, 3...9, construct a 3x3 matrix such that
% the sum of each row is equal to the sum of each column.

clear;
close all;
clc;
M = 3;     % Matrix order
M2 = M*M;
numeros = 1:M2;
sumprom = (M2*(M2+1)/2)/M;   % What each row or column must sum
bpm = 4;   % Bits per number
d = [ 8 4 2 1 ];     % bpm = 4   
nb = bpm*M2;    % Bits
np = 8;    % Population

%Generation of numbers 1 to 9 randomly placed 
for p = 1:np
  x = numeros;
  y = x;
  nx = length(x);  
  for k = 1:M2
     n = rand(1);
     kn = (M2-0.001) - (k-1);
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
     xx(p,k) = no;  
  end
end
% xx is a matrix with np rows of ten numers each (numbers 1 to 9 randomly placed)  

% disp('Pause');
% pause;

% Converting each decimal number to binary with four bits each
for p = 1:np
    for k = 1:M2
        Div = xx(p,k); 
        for j = 1:(bpm-1)
           res(1,j) = mod(Div,2);
           Div = floor(Div/2);
        end
        res(1,j+1) = Div; 
        k1 = 1 + bpm*(k-1);
        k2 = k1 + (bpm-1);
        z(p,k1:k2) = fliplr(res);
    end
end


% Starting loop
for k = 1:20000
    for cc = 1:M2
        k1 = 1 + bpm*(cc-1);
        k2 = k1 + (bpm-1);
        nz(:,cc) = z(:,k1:k2)*d';    % Decimal numbers 
    end
    for ii = 1:M
        sumf(:,ii) = zeros(np,1);
        k1 = 1 + M*(ii-1);
        k2 = k1 + (M-1);
        for jj = k1:k2
           sumf(:,ii) = sumf(:,ii) + nz(:,jj); 
        end
        k3 = ii;
        k4 = M2;
        sumc(:,ii) = zeros(np,1);
        for jj = k3:M:k4
           sumc(:,ii) = sumc(:,ii) + nz(:,jj); 
        end     
        
    end
    sumff = (sumf-sumprom).^2; 
    sumcc = (sumc-sumprom).^2;
    fitness = sum(sumff') + sum(sumcc');
    fitness = fitness';    
    min(fitness);
%    pause;
    [fitorden norden] = sort(fitness,'ascend');  

% Choose the father among the two more strong individuals
    nn = rand(1,1);    % Generate random number 1 or 2
    nn = 1.999*nn + 0.5;
    nn = round(nn);
    kp = norden(nn,1);
    z1 = z(kp,:);     % Father
%   Choose the mother from the rest of the population
    kn = (np-1)*rand(1,1);        kn = round(kn);
    kn = kn + 1;
    z2 = z(kn,:);     % Mother
%   Child 1
    zh1 = z1;
    zh1(1,5:8) = z2(1,5:8);
    zh1(1,13:16) = z2(1,13:16);
    zh1(1,21:24) = z2(1,21:24);
    zh1(1,29:32) = z2(1,29:32);   
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
%   Two most weak individuals 
    kn1 = norden(np,1);
    kn2 = norden(np-1,1);
% Penultimate individual is changed for a child
    z(kn2,:) = zh2;        % IIt could be child1, child2, child3, child4 
 
% Generating aleatory individual for mutation
% Ensuring the random individual contains numbers 1 to 9 without repetition
  x = numeros;
  nx = length(x);  
  for kk = 1:M2
     n = rand(1);
     kn = (M2-0.001) - (kk-1);
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
     xx(1,kk) = no;  
  end
  for kk = 1:M2
        Div = xx(1,kk); 
        for j = 1:(bpm-1)
           res(1,j) = mod(Div,2);
           Div = floor(Div/2);
        end
        res(1,j+1) = Div; 
        k1 = 1 + bpm*(kk-1);
        k2 = k1 + (bpm-1);
        z(kn1,k1:k2) = fliplr(res);
  end
  
count(k,1) = k;    
J(k,1) = min(fitness); 
if(J(k,1) == 0)
    break;
end

%pause;
end

nzkp = nz(kp,:);
matriz = [];
for k = 1:M
   k1 = 1 + M*(k-1);
   k2 = k1 + (M-1);
   matriz = [ matriz
              nzkp(1,k1:k2) ];

end
matriz
figure(1);
plot(count,J);
title('Fitness Function');
