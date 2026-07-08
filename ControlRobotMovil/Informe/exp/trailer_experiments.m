function trailer_experiments(figdir)
% Valida el neurocontrolador del TRAILER en las tres trayectorias.
addpath(fileparts(mfilename('fullpath')));
net=load(fullfile(figdir,'..','exp','trailer_net.mat'));
L1=net.L1;

% (1) Estacionamiento vertical (x*=0, th2*=pi/2)
figure('Visible','off','Position',[0 0 620 480]); hold on;
for x0=[-8 -3 5 9]
    [X,Y]=trailer_roll(net,[x0;3;pi/2;pi/2],@(x,y)deal(0,pi/2),0,50,12000);
    plot(X,Y,'LineWidth',1.4);
end
xline(0,'k--'); axis([-15 15 0 55]); grid on; xlabel('X'); ylabel('Y');
title('Trailer - Estacionamiento vertical');
saveas(gcf,fullfile(figdir,'trailer_parking.png')); close;

% (2) Trayectorias oblicuas 45 y 60
for th=[45 60]
    thr=th*pi/180;
    figure('Visible','off','Position',[0 0 620 480]); hold on;
    xx=0:1:40; plot(xx,tan(thr)*xx,'k--','LineWidth',1);
    for x0=[-8 0 10]
        [X,Y]=trailer_roll(net,[x0;3;thr;thr],@(x,y)obref(x,y,thr),0,60,10000);
        plot(X,Y,'LineWidth',1.3);
    end
    axis equal; axis([-12 45 0 45]); grid on; xlabel('X'); ylabel('Y');
    title(sprintf('Trailer - Trayectoria oblicua %d\\circ',th));
    saveas(gcf,fullfile(figdir,sprintf('trailer_oblique%d.png',th))); close;
end

% (3) Trayectoria circular
R=20; xc=0; yc=0; dast=atan(L1/R);
figure('Visible','off','Position',[0 0 560 520]); hold on;
ang=linspace(0,2*pi,200); plot(xc+R*cos(ang),yc+R*sin(ang),'k--','LineWidth',1);
[X,Y]=trailer_roll(net,[xc+R;yc;-pi/2;-pi/2],@(x,y)cref(x,y,xc,yc,R),dast,[],14000);
plot(X,Y,'LineWidth',1.6);
axis equal; grid on; xlabel('X'); ylabel('Y');
title(sprintf('Trailer - Trayectoria circular (R=%d)',R));
saveas(gcf,fullfile(figdir,'trailer_circular.png')); close;
fprintf('  TRAILER trayectorias OK.\n');
end

function [xast,th2ast]=obref(x,y,thr)
proj=x*cos(thr)+y*sin(thr); xast=proj*cos(thr); th2ast=thr;
end
function [xast,th2ast]=cref(x,y,xc,yc,R)
ang=atan2(y-yc,x-xc); Px=xc+R*cos(ang); Py=yc+R*sin(ang);
phiast=ang-pi/2; d=[cos(phiast);sin(phiast)];
foot=[Px;Py]+(([x;y]-[Px;Py])'*d)*d; xast=foot(1); th2ast=phiast;
end
