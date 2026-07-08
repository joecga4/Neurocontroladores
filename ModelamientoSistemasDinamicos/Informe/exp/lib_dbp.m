function out = lib_dbp(z, u, nm, eta, etaa, niter, seed, q, linear)
% Entrenamiento de red DINAMICA recurrente por Dynamic Back Propagation (DBP).
% Fiel a DynamicBPModelamiento2v/3v.m pero vectorizado para ns salidas
% (forma matricial simultanea de la ec. (13)-(14) del PDF).
%   z      : ndata x ns  salidas deseadas (puede incluir ruido de medicion)
%   u      : ndata x 1    entrada
%   nm     : neuronas ocultas ; eta,etaa : tasas (pesos, pendiente a)
%   niter  : iteraciones ; seed : rng ; q : ns x 1 pesos de medicion (matriz Q)
%   linear : true -> neuronas lineales (n=m) ; false -> sigmoide bipolar
% El modelo corre en LAZO CERRADO: la salida se realimenta como estado (x=out).
ndata = size(z,1);
ns = size(z,2);
ne = ns + 1;                 % estados + entrada (sin bias)
rng(seed);
v = 0.1*randn(ne,nm);
w = 0.1*randn(nm,ns);
c = zeros(nm,1);
a = ones(nm,1);
outsum2total = sum(sum(z.^2));
errhist = zeros(niter,1);
outfit = zeros(ndata-1,ns);
for iter = 1:niter
    ersum2 = zeros(ns,1);
    dJdw = zeros(nm,ns);
    dJdv = zeros(ne,nm);
    dJda = zeros(nm,1);
    Sw = zeros(nm,ns,ns);    % dy_i/dw
    Sv = zeros(ne,nm,ns);    % dy_i/dv
    Sa = zeros(nm,ns);       % dy_i/da
    x = z(1,:)';             % estado inicial
    for k = 1:ndata-1
        in_red = [x; u(k)];
        m = v'*in_red;
        if linear
            n = m;
            dndm = diag(ones(nm,1));
        else
            n = 2.0./(1+exp(-(m-c)./a)) - 1;
            dndm = diag((1 - n.*n)./(2*a));
        end
        o = w'*n;
        outfit(k,:) = o';
        Jac = w'*dndm*v(1:ns,:)';           % ns x ns  (Jacobiano de la red)
        Sw_new = zeros(nm,ns,ns);
        Sv_new = zeros(ne,nm,ns);
        Sa_new = zeros(nm,ns);
        for i = 1:ns
            Sw_s = zeros(nm,ns); Sw_s(:,i) = n;      % parte instantanea
            Sv_s = in_red*w(:,i)'*dndm;
            if linear
                Sa_s = zeros(nm,1);
            else
                Sa_s = w(:,i).*((n.*n-1).*(m-c)./(2*a.*a));
            end
            acc_w = zeros(nm,ns); acc_v = zeros(ne,nm); acc_a = zeros(nm,1);
            for l = 1:ns                              % termino recursivo Jac*S_prev
                acc_w = acc_w + Jac(i,l)*Sw(:,:,l);
                acc_v = acc_v + Jac(i,l)*Sv(:,:,l);
                acc_a = acc_a + Jac(i,l)*Sa(:,l);
            end
            Sw_new(:,:,i) = Sw_s + acc_w;
            Sv_new(:,:,i) = Sv_s + acc_v;
            Sa_new(:,i)   = Sa_s + acc_a;
        end
        Sw = Sw_new; Sv = Sv_new; Sa = Sa_new;
        er = o - z(k+1,:)';
        for i = 1:ns
            dJdw = dJdw + q(i)*er(i)*Sw(:,:,i);
            dJdv = dJdv + q(i)*er(i)*Sv(:,:,i);
            dJda = dJda + q(i)*er(i)*Sa(:,i);
        end
        ersum2 = ersum2 + er.^2;
        x = o;                    % la salida se convierte en entrada del sig. paso
    end
    w = w - eta*dJdw/ndata;
    v = v - eta*dJdv/ndata;
    a = a - etaa*dJda/ndata;
    errhist(iter) = sqrt(sum(ersum2)/outsum2total);
end
out.v = v; out.w = w; out.a = a; out.c = c;
out.errhist = errhist;
out.outfit = outfit;
out.finalerr = errhist(end);
end
