% Genetic Algortihm.
% From numbers 1, 2, 3...16, construct a 4x4 matrix such that
% the sum of each row is equal to the sum of each column.

clear;
close all;
clc;
M = 4;     % Matrix order
M2 = M*M;
numeros = 1:M2;    % Numbers from 1 to M2 (1 to 16)
sumanumeros = M2*(M2+1)/2;
sumprom = sumanumeros/M;   % What each row or column must sum

bpm = floor(log(M2)/log(2) + 1);  % Bits per number (analyze for M=4)
d = [ 1 ];
for k = 1:(bpm-1) 
    d = [ (2^k)  d ];     % d = [ ... 16 8 4 2 1 ]. Used for converting binary into decimal number 
end

np = 400;    % Population

% Generation of numbers 1 to M2 (16) randomly placed 

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

kj = 1;    % Contador para J
% Iteration loop 
for k = 1:100000
    for cc = 1:M2             % Conversion to decimal
        k1 = 1 + bpm*(cc-1);
        k2 = k1 + (bpm-1);
        nz(:,cc) = z(:,k1:k2)*d';   
    end
%   sum(nz')
    for ii = 1:M       % Summing rows and columns
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
    sumff = (sumf-sumprom).^2;      % Error between present sum and desired sum for rows
    sumcc = (sumc-sumprom).^2;    % Error between present sum and desired sum for columnas
    sumann = ((sum(nz'))' - sumanumeros).^2;        % Sum of the whole matrix
%    sumff = abs((sumf-sumprom)/sumprom);       % Averaged sum (rows)
%    sumcc = abs((sumc-sumprom)/sumprom);     % Averaged sum (columns)
%    sumann = abs(((sum(nz'))'- sumanumeros)/sumanumeros);     % Sum of the whole matrix
    fitness = sum(sumff') + sum(sumcc');     % No weights are considered
    fitness = fitness';    
    min_fitness = min(fitness)
    [fitorden norden] = sort(fitness,'ascend');    

    if(min_fitness == 0)
        break;
    end

% Choose the father among the two most strong individuals 
    nn = rand(1,1);    % Generating random number 1 or 2 
    nn = 1.999*nn + 0.5;
    nn = round(nn);
    kp = norden(nn,1);
    z1 = z(kp,:);     % Father
% Choose the mother from the rest of the population starting from the third row.
% (any of the first two rows could have been chosen as the father.  
    km = (np-3)*rand(1,1);        km = round(km);
    km = km + 3;
    z2 = z(km,:);     %Mother
%    [ kp km]
%   Child 1 
    zh1 = crossover(z1,z2,bpm,1,1); 
%   Child 2 
    zh2 = crossover(z1,z2,bpm,1,2); 
%   Child 3 
    zh3 = crossover(z1,z2,bpm,1,3); 
%   Child 4 
    zh4 = crossover(z1,z2,bpm,1,4);     
%   Child 5 
    zh5 = crossover(z1,z2,bpm,2,1); 
%   Child 6 
    zh6 = crossover(z1,z2,bpm,2,2); 
%   Child 7 
    zh7 = crossover(z1,z2,bpm,2,3); 
%   Child 8 
    zh8 = crossover(z1,z2,bpm,2,4);     
%   Child 9 
    zh9 = crossover(z1,z2,bpm,3,1); 
%   Child 10 
    zh10 = crossover(z1,z2,bpm,3,2);         
%   Child 11 
    zh11 = crossover(z1,z2,bpm,3,3); 
%   Child 12 
    zh12 = crossover(z1,z2,bpm,3,4); 
%   Child 13 
    zh13 = crossover(z1,z2,bpm,3,5); 
%   Child 14 
    zh14 = crossover(z1,z2,bpm,5,1);     
%   Child 15 
    zh15 = crossover(z1,z2,bpm,5,2);     
%   Child 16 
    zh16 = crossover(z1,z2,bpm,10,1); 
%   Child 17 
    zh17 = crossover(z1,z2,bpm,20,1); 
%   Child 18 
    zh18 = crossover(z1,z2,bpm,30,1); 
%   Child 19 
    zh19 = crossover(z1,z2,bpm,40,1);     
%   Child 20
    zh20 = crossover(z1,z2,bpm,50,1);     
%   Child 21 
    zh21 = crossover(z1,z2,bpm,10,2); 
%   Child 22 
    zh22 = crossover(z1,z2,bpm,20,2); 
%   Child 23 
    zh23 = crossover(z1,z2,bpm,30,2); 
%   Child 24 
    zh24 = crossover(z1,z2,bpm,40,2);     
%   Child 25 
    zh25 = crossover(z1,z2,bpm,50,2);     
    
%   Determing the indexes of the most weak individuals for replacement or mutation
    kn1  = norden(np,1);
    kn2  = norden(np-1,1);
    kn3  = norden(np-2,1);
    kn4  = norden(np-3,1);
    kn5  = norden(np-4,1);
    kn6  = norden(np-5,1);
    kn7  = norden(np-6,1);
    kn8  = norden(np-7,1);
    kn9  = norden(np-8,1);
    kn10 = norden(np-9,1);
    kn11 = norden(np-10,1);
    kn12 = norden(np-11,1);
    kn13 = norden(np-12,1);
    kn14 = norden(np-13,1);        
    kn15 = norden(np-14,1);
    kn16 = norden(np-15,1);
    kn17 = norden(np-16,1);
    kn18 = norden(np-17,1);
    kn19 = norden(np-18,1);
    kn20 = norden(np-19,1);
    kn21 = norden(np-20,1);        
    kn22 = norden(np-21,1);
    kn23 = norden(np-22,1);
    kn24 = norden(np-23,1);
    kn25 = norden(np-24,1);   
    kn26 = norden(np-25,1);        
    kn27 = norden(np-26,1);
    kn28 = norden(np-27,1);
    kn29 = norden(np-28,1);
    kn30 = norden(np-29,1);       
    kn31 = norden(np-30,1);        
    kn32 = norden(np-31,1);
    kn33 = norden(np-32,1);
    kn34 = norden(np-33,1);
    kn35 = norden(np-34,1);   
    kn36 = norden(np-35,1);        
    kn37 = norden(np-36,1);
    kn38 = norden(np-37,1);
    kn39 = norden(np-38,1);
    kn40 = norden(np-39,1);       
    kn41 = norden(np-40,1);        
    kn42 = norden(np-41,1);
    kn43 = norden(np-42,1);
    kn44 = norden(np-43,1);
    kn45 = norden(np-44,1);   
    kn46 = norden(np-45,1);        
    kn47 = norden(np-46,1);
    kn48 = norden(np-47,1);
    kn49 = norden(np-48,1);
    kn50 = norden(np-49,1);
    kn51 = norden(np-50,1);        
    kn52 = norden(np-51,1);
    kn53 = norden(np-52,1);
    kn54 = norden(np-53,1);
    kn55 = norden(np-54,1);  
    kn56 = norden(np-55,1);        
    kn57 = norden(np-56,1);
    kn58 = norden(np-57,1);
    kn59 = norden(np-58,1);
    kn60 = norden(np-59,1);
    kn61 = norden(np-60,1);        
    kn62 = norden(np-61,1);
    kn63 = norden(np-62,1);
    kn64 = norden(np-63,1);
    kn65 = norden(np-64,1); 
    
% Generating random individuals for mutation ensuring each one contains numbers from
% 1 to 16 without repetition and randomly placed.
  z(kn1,:)  = GeneraPermutacionBinaria(M2,bpm);
  z(kn2,:)  = GeneraPermutacionBinaria(M2,bpm);
  z(kn3,:)  = GeneraPermutacionBinaria(M2,bpm);
  z(kn4,:)  = GeneraPermutacionBinaria(M2,bpm); 
  z(kn5,:)  = GeneraPermutacionBinaria(M2,bpm);
  z(kn6,:)  = GeneraPermutacionBinaria(M2,bpm);   
  z(kn7,:)  = GeneraPermutacionBinaria(M2,bpm);
  z(kn8,:)  = GeneraPermutacionBinaria(M2,bpm); 
  z(kn9,:)  = GeneraPermutacionBinaria(M2,bpm);
  z(kn10,:) = GeneraPermutacionBinaria(M2,bpm);   
  z(kn11,:) = GeneraPermutacionBinaria(M2,bpm);   
  z(kn12,:) = GeneraPermutacionBinaria(M2,bpm);
  z(kn13,:) = GeneraPermutacionBinaria(M2,bpm); 
  z(kn14,:) = GeneraPermutacionBinaria(M2,bpm);
  z(kn15,:) = GeneraPermutacionBinaria(M2,bpm);    
  z(kn16,:) = GeneraPermutacionBinaria(M2,bpm);   
  z(kn17,:) = GeneraPermutacionBinaria(M2,bpm);
  z(kn18,:) = GeneraPermutacionBinaria(M2,bpm); 
  z(kn19,:) = GeneraPermutacionBinaria(M2,bpm);
  z(kn20,:) = GeneraPermutacionBinaria(M2,bpm);
  z(kn21,:) = GeneraPermutacionBinaria(M2,bpm);   
  z(kn22,:) = GeneraPermutacionBinaria(M2,bpm);
  z(kn23,:) = GeneraPermutacionBinaria(M2,bpm); 
  z(kn24,:) = GeneraPermutacionBinaria(M2,bpm);
  z(kn25,:) = GeneraPermutacionBinaria(M2,bpm);
  z(kn26,:) = GeneraPermutacionBinaria(M2,bpm);   
  z(kn27,:) = GeneraPermutacionBinaria(M2,bpm);
  z(kn28,:) = GeneraPermutacionBinaria(M2,bpm); 
  z(kn29,:) = GeneraPermutacionBinaria(M2,bpm);
  z(kn30,:) = GeneraPermutacionBinaria(M2,bpm);  
  z(kn31,:) = GeneraPermutacionBinaria(M2,bpm);   
  z(kn32,:) = GeneraPermutacionBinaria(M2,bpm);
%  z(kn33,:) = GeneraPermutacionBinaria(M2,bpm); 
%  z(kn34,:) = GeneraPermutacionBinaria(M2,bpm);
%  z(kn35,:) = GeneraPermutacionBinaria(M2,bpm);
%  z(kn36,:) = GeneraPermutacionBinaria(M2,bpm);   
%  z(kn37,:) = GeneraPermutacionBinaria(M2,bpm);
%  z(kn38,:) = GeneraPermutacionBinaria(M2,bpm); 
%  z(kn39,:) = GeneraPermutacionBinaria(M2,bpm);
%  z(kn40,:) = GeneraPermutacionBinaria(M2,bpm);  
  
  % Replacing with children 
  z(kn41,:) = zh1;
  z(kn42,:) = zh2; 
  z(kn43,:) = zh3;
  z(kn44,:) = zh4;  
  z(kn45,:) = zh5;
  z(kn46,:) = zh6; 
  z(kn47,:) = zh7;
  z(kn48,:) = zh8;  
  z(kn49,:) = zh9; 
  z(kn50,:) = zh10;
  z(kn51,:) = zh11; 
  z(kn52,:) = zh12;
  z(kn53,:) = zh13;  
  z(kn54,:) = zh14; 
  z(kn55,:) = zh15;     
  z(kn56,:) = zh16; 
  z(kn57,:) = zh17;
  z(kn58,:) = zh18;  
  z(kn59,:) = zh19; 
  z(kn60,:) = zh20; 
  z(kn61,:) = zh21; 
  % z(kn62,:) = zh22;
  % z(kn63,:) = zh23;  
  % z(kn64,:) = zh24; 
  % z(kn65,:) = zh25; 

  if(mod(k,10) == 0)
    J(kj,1) = min(fitness); 
    count(kj,1) = kj;
    if(J(kj,1) == 0)
         break;
    end
    kj = kj + 1;
  end
  
%disp('Pause');
%pause;
end

kp = norden(1,1);
nzkp = nz(kp,:);
matriz = [];
for k = 1:M
   k1 = 1 + M*(k-1);
   k2 = k1 + (M-1);
   matriz = [ matriz
              nzkp(1,k1:k2) ];
end
matriz
sum(matriz)
sum(matriz')
sum(sum(matriz))
figure(1);
plot(count,J);
title('Fitness Function');