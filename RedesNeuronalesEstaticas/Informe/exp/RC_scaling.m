function RC_scaling(figdir)
% RC: PROBLEMA DE ESCALAMIENTO (fiel a NeuronCubicaEscalamiento.m, factor FACTOR).
% Con una MISMA tasa de aprendizaje fija, al crecer la magnitud de la salida deseada
% el entrenamiento SIN escalar se vuelve inestable (el gradiente ~ error se dispara),
% mientras que escalando la salida a ~[-1,1] un unico eta funciona para toda magnitud.
% El error se mide contra la senal LIMPIA (sin ruido) para aislar la calidad del ajuste.
fprintf('\n===== RC: Escalamiento de la salida =====\n');
rng(0);
x=(-4:0.1:4)'; nx=numel(x); Xb=[x ones(nx,1)];
base=0.075*(1.6*x.^3 + 1.2*x.^2 - 20*x);   % cubica base (magnitud ~O(8))
factors=[1 10 100 1000 5000];
relRaw=zeros(size(factors)); relScaled=zeros(size(factors));
hp=struct('eta',0.1,'niter',6000,'seed',1,'mode','batch','act','bip');
for i=1:numel(factors)
    clean=factors(i)*base;
    yb=clean + factors(i)*0.02*randn(nx,1);     % ruido proporcional a la escala
    % (a) sin escalar la salida  -> mismo eta para toda magnitud
    oR=lib_mlp(Xb,yb,25,hp);
    relRaw(i)=relc(oR.yhat,clean);
    % (b) escalando la salida a ~[-1,1], entrenar y desescalar la prediccion
    sy=max(abs(yb)); if sy==0, sy=1; end
    oS=lib_mlp(Xb,yb/sy,25,hp);
    relScaled(i)=relc(oS.yhat*sy,clean);
end
figure('Visible','off','Position',[0 0 640 380]);
loglog(factors,max(relRaw,1e-6),'-s','LineWidth',1.5); hold on;
loglog(factors,max(relScaled,1e-6),'-o','LineWidth',1.5); grid on;
xlabel('FACTOR (magnitud de la salida deseada)'); ylabel('Error relativo vs senal limpia');
legend('Salida SIN escalar (eta fijo)','Salida escalada a [-1,1]','Location','northwest');
title('RC - El escalamiento de la salida permite un unico eta');
saveas(gcf,fullfile(figdir,'RC_scaling.png')); close;
fprintf('  factors:   '); fprintf('%g ',factors); fprintf('\n');
fprintf('  relRaw:    '); fprintf('%.4g ',relRaw); fprintf('\n');
fprintf('  relScaled: '); fprintf('%.4g ',relScaled); fprintf('\n');
save(fullfile(figdir,'..','exp','RC_metrics.mat'),'factors','relRaw','relScaled');
fprintf('  RC OK.\n');
end

function r=relc(yhat,clean)
if ~all(isfinite(yhat)), r=Inf; return; end
r=sqrt(sum((yhat-clean).^2)/sum(clean.^2));
end
