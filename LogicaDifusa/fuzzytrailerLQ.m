% This program is for controlling a truck-trailer mobile robot.
% The robot position is defined by: x, y, fi2, fi12.
% Only variabes y, fi2 and fi2 will be used for control.
% Then the state-space equation for control will be based on
% vector [ y  fi2  fi12 ].
% The nonlinear model is linearized around final desired position:
% y = 0, fi12 = 0, sinf(fi12) = fi2, and a linera controller is designed 
% using LQR.
% However, in order to ensure that fi12 does not attain a higher value
% (close to jack-knife position), three controllers are considered.
% Fi12 must be in the range: -90 < fi12 < 90, and three membership 
% functions are constructed for every partition of angle fi12. 
% The controller are:
%    IF fi12 = negative  ->    delta = -deltamax
%    IF fi12 = cero        ->    delta = linear control law
%    IF fi12 = positive    ->   delta = deltamax
% Looking at the equation of f12_dot it is possible to formulate controllers
% for the first and third partitions.

clear;
close all;
clc;
% Membership functions of fi12 (in the range -90 deg to +90 deg)
np = 2000;   % Number of sample points between -90 a nd +90 (try other values)
% np0=1;  np1=round(np/4);   np2=np/2;   np3=np-np1;   np4=np;
np0=1;  np1=round(np/20);  np2=np/2;   np3=np-np1;   np4=np;
% np0=1;  np1=round(np/3);   np2=np/2;   np3=np-np1;   np4=np;

% np0=1;  np1=1;   np2=np/2;   np3=np-np1;   np4=np;
% np0=1;  np1=round(2*np/15);   np2=np/2;   np3=np-np1;   np4=np;
np01 = np0:np1;      np01 = np01';
np12 = (np1+1):np2;  np12 = np12';
np23 = (np2+1):np3;  np23 = np23';
np34 = (np3+1):np4;  np34 = np34';
fdp1(np0:np1,1)   = 0*np01 + 1;
fdp1(np1+1:np2,1) = (np12-np2)/(np1-np2);
fdp1(np2+1:np,1)  = 0*(np2+1:np)';
fdp2(np0:np1,1)   = 0*np01;
fdp2(np1+1:np2,1) = (np12-np1)/(np2-np1);
fdp2(np2+1:np3,1)  = (np23-np3)/(np2-np3); 
fdp2(np3+1:np,1)  = 0*(np3+1:np)';
fdp3(np0:np2,1)   = 0*(np0:np2)';
fdp3(np2+1:np3,1) = (np23-np2)/(np3-np2);
fdp3(np3+1:np,1)  = 0*(np3+1:np)' + 1;
nf = length(fdp1);
nnp = 1:np;   nnp = nnp';
fi12fuz = (nnp-1)/(np-1)*180 - 90;   % Vector fi12 in the range -90 to +90
figure(1);
plot(fi12fuz,fdp1,'Linewidth',1.25); hold on;
plot(fi12fuz,fdp2,'Linewidth',1.25);
plot(fi12fuz,fdp3,'Linewidth',1.25);
title('Membership functions of fi12 ');
axis([-90 90 0 1.4]);
 
% Robot parameters
v = 3;
L1 = 2;
L2 = 4;
dt = 0.0025;
r = v*dt;

% Linearized system around y=0, fi12=0, fi2 = 0 
A = [  0   v   0
       0   0 -v/L2
       0   0  v/L2 ];
B = [ 0
      0
     -v/L1 ];

% Determine control gain K (u=-Kx) by Ricati equation
   
q1 = 20*8*4*2;          % yini = 0
q1 = 10*8*4*2;      % yini = 5 
q1 = 2*8*4*2;        % yini = 10
%q1 = 0.3*8*4*2;      % yini = 20
% q1 = 0.075*8*4*2;      % yini = 30 
q2 = 1*100;
q3 = 15*200;
Q = diag([ q1 q2 q3 ]);

