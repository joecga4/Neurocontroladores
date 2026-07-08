function car_experiments(figdir, netfile)
% Valida el neurocontrolador del carro en las TRES trayectorias:
%  (1) estacionamiento vertical (x*=0, phi*=pi/2)
%  (2) trayectoria oblicua (rectas a 45 y 60 grados)
%  (3) trayectoria circular (radio R)
% Usa una MISMA red entrenada (regulacion), redefiniendo x* y phi* por trayectoria.
fprintf('\n===== CARRO: 3 trayectorias =====\n');
S = load(netfile); net.v=S.v; net.w=S.w; net.c=S.c; net.a=S.a;
inscale=[10;1]; r=0.01; L=2; umax=tan(45*pi/180);

% ---------- (1) Estacionamiento vertical ----------
figure('Visible','off','Position',[0 0 620 480]); hold on;
x0set=[-15 -8 8 15]; phi0set=[0 pi 3*pi/2 pi/2];
for c=1:numel(x0set)
    [X,Y]=rollout(net,inscale,r,L,umax,[x0set(c);5;phi0set(c)],@(x,y)deal(0,pi/2,0),50,8000);
    plot(X,Y,'LineWidth',1.4);
end
xline(0,'k--'); yline(50,'k:'); axis([-20 20 0 55]); grid on;
xlabel('X'); ylabel('Y'); title('Carro - Estacionamiento vertical (x*=0, \phi*=\pi/2)');
saveas(gcf,fullfile(figdir,'car_parking.png')); close;

% ---------- (2) Trayectorias oblicuas 45 y 60 ----------
for th=[45 60]
    thr=th*pi/180;
    figure('Visible','off','Position',[0 0 620 480]); hold on;
    xx=0:1:40; plot(xx, tan(thr)*xx, 'k--','LineWidth',1);   % recta deseada
    for x0=[-10 0 12]
        for y0=[2 15]
            ref=@(x,y) obliqueref(x,y,thr);
            [X,Y]=rollout(net,inscale,r,L,umax,[x0;y0;thr*0],ref,60,9000);
            plot(X,Y,'LineWidth',1.3);
        end
    end
    axis equal; axis([-12 45 0 45]); grid on;
    xlabel('X'); ylabel('Y'); title(sprintf('Carro - Trayectoria oblicua %d\\circ',th));
    saveas(gcf,fullfile(figdir,sprintf('car_oblique%d.png',th))); close;
end

% ---------- (3) Trayectoria circular ----------
R=20; xc=0; yc=0;    % circulo centro (xc,yc), radio R
dast=atan(L/R);      % feedforward de direccion (curvatura constante)
figure('Visible','off','Position',[0 0 560 520]); hold on;
ang=linspace(0,2*pi,200); plot(xc+R*cos(ang), yc+R*sin(ang),'k--','LineWidth',1);
% (a) arranca SOBRE el circulo con rumbo tangente (horario) -> mantiene la trayectoria
[Xo,Yo]=rollout(net,inscale,r,L,umax,[xc+R;yc;-pi/2], @(x,y)circref(x,y,xc,yc,R,L), [], 14000, dast);
plot(Xo,Yo,'LineWidth',1.6);
% (b) arranca ligeramente fuera -> captura y luego mantiene
[Xc,Yc]=rollout(net,inscale,r,L,umax,[xc+R+4;yc;-pi/2], @(x,y)circref(x,y,xc,yc,R,L), [], 14000, dast);
plot(Xc,Yc,'--','LineWidth',1.3);
legend('Circulo deseado','Sobre el circulo','Captura desde fuera','Location','best');
axis equal; grid on; xlabel('X'); ylabel('Y');
title(sprintf('Carro - Trayectoria circular (R=%d)',R));
saveas(gcf,fullfile(figdir,'car_circular.png')); close;

fprintf('  CARRO OK (figuras generadas).\n');
end

% ================= auxiliares =================
function [X,Y,PHI,U]=rollout(net,inscale,r,L,umax,x0,reffun,ymax,kmax,dast)
if nargin<10, dast=0; end
X=zeros(kmax,1); Y=zeros(kmax,1); PHI=zeros(kmax,1); U=zeros(kmax,1);
x=x0(1); y=x0(2); phi=x0(3); k=1;
while k<=kmax
    [xast,phiast,~]=reffun(x,y);
    u = carnet(net,inscale, x-xast, phi-phiast) + tan(dast);
    u = max(-umax-abs(tan(dast)), min(umax+abs(tan(dast)), u));
    X(k)=x; Y(k)=y; PHI(k)=phi; U(k)=u;
    x = x + r*cos(phi);
    y = y + r*sin(phi);
    phi = phi - r/L*u;
    if ~isempty(ymax) && y>=ymax, break; end
    if abs(x)>200 || y>200 || y< -50, break; end
    k=k+1;
end
k=min(k,kmax); X=X(1:k); Y=Y(1:k); PHI=PHI(1:k); U=U(1:k);
end

function [xast,phiast,dast]=obliqueref(x,y,thr)
% Pie de la perpendicular de (x,y) sobre la recta y=tan(thr)x que pasa por 0.
proj = x*cos(thr) + y*sin(thr);      % coordenada a lo largo de la recta
xast = proj*cos(thr);                % x del pie de perpendicular
phiast = thr; dast = 0;
end

function [xast,phiast,dast]=circref(x,y,xc,yc,R,L)
% Circular = seguir la RECTA TANGENTE local al circulo (misma idea que la
% oblicua, con recta movil): punto mas cercano del circulo P, direccion
% tangente phi*, y x* = pie de la perpendicular de (x,y) sobre esa tangente.
ang = atan2(y-yc, x-xc);
Px = xc + R*cos(ang);  Py = yc + R*sin(ang);   % punto del circulo mas cercano
phiast = ang - pi/2;                            % tangente (sentido HORARIO, u>0)
d = [cos(phiast); sin(phiast)];
foot = [Px;Py] + (([x;y]-[Px;Py])'*d)*d;        % pie de perpendicular sobre la tangente
xast = foot(1);
dast = atan(L/R);
end
