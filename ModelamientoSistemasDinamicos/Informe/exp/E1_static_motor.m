function E1_static_motor(figdir, R)
% E1: Modelamiento ESTATICO de un motor (fiel a MotorNeuroEstatico.m).
% Estudia convergencia, ruido de medicion, # neuronas, tasa eta y # regresores.
fprintf('\n===== E1: Modelo estatico (motor) =====\n');

% ---- Planta: motor DC (3 estados) discretizado ----
Rr=1.1; L=0.0001; Kt=0.0815; Kb=0.0715; I=15.865e-5; p=0.0025; mm=30.0; c=200;
r=0.01; alfa=45*pi/180;
d = mm + 2*pi*I*tan(alfa)/(p*r);
A = [0 1 0; 0 -c/d Kt*tan(alfa)/(r*d); 0 -2*pi*Kb/(p*L) -Rr/L];
B = [0;0;1/L];
dt = 0.0075;
[Ak,Bk] = c2d(A,B,dt);
vmax = 24;

% ---- Entradas de entrenamiento y validacion ----
build = @(sig) buildmotor(sig, Ak, Bk, vmax);
t3=(0:dt:3)'; t2=(0:dt:2)'; on1=ones(numel(0:dt:1),1);
vtr = [vmax*sin(2*pi*0.5*t3); -0.75*vmax*on1; 0.5*vmax*on1; vmax*on1; ...
       vmax*sin(2*pi*1*t3); 0*on1; -vmax*on1; -vmax*on1; -vmax*on1; ...
       vmax*sin(2*pi*2*t2); vmax*on1; 0*on1];
vva = [vmax*ones(numel(0:dt:2),1); -vmax*ones(numel(0:dt:2),1); ...
       -vmax*ones(numel(0:dt:2),1); vmax*on1; 0*on1; -vmax*on1; vmax*on1];
[voltT,posT] = build(vtr);
[voltV,posV] = build(vva);

% ---- Baseline: ne=7 (voltaje + 6 posiciones pasadas), nm=20 ----
seed=1; nm=20; eta=0.5; niter=400; ndelay=6;
[xT,yT,fx,fy] = narx(voltT,posT,ndelay);
o = lib_static(xT,yT,nm,eta,niter,seed);
fprintf('  baseline relerr(train)=%.4f\n', o.relerr);

figure('Visible','off','Position',[0 0 560 360]);
plot(o.Jhist,'LineWidth',1.3); grid on;
xlabel('Iteracion'); ylabel('J'); title('E1 - Convergencia (motor estatico, n_m=20)');
saveas(gcf, fullfile(figdir,'E1_conv.png')); close;

figure('Visible','off','Position',[0 0 700 360]);
plot(yT*fy,'r','LineWidth',1.2); hold on; plot(o.y*fy,'b--','LineWidth',1.1);
grid on; xlabel('Muestra'); ylabel('Posicion [m]');
legend('Deseada (planta)','Red','Location','best');
title('E1 - Ajuste del modelo estatico (entrenamiento)');
saveas(gcf, fullfile(figdir,'E1_fit.png')); close;

% ---- Estudio de RUIDO de medicion (en unidades fisicas [m]) ----
noises = [0 0.005 0.01 0.02 0.05 0.1];
rmseTr = zeros(size(noises)); rmseVa = zeros(size(noises));
for i=1:numel(noises)
    rng(100+i);
    posTn = posT + noises(i)*randn(size(posT));   % medicion ruidosa
    [xTn,yTn,fxn,fyn] = narx(voltT,posTn,ndelay);
    oi = lib_static(xTn,yTn,nm,eta,niter,seed);
    % Salida de la red (regresores ruidosos) vs senal LIMPIA (verdad de terreno)
    rmseTr(i) = sqrt(mean((oi.y*fyn - posT).^2));
    % Validacion: desplegar el modelo entrenado sobre otra secuencia
    posVn = posV + noises(i)*randn(size(posV));
    [xVn,~,~,~] = narx(voltV,posVn,ndelay);
    xVn = xVn ./ fxn;                 % escalar con factores de entrenamiento
    yV = predict_static(oi, xVn) * fyn;
    rmseVa(i) = sqrt(mean((yV - posV).^2));
