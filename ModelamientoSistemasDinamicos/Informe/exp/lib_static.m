function out = lib_static(xesc, yesc, nm, eta, niter, seed)
% Entrenamiento batch de red ESTATICA (fiel a MotorNeuroEstatico.m)
%   xesc : nx x ne  entradas escaladas (regresores: u y salidas pasadas)
%   yesc : nx x ns  salida(s) escalada(s)
%   nm   : neuronas ocultas ; eta : tasa ; niter : iteraciones ; seed : rng
% Sigmoide bipolar n = 2/(1+exp(-m/a)) - 1, backprop estandar (sin recursion).
rng(seed);
[nx, ne] = size(xesc);
ns = size(yesc,2);
v = 0.25*randn(ne,nm);
w = 0.25*randn(nm,ns);
a = ones(nm,1);
Jhist = zeros(niter,1);
y = zeros(nx,ns);
for iter = 1:niter
    JJ = 0; dJdw = 0; dJdv = 0;
    for k = 1:nx
        in = xesc(k,:)';
        m  = v'*in;
        n  = 2.0./(1+exp(-m./a)) - 1;
        o  = w'*n;
        y(k,:) = o';
        er = o - yesc(k,:)';
        JJ = JJ + 0.5*(er'*er);
        dndm = (1 - n.*n)/2;
        dJdw = dJdw + n*er';
        dJdv = dJdv + in*(dndm.*(w*er))';
    end
    w = w - eta*dJdw/nx;
    v = v - eta*dJdv/nx;
    Jhist(iter) = JJ;
end
out.v = v; out.w = w; out.a = a;
out.Jhist = Jhist;
out.y = y;
% RMSE relativo de ajuste (sobre datos escalados)
err = y - yesc;
out.rmse = sqrt(mean(err(:).^2));
out.relerr = sqrt(sum(err(:).^2)/sum(yesc(:).^2));
end
