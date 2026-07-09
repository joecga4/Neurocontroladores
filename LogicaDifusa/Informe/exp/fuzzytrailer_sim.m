function [xx,yy,th2,th12,dl] = fuzzytrailer_sim(xini,yini,Pini,Tini,des,mode)
% Simulacion (no interactiva) del controlador DIFUSO del trailer (porte fiel de
% fuzzytrailerxbueno.m).
%   mode='x': regula la coordenada X hacia des (=xdeseado); avanza hacia arriba
%             (theta2 objetivo 90); termina en y>100.   [ORIGINAL]
%   mode='y': regula la coordenada Y hacia des (=ydeseado=50); avanza en +x
%             (theta2 objetivo 0); termina en x>100.     [ROTADO 90 grados]
% La rotacion se logra alimentando la inferencia con:
%   posicion:    posvar = 50 + des - y     (en vez de x + 50 - des)
%   orientacion: Pfz = theta2 + 90          (para que theta2=0 -> "vertical"=90)
% La cinematica y la tabla de reglas 3D son las mismas.
if nargin<6, mode='x'; end
PI=3.141592; kX=7; kP=7; kT=3; kD=7;
Xrango=[-50 25; 22 38; 35 50; 49 51; 50 65; 62 78; 75 150];
LE0=Xrango(1,1); LE1=10; LE2=Xrango(1,2);
LEC1=Xrango(2,1); LEC2=30; LEC3=Xrango(2,2);
LC1=Xrango(3,1); LC2=42; LC3=Xrango(3,2);
CE1=Xrango(4,1); CE2=50; CE3=Xrango(4,2);
RC1=Xrango(5,1); RC2=58; RC3=Xrango(5,2);
RIC1=Xrango(6,1); RIC2=70; RIC3=Xrango(6,2);
RI1=Xrango(7,1); RI2=90; RI3=Xrango(7,2);
Prango=[-95 10; -30 60; 40 90; 60 120; 90 140; 120 210; 170 275];
RB1=Prango(1,1); RB2=-45; RB3=Prango(1,2);
RU1=Prango(2,1); RU2=40; RU3=Prango(2,2);
RV1=Prango(3,1); RV2=60; RV3=Prango(3,2);
VE1=Prango(4,1); VE2=90; VE3=Prango(4,2);
LV1=Prango(5,1); LV2=120; LV3=Prango(5,2);
LU1=Prango(6,1); LU2=140; LU3=Prango(6,2);
LB1=Prango(7,1); LB2=222.5; LB3=Prango(7,2);
Trango=[-100 0; -30 30; 0 100];
NE2=-80; ZT1=Trango(2,1); ZT2=0; ZT3=Trango(2,2); PO1=Trango(3,1); PO2=80;
Drango=[-70 -15; -25 -6; -12 -1; -2 2; 1 12; 6 25; 15 70];
NB1=Drango(1,1); NB2=Drango(1,2);
NM1=Drango(2,1); NM2=-15.5; NM3=Drango(2,2);
NS1=Drango(3,1); NS2=-6.5; NS3=Drango(3,2);
ZE1=Drango(4,1); ZE2=0; ZE3=Drango(4,2);
PS1=Drango(5,1); PS2=6.5; PS3=Drango(5,2);
PM1=Drango(6,1); PM2=15.5; PM3=Drango(6,2);
PB1=Drango(7,1); PB2=Drango(7,2);

% Tabla de reglas 3D (fila=orientacion, col=posicion, hoja=hitch T)
BaseReg(:,:,1)=ones(7,7);
BaseReg(:,:,2)=[7 7 7 7 1 1 1; 1 1 7 7 7 7 7; 1 1 7 7 7 7 7; 1 1 1 4 7 7 7; 1 1 1 1 1 7 7; 1 1 1 1 1 7 7; 7 7 7 7 1 1 1];
BaseReg(:,:,3)=7*ones(7,7);

