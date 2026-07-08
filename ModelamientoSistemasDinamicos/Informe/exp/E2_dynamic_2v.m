function E2_dynamic_2v(figdir)
% E2: Modelamiento DINAMICO (DBP) de un sistema no lineal 1 entrada / 2 estados.
% Fiel a DynamicBPModelamiento2v.m. Estudia convergencia, ajuste en lazo cerrado,
% # neuronas, medicion parcial (matriz Q) y neuronas lineales vs sigmoide.
fprintf('\n===== E2: Modelo dinamico DBP (2 estados) =====\n');

u = gen_input();
z = plant_nl2(u, [0.1;0.2]);
ndata = numel(u);

% ---- Baseline ----
seed=1; nm=50; eta=0.05; etaa=0.0; niter=600; q=[1;1];
o = lib_dbp(z, u, nm, eta, etaa, 1500, seed, q, false);   % base: mas iteraciones
fprintf('  baseline errrel final=%.4f\n', o.finalerr);

figure('Visible','off','Position',[0 0 560 360]);
semilogy(o.errhist*100,'LineWidth',1.3); grid on;
xlabel('Iteracion'); ylabel('Error relativo total [%]');
title('E2 - Convergencia DBP (n_m=50)');
saveas(gcf, fullfile(figdir,'E2_conv.png')); close;

figure('Visible','off','Position',[0 0 760 420]);
subplot(2,1,1);
plot(z(2:ndata,1),'r','LineWidth',1.2); hold on; plot(o.outfit(:,1),'b--','LineWidth',1.1);
grid on; ylabel('z_1'); legend('Sistema','Red','Location','best'); title('E2 - Ajuste en lazo cerrado');
subplot(2,1,2);
plot(z(2:ndata,2),'r','LineWidth',1.2); hold on; plot(o.outfit(:,2),'b--','LineWidth',1.1);
grid on; ylabel('z_2'); xlabel('Muestra');
saveas(gcf, fullfile(figdir,'E2_fit.png')); close;

% ---- # neuronas ----
nmset = [5 10 20 50 80];
relN = zeros(size(nmset));
for i=1:numel(nmset)
    oi = lib_dbp(z, u, nmset(i), eta, etaa, niter, seed, q, false);
    relN(i) = oi.finalerr;
end
figure('Visible','off','Position',[0 0 560 360]);
plot(nmset, relN*100,'-o','LineWidth',1.3); grid on;
xlabel('Neuronas ocultas n_m'); ylabel('Error relativo final [%]');
title('E2 - DBP: error vs # neuronas');
saveas(gcf, fullfile(figdir,'E2_neurons.png')); close;

% ---- Medicion parcial (matriz Q): medir ambas vs solo z1 ----
oFull = lib_dbp(z, u, nm, eta, etaa, niter, seed, [1;1], false);
oPart = lib_dbp(z, u, nm, eta, etaa, niter, seed, [1;0], false);
% error POR salida (evaluado sobre ambas, aunque solo se mida z1)
ef = sqrt(mean((oFull.outfit - z(2:ndata,:)).^2));
ep = sqrt(mean((oPart.outfit - z(2:ndata,:)).^2));
figure('Visible','off','Position',[0 0 560 360]);
bar([ef; ep]'); grid on; set(gca,'XTickLabel',{'z_1','z_2'});
ylabel('RMSE en lazo cerrado'); legend('Q=[1 1]','Q=[1 0] (solo z_1)','Location','best');
title('E2 - Medicion completa vs parcial');
saveas(gcf, fullfile(figdir,'E2_partial.png')); close;
fprintf('  Q=[1 1] RMSE=[%.4f %.4f]  Q=[1 0] RMSE=[%.4f %.4f]\n', ef(1),ef(2),ep(1),ep(2));

% ---- Neuronas lineales vs sigmoide ----
oLin = lib_dbp(z, u, nm, eta, etaa, niter, seed, q, true);
figure('Visible','off','Position',[0 0 560 360]);
semilogy(o.errhist*100,'LineWidth',1.3,'DisplayName','Sigmoide'); hold on;
semilogy(oLin.errhist*100,'LineWidth',1.3,'DisplayName','Lineal (n=m)'); grid on;
xlabel('Iteracion'); ylabel('Error relativo total [%]'); legend('Location','best');
title('E2 - Sigmoide vs lineal (planta con termino bilineal)');
saveas(gcf, fullfile(figdir,'E2_activation.png')); close;
fprintf('  sigmoide=%.4f  lineal=%.4f\n', o.finalerr, oLin.finalerr);

save(fullfile(figdir,'..','exp','E2_metrics.mat'), ...
    'nmset','relN','ef','ep','q');
fprintf('  E2 OK.\n');
end
