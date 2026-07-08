function C2_robust_dist(figdir)
% C2: Robustez ante cambios de planta (Modelo3) y rechazo de perturbaciones
% (Modelo1) usando el neurocontrolador ESTATICO entrenado en la planta nominal.
fprintf('\n===== C2: Robustez y perturbaciones (estatico) =====\n');
P.A=[0.98 0.18; -0.10 0.98]; P.B=[0;0.8]; P.G=[0.1 0;0.1 -0.1];
x_ini=[0.1 0.1 -0.1 -0.1; 0.1 -0.1 0.1 -0.1]; r0=[0;0]; uast0=0;
hp=struct('eta',2.0,'etaa',0.2,'alpha',0.95,'R',0.05,'niter',600,'seed',1,'q',[1;1],'ndata',300);
o=train_static_ctrl(P,x_ini,r0,uast0,50,hp);   % controlador nominal

% ---- Robustez: aplicar el MISMO controlador a variantes de planta ----
V(1)=struct('A',P.A,'B',P.B,'G',P.G,'name','Nominal');
V(2)=struct('A',[1.02 0.18;-0.10 1.02],'B',P.B,'G',P.G,'name','A menos estable');
V(3)=struct('A',P.A,'B',0.5*P.B,'G',P.G,'name','Ganancia B -50%');
V(4)=struct('A',P.A,'B',P.B,'G',2*P.G,'name','Bilineal G x2');
x0=[0.1;0.1]; ndp=400; nrm=zeros(ndp-1,4); verd=zeros(1,4);
for i=1:4
    Pi.A=V(i).A; Pi.B=V(i).B; Pi.G=V(i).G;
    Si=sim_ctrl(Pi,x0,r0,uast0,o.net,ndp,[]);
    nrm(:,i)=vecnorm(squeeze(Si.estado(:,:,1))')';
    verd(i)=Si.stable(1);
end
figure('Visible','off','Position',[0 0 620 380]);
plot(nrm,'LineWidth',1.3); grid on; xlabel('k'); ylabel('||x||');
legend({V.name},'Location','best'); title('C2 - Robustez ante variaciones de planta');
saveas(gcf,fullfile(figdir,'C2_robust.png')); close;
fprintf('  robustez estable? '); fprintf('%d ',verd); fprintf('\n');

% ---- Rechazo de perturbacion senoidal (Modelo1: tracking con feedforward) ----
r=[0.1;0.01041]; uast=0.01262;   % setpoint con su control de equilibrio
Pd=P; Pd.W=[0;0.01];
perts=[0 0.02 0.1 0.5]; ampErr=zeros(size(perts)); x0t=[0;0];
figure('Visible','off','Position',[0 0 700 380]);
for i=1:numel(perts)
    Pi=Pd; Pi.pert=perts(i);
    Si=sim_ctrl(Pi,x0t,r,uast,o.net,600,[]);
    e=vecnorm((squeeze(Si.estado(:,:,1))'-r));
    ampErr(i)=mean(e(end-100:end));   % error en regimen permanente
    plot(squeeze(Si.estado(:,1,1)),'LineWidth',1.2,'DisplayName',sprintf('pert=%.2f',perts(i)));
    hold on;
end
yline(r(1),'k--','DisplayName','consigna x_1'); grid on; xlabel('k'); ylabel('x_1');
legend('Location','best'); title('C2 - Seguimiento de x_1 con perturbacion senoidal');
saveas(gcf,fullfile(figdir,'C2_disturb.png')); close;
fprintf('  error RP vs pert: '); fprintf('%.4g ',ampErr); fprintf('\n');

save(fullfile(figdir,'..','exp','C2_metrics.mat'),'verd','perts','ampErr');
fprintf('  C2 OK.\n');
end
