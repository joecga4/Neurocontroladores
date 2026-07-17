function [ zz ] = GeneraPermutacionBinaria(M2,bpm)
% Asegurando que esten todos los números del 1 al M2 sin repetirse
  numeros = 1:M2;    % Lista de numeros naturales de 1 a M2
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
     yy(1,kk) = no;   
  end
  for kk = 1:M2
        Div = yy(1,kk); 
        for j = 1:(bpm-1)
           res(1,j) = mod(Div,2);
           Div = floor(Div/2);
        end
        res(1,j+1) = Div; 
        k1 = 1 + bpm*(kk-1);
        k2 = k1 + (bpm-1);
        zz(1,k1:k2) = fliplr(res);
  end
end

