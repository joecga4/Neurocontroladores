function trailer_probe(figdir)
addpath(fileparts(mfilename('fullpath')));
% Entrenamiento BPTT del trailer (una etapa, casos alrededor de la vertical).
% Sistema SUBACTUADO: se usan mejores-pesos, tasa baja, BPTT truncado y clip.
p2=pi/2;
x1set=[-4 0 4]; dth=(-90:30:90)*pi/180;
[X1,DTH]=meshgrid(x1set,dth); th2=p2+DTH(:)';
xini=[X1(:)'; th2; th2];
hp=struct('L1',2,'L2',3,'inscale',[10;1;1],'q',[1;10;5],'ndata',2000, ...
          'Ttrunc',700,'gmax',8,'nm',50,'eta',0.012,'etaa',0.0015, ...
          'niter',500,'x_ini',xini);
fprintf('Trailer: %d CI\n', size(xini,2));
o=train_trailer(hp);
net=o;
save(fullfile(figdir,'..','exp','trailer_net.mat'),'-struct','net');
fprintf('  trailer costo mejor=%.4g  (J0=%.4g  relativo=%.3f)\n', o.finalcost, o.J0, o.finalcost/o.J0);

% Curva de convergencia
JJ=o.JJ; JJ=JJ(JJ>0);
figure('Visible','off','Position',[0 0 560 360]);
plot(JJ/JJ(1),'LineWidth',1.4); grid on; xlabel('Iteracion'); ylabel('Costo relativo J/J_0');
title('Trailer - Convergencia del entrenamiento DBP');
saveas(gcf,fullfile(figdir,'trailer_training.png')); close;

% Prueba de estacionamiento vertical
figure('Visible','off','Position',[0 0 620 480]); hold on;
for x0=[-6 -2 3 7]
  for dth0=[-60 0 60]
    [X,Y]=trailer_roll(net,[x0;3;p2+dth0*pi/180;p2+dth0*pi/180],@(x,y)deal(0,p2),0,50,10000);
    plot(X,Y,'LineWidth',1.2);
  end
end
xline(0,'k--'); axis([-15 15 0 55]); grid on; xlabel('X'); ylabel('Y');
title('Trailer - Estacionamiento vertical (prueba)');
saveas(gcf,fullfile(figdir,'trailer_parking_probe.png')); close;
fprintf('  trailer probe listo.\n');
end
