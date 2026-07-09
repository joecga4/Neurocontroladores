function [xx,yy,PP,dd] = fuzzycar_sim(xini,yini,Pini,xdeseado,BaseReg,gain)
% Simulacion (no interactiva) del controlador DIFUSO del carro (porte fiel de
% fuzzycarxloco.m). Regula la coordenada X hacia xdeseado (xnuevo = x+50-xdeseado
% -> centro 50) y el vehiculo avanza hacia arriba (orientacion objetivo 90) hasta y>100.
%   BaseReg : matriz de reglas 7x7 (fila=phi, col=X) -> region de delta (1..7)
%   gain    : ganancia de defuzzificacion (original: 1.5)
if nargin<6, gain=1.5; end
PI=3.141592;
kX=7; kP=7; kD=7;
Xrango=[-50 25; 22 38; 35 49; 40 60; 51 65; 62 78; 75 150];
LE0=Xrango(1,1); LE1=10; LE2=Xrango(1,2);
LEC1=Xrango(2,1); LEC2=30; LEC3=Xrango(2,2);
LC1=Xrango(3,1); LC2=42; LC3=Xrango(3,2);
CE1=Xrango(4,1); CE2=50; CE3=Xrango(4,2);
RC1=Xrango(5,1); RC2=58; RC3=Xrango(5,2);
RIC1=Xrango(6,1); RIC2=70; RIC3=Xrango(6,2);
RI1=Xrango(7,1); RI2=90; RI3=Xrango(7,2);
Prango=[-95 10; -10 55; 45 88; 70 110; 92 135; 125 190; 170 275];
RB1=Prango(1,1); RB2=-45; RB3=Prango(1,2);
RU1=Prango(2,1); RU2=22.5; RU3=Prango(2,2);
RV1=Prango(3,1); RV2=66.5; RV3=Prango(3,2);
VE1=Prango(4,1); VE2=90; VE3=Prango(4,2);
LV1=Prango(5,1); LV2=113.5; LV3=Prango(5,2);
LU1=Prango(6,1); LU2=157.5; LU3=Prango(6,2);
LB1=Prango(7,1); LB2=222.5; LB3=Prango(7,2);
Drango=[-60 -15; -25 -6; -12 -1; -5 5; 1 12; 6 25; 15 60];
NB1=Drango(1,1); NB2=Drango(1,2);
NM1=Drango(2,1); NM2=-15.5; NM3=Drango(2,2);
NS1=Drango(3,1); NS2=-6.5; NS3=Drango(3,2);
ZE1=Drango(4,1); ZE2=0; ZE3=Drango(4,2);
PS1=Drango(5,1); PS2=6.5; PS3=Drango(5,2);
PM1=Drango(6,1); PM2=15.5; PM3=Drango(6,2);
PB1=Drango(7,1); PB2=Drango(7,2);

