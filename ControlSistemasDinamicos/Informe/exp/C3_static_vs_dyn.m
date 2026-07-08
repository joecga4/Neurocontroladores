function C3_static_vs_dyn(figdir)
% C3 (EXPERIMENTO CENTRAL a): control ESTATICO vs DINAMICO (BPTT) en planta INESTABLE.
% Tesis del PDF (Clase 9): el aprendizaje estatico no estabiliza sistemas inestables
% (ignora la dinamica de lazo cerrado); el dinamico (BPTT) si lo logra.
fprintf('\n===== C3: Estatico vs Dinamico (planta inestable) =====\n');
B=[0;0.8]; G=[0.1 0;0.1 -0.1]; r=[0;0]; uast=0;
x_ini=[0.1 0.1 -0.1 -0.1; 0.1 -0.1 0.1 -0.1];

% ---- Barrido de inestabilidad (diagonal de A) ----
diags=[0.98 1.02 1.06 1.10 1.15 1.20];
errS=zeros(size(diags)); errD=zeros(size(diags));
hpS=struct('eta',1.0,'etaa',0.1,'alpha',0.9,'R',0.0,'niter',500,'seed',1,'q',[1;1],'ndata',200);
hpD=struct('eta',0.3,'etaa',0.05,'niter',400,'seed',1,'q',[1;1],'ndata',200);
initD=[];
for i=1:numel(diags)
    d=diags(i); P.A=[d 0.3;-0.2 d]; P.B=B; P.G=G;
    % Estatico: entrenado desde cero en cada nivel
    oS=train_static_ctrl(P,x_ini,r,uast,50,hpS);
    errS(i)=mean(vecnorm(oS.xfin-r));
    % Dinamico BPTT: incremental (arranque en caliente del nivel previo)
    hpi=hpD; hpi.init=initD;
    oD=train_bptt_ctrl(P,x_ini,r,uast,eye(2),50,hpi);
    errD(i)=mean(vecnorm(oD.xfin-r));
    initD=oD.net;   % warm-start para el siguiente nivel
end
figure('Visible','off','Position',[0 0 620 380]);
semilogy(diags,max(errS,1e-6),'-s','LineWidth',1.5); hold on;
semilogy(diags,max(errD,1e-6),'-o','LineWidth',1.5); grid on;
xlabel('Inestabilidad (diagonal de A)'); ylabel('Error final medio ||x_f|| (log)');
legend('Estatico','Dinamico (BPTT)','Location','northwest');
title('C3 - Estabilizacion vs grado de inestabilidad'); yline(0.1,'k--');
saveas(gcf,fullfile(figdir,'C3_sweep.png')); close;
fprintf('  errS: '); fprintf('%.3g ',errS); fprintf('\n  errD: '); fprintf('%.3g ',errD); fprintf('\n');

% ---- Comparacion directa en la planta mas inestable (A diag=1.20) ----
P.A=[1.20 0.3;-0.2 1.15]; P.B=B; P.G=G; ndp=200;
oS=train_static_ctrl(P,x_ini,r,uast,50,hpS);
hpi=hpD; hpi.init=initD; oD=train_bptt_ctrl(P,x_ini,r,uast,eye(2),50,hpi);
Ss=sim_ctrl(P,x_ini,r,uast,oS.net,ndp,[]); Sd=sim_ctrl(P,x_ini,r,uast,oD.net,ndp,[]);
ns1=vecnorm(squeeze(Ss.estado(:,:,1))'); nd1=vecnorm(squeeze(Sd.estado(:,:,1))');
figure('Visible','off','Position',[0 0 620 380]);
semilogy(max(ns1,1e-6),'--','LineWidth',1.5); hold on; semilogy(max(nd1,1e-6),'LineWidth',1.5);
grid on; xlabel('k'); ylabel('||x|| (log)');
legend('Estatico (diverge)','Dinamico BPTT (estabiliza)','Location','best');
title('C3 - Respuesta en la planta inestable A=[1.20 0.3;-0.2 1.15]');
saveas(gcf,fullfile(figdir,'C3_response.png')); close;
fprintf('  A=1.20  |xf| estatico=%.3g  dinamico=%.3g\n',mean(vecnorm(Ss.xfin)),mean(vecnorm(Sd.xfin)));

save(fullfile(figdir,'..','exp','C3_metrics.mat'),'diags','errS','errD');
fprintf('  C3 OK.\n');
end