x=xini; y=yini; P=Pini; Prad=P*PI/180; T=Tini; Trad=T*PI/180;
r=0.075; L1=2.5; L2=6;
countmax=12000; dD=0.1; tvec=-70:dD:70;
xx=zeros(countmax,1); yy=xx; th2=xx; th12=xx; dl=xx; cnt=0;
for count=1:countmax
    if strcmp(mode,'y')
        posvar = 50 + des - y;     % regula Y -> des (rotado)
        Pfz = P + 90;              % theta2=0 (este) equivale a "vertical"
    else
        posvar = x + 50 - des;     % regula X -> des (original)
        Pfz = P;
    end
    % --- membresia de X (posicion) ---
    numx=0; valuex=[];
    for nx=1:kX
        if (posvar>=Xrango(nx,1)) && (posvar<=Xrango(nx,2)), numx=numx+1; valuex(numx,1)=nx; end
    end
    for nx=1:numx
        vx=valuex(nx,1); fpx=0;
        switch vx
            case 1, if posvar<LE1, fpx=1; else, fpx=1-((posvar-LE1)/(LE2-LE1)); end
            case 2, if posvar<LEC2, fpx=(posvar-LEC1)/(LEC2-LEC1); else, fpx=1-((posvar-LEC2)/(LEC3-LEC2)); end
            case 3, if posvar<LC2, fpx=(posvar-LC1)/(LC2-LC1); else, fpx=1-((posvar-LC2)/(LC3-LC2)); end
            case 4, if posvar<CE2, fpx=(posvar-CE1)/(CE2-CE1); else, fpx=1-((posvar-CE2)/(CE3-CE2)); end
            case 5, if posvar<RC2, fpx=(posvar-RC1)/(RC2-RC1); else, fpx=1-((posvar-RC2)/(RC3-RC2)); end
            case 6, if posvar<RIC2, fpx=(posvar-RIC1)/(RIC2-RIC1); else, fpx=1-((posvar-RIC2)/(RIC3-RIC2)); end
            case 7, if posvar<RI2, fpx=(posvar-RI1)/(RI2-RI1); else, fpx=1; end
        end
        valuex(nx,2)=fpx;
    end
    % --- membresia de P (orientacion) ---
    numP=0; valueP=[];
    for nP=1:kP
        if (Pfz>=Prango(nP,1)) && (Pfz<=Prango(nP,2)), numP=numP+1; valueP(numP,1)=nP; end
    end
    for nP=1:numP
        vP=valueP(nP,1); fpP=0;
        switch vP
            case 1, if Pfz<RB2, fpP=(Pfz-RB1)/(RB2-RB1); else, fpP=1-((Pfz-RB2)/(RB3-RB2)); end
            case 2, if Pfz<RU2, fpP=(Pfz-RU1)/(RU2-RU1); else, fpP=1-((Pfz-RU2)/(RU3-RU2)); end
            case 3, if Pfz<RV2, fpP=(Pfz-RV1)/(RV2-RV1); else, fpP=1-((Pfz-RV2)/(RV3-RV2)); end
            case 4, if Pfz<VE2, fpP=(Pfz-VE1)/(VE2-VE1); else, fpP=1-((Pfz-VE2)/(VE3-VE2)); end
            case 5, if Pfz<LV2, fpP=(Pfz-LV1)/(LV2-LV1); else, fpP=1-((Pfz-LV2)/(LV3-LV2)); end
            case 6, if Pfz<LU2, fpP=(Pfz-LU1)/(LU2-LU1); else, fpP=1-((Pfz-LU2)/(LU3-LU2)); end
            case 7, if Pfz<LB2, fpP=(Pfz-LB1)/(LB2-LB1); else, fpP=1-((Pfz-LB2)/(LB3-LB2)); end
        end
        valueP(nP,2)=fpP;
    end
    % --- membresia de T (hitch) ---
    numT=0; valueT=[];
    for nT=1:kT
        if (T>=Trango(nT,1)) && (T<=Trango(nT,2)), numT=numT+1; valueT(numT,1)=nT; end
    end
    for nT=1:numT
        vT=valueT(nT,1); fpT=0;
        switch vT
            case 1, if T<NE2, fpT=1; else, fpT=1-((T-NE2)/(Trango(1,2)-NE2)); end
            case 2, if T<ZT2, fpT=(T-ZT1)/(ZT2-ZT1); else, fpT=1-((T-ZT2)/(ZT3-ZT2)); end
            case 3, if T<PO2, fpT=(T-PO1)/(PO2-PO1); else, fpT=1; end
        end
        valueT(nT,2)=fpT;
    end
    % --- reglas activas ---
    kkd=1; valueD=[];
    for kkx=1:numx, for kkP=1:numP, for kkT=1:numT
        valueD(kkd,1)=BaseReg(valueP(kkP,1),valuex(kkx,1),valueT(kkT,1));
        valueD(kkd,2)=min(min(valuex(kkx,2),valueP(kkP,2)),valueT(kkT,2));
        kkd=kkd+1;
    end, end, end
    numD=kkd-1;
    Dbase=zeros(numD,numel(tvec));
    for nD=1:numD
        mu=trapD(tvec,valueD(nD,1),NB1,NB2,NM1,NM2,NM3,NS1,NS2,NS3,ZE1,ZE2,ZE3,PS1,PS2,PS3,PM1,PM2,PM3,PB1,PB2);
        Dbase(nD,:)=min(mu,valueD(nD,2));
    end
    maxD=max(Dbase,[],1); AreaD=sum(maxD)*dD;
    if AreaD==0, DxG=0; else, DxG=((dD.*maxD)*tvec')/AreaD; end
    DxG=DxG*6; DxG=max(-50,min(50,DxG));
    % --- registro y cinematica (identica en ambos modos) ---
    cnt=cnt+1; xx(cnt)=x; yy(cnt)=y; th2(cnt)=P; th12(cnt)=T; dl(cnt)=DxG;
    Prad=Prad-(r/L2)*sin(Trad);
    if strcmp(mode,'y')
        % rotado: theta2 ronda 0 (este) -> mantener en (-pi,pi] para no salir del rango difuso
        if Prad>PI, Prad=Prad-2*PI; end
        if Prad<-PI, Prad=Prad+2*PI; end
    else
        if Prad>(3*PI/2), Prad=Prad-2*PI; end
        if Prad<-PI/2, Prad=Prad+2*PI; end
    end
    P=Prad*180/PI;
    Trad=Trad+(r/L2)*sin(Trad)-r/L1*tan(PI/180*DxG);
    if Trad>2*PI, Trad=Trad-2*PI; end
    if Trad<-2*PI, Trad=Trad+2*PI; end
    T=Trad*180/PI;
    x=x+r*cos(Trad)*cos(Prad); y=y+r*cos(Trad)*sin(Prad);
    if strcmp(mode,'y')
        if x>100, break; end
    else
        if y>100, break; end
    end
end
xx=xx(1:cnt); yy=yy(1:cnt); th2=th2(1:cnt); th12=th12(1:cnt); dl=dl(1:cnt);
end

function mu=trapD(t,vD,NB1,NB2,NM1,NM2,NM3,NS1,NS2,NS3,ZE1,ZE2,ZE3,PS1,PS2,PS3,PM1,PM2,PM3,PB1,PB2)
mu=zeros(size(t));
switch vD
    case 1, mu(t<NB1)=1; i=t>=NB1&t<NB2; mu(i)=1-((t(i)-NB1)/(NB2-NB1));
    case 2, i=t>NM1&t<=NM2; mu(i)=(t(i)-NM1)/(NM2-NM1); i=t>NM2&t<=NM3; mu(i)=1-((t(i)-NM2)/(NM3-NM2));
    case 3, i=t>NS1&t<=NS2; mu(i)=(t(i)-NS1)/(NS2-NS1); i=t>NS2&t<=NS3; mu(i)=1-((t(i)-NS2)/(NS3-NS2));
    case 4, i=t>ZE1&t<=ZE2; mu(i)=(t(i)-ZE1)/(ZE2-ZE1); i=t>ZE2&t<=ZE3; mu(i)=1-((t(i)-ZE2)/(ZE3-ZE2));
    case 5, i=t>PS1&t<=PS2; mu(i)=(t(i)-PS1)/(PS2-PS1); i=t>PS2&t<=PS3; mu(i)=1-((t(i)-PS2)/(PS3-PS2));
    case 6, i=t>PM1&t<=PM2; mu(i)=(t(i)-PM1)/(PM2-PM1); i=t>PM2&t<=PM3; mu(i)=1-((t(i)-PM2)/(PM3-PM2));
    case 7, i=t>PB1&t<=PB2; mu(i)=(t(i)-PB1)/(PB2-PB1); mu(t>PB2)=1;
end
end
