function RB_cubic(figdir)
% RB: aproximacion de una CUBICA (fiel a NeuronCubicaEscalamiento.m).
% Estudia: numero de neuronas ocultas y tipo de funcion de activacion.
fprintf('\n===== RB: Cubica (neuronas, activacion) =====\n');
rng(0);
x=(-4:0.1:4)'; nx=numel(x);
yb=0.075*(1.6*x.^3 + 1.2*x.^2 - 20*x) + 0.2*randn(nx,1);
Xb=[x ones(nx,1)];

% ---- Numero de neuronas ----
nmset=[1 2 5 10 25 50]; relN=zeros(size(nmset)); fits=cell(1,numel(nmset));
for i=1:numel(nmset)
    hp=struct('eta',0.1,'niter',6000,'seed',1,'mode','batch','act','bip');
    oi=lib_mlp(Xb,yb,nmset(i),hp); relN(i)=oi.rmse; fits{i}=oi.yhat;
end
figure('Visible','off','Position',[0 0 560 360]);
plot(nmset,relN,'-o','LineWidth',1.3); grid on; xlabel('Neuronas ocultas n_m'); ylabel('RMSE');
title('RB - Error de ajuste vs # neuronas'); saveas(gcf,fullfile(figdir,'RB_neurons.png')); close;
% Ejemplos de ajuste: pocas vs muchas neuronas
figure('Visible','off','Position',[0 0 620 380]);
plot(x,yb,'.','Color',[.6 .6 .6]); hold on;
plot(x,fits{2},'r--','LineWidth',1.5); plot(x,fits{5},'b','LineWidth',1.5);
grid on; xlabel('x'); ylabel('y');
legend('Datos',sprintf('n_m=%d (subajuste)',nmset(2)),sprintf('n_m=%d',nmset(5)),'Location','best');
title('RB - Capacidad de la red (cubica)'); saveas(gcf,fullfile(figdir,'RB_fit.png')); close;
fprintf('  neuronas rmse: '); fprintf('%.4f ',relN); fprintf('\n');

% ---- Funcion de activacion ----
acts={'log','bip','gauss'}; aname={'Logistica','Bipolar','Gaussiana'}; relA=zeros(1,3);
figure('Visible','off','Position',[0 0 560 360]); hold on;
for i=1:3
    hp=struct('eta',0.1,'niter',6000,'seed',1,'mode','batch','act',acts{i});
    oi=lib_mlp(Xb,yb,25,hp); relA(i)=oi.rmse;
    semilogy(oi.J,'LineWidth',1.3,'DisplayName',aname{i});
end
set(gca,'YScale','log'); grid on; xlabel('Epoca'); ylabel('Costo J'); legend('Location','best');
title('RB - Convergencia por funcion de activacion'); saveas(gcf,fullfile(figdir,'RB_activation.png')); close;
fprintf('  activacion rmse [log bip gauss]: '); fprintf('%.4f ',relA); fprintf('\n');

save(fullfile(figdir,'..','exp','RB_metrics.mat'),'nmset','relN','relA','aname');
fprintf('  RB OK.\n');
end
