function [X,Y,TH1,TH2]=trailer_roll(net, s0, reffun, dast, ymax, kmax)
% Simulacion 4-estados (X,Y,th1,th2) del robot trailer con la red neurocontroladora.
%   s0 = [x0; y0; th1_0; th2_0] ; reffun(x,y)->[xast, th2ast]
%   dast = feedforward de direccion (curvatura) ; ymax/kmax = parada
if nargin<4, dast=0; end
if nargin<5, ymax=[]; end
if nargin<6, kmax=15000; end
r=0.01; L1=net.L1; L2=net.L2; ins=net.inscale; umax=tan(45*pi/180);
X=zeros(kmax,1);Y=zeros(kmax,1);TH1=zeros(kmax,1);TH2=zeros(kmax,1);
x=s0(1); y=s0(2); th1=s0(3); th2=s0(4); k=1;
while k<=kmax
    [xast,th2ast]=reffun(x,y);
    th12=th1-th2;
    in=[x-xast; mod(th2-th2ast+pi,2*pi)-pi; mod(th12+pi,2*pi)-pi]./ins;
    m=net.v'*in; n=2./(1+exp(-(m-net.c)./net.a))-1; u=net.w'*n + tan(dast);
    u=max(-umax-abs(tan(dast)),min(umax+abs(tan(dast)),u));
    X(k)=x;Y(k)=y;TH1(k)=th1;TH2(k)=th2;
    x=x+r*cos(th12)*cos(th2);
    y=y+r*cos(th12)*sin(th2);
    th1=th1-(r/L1)*u;
    th2=th2-(r/L2)*sin(th12);
    if ~isempty(ymax) && y>=ymax, break; end
    if abs(x)>250||abs(y)>250, break; end
    k=k+1;
end
k=min(k,kmax); X=X(1:k);Y=Y(1:k);TH1=TH1(1:k);TH2=TH2(1:k);
end
