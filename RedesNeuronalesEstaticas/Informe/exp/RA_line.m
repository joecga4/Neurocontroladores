function RA_line(figdir)
% RA: aproximacion de una recta ruidosa y=a x+b (fiel a NeuronLinealPatron[Batch].m).
% Estudia: entrenamiento PATRON vs LOTE, neurona BIAS, tasa eta y escala inicial.
fprintf('\n===== RA: Recta (patron vs lote, bias, eta, init) =====\n');
rng(0);
x=(-2:0.05:3)'; N=numel(x); yb=1*x+2+0.2*randn(N,1);
Xb=[x ones(N,1)];   % con bias

% ---- Patron (en linea) vs Lote ----
hpP=struct('eta',0.05,'niter',400,'seed',1,'mode','pattern','act','bip');
hpB=struct('eta',0.05,'niter',400,'seed',1,'mode','batch','act','bip');
oP=lib_mlp(Xb,yb,10,hpP); oB=lib_mlp(Xb,yb,10,hpB);
fprintf('  patron rmse=%.4f  lote rmse=%.4f\n',oP.rmse,oB.rmse);
figure('Visible','off','Position',[0 0 560 360]);
semilogy(oP.J,'LineWidth',1.3); hold on; semilogy(oB.J,'LineWidth',1.3); grid on;
xlabel('Epoca'); ylabel('Costo J'); legend('Patron (en linea)','Lote (batch)','Location','best');
title('RA - Convergencia: patron vs lote'); saveas(gcf,fullfile(figdir,'RA_pattern_batch.png')); close;
% Ajuste resultante: se comparan AMBOS entrenamientos (patron y lote)
figure('Visible','off','Position',[0 0 560 360]);
plot(x,yb,'.','Color',[.6 .6 .6]); hold on;
plot(x,oB.yhat,'b','LineWidth',1.6);
plot(x,oP.yhat,'r--','LineWidth',1.4);
grid on; xlabel('x'); ylabel('y');
legend('Datos','Red (lote)','Red (patron)','Location','best');
title('RA - Ajuste de la recta (patron y lote)'); saveas(gcf,fullfile(figdir,'RA_fit.png')); close;

% ---- Bias si / no ----
hp=struct('eta',0.1,'niter',2000,'seed',1,'mode','batch','act','bip');
oBias=lib_mlp(Xb,yb,10,hp);          % con bias
oNo  =lib_mlp(x,yb,10,hp);           % sin bias (solo x)
figure('Visible','off','Position',[0 0 560 360]);
plot(x,yb,'.','Color',[.6 .6 .6]); hold on;
plot(x,oNo.yhat,'r--','LineWidth',1.6); plot(x,oBias.yhat,'b','LineWidth',1.6);
grid on; xlabel('x'); ylabel('y'); legend('Datos','Sin bias','Con bias','Location','best');
title('RA - Efecto de la neurona bias'); saveas(gcf,fullfile(figdir,'RA_bias.png')); close;
fprintf('  bias rmse=%.4f  sin bias rmse=%.4f\n',oBias.rmse,oNo.rmse);

% ---- Tasa de aprendizaje eta ----
etas=[0.005 0.02 0.1 0.5 1.5];
figure('Visible','off','Position',[0 0 560 360]); hold on;
for i=1:numel(etas)
    hpi=struct('eta',etas(i),'niter',1500,'seed',1,'mode','batch','act','bip');
    oi=lib_mlp(Xb,yb,10,hpi);
    semilogy(oi.J,'LineWidth',1.2,'DisplayName',sprintf('\\eta=%.3f',etas(i)));
end
set(gca,'YScale','log'); grid on; xlabel('Epoca'); ylabel('Costo J'); legend('Location','best');
title('RA - Convergencia vs tasa de aprendizaje'); saveas(gcf,fullfile(figdir,'RA_eta.png')); close;

% ---- Escala de inicializacion de pesos ----
winits=[0.01 0.15 1.0 5.0]; relI=zeros(size(winits));
figure('Visible','off','Position',[0 0 560 360]); hold on;
for i=1:numel(winits)
    hpi=struct('eta',0.1,'niter',1500,'seed',1,'mode','batch','act','bip','winit',winits(i));
    oi=lib_mlp(Xb,yb,10,hpi); relI(i)=oi.rmse;
    semilogy(oi.J,'LineWidth',1.2,'DisplayName',sprintf('init=%.2f',winits(i)));
end
set(gca,'YScale','log'); grid on; xlabel('Epoca'); ylabel('Costo J'); legend('Location','best');
title('RA - Convergencia vs escala inicial de pesos'); saveas(gcf,fullfile(figdir,'RA_init.png')); close;
fprintf('  init rmse: '); fprintf('%.4f ',relI); fprintf('\n');

save(fullfile(figdir,'..','exp','RA_metrics.mat'),'etas','winits','relI');
fprintf('  RA OK. patron/lote/bias listos.\n');
end
