% Genetic algorithm
% Puzzle - GOOD
% The image can de divided in 9, 16, 25 ....  100 parts (M = 3, 4, 5 .... 10)

clear;
close all;
clc;
M = 12;     % Orderof matrix: 10
A_RGB = imread('mariobros.jpg','jpg');
nf = 17*(3*4*5);    %Multiplo of M 
nc = 20*(3*4*5);
A = A_RGB(1:nf,1:nc,:);

% Partitioning the image-matrix 
nfM = nf/M;
ncM = nc/M;
k = 1;
for i = 1:M
    kf1 = (i-1)*nfM + 1;
    kf2 = kf1 + nfM - 1;
    for j = 1:M
      kc1 = (j-1)*ncM + 1;
      kc2 = kc1 + ncM - 1;
      AA(:,:,:,k) = A(kf1:kf2,kc1:kc2,:);  
      k = k + 1;  
    end
end

k = 1;
for i = 1:M
   for j = 1:M
     kf1 = (i-1)*nfM + 1;
     kf2 = kf1 + nfM - 1;
     kc1 = (j-1)*ncM + 1;
     kc2 = kc1 + ncM - 1;
     BB(kf1:kf2,kc1:kc2,:) = AA(:,:,:,k);  
     k = k + 1;  
   end    
end
figure(1);
BB = uint8(BB);
imshow(BB);
disp('Press ENTER');
pause;


M2 = M*M;
numeros = 1:M2;    % List of numbers from 1 to M2
sumanumeros = M2*(M2+1)/2;
sumprom = sumanumeros/M;   % What each row (or column) must sum 

bpm = floor(log(M2)/log(2) + 1);  % Bits per sample 
d = [ 1 ];
for k = 1:(bpm-1) 
    d = [ (2^k)  d ];     % d = [ ... 16 8 4 2 1 ]     
end

np = 70;    % Population

% Generation of decimal numbers from 1 to M2 without repeating and in random locations
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
% xx: Matriz with  np rows containing the numbers from 1 to M2 randomly placed

for ii = 1:np     %
    fitness(ii,1) = sum((xx(ii,:) - numeros).^2); 
end
min_fitness = min(fitness)
[fitorden norden] = sort(fitness,'ascend');  
minxx = norden(1,1);
nzfig = xx(minxx,:);

k = 1;
for i = 1:M
   for j = 1:M
     kk = nzfig(1,k);
     kf1 = (i-1)*nfM + 1;
     EE(i,j) = kk;
     kf2 = kf1 + nfM - 1;
     kc1 = (j-1)*ncM + 1;
     kc2 = kc1 + ncM - 1;
     BB(kf1:kf2,kc1:kc2,:) = AA(:,:,:,kk);  
     k = k + 1;  
   end    
end
EE
figure(2);
imshow(BB);
disp('Press ENTER');
pause;

% Converting decimal numbers into binary with bpm bits
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

kj = 1;    % Counter for J for drawing
ff = 1;

% Algorithm loop 
for k = 1:500000
    for cc = 1:M2             % Conversion to decimal
        k1 = 1 + bpm*(cc-1);
        k2 = k1 + (bpm-1);
        nz(:,cc) = z(:,k1:k2)*d';    % Decimal numbers
    end

    for ii = 1:np     %
        fitness(ii,1) = sum((nz(ii,:) - numeros).^2); 
    end
    
    min_fitness = min(fitness);
    [fitorden norden] = sort(fitness,'ascend');    

%    if(min_fitness == 0)
%        break;
%    end
    
    kp = norden(1,1);
    nzclose = nz(kp,:);
    diffnz = numeros - nzclose;  
    kcc = 1;
    for cc = 1:M2    % Looking for tokens in the right position
        if(diffnz(1,cc) == 0)
            DD(1,ff) = nzclose(1,cc);
            fila = ceil(DD(1,ff)/M);
            colum = DD(1,ff) - (fila-1)*M;
            EE(fila,colum) = DD(1,ff);
            ff = ff + 1;
            abc(1,kcc) = cc;
            kcc = kcc + 1;
            
              for i = 1:M
                for j = 1:M
