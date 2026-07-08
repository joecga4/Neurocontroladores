here = fileparts(mfilename('fullpath'));
addpath(here);
figdir = fullfile(here,'..','figs');

% ---- Re-ejecutar E4 con eta teacher corregido ----
E4_linear_id(figdir);

% ---- Re-graficar E1_noise: solo RMSE de entrenamiento (fisico) ----
S = load(fullfile(here,'E1_metrics.mat'));
figure('Visible','off','Position',[0 0 560 360]);
plot(S.noises, S.rmseTr,'-o','LineWidth',1.4); grid on;
xlabel('Desv. del ruido de medicion \eta'); ylabel('RMSE vs senal limpia [m]');
title('E1 - Efecto del ruido de medicion (modelo estatico)');
saveas(gcf, fullfile(figdir,'E1_noise.png')); close;

disp('fix_e1e4 OK');
run('dump_metrics.m');
