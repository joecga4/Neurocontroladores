function out = train_bptt_ctrl(P, x_ini, r, uast, C, nm, hp)
% Entrenamiento DINAMICO (BPTT / DBP) de un neurocontrolador (fiel a DynamicBPControl2.m).
% Propaga las derivadas del estado respecto de los parametros RECURSIVAMENTE en el
% tiempo a traves del jacobiano del lazo cerrado jacob_t.
%   P : planta A,B,G,(W,pert opcionales) ; C : matriz de salida (ne=size(C,1))
%      C=eye(2) -> realimentacion completa ; C=[0 1] -> parcial (mide x2)
%   hp : eta,etaa,niter,seed,q,ndata  (+ opcional hp.noise ruido en in_red)
A=P.A; B=P.B; G=P.G;
if isfield(P,'W'), W=P.W; else, W=[0;0]; end
if isfield(P,'pert'), pert=P.pert; else, pert=0; end
noise = 0; if isfield(hp,'noise'), noise=hp.noise; end
eta=hp.eta; etaa=hp.etaa; etac=0; niter=hp.niter; q=hp.q; ndata=hp.ndata;
rng(hp.seed);
[nx,nini]=size(x_ini); ne=size(C,1); ns=1;
v=0.1*randn(ne,nm); w=0.1*randn(nm,ns); c=zeros(nm,1); a=ones(nm,1);
if isfield(hp,'init') && ~isempty(hp.init)   % arranque en caliente (curriculo)
    v=hp.init.v; w=hp.init.w; c=hp.init.c; a=hp.init.a;
end
JJ=zeros(niter,1); erreltotal=1; J0=1;
for it=1:niter
    ersum2=zeros(nx,1);
    dJdw_t=zeros(nm,ns); dJdv_t=zeros(ne,nm); dJdc_t=zeros(nm,1); dJda_t=zeros(nm,1);
    ktot=0;
    for j=1:nini
        Sw_t=zeros(nm,nx); Sc_t=zeros(nm,nx); Sa_t=zeros(nm,nx); Sv_t=zeros(ne,nm,nx);
        x=x_ini(:,j);
        for k=1:ndata-1
            in_red=C*(x-r) + noise*randn(ne,1);
            m=v'*in_red; n=2.0./(1+exp(-(m-c)./a))-1; u=w'*n + uast;
            jacob=A + u.*G; dxdu=B+G*x;
            x=A*x + B*u + (G*x)*u + W*pert*sin(2*pi*1*k*0.01);
            dndm=diag((1-n.*n)./(2*a));
            dudw_s=n; dudv_s=in_red*w'*dndm;
            dudc_s=w.*((n.*n-1)./(2.0.*a));
            duda_s=w.*((n.*n-1).*(m-c)./(2*a.*a));
            dudx=(w'*dndm*v')*C;         % du/dx (1 x nx), incluye la matriz de salida C
            jacob_t=dxdu*dudx + jacob;   % jacobiano del lazo cerrado (nx x nx)
            Sw_t=dudw_s*dxdu' + Sw_t*jacob_t';
            Sc_t=dudc_s*dxdu' + Sc_t*jacob_t';
            Sa_t=duda_s*dxdu' + Sa_t*jacob_t';
            Sv_new=zeros(ne,nm,nx);
            for i=1:nx
                inc=dxdu(i,1).*dudv_s;
                for jj=1:nx, inc=inc+jacob_t(i,jj).*Sv_t(:,:,jj); end
                Sv_new(:,:,i)=inc;
            end
            Sv_t=Sv_new;
            er=x-r; erq=q.*er;
            dJdw_t=dJdw_t+Sw_t*erq; dJdc_t=dJdc_t+Sc_t*erq; dJda_t=dJda_t+Sa_t*erq;
            for i=1:nx, dJdv_t=dJdv_t+erq(i,1).*Sv_t(:,:,i); end
            ersum2=ersum2+er.^2;
            if any(abs(x)>50), break; end     % corte por divergencia
        end
        ktot=ktot+k;
    end
    w=w-eta*dJdw_t/ktot; v=v-eta*dJdv_t/ktot;
    c=c-etac*dJdc_t/ktot; a=a-etaa*dJda_t/ktot;
    JJt=sum(ersum2); JJ(it)=JJt;
    if it==1, J0=JJt; if J0==0, J0=1; end; end
    erreltotal=JJt/J0;
    if ~isfinite(JJt), JJ=JJ(1:it); break; end
    JJ1(it,1)=ersum2(1); JJ2(it,1)=ersum2(2);
end
net.v=v; net.w=w; net.c=c; net.a=a; net.C=C;
out.net=net; out.JJ=JJ; out.JJbest=min(JJ);
out.JJ1=JJ1; out.JJ2=JJ2;
S=sim_ctrl(P, x_ini, r, uast, net, ndata, []);
out.estado=S.estado; out.u=S.u; out.xfin=S.xfin; out.stable=S.stable;
end
