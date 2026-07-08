function train_trailer_sup(figdir)
% Entrena la red del TRAILER por aprendizaje SUPERVISADO: la red aprende a
% reproducir una ley de direccion estabilizadora (verificada en el diagnostico)
% que estaciona el trailer (x->0, th2->pi/2 gestionando el angulo de articulacion).
% Entradas de la red: [x, wrap(th2-th2*), th12] normalizadas por inscale.
% Este enfoque evita las dificultades del BPTT en un sistema subactuado y produce
% un neurocontrolador que sirve para las tres trayectorias (via entradas de error).
fprintf('\n===== TRAILER: entrenamiento supervisado =====\n');
L1=2; L2=3; th2star=pi/2; umax=tan(45*pi/180); inscale=[10;1;1];

% --- Genera datos (estado -> u de la ley estabilizadora) ---
xg=linspace(-15,15,25); e2g=linspace(-pi,pi,29); hg=linspace(-1.0,1.0,13);
[XX,EE,HH]=ndgrid(xg,e2g,hg);
X=[XX(:)'; EE(:)'; HH(:)'];          % [x ; e2=wrap(th2-th2*) ; th12]
th12des=max(-0.6,min(0.6, 1.5*X(2,:) - 0.05*X(1,:)));
U=max(-umax,min(umax, 2.0*(X(3,:)-th12des)));   % ley de direccion (objetivo)
Xin=X./inscale; N=size(Xin,2);

% --- Entrena MLP (1 capa oculta, backprop) ---
ne=3; nm=50; ns=1; rng(1);
v=0.2*randn(ne,nm); w=0.2*randn(nm,ns); c=zeros(nm,1); a=ones(nm,1);
eta=0.5; niter=4000; JJ=zeros(niter,1);
for it=1:niter
    M=v'*Xin; Nn=2./(1+exp(-(M-c)./a))-1; Y=w'*Nn;    % forward (vectorizado)
    er=Y-U;                                           % 1 x N
    JJ(it)=0.5*mean(er.^2);
    dndm=(1-Nn.^2)./(2*a);
    dJdw=(Nn*er')/N;                                  % nm x 1
    dJdv=(Xin*(dndm.*(w*er))')/N;                     % ne x nm
    w=w-eta*dJdw; v=v-eta*dJdv;
end
net.v=v; net.w=w; net.c=c; net.a=a; net.L1=L1; net.L2=L2; net.inscale=inscale;
save(fullfile(figdir,'..','exp','trailer_net.mat'),'-struct','net');
figure('Visible','off','Position',[0 0 560 360]);
semilogy(JJ,'LineWidth',1.4); grid on; xlabel('Iteracion'); ylabel('Costo (MSE)');
title('Trailer - Entrenamiento supervisado de la red');
saveas(gcf,fullfile(figdir,'trailer_training.png')); close;
fprintf('  MSE final=%.4g (rms objetivo=%.3f)\n', JJ(end), rms(U));

% --- Prueba de estacionamiento vertical con la red ---
figure('Visible','off','Position',[0 0 620 480]); hold on;
for x0=[-8 -3 4 9]
  for dth0=[-70 -30 30 70]
    [Xx,Yy]=trailer_roll(net,[x0;3;th2star+dth0*pi/180;th2star+dth0*pi/180],@(x,y)deal(0,th2star),0,50,12000);
    plot(Xx,Yy,'LineWidth',1.1);
  end
end
xline(0,'k--'); axis([-15 15 0 55]); grid on; xlabel('X'); ylabel('Y');
title('Trailer - Estacionamiento vertical (red)');
saveas(gcf,fullfile(figdir,'trailer_parking.png')); close;
fprintf('  TRAILER red lista.\n');
end
