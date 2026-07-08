function u = carnet(net, inscale, xerr, pherr)
% Salida del neurocontrolador del carro. Entradas: error de x y de orientacion
% (esta ultima ENVUELTA a (-pi,pi]) y NORMALIZADA por inscale, igual que en
% el entrenamiento (DynamicBPCarro.m).
in = [ xerr ; mod(pherr + pi, 2*pi) - pi ] ./ inscale;
m  = net.v'*in;
n  = 2.0./(1 + exp(-(m - net.c)./net.a)) - 1;
u  = net.w'*n;
end
