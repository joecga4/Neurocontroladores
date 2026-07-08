function E3_static_vs_dynamic(figdir)
% E3: Robustez al RUIDO DE MEDICION: modelo estatico vs dinamico, misma planta.
% Valida la tesis del PDF (seccion 3): el modelo estatico usa la salida medida
% (ruidosa) como entrada tambien en operacion, mientras que el dinamico, una vez
% entrenado, es independiente de la medida ruidosa (corre en lazo cerrado).
fprintf('\n===== E3: Estatico vs Dinamico ante ruido =====\n');

u = gen_input();
z = plant_nl2(u, [0.1;0.2]);      % salida limpia (verdad de terreno)
ndata = numel(u);
noises = [0 0.01 0.02 0.05 0.1 0.15];

seed=1; niter=900;
errS = zeros(size(noises));   % estatico (uso nativo: 1 paso, regresores medidos)
errD = zeros(size(noises));   % dinamico (lazo cerrado, libre)

for i=1:numel(noises)
    rng(200+i);
    zn = z + noises(i)*randn(size(z));   % medicion ruidosa

    % ----- Modelo DINAMICO (DBP), entrenado con la medida ruidosa -----
    od = lib_dbp(zn, u, 50, 0.05, 0.0, niter, seed, [1;1], false);
    % Evaluar en lazo cerrado vs senal LIMPIA
    errD(i) = sqrt(mean((od.outfit - z(2:ndata,:)).^2,'all'));

    % ----- Modelo ESTATICO (NARX), entrenado con la medida ruidosa -----
    [Xs,Ys,fx,fy] = narx2(u, zn);            % regresores y objetivo ruidosos
    os = lib_static(Xs, Ys, 50, 0.3, niter, seed);
    % Uso nativo: prediccion a 1 paso con regresores MEDIDOS (ruidosos),
    % comparada con la salida LIMPIA del paso siguiente.
    yhat = os.y .* fy;                        % en unidades fisicas
    ytrue = z(3:ndata,:);                     % objetivo limpio alineado con NARX
    errS(i) = sqrt(mean((yhat - ytrue).^2,'all'));
end

figure('Visible','off','Position',[0 0 900 380]);
subplot(1,2,1);
plot(noises, errS,'-s','LineWidth',1.4); hold on;
plot(noises, errD,'-o','LineWidth',1.4); grid on;
xlabel('Ruido de medicion \eta'); ylabel('RMSE vs senal limpia');
legend('Estatico (1 paso, usa medida)','Dinamico (lazo cerrado)','Location','northwest');
title('(a) Error absoluto');
subplot(1,2,2);
plot(noises, errS/errS(1),'-s','LineWidth',1.4); hold on;
plot(noises, errD/errD(1),'-o','LineWidth',1.4); grid on;
xlabel('Ruido de medicion \eta'); ylabel('Error normalizado (\eta=0 \rightarrow 1)');
legend('Estatico','Dinamico','Location','northwest');
title('(b) Degradacion relativa al ruido');
sgtitle('E3 - Robustez al ruido: estatico vs dinamico');
saveas(gcf, fullfile(figdir,'E3_noise_robustness.png')); close;

% Trazas cualitativas a ruido alto (eta=0.1)
rng(999);
zn = z + 0.1*randn(size(z));
od = lib_dbp(zn, u, 50, 0.05, 0.0, niter, seed, [1;1], false);
figure('Visible','off','Position',[0 0 760 360]);
plot(z(2:ndata,2),'r','LineWidth',1.3); hold on;
plot(zn(2:ndata,2),'Color',[0.7 0.7 0.7]);
plot(od.outfit(:,2),'b--','LineWidth',1.2); grid on;
legend('Limpia','Medida ruidosa (\eta=0.1)','Modelo dinamico','Location','best');
xlabel('Muestra'); ylabel('z_2');
title('E3 - El modelo dinamico filtra el ruido de medicion');
saveas(gcf, fullfile(figdir,'E3_traces.png')); close;

save(fullfile(figdir,'..','exp','E3_metrics.mat'),'noises','errS','errD');
fprintf('  estatico RMSE: '); fprintf('%.4f ',errS); fprintf('\n');
fprintf('  dinamico RMSE: '); fprintf('%.4f ',errD); fprintf('\n');
fprintf('  E3 OK.\n');
end

function [X,Y,fx,fy] = narx2(u, z)
% Regresores NARX para planta 1 entrada / 2 salidas:
%   entrada:  [u_k, u_{k-1}, y1_k, y1_{k-1}, y2_k, y2_{k-1}]
%   objetivo: [y1_{k+1}, y2_{k+1}]
nu = numel(u);
idx = 2:nu-1;                 % k tal que existen k-1 y k+1
X = [u(idx), u(idx-1), z(idx,1), z(idx-1,1), z(idx,2), z(idx-1,2)];
Y = [z(idx+1,1), z(idx+1,2)];
fx = max(abs(X)); fx(fx==0)=1;
fy = max(abs(Y)); fy(fy==0)=1;
X = X ./ fx; Y = Y ./ fy;
end