end
figure('Visible','off','Position',[0 0 560 360]);
plot(noises, rmseTr,'-o','LineWidth',1.3); hold on;
plot(noises, rmseVa,'-s','LineWidth',1.3); grid on;
xlabel('Desv. del ruido de medicion \eta'); ylabel('RMSE vs senal limpia (escalado)');
legend('Entrenamiento','Validacion','Location','northwest');
title('E1 - Efecto del ruido de medicion (modelo estatico)');
saveas(gcf, fullfile(figdir,'E1_noise.png')); close;
fprintf('  ruido: relerr crece de %.4f a %.4f\n', rmseTr(1), rmseTr(end));

% ---- Estudio de # neuronas ----
nmset = [3 5 10 20 40 80];
relN = zeros(size(nmset));
for i=1:numel(nmset)
    oi = lib_static(xT,yT,nmset(i),eta,niter,seed);
    relN(i) = oi.relerr;
end
figure('Visible','off','Position',[0 0 560 360]);
semilogy(nmset, relN,'-o','LineWidth',1.3); grid on;
xlabel('Neuronas ocultas n_m'); ylabel('Error relativo de ajuste');
title('E1 - Capacidad de la red vs # neuronas');
saveas(gcf, fullfile(figdir,'E1_neurons.png')); close;

% ---- Estudio de tasa de aprendizaje eta ----
etaset = [0.05 0.2 0.5 1.0 2.0];
figure('Visible','off','Position',[0 0 560 360]); hold on;
for i=1:numel(etaset)
    oi = lib_static(xT,yT,nm,etaset(i),niter,seed);
    semilogy(oi.Jhist,'LineWidth',1.2,'DisplayName',sprintf('\\eta=%.2f',etaset(i)));
end
grid on; xlabel('Iteracion'); ylabel('J'); legend('Location','best');
title('E1 - Convergencia vs tasa de aprendizaje');
set(gca,'YScale','log');
saveas(gcf, fullfile(figdir,'E1_eta.png')); close;

% ---- Estudio de # regresores (memoria) ----
delset = [1 2 3 6];
relD = zeros(size(delset));
for i=1:numel(delset)
    [xd,yd] = narx(voltT,posT,delset(i));
    oi = lib_static(xd,yd,nm,eta,niter,seed);
    relD(i) = oi.relerr;
end
figure('Visible','off','Position',[0 0 560 360]);
plot(delset, relD,'-o','LineWidth',1.3); grid on;
xlabel('# de posiciones pasadas (regresores)'); ylabel('Error relativo de ajuste');
title('E1 - Efecto del numero de regresores');
saveas(gcf, fullfile(figdir,'E1_regressors.png')); close;

% ---- Guardar metricas ----
save(fullfile(figdir,'..','exp','E1_metrics.mat'), ...
    'noises','rmseTr','rmseVa','nmset','relN','etaset','delset','relD');
fprintf('  E1 OK. neuronas relerr: '); fprintf('%.4f ',relN); fprintf('\n');
fprintf('  regresores relerr: '); fprintf('%.4f ',relD); fprintf('\n');
end

% ================= auxiliares =================
function [volt,pos] = buildmotor(vv, Ak, Bk, vmax)
nv = numel(vv); x=[0;0;0]; pos=zeros(nv,1); volt=zeros(nv,1);
for k=1:nv
    pos(k)=x(1);
    u = min(max(vv(k),-vmax),vmax);
    volt(k)=u;
    x = Ak*x + Bk*u;
end
end

function [xesc,yesc,fx,fy] = narx(volt, pos, ndelay)
% Construye regresores NARX: [volt, pos(k-1..k-ndelay)] y escala a [-1,1] aprox.
nv = numel(volt);
X = zeros(nv, 1+ndelay);
X(:,1) = volt;
for j=1:ndelay
    col = zeros(nv,1);
    col(j+1:nv) = pos(1:nv-j);
    X(:,j+1) = col;
end
fx = max(abs(X)); fx(fx==0)=1;
fy = max(abs(pos)); if fy==0, fy=1; end
xesc = X ./ fx;
yesc = pos ./ fy;
end

function y = predict_static(o, xesc)
nx=size(xesc,1); ns=size(o.w,2); y=zeros(nx,ns);
for k=1:nx
    in=xesc(k,:)'; m=o.v'*in; n=2.0./(1+exp(-m./o.a))-1; y(k,:)=(o.w'*n)';
end
end
