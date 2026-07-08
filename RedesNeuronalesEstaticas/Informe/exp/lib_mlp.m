function out = lib_mlp(X, Y, nm, hp)
% MLP de una capa oculta con retropropagacion (fiel a los scripts Neuron*.m).
%   X : N x ne  (incluir la columna de bias si se desea) ; Y : N x ns
%   nm : neuronas ocultas
%   hp : struct con campos
%        eta   : tasa de aprendizaje
%        niter : maximo de epocas
%        seed  : semilla rng
%        mode  : 'batch' (lote) | 'pattern' (patron/en linea)
%        act   : 'log' (sigmoide 1) | 'bip' (sigmoide 2) | 'gauss'
%        winit : escala de inicializacion de pesos (def. 0.15)
%        tol   : (opcional) parada por mejora relativa % (def. sin parada)
% Salida lineal: out = w'*n.  Devuelve pesos, historial J, prediccion y RMSE.
eta=hp.eta; niter=hp.niter; mode=hp.mode; act=hp.act;
winit=0.15; if isfield(hp,'winit'), winit=hp.winit; end
tol=-1; if isfield(hp,'tol'), tol=hp.tol; end
rng(hp.seed);
[N,ne]=size(X); ns=size(Y,2);
v=winit*randn(ne,nm); w=winit*randn(nm,ns);
J=zeros(niter,1); Jold=1e15; yhat=zeros(N,ns); ep=niter;
for it=1:niter
    dJdw=zeros(nm,ns); dJdv=zeros(ne,nm); errsum=0;
    for k=1:N
        in=X(k,:)'; m=v'*in;
        [n,dndm]=activ(m,act);
        o=w'*n; yhat(k,:)=o';
        er=o-Y(k,:)';
        errsum=errsum+0.5*(er'*er);
        if strcmp(mode,'pattern')
            w=w-eta*(n*er');
            v=v-eta*(in*(dndm.*(w*er))');
        else
            dJdw=dJdw+n*er';
            dJdv=dJdv+in*(dndm.*(w*er))';
        end
    end
    if strcmp(mode,'batch')
        w=w-eta*dJdw/N; v=v-eta*dJdv/N;
    end
    J(it)=errsum/N;
    if tol>0
        if sqrt(abs(J(it)-Jold)/J(it))*100 < tol, ep=it; J=J(1:it); break; end
        Jold=J(it);
    end
end
% recomputar prediccion final con los pesos finales
for k=1:N, in=X(k,:)'; [n,~]=activ(v'*in,act); yhat(k,:)=(w'*n)'; end
out.v=v; out.w=w; out.J=J; out.yhat=yhat; out.epochs=ep;
E=yhat-Y; out.rmse=sqrt(mean(E(:).^2));
out.relerr=sqrt(sum(E(:).^2)/sum(Y(:).^2));
end

function [n,dndm]=activ(m,act)
switch act
    case 'log'   % sigmoide logistica (tipo 1)
        n=1.0./(1+exp(-m)); dndm=n.*(1-n);
    case 'bip'   % sigmoide bipolar (tipo 2)
        n=2.0./(1+exp(-m))-1; dndm=(1-n.*n)/2;
    case 'gauss' % gaussiana
        n=exp(-m.^2); dndm=-2.0*(n.*m);
end
end
