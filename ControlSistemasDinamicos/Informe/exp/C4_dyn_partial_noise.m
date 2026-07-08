function C4_dyn_partial_noise(figdir)
% C4 (EXPERIMENTO CENTRAL b): control DINAMICO BPTT en planta inestable.
% Realimentacion parcial (2a), rechazo de perturbaciones y ruido de medicion (2b).
% El entrenamiento BPTT en planta muy inestable requiere CURRICULO (arranque en
% caliente subiendo la inestabilidad), tal como hacen los scripts originales.
fprintf('\n===== C4: Dinamico BPTT (parcial, perturbacion, ruido) =====\n');
B=[0;0.8]; G=[0.1 0;0.1 -0.1]; r=[0;0]; uast=0;
x_ini=[0.1 0.1 -0.1 -0.1; 0.1 -0.1 0.1 -0.1];
diagseq=[0.98 1.02 1.06 1.10 1.15];

% ---- C4a: realimentacion completa vs parcial (currículo por configuracion) ----
% La realimentacion parcial es mas dificil: se usa un currículo mas fino, mas
% iteraciones y una planta objetivo algo menos inestable (diag=1.10).
Pfin.A=[1.10 0.3;-0.2 1.10]; Pfin.B=B; Pfin.G=G; ndp=250;
diaga=[0.98 1.02 1.05 1.08 1.10];
cases={eye(2),[0 1],[1 0]}; cname={'Completa (x_1,x_2)','Parcial C=[0 1] (mide x_2)','Parcial C=[1 0] (mide x_1)'};
nrm=zeros(ndp-1,3); fxa=zeros(1,3);
for i=1:3
    net=curriculum(B,G,x_ini,r,uast,diaga,cases{i},40,0,900);
    Si=sim_ctrl(Pfin,x_ini,r,uast,net,ndp,[]);
    nrm(:,i)=vecnorm(squeeze(Si.estado(:,:,1))')'; fxa(i)=mean(vecnorm(Si.xfin));
end
figure('Visible','off','Position',[0 0 640 380]);
semilogy(max(nrm,1e-6),'LineWidth',1.4); grid on; xlabel('k'); ylabel('||x|| (log)');
legend(cname,'Location','best'); title('C4 - Realimentacion completa vs parcial (BPTT)');
saveas(gcf,fullfile(figdir,'C4_partial.png')); close;
fprintf('  |xf| completa=%.3g  C=[0 1]=%.3g  C=[1 0]=%.3g\n',fxa(1),fxa(2),fxa(3));

% ---- Regulador BPTT en la planta muy inestable (currículo hasta 1.20) ----
netreg=curriculum(B,G,x_ini,r,uast,[diagseq 1.20],eye(2),50,0);

% ---- C4b: rechazo de perturbacion senoidal (amplitud creciente) ----
Pu.A=[1.20 0.3;-0.2 1.20]; Pu.B=B; Pu.G=G; Pu.W=[0;1];
amps=[0 0.01 0.03 0.05 0.1]; ssErr=zeros(size(amps)); dt=0.01; tt=(0:599)'*dt;
figure('Visible','off','Position',[0 0 640 380]);
for i=1:numel(amps)
    wr=amps(i)*sin(2*pi*2*tt);
    Si=sim_ctrl(Pu,[0.1;0.1],r,uast,netreg,600,wr);
    e=vecnorm(squeeze(Si.estado(:,:,1))'); ssErr(i)=mean(e(end-100:end));
    plot(squeeze(Si.estado(1:300,1,1)),'LineWidth',1.2,'DisplayName',sprintf('amp=%.2f',amps(i))); hold on;
end
grid on; xlabel('k'); ylabel('x_1'); legend('Location','best');
title('C4 - Rechazo de perturbacion senoidal (regulacion)');
saveas(gcf,fullfile(figdir,'C4_disturb.png')); close;
fprintf('  error RP vs amp pert: '); fprintf('%.4g ',ssErr); fprintf('\n');

% ---- C4c: ruido de medicion durante el entrenamiento (2b) ----
% Base limpia por currículo hasta 1.12; luego se re-entrena con ruido (warm-start).
base=curriculum(B,G,x_ini,r,uast,[0.98 1.06 1.12],eye(2),40,0);
Pn.A=[1.12 0.3;-0.2 1.12]; Pn.B=B; Pn.G=G;
noises=[0 0.005 0.01 0.02 0.05]; nerr=zeros(size(noises));
for i=1:numel(noises)
    hpi=struct('eta',0.2,'etaa',0.03,'niter',300,'seed',1,'q',[1;1],'ndata',200,'noise',noises(i),'init',base);
    oi=train_bptt_ctrl(Pn,x_ini,r,uast,eye(2),40,hpi);
    Sc=sim_ctrl(Pn,x_ini,r,uast,oi.net,250,[]);   % validar sin ruido
    nerr(i)=mean(vecnorm(Sc.xfin-r));
end
figure('Visible','off','Position',[0 0 560 360]);
plot(noises,nerr,'-o','LineWidth',1.3); grid on;
xlabel('Ruido de medicion en el entrenamiento \eta'); ylabel('Error final medio ||x_f||');
title('C4 - Efecto del ruido de medicion (BPTT)');
saveas(gcf,fullfile(figdir,'C4_noise.png')); close;
fprintf('  errfinal vs ruido: '); fprintf('%.4g ',nerr); fprintf('\n');

save(fullfile(figdir,'..','exp','C4_metrics.mat'),'fxa','amps','ssErr','noises','nerr');
fprintf('  C4 OK.\n');
end

function net = curriculum(B,G,x_ini,r,uast,diags,C,nm,noise,niter)
% Entrena un regulador BPTT de forma incremental subiendo la inestabilidad,
% arrancando en caliente en cada nivel. C: matriz de salida ; nm: neuronas.
if nargin<10 || isempty(niter), niter=400; end
hp=struct('eta',0.3,'etaa',0.05,'niter',niter,'seed',1,'q',[1;1],'ndata',200,'noise',noise);
init=[];
for d=diags
    P.A=[d 0.3;-0.2 d]; P.B=B; P.G=G;
    hp.init=init; o=train_bptt_ctrl(P,x_ini,r,uast,C,nm,hp); init=o.net;
end
net=o.net;
end