%                  kk = nzkp(1,k);
                   kk = EE(i,j);
                   kf1 = (i-1)*nfM + 1;
                   kf2 = kf1 + nfM - 1;
                   kc1 = (j-1)*ncM + 1;
                   kc2 = kc1 + ncM - 1;
                   BB(kf1:kf2,kc1:kc2,:) = AA(:,:,:,kk);  
                end    
              end
              figure(3);
              imshow(BB);        
            
        end
    end
    kcc = kcc - 1; 
    
    for dd = 1:kcc      % Eliminate tokens in the right position
            cc = abc(1,dd);
            kz1 = (cc-1)*bpm + 1 - (dd-1)*bpm;
            kz2 = kz1 + bpm - 1; 
            cc = cc + (dd-1)*(-1);   % Adjusting for number shifting
            if(cc == M2)
                numeros = numeros(1,1:M2-1);
                nz = nz(:,1:M2-1);
                z = z(:,1:bpm*(M2-1));
            else
                numeros(1,cc:M2-1) = numeros(1,cc+1:M2);
                numeros = numeros(1,1:M2-1);
                nz(:,cc:M2-1) = nz(:,cc+1:M2);
                nz = nz(:,1:M2-1); 
                z(:,kz1:bpm*(M2-1)) = z(:,kz2+1:bpm*M2); 
                z = z(:,1:bpm*(M2-1));
            end
            M2 = M2 - 1;   
    end
    
    if(min_fitness == 0)
       break;
    end
    
       
% Choose the parent among the two moss strong individuals
    nn = rand(1,1);    % Generating random number 1 or 2
    nn = 1.999*nn + 0.5;
    nn = round(nn);
    kp = norden(nn,1);
    kp = norden(1,1);   
    z1 = z(kp,:);     % Father
    
