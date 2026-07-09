function trailer_experiments(figdir)
% Valida el controlador difuso del trailer en el modo ROTADO (regula Y -> 50),
% comparado con el modo original (regula X). Genera figuras y metricas.
addpath(fileparts(mfilename('fullpath')));
fprintf('\n===== FUZZY TRAILER: y*=50 (rotado) =====\n');

% ---- Modo ORIGINAL (regula X -> 50), referencia ----
figure('Visible','off','Position',[0 0 560 480]); hold on;
for c = [30 50 70]
    [x,y]=fuzzytrailer_sim(c,25,90,0,50,'x');
    plot(x,y,'LineWidth',1.4);
end
xline(50,'k--'); yline(100,'k:'); axis([0 100 0 105]); grid on;
xlabel('X'); ylabel('Y'); title('Trailer ORIGINAL: regula X\rightarrow50 (sube)');
saveas(gcf,fullfile(figdir,'trailer_x.png')); close;

% ---- Modo ROTADO (regula Y -> 50, avanza en +x) ----
ICy = [ 10 20 ; 10 80 ; 5 35 ; 8 65 ];    % [xini yini], theta2=0 (este)
figure('Visible','off','Position',[0 0 620 460]); hold on;
finY=zeros(size(ICy,1),1);
for i=1:size(ICy,1)
    [x,y]=fuzzytrailer_sim(ICy(i,1),ICy(i,2),0,0,50,'y');
    plot(x,y,'LineWidth',1.4); finY(i)=y(end);
end
yline(50,'k--'); xline(100,'k:'); axis([0 110 0 100]); grid on;
xlabel('X'); ylabel('Y'); title('Trailer ROTADO: regula Y\rightarrow50 (avanza en +x)');
saveas(gcf,fullfile(figdir,'trailer_y.png')); close;
fprintf('  modo Y: y_final por CI = '); fprintf('%.2f ',finY); fprintf('(objetivo 50)\n');

% ---- Estados (theta2, theta12, delta) de una corrida rotada ----
[x,y,th2,th12,dl]=fuzzytrailer_sim(10,20,0,0,50,'y');
figure('Visible','off','Position',[0 0 700 460]);
subplot(3,1,1); plot(th2,'LineWidth',1.2); grid on; ylabel('\theta_2 [\circ]');
title('Trailer rotado - estados (CI: x=10, y=20, \theta_2=0)'); yline(0,'k--');
subplot(3,1,2); plot(th12,'LineWidth',1.2); grid on; ylabel('\theta_{12} [\circ]');
subplot(3,1,3); plot(dl,'LineWidth',1.2); grid on; ylabel('\delta [\circ]'); xlabel('Paso');
saveas(gcf,fullfile(figdir,'trailer_y_states.png')); close;

save(fullfile(figdir,'..','exp','trailer_metrics.mat'),'ICy','finY');
fprintf('  FUZZY TRAILER OK.\n');
end
