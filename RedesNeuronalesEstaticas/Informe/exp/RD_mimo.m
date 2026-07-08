function RD_mimo(figdir)
% RD: aproximacion MIMO, 2 entradas / 2 salidas (fiel a NeuronDosEntradasDosSalidas.m).
fprintf('\n===== RD: MIMO (2 entradas, 2 salidas) =====\n');
rng(0);
x1=(-4:0.1:4)'; N=numel(x1); x2=linspace(-3,3,N)';
yb1=0.075*(1.0*x1.^3 + 1.2*x1.^2 - 20*x2) + 0.1*randn(N,1);
yb2=0.6*0.075*(1.0*x2.^3 + 1.2*x2.^2 - 20*x1) + 0.1*randn(N,1);
Y=[yb1 yb2]; Xb=[x1 x2 ones(N,1)];
hp=struct('eta',0.1,'niter',4000,'seed',1,'mode','batch','act','bip');
o=lib_mlp(Xb,Y,50,hp);
e1=sqrt(mean((o.yhat(:,1)-yb1).^2)); e2=sqrt(mean((o.yhat(:,2)-yb2).^2));
fprintf('  MIMO rmse y1=%.4f  y2=%.4f\n',e1,e2);
figure('Visible','off','Position',[0 0 760 420]);
subplot(2,1,1);
plot(yb1,'.','Color',[.6 .6 .6]); hold on; plot(o.yhat(:,1),'b','LineWidth',1.4);
grid on; ylabel('y_1'); legend('Datos','Red','Location','best'); title('RD - Ajuste MIMO');
subplot(2,1,2);
plot(yb2,'.','Color',[.6 .6 .6]); hold on; plot(o.yhat(:,2),'b','LineWidth',1.4);
grid on; ylabel('y_2'); xlabel('Muestra');
saveas(gcf,fullfile(figdir,'RD_mimo.png')); close;
figure('Visible','off','Position',[0 0 560 360]);
semilogy(o.J,'LineWidth',1.3); grid on; xlabel('Epoca'); ylabel('Costo J');
title('RD - Convergencia MIMO'); saveas(gcf,fullfile(figdir,'RD_conv.png')); close;
save(fullfile(figdir,'..','exp','RD_metrics.mat'),'e1','e2');
fprintf('  RD OK.\n');
end