x=xini; P=Pini; Prad=P*(PI/180); y=yini; r=0.5; L=12;
countmax=600; dD=0.1;
xx=zeros(countmax,1); yy=zeros(countmax,1); PP=zeros(countmax,1); dd=zeros(countmax,1);
cnt=0;
for count=1:countmax
    xnuevo = x + 50 - xdeseado;
    % --- membresia de X ---
    numx=0; valuex=[];
    for nx=1:kX
        if (xnuevo>=Xrango(nx,1)) && (xnuevo<=Xrango(nx,2))
            numx=numx+1; valuex(numx,1)=nx;
        end
    end
    for nx=1:numx
        vx=valuex(nx,1); fpx=0;
        switch vx
            case 1, if xnuevo<LE1, fpx=1; elseif xnuevo<=LE2, fpx=1-((xnuevo-LE1)/(LE2-LE1)); end
            case 2, if xnuevo<LEC2, fpx=(xnuevo-LEC1)/(LEC2-LEC1); else, fpx=1-((xnuevo-LEC2)/(LEC3-LEC2)); end
            case 3, if xnuevo<LC2, fpx=(xnuevo-LC1)/(LC2-LC1); else, fpx=1-((xnuevo-LC2)/(LC3-LC2)); end
            case 4, if xnuevo<CE2, fpx=(xnuevo-CE1)/(CE2-CE1); else, fpx=1-((xnuevo-CE2)/(CE3-CE2)); end
            case 5, if xnuevo<RC2, fpx=(xnuevo-RC1)/(RC2-RC1); else, fpx=1-((xnuevo-RC2)/(RC3-RC2)); end
            case 6, if xnuevo<RIC2, fpx=(xnuevo-RIC1)/(RIC2-RIC1); else, fpx=1-((xnuevo-RIC2)/(RIC3-RIC2)); end
            case 7, if xnuevo<RI2, fpx=(xnuevo-RI1)/(RI2-RI1); else, fpx=1; end
        end
        valuex(nx,2)=fpx;
    end
    % --- membresia de P ---
    numP=0; valueP=[];
    for nP=1:kP
        if (P>=Prango(nP,1)) && (P<=Prango(nP,2))
            numP=numP+1; valueP(numP,1)=nP;
        end
    end
    for nP=1:numP
        vP=valueP(nP,1); fpP=0;
        switch vP
            case 1, if P<RB2, fpP=(P-RB1)/(RB2-RB1); else, fpP=1-((P-RB2)/(RB3-RB2)); end
            case 2, if P<RU2, fpP=(P-RU1)/(RU2-RU1); else, fpP=1-((P-RU2)/(RU3-RU2)); end
            case 3, if P<RV2, fpP=(P-RV1)/(RV2-RV1); else, fpP=1-((P-RV2)/(RV3-RV2)); end
            case 4, if P<VE2, fpP=(P-VE1)/(VE2-VE1); else, fpP=1-((P-VE2)/(VE3-VE2)); end
            case 5, if P<LV2, fpP=(P-LV1)/(LV2-LV1); else, fpP=1-((P-LV2)/(LV3-LV2)); end
            case 6, if P<LU2, fpP=(P-LU1)/(LU2-LU1); else, fpP=1-((P-LU2)/(LU3-LU2)); end
            case 7, if P<LB2, fpP=(P-LB1)/(LB2-LB1); else, fpP=1-((P-LB2)/(LB3-LB2)); end
        end
        valueP(nP,2)=fpP;
    end
    % --- reglas activas -> valueD ---
    kkd=1; valueD=[];
    for kkx=1:numx
        for kkP=1:numP
            valueD(kkd,1)=BaseReg(valueP(kkP,1),valuex(kkx,1));
            valueD(kkd,2)=min(valuex(kkx,2),valueP(kkP,2));
            kkd=kkd+1;
        end
    end
    numD=kkd-1;
    % --- agregacion (Mamdani, min-max) sobre el universo de delta ---
    tvec=-50:dD:50; nnD=numel(tvec);
    Dbase=zeros(numD,nnD);
    for nD=1:numD
        vD=valueD(nD,1); minD=valueD(nD,2);
        mu=trapmf(tvec,vD,NB1,NB2,NM1,NM2,NM3,NS1,NS2,NS3,ZE1,ZE2,ZE3,PS1,PS2,PS3,PM1,PM2,PM3,PB1,PB2);
        Dbase(nD,:)=min(mu,minD);
    end
    maxDbase=max(Dbase,[],1);
    AreaD=sum(maxDbase)*dD;
    if AreaD==0, DxG=0; else, DxG=((dD.*maxDbase)*tvec')/AreaD; end
    DxG=DxG*gain;
    DxG=max(-50,min(50,DxG));
    % --- registro y cinematica ---
    cnt=cnt+1; xx(cnt)=x; yy(cnt)=y; PP(cnt)=P; dd(cnt)=DxG;
    Prad=Prad-(r/L)*tan((PI/180)*DxG);
    if Prad>(3*PI/2), Prad=Prad-2*PI; end
    if Prad<-PI/2, Prad=Prad+2*PI; end
    P=Prad*180/PI;
    x=x+r*cos(Prad); y=y+r*sin(Prad);
    if y>100, break; end
end
xx=xx(1:cnt); yy=yy(1:cnt); PP=PP(1:cnt); dd=dd(1:cnt);
end

function mu=trapmf(t,vD,NB1,NB2,NM1,NM2,NM3,NS1,NS2,NS3,ZE1,ZE2,ZE3,PS1,PS2,PS3,PM1,PM2,PM3,PB1,PB2)
% Funcion de pertenencia de la region de delta vD evaluada en el vector t.
mu=zeros(size(t));
switch vD
    case 1  % NB: 1 hasta NB1, baja a 0 en NB2
        mu(t<NB1)=1; idx=t>=NB1 & t<NB2; mu(idx)=1-((t(idx)-NB1)/(NB2-NB1));
    case 2  % NM triangular
        idx=t>NM1 & t<=NM2; mu(idx)=(t(idx)-NM1)/(NM2-NM1);
        idx=t>NM2 & t<=NM3; mu(idx)=1-((t(idx)-NM2)/(NM3-NM2));
    case 3
        idx=t>NS1 & t<=NS2; mu(idx)=(t(idx)-NS1)/(NS2-NS1);
        idx=t>NS2 & t<=NS3; mu(idx)=1-((t(idx)-NS2)/(NS3-NS2));
    case 4
        idx=t>ZE1 & t<=ZE2; mu(idx)=(t(idx)-ZE1)/(ZE2-ZE1);
        idx=t>ZE2 & t<=ZE3; mu(idx)=1-((t(idx)-ZE2)/(ZE3-ZE2));
    case 5
        idx=t>PS1 & t<=PS2; mu(idx)=(t(idx)-PS1)/(PS2-PS1);
        idx=t>PS2 & t<=PS3; mu(idx)=1-((t(idx)-PS2)/(PS3-PS2));
    case 6
        idx=t>PM1 & t<=PM2; mu(idx)=(t(idx)-PM1)/(PM2-PM1);
        idx=t>PM2 & t<=PM3; mu(idx)=1-((t(idx)-PM2)/(PM3-PM2));
    case 7  % PB: sube en PB1, 1 desde PB2
        idx=t>PB1 & t<=PB2; mu(idx)=(t(idx)-PB1)/(PB2-PB1); mu(t>PB2)=1;
end
end
