function S = sim_ctrl(P, x_ini, r, uast, net, ndata, wr)
% Simula el lazo cerrado planta+neurocontrolador para cada condicion inicial.
%   net.C : matriz de salida ; net.zero=true -> control apagado (u=0, comparacion)
%   wr : (opcional) vector de perturbacion externa por paso (via P.W). Si vacio,
%        usa P.pert*sin(...) si P.pert existe.
A=P.A; B=P.B; G=P.G;
if isfield(P,'W'), W=P.W; else, W=[0;0]; end
if isfield(P,'pert'), pert=P.pert; else, pert=0; end
useZero = isfield(net,'zero') && net.zero;
[nx,nini]=size(x_ini);
S.estado=zeros(ndata-1,nx,nini); S.u=zeros(ndata-1,nini);
S.xfin=zeros(nx,nini); S.stable=false(1,nini);
for j=1:nini
    x=x_ini(:,j);
    for k=1:ndata-1
        if useZero
            u=0;
        else
            in_red=net.C*(x-r);
            m=net.v'*in_red; n=2.0./(1+exp(-(m-net.c)./net.a))-1;
            u=net.w'*n + uast;
        end
        if ~isempty(wr), d=wr(min(k,numel(wr)));
        else, d=pert*sin(2*pi*1*k*0.01); end
        x=A*x + B*u + (G*x)*u + W*d;
        S.estado(k,:,j)=x'; S.u(k,j)=u;
        if any(abs(x)>1e3), break; end
    end
    S.xfin(:,j)=x;
    S.stable(j)= all(isfinite(x)) && norm(x-r)<1e-1;
end
end
