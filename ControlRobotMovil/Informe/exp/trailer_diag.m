function trailer_diag(figdir)
% Diagnostico: ley de control MANUAL para verificar que el modelo del trailer
% es estacionable (descarta errores de signo/modelo).
r=0.01; L1=2; L2=3; th2star=pi/2; umax=tan(45*pi/180);
figure('Visible','off','Position',[0 0 620 480]); hold on;
offs=[-60 -30 30 60]*pi/180; x0s=[-6 -2 3 7];
for c=1:4
    x=x0s(c); y=3; th2=th2star+offs(c); th1=th2;
    X=zeros(12000,1); Y=zeros(12000,1); kk=0;
    for k=1:12000
        th12=th1-th2;
        e2=mod(th2-th2star+pi,2*pi)-pi;
        th12des=max(-0.6,min(0.6, 1.5*e2 - 0.05*x));   % hitch deseado (gira trailer + corrige x)
        dsteer=2.0*(th12-th12des);                      % steer para llevar th12 -> th12des
        u=max(-umax,min(umax,dsteer));
        kk=kk+1; X(kk)=x; Y(kk)=y;
        x=x+r*cos(th12)*cos(th2); y=y+r*cos(th12)*sin(th2);
        th1=th1-(r/L1)*u; th2=th2-(r/L2)*sin(th12);
        if y>=50 || abs(x)>60 || y>60, break; end
    end
    plot(X(1:kk),Y(1:kk),'LineWidth',1.3);
    fprintf('x0=%d off=%.0f -> x_fin=%.3f th2_fin=%.1f deg\n', x0s(c), offs(c)*180/pi, x, th2*180/pi);
end
xline(0,'k--'); axis([-15 15 0 55]); grid on;
title('Diagnostico: ley manual del trailer'); xlabel('X'); ylabel('Y');
saveas(gcf,fullfile(figdir,'trailer_diag.png')); close;
disp('DIAG OK');
end