% Choose the mother from the rest of the population starting from
% the third position (one of the first two postions were used to choose the
% father
    km = (np-3)*rand(1,1);        km = round(km);
    km = km + 3;
    z2 = z(km,:);     % Mather
%    [ kp km]
%  Child 1
    zh1 = CrucePermutacion(z1,z2,bpm,0.1,0.1,1,numeros); 
%  Child 2 
    zh2 = CrucePermutacion(z1,z2,bpm,0.1,0.1,2,numeros); 
%  Child 3
    zh3 = CrucePermutacion(z1,z2,bpm,0.1,0.2,1,numeros); 
%  Child 4
    zh4 = CrucePermutacion(z1,z2,bpm,0.1,0.2,2,numeros);     
%  Child 5
    zh5 = CrucePermutacion(z1,z2,bpm,0.1,0.3,1,numeros); 
%  Child 6
    zh6 = CrucePermutacion(z1,z2,bpm,0.1,0.3,2,numeros); 
%  Child 7
    zh7 = CrucePermutacion(z1,z2,bpm,0.1,0.5,1,numeros); 
%  Child 8 
    zh8 = CrucePermutacion(z1,z2,bpm,0.1,0.5,2,numeros);     
%  Child 9
    zh9 = CrucePermutacion(z1,z2,bpm,0.2,0.2,1,numeros); 
%  Child 10
    zh10 = CrucePermutacion(z1,z2,bpm,0.2,0.2,2,numeros);         
%  Child 11
    zh11 = CrucePermutacion(z1,z2,bpm,0.2,0.3,1,numeros); 
%  Child 12
    zh12 = CrucePermutacion(z1,z2,bpm,0.2,0.3,2,numeros); 
%  Child 13
    zh13 = CrucePermutacion(z1,z2,bpm,0.2,0.5,1,numeros); 
%  Child 14
    zh14 = CrucePermutacion(z1,z2,bpm,0.2,0.5,2,numeros);     
%  Child 15
    zh15 = CrucePermutacion(z1,z2,bpm,0.3,0.3,1,numeros);     
%  Child 16
    zh16 = CrucePermutacion(z1,z2,bpm,0.3,0.3,2,numeros); 
%  Child 17
    zh17 = CrucePermutacion(z1,z2,bpm,0.3,0.5,1,numeros); 
%  Child 18
    zh18 = CrucePermutacion(z1,z2,bpm,0.3,0.5,2,numeros); 
%  Child 19
    zh19 = CrucePermutacion(z1,z2,bpm,0.3,0.7,1,numeros);     
%  Child 20
    zh20 = CrucePermutacion(z1,z2,bpm,0.3,0.7,2,numeros);     
%  Child 21
    zh21 = CrucePermutacion(z1,z2,bpm,0.4,0.4,1,numeros); 
%  Child 22
    zh22 = CrucePermutacion(z1,z2,bpm,0.4,0.4,2,numeros); 
%  Child 23
    zh23 = CrucePermutacion(z1,z2,bpm,0.4,0.6,1,numeros); 
%  Child 24
    zh24 = CrucePermutacion(z1,z2,bpm,0.4,0.6,2,numeros);     
%  Child 25
    zh25 = CrucePermutacion(z1,z2,bpm,0.5,0.5,2,numeros);     
       
    
%   Indexes of the 65 most weak individuals 
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
    
% Generating random individuals for mutations
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
  z(kn33,:) = GeneraPermutacionBinaria(M2,bpm); 
  z(kn34,:) = GeneraPermutacionBinaria(M2,bpm);
  z(kn35,:) = GeneraPermutacionBinaria(M2,bpm);
  z(kn36,:) = GeneraPermutacionBinaria(M2,bpm);   
  z(kn37,:) = GeneraPermutacionBinaria(M2,bpm);
  z(kn38,:) = GeneraPermutacionBinaria(M2,bpm); 
  z(kn39,:) = GeneraPermutacionBinaria(M2,bpm);
  z(kn40,:) = GeneraPermutacionBinaria(M2,bpm);  
  
  % Replacing weak individuals by children
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
  z(kn62,:) = zh22;
  z(kn63,:) = zh23;  
  z(kn64,:) = zh24; 
  z(kn65,:) = zh25; 
    
  k
  if(mod(k,1) == 0)
    J(kj,1) = min(fitness); 
    count(kj,1) = kj;
    kj = kj + 1;
%    kp = norden(1,1);
%    nzkp = nz(kp,:);
%    k = 1;
%    for i = 1:M
%     for j = 1:M
%       kk = nzkp(1,k);
%       kf1 = (i-1)*nfM + 1;
%       kf2 = kf1 + nfM - 1;
%       kc1 = (j-1)*ncM + 1;
%       kc2 = kc1 + ncM - 1;
%       BB(kf1:kf2,kc1:kc2,:) = AA(:,:,:,kk);  
%       k = k + 1;  
%     end    
%    end
%figure(3);
%imshow(BB);
   
  
  end
%disp('Pause');
%pause;
end


%kp = norden(1,1);
%nzkp = nz(kp,:);
%k = 1;
%for i = 1:M
%   for j = 1:M
%     kk = nzkp(1,k);
%     kf1 = (i-1)*nfM + 1;
%     kf2 = kf1 + nfM - 1;
%     kc1 = (j-1)*ncM + 1;
%     kc2 = kc1 + ncM - 1;
%     BB(kf1:kf2,kc1:kc2,:) = AA(:,:,:,kk);  
%     k = k + 1;  
%   end    
%end
%figure(3);
%imshow(BB);

%kp = norden(1,1);
%nzkp = nz(kp,:);
%matriz = [];
%for k = 1:M
%   k1 = 1 + M*(k-1);
%   k2 = k1 + (M-1);
%   matriz = [ matriz
%              nzkp(1,k1:k2) ];
%end
%matriz
%sum(matriz)
%sum(matriz')
%sum(sum(matriz))
%figure(4);
%plot(count,J);
