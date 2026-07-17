function [ zh ] = CrucePermutacion(z1,z2,bpm,ps1,ps2,start,numeros)
% z1 = padre
% z2 = madre
% bpm = bits por muestra
% ps1 = porcentaje de segmento 1. Tanto por uno.
% ps2 = porcentaje de segmento 2. Tanto por uno.
% ps1 + ps2 <= 1
% start = bloque de inicio 
%       start = 1: Inicia en el primer  bloque (segmento)
%       start = 2: Inicia en el segundo bloque (segmento)
%
%      ps1       ps2
%    -------............
%    ooooo*****ooooo*****ooooo*****

nz = length(z1);
M2 = nz/bpm;
s1 = round(nz*ps1);
s2 = round(nz*ps2);
if((s1+s2) > nz)
   s2 = nz-s1;
end    
zh = z1;
if(start == 1)
    incre = s1 - 1;
elseif(start == 2)
    incre = s2 - 1;
end
kini = (start-1)*s1 + 0*s2 + 1;
k1 = kini;

while(1 > 0)
    k2 = k1 + incre;
    if(k2 > nz)
        break;
    end
    zh(1,k1:k2) = z2(1,k1:k2);    
    k1 = k1 + s1 + s2;    
end

% Luego del crossover hay numeros que se pueden
% repetir o estar fuera del rango 1,2,3,4,....25
% Debe cambiarse para que estén todos los números
% 1,2,3,4,... 25




d = [ 1 ];
for k = 1:(bpm-1) 
    d = [ (2^k)  d ];     % d = [ ... 16 8 4 2 1 ]     bpm elementos
end

for kk = 1:M2             % Conversion a decimal
    k1 = 1 + bpm*(kk-1);
    k2 = k1 + (bpm-1);
    nz(1,kk) = zh(1,k1:k2)*d';    % Numeros decimales
end
 
[nzorden nzindex] = sort(nz,'ascend'); 
for kk = 1:M2
    nnz = nzindex(1,kk);
    nzcom(1,nnz) = numeros(1,kk);
end

%[nzorden nzindex] = sort(nz,'descend'); 
%for kk = M2:-1:1
%    nnz = nzindex(1,kk);
%    nzcom(1,nnz) = kk;
%end

% Convirtiendo cada número decimal a binario de 4 bits
for kz = 1:M2
   Div = nzcom(1,kz); 
   for j = 1:(bpm-1)
      res(1,j) = mod(Div,2);
      Div = floor(Div/2);
   end
   res(1,j+1) = Div; 
   k1 = 1 + bpm*(kz-1);
   k2 = k1 + (bpm-1);
   zh(1,k1:k2) = fliplr(res);
end


return