P = are(A,B*B',Q);
K = B'*P;
k1 = K(1,1);   k2 = K(1,2);   k3 = K(1,3);




% Initial position of the mobile robot

ti= 0;   tf = 40;
tanmax = tan(45*pi/180);
x    = input('Initial coordinate x [30 to 40] : ');
y    = input('Initial coordinate y [-10 to 10]: ');
fi1  = input('Initial inclination angle fi1 (deg) [-180 to 180]: ');
fi2  = input('Initial inclination angle fi2 (deg) [-180 to 180]: ');
yast = input('Desired coordinate y [-10 to 10]: ');
fi12 = fi1 - fi2;
if(fi12 > 180);      % To the range in -180 to +180
    fi12 = fi12 - 360;
elseif(fi12 < -180)
    fi12 = fi12 + 360;
end
%x = 10;
%y = 3;
%fi1 = 0;
%fi12 = 12;
fi1 = fi1*pi/180;
fi2 = fi2*pi/180;
fi12 = fi12*pi/180;
k = 1;
for tt = ti:dt:tf
%  yast = (x+y)/2;       % 45 degrees desired path
%   fi2ast = 45*pi/180;
%   fi12ast = 0;
%   yast = 0;
   fi2ast = 0;
   fi12ast = 0;
   xx(k,1) = x;
   yy(k,1) = y;
   ffi1(k,1) = fi1;
   ffi2(k,1) = fi2;
   ffi12(k,1) = fi12;
   t(k,1) = tt;

   tand = -k1*(y-yast) - k2*(fi2-fi2ast) - k3*(fi12-fi12ast);
   tand = 1*tand;
   
   if( tand > tanmax )
       tand = tanmax;
   elseif( tand < -tanmax )
       tand = -tanmax;
   end
   
 % Weighting of three controllers using membership functions 
   kfi12  = round((fi12-pi/2)/pi*(np-1) + np);
   ffdp1 = fdp1(kfi12,1);
   ffdp2 = fdp2(kfi12,1);
   ffdp3 = fdp3(kfi12,1);
   ffdp1 = ffdp1/(ffdp1+ffdp2+ffdp3);
   ffdp2 = ffdp2/(ffdp1+ffdp2+ffdp3);
   ffdp3 = ffdp3/(ffdp1+ffdp2+ffdp3);
   tand  = ffdp1*(-tanmax) + ffdp2*tand + ffdp3*(tanmax);
   delta(k,1) = atan(tand);

   % Robot model
   xp = v*cos(fi12)*cos(fi2);
   yp = v*cos(fi12)*sin(fi2); 
   fi1p = -v/L1*tand;
   fi2p = -v/L2*sin(fi12);
   x = x + xp*dt;
   y = y + yp*dt;
   fi1 = fi1 + fi1p*dt;
   fi2 = fi2 + fi2p*dt;
   fi12 = fi1 - fi2;
   if(fi12 > pi);
      fi12 = fi12 - 2*pi;
   elseif(fi12 < -pi)
      fi12 = fi12 + 2*pi;
   end
   if(x > 80)    % Límite de área de trabajo 
       break;
   end
   k = k + 1;
end

xxe = [ 0 40 ];
yye = [ 0  0 ];
figure(2);  subplot(2,1,1); plot(xx); title('Coordinate x'); 
            subplot(2,1,2); plot(yy); title('Coordinate y'); 
figure(3);  subplot(4,1,1); plot(t,180/pi*ffi1,'-b','Linewidth',1.25);   axis([0 40 -200 200]);
title('Angle Fi1'); hold on;
plot(xxe,yye,':b');
            subplot(4,1,2); plot(t,180/pi*ffi2,'-b','Linewidth',1.25);   axis([0 40 -200 200]);
title('Angle Fi2');  hold on;
plot(xxe,yye,':b');
            subplot(4,1,3); plot(t,180/pi*ffi12,'-b','Linewidth',1.25);   axis([0 40 -60 60]);
title('Angle Fi12');  hold on;
plot(xxe,yye,':b');
            subplot(4,1,4); plot(t,180/pi*delta,'-b','Linewidth',1.25);   axis([0 40 -50 50]);
title('Steering angle Delta');hold on;
plot(xxe,yye,':b');
figure(5);  plot(xx,yy);  grid;    title('X-Y');
axis([ 0 100 -50 50 ]);

disp(' ');
disp('Press ENTER for animation');
pause;

La = 1.0*L1;    % Trailer width (for drawing)
Lt = L1;           % Trailer length 
nk = length(xx);
hf = figure(6);
set(hf,'Position',[300 50 750 620]);
axis([0 80 -40 40]);
hold on;
xct = [ 0 80 ];   yct = [ yast yast ];
%plot(xct,yct);
xobs1 = [ 75     75       80    80  75 ];
yobs1 = [ 40   yast+3   yast+3  40  40 ];
xobs2 = [  75     75  80    80     75 ];
yobs2 = [ yast-3 -40 -40  yast-3  yast-3 ];
plot(xct,yct,':b');
fill(xobs1,yobs1,'c');
fill(xobs2,yobs2,'c');

writeObj=VideoWriter('trailer4.avi');
writeObj.FrameRate=20;
open(writeObj);

for k = 1:100:nk
  x = xx(k,1);   y = yy(k,1);  
  fi1 = ffi1(k,1);  fi2 = ffi2(k,1);
  x1 = x - L2*cos(fi2);     y1 = y - L2*sin(fi2);
  x2 = x1 - L1*cos(fi1);    y2 = y1 - L1*sin(fi1); 

  xA = x2 - La/2*sin(fi1);
  yA = y2 + La/2*cos(fi1);
  xB = x2 + La/2*sin(fi1);
  yB = y2 - La/2*cos(fi1);
  xC = x1 + La/2*sin(fi1);
  yC = y1 - La/2*cos(fi1); 
  xD = x1 - La/2*sin(fi1);
  yD = y1 + La/2*cos(fi1); 
  xE = x1 - La/2*sin(fi2);
  yE = y1 + La/2*cos(fi2);
  xF = x1 + La/2*sin(fi2);
  yF = y1 - La/2*cos(fi2);
  xG = x + La/2*sin(fi2);
  yG = y - La/2*cos(fi2); 
  xH = x - La/2*sin(fi2);
  yH = y + La/2*cos(fi2); 
  xcab  = [ xA; xB; xC; xD; xA ];
  ycab  = [ yA; yB; yC; yD; yA ]; 
  xtrai = [ xE; xF; xG; xH; xE ];
  ytrai = [ yE; yF; yG; yH; yE ];  
  dfi1 = delta(k,1) + fi1 - pi/2;
  xT1 = xB - Lt/2*sin(dfi1); 
  yT1 = yB + Lt/2*cos(dfi1);
  xT2 = xB + Lt/2*sin(dfi1); 
  yT2 = yB - Lt/2*cos(dfi1);
  xT3 = xA - Lt/2*sin(dfi1); 
  yT3 = yA + Lt/2*cos(dfi1);
  xT4 = xA + Lt/2*sin(dfi1); 
  yT4 = yA - Lt/2*cos(dfi1); 
  xTB = [ xT1; xT2 ];
  yTB = [ yT1; yT2 ];
  xTA = [ xT3; xT4 ];
  yTA = [ yT3; yT4 ]; 
  plot(xct,yct,':');
  plot(xcab,ycab,'-b','Linewidth',2);
  plot(xtrai,ytrai,'-r','Linewidth',2);
     frame=getframe(gcf);
    writeVideo(writeObj, frame); 
  
%  plot(xTB,yTB,'-k','Linewidth',2);
%  plot(xTA,yTA,'-k','Linewidth',2); 
  pause(0.1);
  plot(xcab,ycab,'-w','Linewidth',2);
  plot(xtrai,ytrai,'-w','Linewidth',2);
 %  plot(xcab,ycab,'-w','Linewidth',2);
%  plot(xtrai,ytrai,'-w','Linewidth',2);
%  plot(xTB,yTB,'-w','Linewidth',2);
%  plot(xTA,yTA,'-w','Linewidth',2);   


  k = k + 1;  
end
close(writeObj);

plot(xcab,ycab,'-b','Linewidth',2);
plot(xtrai,ytrai,'-r','Linewidth',2);
%plot(xTB,yTB,'-k','Linewidth',2);
%plot(xTA,yTA,'-k','Linewidth',2);
xbox = [  0  80  80   0   0 ];
ybox = [-40 -40  40  40 -40 ];
plot(xbox,ybox,'-k');

