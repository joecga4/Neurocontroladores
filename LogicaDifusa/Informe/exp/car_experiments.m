function car_experiments(figdir)
% Compara la tabla de reglas ORIGINAL vs la MEJORADA en el controlador difuso
% del carro (fuzzycarxloco). Estacionamiento en x=xdeseado moviendose hacia arriba.
addpath(fileparts(mfilename('fullpath')));
fprintf('\n===== FUZZY CARRO: tabla vieja vs mejorada =====\n');

% Tabla ORIGINAL (solo usa NB=1, ZE=4, PB=7)
BR_old = [ 1 1 1 4 7 7 7
           1 1 1 4 7 7 7
           1 7 7 4 7 7 1
           7 7 7 4 7 7 1
           1 7 7 4 7 7 1
           1 1 1 4 7 7 7
           1 1 1 4 7 7 7 ];
% Tabla MEJORADA (7 niveles graduados, simetrica, monotona)
BR_new = [ 1 1 1 1 1 1 1
           2 1 1 1 1 1 1
           6 4 3 2 2 1 1
           7 6 5 4 3 2 1
           7 7 6 6 5 4 2
           7 7 7 7 7 7 6
           7 7 7 7 7 7 7 ];

xdes = 50;
ICs = [ 20 10  90 ; 80 10  90 ; 30 10 135 ; 70 10  45 ];   % [xini yini Pini]
col = lines(size(ICs,1));

% ---- Trayectorias X-Y ----
figure('Visible','off','Position',[0 0 900 420]);
for m=1:2
    if m==1, BR=BR_old; ttl='Tabla original'; else, BR=BR_new; ttl='Tabla mejorada'; end
    subplot(1,2,m); hold on;
    for i=1:size(ICs,1)
        [xx,yy]=fuzzycar_sim(ICs(i,1),ICs(i,2),ICs(i,3),xdes,BR);
        plot(xx,yy,'LineWidth',1.4,'Color',col(i,:));
    end
    xline(xdes,'k--'); yline(100,'k:'); axis([0 100 0 105]); grid on;
    xlabel('X'); ylabel('Y'); title(ttl);
end
sgtitle('Fuzzy carro - Trayectorias (estacionar en x=50)');
saveas(gcf,fullfile(figdir,'car_traj.png')); close;

% ---- Angulo del timon (suavidad) para una CI ----
[~,~,~,dOld]=fuzzycar_sim(30,10,135,xdes,BR_old);
[~,~,~,dNew]=fuzzycar_sim(30,10,135,xdes,BR_new);
figure('Visible','off','Position',[0 0 620 360]);
plot(dOld,'LineWidth',1.3); hold on; plot(dNew,'LineWidth',1.3); grid on;
xlabel('Paso'); ylabel('\delta [grados]'); legend('Original','Mejorada','Location','best');
title('Fuzzy carro - Angulo del timon (CI: x=30, \phi=135\circ)');
saveas(gcf,fullfile(figdir,'car_delta.png')); close;

% ---- Metricas: error final y variacion total del timon (aspereza) ----
fprintf('  %-4s | %-22s | %-22s\n','CI','ORIGINAL','MEJORADA');
errOld=zeros(size(ICs,1),1); errNew=errOld; tvOld=errOld; tvNew=errOld;
for i=1:size(ICs,1)
    [xo,yo,~,do]=fuzzycar_sim(ICs(i,1),ICs(i,2),ICs(i,3),xdes,BR_old);
    [xn,yn,~,dn]=fuzzycar_sim(ICs(i,1),ICs(i,2),ICs(i,3),xdes,BR_new);
    errOld(i)=abs(xo(end)-xdes); errNew(i)=abs(xn(end)-xdes);
    tvOld(i)=sum(abs(diff(do))); tvNew(i)=sum(abs(diff(dn)));
    fprintf('  %d,%d,%3d | errX=%6.2f TV(delta)=%7.1f | errX=%6.2f TV(delta)=%7.1f\n',...
        ICs(i,1),ICs(i,2),ICs(i,3),errOld(i),tvOld(i),errNew(i),tvNew(i));
end
save(fullfile(figdir,'..','exp','car_metrics.mat'),'ICs','xdes','errOld','errNew','tvOld','tvNew');
fprintf('  media: errX old=%.2f new=%.2f | TV old=%.0f new=%.0f\n',...
    mean(errOld),mean(errNew),mean(tvOld),mean(tvNew));
fprintf('  FUZZY CARRO OK.\n');
end
