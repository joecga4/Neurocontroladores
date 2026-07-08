function E56_arch(figdir)
% E5: red dinamica de UNA capa oculta vs DOS capas (DosIntermedias).
% E6: modelamiento dinamico de un sistema de 3 variables (fiel a 3v).
fprintf('\n===== E5/E6: Arquitecturas =====\n');

% ---------- E5: una vs dos capas ----------
u = gen_input();
z = plant_nl2(u, [0.1;0.2]);
seed=1; niter=600;
o1 = lib_dbp(z, u, 12, 0.05, 0.0, niter, seed, [1;1], false);   % 1 capa, 12 neur
o2 = train_2hidden(z, u, 12, 10, 0.05, niter, seed);            % 2 capas 12-10
figure('Visible','off','Position',[0 0 560 360]);
semilogy(o1.errhist*100,'LineWidth',1.3,'DisplayName','1 capa (12)'); hold on;
semilogy(o2.errhist*100,'LineWidth',1.3,'DisplayName','2 capas (12-10)'); grid on;
xlabel('Iteracion'); ylabel('Error relativo total [%]'); legend('Location','best');
title('E5 - Una vs dos capas ocultas (DBP)');
saveas(gcf, fullfile(figdir,'E5_layers.png')); close;
fprintf('  1 capa=%.4f  2 capas=%.4f\n', o1.finalerr, o2.finalerr);

% ---------- E6: sistema de 3 variables ----------
nu=400; nt=(0:nu-1)'; u3 = sin(2*pi*0.005*nt);
z3 = plant_lin3(u3);
o3 = lib_dbp(z3, u3, 60, 0.05, 0.0, 800, seed, [1;1;1], true);  % lineal, como el script
nd=size(z3,1);
figure('Visible','off','Position',[0 0 760 520]);
for j=1:3
  subplot(3,1,j);
  plot(z3(2:nd,j),'r','LineWidth',1.2); hold on; plot(o3.outfit(:,j),'b--','LineWidth',1.1);
  grid on; ylabel(sprintf('z_%d',j));
  if j==1, title('E6 - Modelo dinamico de 3 variables (rojo: sistema, azul: red)'); end
end
xlabel('Muestra');
saveas(gcf, fullfile(figdir,'E6_three.png')); close;
fprintf('  3 variables errrel=%.4f\n', o3.finalerr);

save(fullfile(figdir,'..','exp','E56_metrics.mat'), ...
    'o1','o2'); %#ok<NASGU>
fprintf('  E5/E6 OK.\n');
end

function z = plant_lin3(u)
nu=numel(u);
z1=zeros(nu+1,1); z2=zeros(nu+1,1); z3=zeros(nu+1,1);
z1(1)=0.1; z2(1)=0; z3(1)=0.2;
for k=1:nu
    z1(k+1)=0.35*z1(k)-0.4*z2(k)+0.5*z3(k);
    z2(k+1)=0.4*z1(k)+0.5*0.15*z2(k)+0.5*u(k);
    z3(k+1)=0.5*0.4*z2(k)+0.2*z3(k)+0.5*u(k);
end
z=[z1(1:nu) z2(1:nu) z3(1:nu)];
end

function out = train_2hidden(z, u, nmh, nph, eta, niter, seed)
% Red dinamica con DOS capas ocultas (fiel a DynamicBPModelamientoDosIntermedias.m).
rng(seed);
ndata=size(z,1); ns=2; ne=3;
ur=0.1*randn(ne,nmh); v=0.1*randn(nmh,nph); w=0.1*randn(nph,ns);
c1=zeros(nmh,1); a1=ones(nmh,1); c2=zeros(nph,1); a2=ones(nph,1);
outsum2total=sum(sum(z.^2)); errhist=zeros(niter,1); outfit=zeros(ndata-1,ns);
for iter=1:niter
  ersum2=zeros(ns,1);
  dy1dw_t=zeros(nph,ns); dy2dw_t=zeros(nph,ns);
  dy1dv_t=zeros(nmh,nph); dy2dv_t=zeros(nmh,nph);
  dy1du_t=zeros(ne,nmh); dy2du_t=zeros(ne,nmh);
  dJdw_t=zeros(nph,ns); dJdv_t=zeros(nmh,nph); dJdu_t=zeros(ne,nmh);
  x=z(1,:)';
  for k=1:ndata-1
    in_red=[x; u(k)];
    m=ur'*in_red; n=2.0./(1+exp(-(m-c1)./a1))-1;
    p=v'*n;       q=2.0./(1+exp(-(p-c2)./a2))-1;
    yo=w'*q; outfit(k,:)=yo';
    dndm=diag((1-n.*n)./(2*a1)); dqdp=diag((1-q.*q)./(2*a2));
    dy1dw_s=[q zeros(nph,1)]; dy2dw_s=[zeros(nph,1) q];
    dy1dv_s=n*w(:,1)'*dqdp;   dy2dv_s=n*w(:,2)'*dqdp;
    dy1du_s=in_red*w(:,1)'*dqdp*v'*dndm;
    dy2du_s=in_red*w(:,2)'*dqdp*v'*dndm;
    jacob=w'*dqdp*v'*dndm*(ur(1:ne-1,:))';
    dy1dw_t=dy1dw_s+jacob(1,1).*dy1dw_t+jacob(1,2).*dy2dw_t;
    dy2dw_t=dy2dw_s+jacob(2,1).*dy1dw_t+jacob(2,2).*dy2dw_t;
    dy1dv_t=dy1dv_s+jacob(1,1).*dy1dv_t+jacob(1,2).*dy2dv_t;
    dy2dv_t=dy2dv_s+jacob(2,1).*dy1dv_t+jacob(2,2).*dy2dv_t;
    dy1du_t=dy1du_s+jacob(1,1).*dy1du_t+jacob(1,2).*dy2du_t;
    dy2du_t=dy2du_s+jacob(2,1).*dy1du_t+jacob(2,2).*dy2du_t;
    er=yo-z(k+1,:)';
    dJdw_t=dJdw_t+er(1).*dy1dw_t+er(2).*dy2dw_t;
    dJdv_t=dJdv_t+er(1).*dy1dv_t+er(2).*dy2dv_t;
    dJdu_t=dJdu_t+er(1).*dy1du_t+er(2).*dy2du_t;
    ersum2=ersum2+er.^2; x=yo;
  end
  w=w-eta*dJdw_t/ndata; v=v-eta*dJdv_t/ndata; ur=ur-eta*dJdu_t/ndata;
  errhist(iter)=sqrt(sum(ersum2)/outsum2total);
end
out.errhist=errhist; out.outfit=outfit; out.finalerr=errhist(end);
end
