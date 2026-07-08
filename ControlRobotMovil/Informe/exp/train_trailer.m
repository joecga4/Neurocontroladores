function out = train_trailer(hp)
% Entrenamiento BPTT del neurocontrolador del ROBOT TIPO TRAILER (truck-trailer).
% Modelo de control (3 estados relevantes; la Y no afecta a la direccion):
%   s = [ x ; th1 ; th2 ]   (x = posicion del trailer, th1 truck, th2 trailer)
%   th12 = th1 - th2  (angulo de articulacion / hitch)
%   x(k+1)   = x   + r*cos(th12)*cos(th2)
%   th1(k+1) = th1 - (r/L1)*u              (u = tan(delta), salida de la red)
%   th2(k+1) = th2 - (r/L2)*sin(th12)
% Meta (regulacion / estacionamiento vertical): x*=0, th2*=pi/2, hitch th12->0.
% Entradas de la red: [x-x*, wrap(th2-th2*), th12] normalizadas por inscale.
% Currículo incremental sobre x0 y orientaciones (como DynamicBPCarro).
r=0.01; L1=hp.L1; L2=hp.L2;
inscale=hp.inscale; q=hp.q; ndata=hp.ndata;
Ttrunc=hp.Ttrunc; gmax=hp.gmax; nm=hp.nm;
xstar=0; th2star=pi/2;
ne=3; nx=3; ns=1;
rng(1);
if isfield(hp,'init') && ~isempty(hp.init)
    v=hp.init.v; w=hp.init.w; c=hp.init.c; a=hp.init.a;
else
    v=0.1*randn(ne,nm); w=0.1*randn(nm,ns); c=zeros(nm,1); a=ones(nm,1);
end
x_ini=hp.x_ini; nini=size(x_ini,2);
JJ=zeros(hp.niter,1); erreltotal=1; J0=1;
JJbest=inf; vb=v; wb=w; cb=c; ab=a;    % seguimiento de MEJORES pesos
for it=1:hp.niter
    ersum2=zeros(nx,1);
    dJdw_t=zeros(nm,ns); dJdv_t=zeros(ne,nm); dJda_t=zeros(nm,1); dJdc_t=zeros(nm,1);
    Sw_t=zeros(nm,nx); Sc_t=zeros(nm,nx); Sa_t=zeros(nm,nx); Sv_t=zeros(ne,nm,nx);
    ktot=0;
    for j=1:nini
        s=x_ini(:,j);
        for k=1:ndata-1
            th12=s(2)-s(3); th2=s(3);
            % entrada de la red (errores) normalizada
            e1=s(1)-xstar; e2=mod(th2-th2star+pi,2*pi)-pi; e3=mod(th12+pi,2*pi)-pi;
            in_red=[e1;e2;e3]./inscale;
            m=v'*in_red; n=2.0./(1+exp(-(m-c)./a))-1; u=w'*n;
            % Jacobianos de la planta
            s12=sin(th12); c12=cos(th12); s2=sin(th2); c2=cos(th2);
            jacob=[ 1, -r*s12*c2, r*(s12*c2 - c12*s2);
                    0, 1,          0;
                    0, -(r/L2)*c12, 1+(r/L2)*c12 ];
            dxdu=[0; -r/L1; 0];
            % dinamica
            s=[ s(1)+r*c12*c2 ; s(2)-(r/L1)*u ; s(3)-(r/L2)*s12 ];
            % derivadas de la red
            dndm=diag((1-n.*n)./(2*a));
            dudw_s=n; dudv_s=in_red*w'*dndm;
            dudc_s=w.*((n.*n-1)./(2.0.*a));
            duda_s=w.*((n.*n-1).*(m-c)./(2*a.*a));
            % du/ds = (w'dndm v') * d(in)/ds  ; d(in)/ds (ne x nx)
            dinds=[1/inscale(1),0,0; 0,0,1/inscale(2); 0,1/inscale(3),-1/inscale(3)];
            dudx=(w'*dndm*v')*dinds;    % 1 x nx
            jacob_t=dxdu*dudx + jacob;
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
            % error de seguimiento (estado ya actualizado)
            er=[ s(1)-xstar ; mod(s(3)-th2star+pi,2*pi)-pi ; mod((s(2)-s(3))+pi,2*pi)-pi ];
            erq=q.*er;
            dJdw_t=dJdw_t+Sw_t*erq; dJdc_t=dJdc_t+Sc_t*erq; dJda_t=dJda_t+Sa_t*erq;
            for i=1:nx, dJdv_t=dJdv_t+erq(i,1).*Sv_t(:,:,i); end
            ersum2=ersum2+q.*(er.^2);
            if mod(k,Ttrunc)==0
                Sw_t=zeros(nm,nx); Sc_t=zeros(nm,nx); Sa_t=zeros(nm,nx); Sv_t=zeros(ne,nm,nx);
            end
            if abs(s(1))>30, break; end
        end
        ktot=ktot+k;
    end
    gw=dJdw_t/ktot; nr=norm(gw(:)); if nr>gmax, gw=gw*gmax/nr; end
    gv=dJdv_t/ktot; nr=norm(gv(:)); if nr>gmax, gv=gv*gmax/nr; end
    ga=dJda_t/ktot; nr=norm(ga(:)); if nr>gmax, ga=ga*gmax/nr; end
    w=w-hp.eta*gw; v=v-hp.eta*gv; a=a-hp.etaa*ga;
    JJt=sum(ersum2); JJ(it)=JJt;
    if it==1, J0=JJt; if J0==0, J0=1; end; end
    erreltotal=JJt/J0;
    if isfinite(JJt) && JJt<JJbest, JJbest=JJt; vb=v; wb=w; cb=c; ab=a; end
    if ~isfinite(JJt) || JJt>5*JJbest, JJ=JJ(1:it); break; end  % corta si diverge
    if mod(it,25)==0, fprintf('  trailer it=%d costo=%.4g errrel=%.4g best=%.4g\n',it,JJt,erreltotal,JJbest); end
end
out.v=vb; out.w=wb; out.c=cb; out.a=ab; out.JJ=JJ; out.inscale=inscale;   % MEJORES pesos
out.L1=L1; out.L2=L2; out.finalcost=JJbest; out.J0=J0;
end
