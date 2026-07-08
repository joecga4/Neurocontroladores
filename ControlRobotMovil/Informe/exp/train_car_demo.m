function train_car_demo(figdir)
% Demostracion de ENTRENAMIENTO del neurocontrolador del carro por BPTT
% (fiel a DynamicBPCarro.m, etapa 1 con horizonte reducido para ilustrar la
% convergencia). Genera la curva de costo. Los pesos finales para las
% trayectorias son los del currículo completo (redcarro11).
fprintf('\n===== CARRO: demo de entrenamiento =====\n');
r=0.01; L=2; out_des=[0;pi/2]; inscale=[10;1];
x1set=[-5 0 5]; thset=(0:90:270)*pi/180;
[X1,TH]=meshgrid(x1set,thset); x_ini=[X1(:)';TH(:)'];
nx=2; ne=2; nm=50; ns=1; ndata=2500; Ttrunc=200; gmax=20;
eta=0.05; etaa=0.005; niter=200; q=[1;10];
rng(1); v=0.1*randn(ne,nm); w=0.1*randn(nm,ns); c=zeros(nm,1); a=ones(nm,1);
nini=size(x_ini,2); JJ=zeros(niter,1);
for it=1:niter
    ersum2=zeros(nx,1);
    Sw_t=zeros(nm,nx);Sc_t=zeros(nm,nx);Sa_t=zeros(nm,nx);Sv_t=zeros(ne,nm,nx);
    dJdw_t=zeros(nm,ns);dJdv_t=zeros(ne,nm);dJdc_t=zeros(nm,1);dJda_t=zeros(nm,1);
    ktot=0;
    for j=1:nini
        x=x_ini(:,j);
        for k=1:ndata-1
            e2=mod(x(2)-out_des(2)+pi,2*pi)-pi;
            in_red=[x(1)-out_des(1);e2]./inscale;
            m=v'*in_red; n=2./(1+exp(-(m-c)./a))-1; u=w'*n;
            jacob=[1,-r*sin(x(2));0,1]; dxdu=[0;-r/L];
            x=[x(1)+r*cos(x(2)); x(2)-r/L*u];
            dndm=diag((1-n.*n)./(2*a));
            dudw_s=n; dudv_s=in_red*w'*dndm;
            dudc_s=w.*((n.*n-1)./(2*a)); duda_s=w.*((n.*n-1).*(m-c)./(2*a.*a));
            dudx=(w'*dndm*v')./inscale';
            jacob_t=dxdu*dudx+jacob;
            Sw_t=dudw_s*dxdu'+Sw_t*jacob_t';
            Sc_t=dudc_s*dxdu'+Sc_t*jacob_t';
            Sa_t=duda_s*dxdu'+Sa_t*jacob_t';
            Sv_new=zeros(ne,nm,nx);
            for i=1:nx
                inc=dxdu(i,1).*dudv_s;
                for jj=1:nx, inc=inc+jacob_t(i,jj).*Sv_t(:,:,jj); end
                Sv_new(:,:,i)=inc;
            end
            Sv_t=Sv_new;
            er=[x(1)-out_des(1); mod(x(2)-out_des(2)+pi,2*pi)-pi]; erq=q.*er;
            dJdw_t=dJdw_t+Sw_t*erq; dJdc_t=dJdc_t+Sc_t*erq; dJda_t=dJda_t+Sa_t*erq;
            for i=1:nx, dJdv_t=dJdv_t+erq(i).*Sv_t(:,:,i); end
            ersum2=ersum2+q.*(er.^2);
            if mod(k,Ttrunc)==0, Sw_t=zeros(nm,nx);Sc_t=zeros(nm,nx);Sa_t=zeros(nm,nx);Sv_t=zeros(ne,nm,nx); end
            if abs(x(1))>25, break; end
        end
        ktot=ktot+k;
    end
    gw=dJdw_t/ktot;nr=norm(gw(:));if nr>gmax,gw=gw*gmax/nr;end
    gv=dJdv_t/ktot;nr=norm(gv(:));if nr>gmax,gv=gv*gmax/nr;end
    ga=dJda_t/ktot;nr=norm(ga(:));if nr>gmax,ga=ga*gmax/nr;end
    w=w-eta*gw; v=v-eta*gv; a=a-etaa*ga;
    JJ(it)=sum(ersum2);
    if mod(it,50)==0, fprintf('  car it=%d costo=%.4g\n',it,JJ(it)); end
end
figure('Visible','off','Position',[0 0 560 360]);
plot(JJ/JJ(1),'LineWidth',1.4); grid on; xlabel('Iteracion'); ylabel('Costo relativo J/J_0');
title('Carro - Convergencia del entrenamiento BPTT (etapa 1)');
saveas(gcf,fullfile(figdir,'car_training.png')); close;
fprintf('  car demo: J0=%.4g Jfin=%.4g (relativo=%.3f)\n',JJ(1),JJ(end),JJ(end)/JJ(1));
end
