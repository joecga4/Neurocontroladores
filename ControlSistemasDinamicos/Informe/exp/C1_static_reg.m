function C1_static_reg(figdir)
% C1: Neurocontrolador ESTATICO en planta ESTABLE (regulacion al origen).
% Estudia convergencia, mejora del transitorio, peso R del esfuerzo, # neuronas
% y generalizacion a condiciones iniciales mayores.
fprintf('\n===== C1: Control estatico (planta estable) =====\n');
P.A=[0.98 0.18; -0.10 0.98]; P.B=[0;0.8]; P.G=[0.1 0;0.1 -0.1];
x_ini=[0.1 0.1 -0.1 -0.1; 0.1 -0.1 0.1 -0.1];
r=[0;0]; uast=0;
hp=struct('eta',2.0,'etaa',0.2,'alpha',0.95,'R',0.05,'niter',600,'seed',1,'q',[1;1],'ndata',300);

o=train_static_ctrl(P,x_ini,r,uast,50,hp);
fprintf('  costo mejor=%.4f  estable=[%d %d %d %d]\n',o.JJbest,o.stable);

% Convergencia
figure('Visible','off','Position',[0 0 560 360]);
semilogy(o.JJ,'LineWidth',1.3); grid on; xlabel('Iteracion'); ylabel('Costo J');
title('C1 - Convergencia del control estatico'); saveas(gcf,fullfile(figdir,'C1_conv.png')); close;

% Respuesta en lazo cerrado (CI #1): estados y control
figure('Visible','off','Position',[0 0 700 420]);
subplot(2,1,1); plot(o.estado(1:150,:,1),'LineWidth',1.2); grid on; ylabel('estados');
legend('x_1','x_2','Location','best'); title('C1 - Respuesta en lazo cerrado (CI 1)');
subplot(2,1,2); plot(o.u(1:150,1),'LineWidth',1.2); grid on; ylabel('u'); xlabel('k');
saveas(gcf,fullfile(figdir,'C1_response.png')); close;

% Controlado vs no controlado (norma del estado)
netz.zero=true; Sz=sim_ctrl(P,x_ini,r,uast,netz,hp.ndata,[]);
nx1=vecnorm(squeeze(o.estado(:,:,1))'); nz1=vecnorm(squeeze(Sz.estado(:,:,1))');
figure('Visible','off','Position',[0 0 560 360]);
plot(nz1(1:200),'--','LineWidth',1.4); hold on; plot(nx1(1:200),'LineWidth',1.4); grid on;
xlabel('k'); ylabel('||x||'); legend('Sin control (u=0)','Con neurocontrolador','Location','best');
title('C1 - Mejora del transitorio'); saveas(gcf,fullfile(figdir,'C1_vs_uncontrolled.png')); close;

% Estudio del peso R (compromiso error/esfuerzo)
Rset=[0 0.01 0.05 0.2 1.0]; errR=zeros(size(Rset)); effR=zeros(size(Rset));
for i=1:numel(Rset)
    hpi=hp; hpi.R=Rset(i); oi=train_static_ctrl(P,x_ini,r,uast,50,hpi);
    errR(i)=mean(vecnorm(oi.xfin-r)); effR(i)=mean(sum(oi.u.^2,1));
end
figure('Visible','off','Position',[0 0 560 360]);
yyaxis left; plot(Rset,errR,'-o','LineWidth',1.3); ylabel('Error final medio ||x_f||');
yyaxis right; plot(Rset,effR,'-s','LineWidth',1.3); ylabel('Esfuerzo de control \Sigma u^2');
grid on; xlabel('Peso R del esfuerzo'); title('C1 - Compromiso error vs esfuerzo (R)');
saveas(gcf,fullfile(figdir,'C1_R.png')); close;
fprintf('  R: errfinal='); fprintf('%.4g ',errR); fprintf(' | esfuerzo='); fprintf('%.4g ',effR); fprintf('\n');

% # neuronas
nmset=[5 10 20 50 80]; relN=zeros(size(nmset));
for i=1:numel(nmset)
    oi=train_static_ctrl(P,x_ini,r,uast,nmset(i),hp); relN(i)=oi.JJbest;
end
figure('Visible','off','Position',[0 0 560 360]);
plot(nmset,relN,'-o','LineWidth',1.3); grid on; xlabel('Neuronas n_m'); ylabel('Costo J final');
title('C1 - Costo vs # neuronas'); saveas(gcf,fullfile(figdir,'C1_neurons.png')); close;

% Generalizacion a CI mayores (entrena en 1x, valida en factores)
facs=[1 2 5 10 20]; genErr=zeros(size(facs));
for i=1:numel(facs)
    Si=sim_ctrl(P,facs(i)*x_ini,r,uast,o.net,hp.ndata,[]);
    genErr(i)=mean(vecnorm(Si.xfin-r));
end
figure('Visible','off','Position',[0 0 560 360]);
semilogy(facs,max(genErr,1e-8),'-o','LineWidth',1.3); grid on;
xlabel('Factor de escala de la CI'); ylabel('Error final medio ||x_f||');
title('C1 - Generalizacion a CI mayores'); saveas(gcf,fullfile(figdir,'C1_gen.png')); close;
fprintf('  generalizacion errfinal: '); fprintf('%.3g ',genErr); fprintf('\n');

save(fullfile(figdir,'..','exp','C1_metrics.mat'),'Rset','errR','effR','nmset','relN','facs','genErr');
fprintf('  C1 OK.\n');
end
