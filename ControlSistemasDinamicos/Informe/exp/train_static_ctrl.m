function out = train_static_ctrl(P, x_ini, r, uast, nm, hp)
% Entrenamiento ESTATICO de un neurocontrolador (fiel a DynamicBPControlEstaticoModelo0.m).
% El gradiente usa SOLO la sensibilidad instantanea dxdu = B + G*x (sin recursion temporal).
%   P  : struct de planta con campos A,B,G
%   x_ini : nx x nini condiciones iniciales ; r : setpoint ; uast : feedforward
%   nm : neuronas ; hp : struct con eta,etaa,alpha,R,niter,seed,q,ndata
% Devuelve pesos, historial de costo y respuesta en lazo cerrado (mejores pesos).
A=P.A; B=P.B; G=P.G;
eta=hp.eta; etaa=hp.etaa; etac=0; alpha=hp.alpha; R=hp.R;
niter=hp.niter; q=hp.q; ndata=hp.ndata;
rng(hp.seed);
[nx,nini]=size(x_ini); ne=nx; ns=1;
v=0.1*randn(ne,nm); w=0.1*randn(nm,ns); c=zeros(nm,1); a=ones(nm,1);
dw_old=0; dv_old=0; dc_old=0; da_old=0;
JJ=zeros(niter,1);
JJbest=1e30; wbest=w; vbest=v; cbest=c; abest=a;
for it=1:niter
    ersum2=zeros(nx,1); dJdw_t=zeros(nm,ns); dJdv_t=zeros(ne,nm);
    dJdc_t=zeros(nm,1); dJda_t=zeros(nm,1); ktot=0;
    for j=1:nini
        x=x_ini(:,j);
        for k=1:ndata-1
            in_red=x-r;
            m=v'*in_red; n=2.0./(1+exp(-(m-c)./a))-1; u=w'*n + uast;
            dxdu=B+G*x;
            x=A*x + B*u + (G*x)*u;
            dndm=diag((1-n.*n)./(2*a));
            dudw_s=n; dudv_s=in_red*w'*dndm;
            dudc_s=w.*((n.*n-1)./(2.0.*a));
            duda_s=w.*((n.*n-1).*(m-c)./(2*a.*a));
            er=x-r; erq=q.*er; g=erq'*dxdu + R*u;
            dJdw_t=dJdw_t+g*dudw_s; dJdv_t=dJdv_t+g*dudv_s;
            dJdc_t=dJdc_t+g*dudc_s; dJda_t=dJda_t+g*duda_s;
            ersum2=ersum2+er.^2 + R*u^2;
        end
        ktot=ktot+k;
    end
    dw_old=eta*dJdw_t/ktot + alpha*dw_old;
    dv_old=eta*dJdv_t/ktot + alpha*dv_old;
    dc_old=etac*dJdc_t/ktot + alpha*dc_old;
    da_old=etaa*dJda_t/ktot + alpha*da_old;
    w=w-dw_old; v=v-dv_old; c=c-dc_old; a=a-da_old;
    JJt=sum(ersum2); JJ(it)=JJt;
    if(JJt<JJbest), JJbest=JJt; wbest=w;vbest=v;cbest=c;abest=a; end
    if(~isfinite(JJt) || JJt>50*JJbest), JJ=JJ(1:it); break; end
end
net.v=vbest; net.w=wbest; net.c=cbest; net.a=abest; net.C=eye(nx);
out.net=net; out.JJ=JJ; out.JJbest=JJbest;
% Respuesta en lazo cerrado con los mejores pesos
S=sim_ctrl(P, x_ini, r, uast, net, ndata, []);
out.estado=S.estado; out.u=S.u; out.xfin=S.xfin; out.stable=S.stable;
end
