function E4_linear_id(figdir)
% E4: Identificacion de parametros de un sistema lineal (fiel a DynamicBPLinealmodel2.m).
% La red lineal de 1 capa aprende directamente las matrices A y B:
%   v_true = [A'; B'] = [0.6 0.3; 0.8 -0.1; 0 -0.2]
% Se comparan dos modos de entrenamiento:
%   - free-run  : x = out (lazo cerrado, como el script original -> output error)
%   - teacher   : x = estado medido (equation error, convexo para sist. lineal)
% Estudia convergencia, riqueza de la entrada e influencia del ruido.
fprintf('\n===== E4: Identificacion de sistema lineal =====\n');

Atrue = [0.6 0.8; 0.3 -0.1];
Btrue = [0; -0.2];
vtrue = [Atrue'; Btrue'];          % 3x2

% ---- E4a: convergencia: free-run vs teacher forcing (entrada rica) ----
u = gen_input();
z = plant_lin(u, Atrue, Btrue);
[eF, vF, vfinF] = train_linid(z, u, 0.02, 12000, 7, vtrue, false);  % free-run
[eT, vT, vfinT] = train_linid(z, u, 0.5, 12000, 7, vtrue, true);   % teacher
fprintf('  v (teacher):\n'); disp(vfinT);
fprintf('  err param  free-run=%.3e  teacher=%.3e\n', vF(end), vT(end));

figure('Visible','off','Position',[0 0 560 360]);
semilogy(vF,'LineWidth',1.3,'DisplayName','error de salida (lazo cerrado)'); hold on;
semilogy(vT,'LineWidth',1.3,'DisplayName','forzado con estado medido'); grid on;
xlabel('Iteracion'); ylabel('||v - v_{true}||_F');
legend('Location','northeast'); title('E4 - Convergencia de la identificacion lineal');
saveas(gcf, fullfile(figdir,'E4_conv.png')); close;

% ---- E4b: riqueza de la entrada (teacher forcing) ----
nu = 300; nt = (0:nu-1)';
inputs = struct();
inputs(1).name='Rica'; inputs(1).u=gen_input();
inputs(2).name='Escalon'; inputs(2).u=[zeros(20,1); ones(nu-20,1)];
inputs(3).name='Senoidal'; inputs(3).u=sin(2*pi*0.02*nt);
verrIn = zeros(1,3);
for i=1:3
    ui=inputs(i).u; zi=plant_lin(ui,Atrue,Btrue);
    [~,ve,~] = train_linid(zi, ui, 0.5, 12000, 7, vtrue, true);
    verrIn(i) = ve(end);
end
figure('Visible','off','Position',[0 0 560 360]);
bar(verrIn); grid on; set(gca,'XTickLabel',{inputs.name});
ylabel('||v - v_{true}||_F final'); title('E4 - Identificabilidad vs riqueza de la entrada');
set(gca,'YScale','log');
saveas(gcf, fullfile(figdir,'E4_richness.png')); close;
fprintf('  error param por entrada (teacher): '); fprintf('%.3e ',verrIn); fprintf('\n');

% ---- E4c: influencia del ruido de medicion (teacher forcing) ----
noises=[0 0.005 0.01 0.02 0.05 0.1];
verrN=zeros(size(noises));
for i=1:numel(noises)
    rng(300+i);
    zn = z + noises(i)*randn(size(z));
    [~,ve,~] = train_linid(zn, u, 0.5, 12000, 7, vtrue, true);
    verrN(i)=ve(end);
end
figure('Visible','off','Position',[0 0 560 360]);
plot(noises, verrN,'-o','LineWidth',1.3); grid on;
xlabel('Desv. del ruido de medicion \eta'); ylabel('||v - v_{true}||_F final');
title('E4 - Sesgo de los parametros identificados por ruido');
saveas(gcf, fullfile(figdir,'E4_noise.png')); close;
fprintf('  error param vs ruido (teacher): '); fprintf('%.3e ',verrN); fprintf('\n');

save(fullfile(figdir,'..','exp','E4_metrics.mat'), ...
    'vtrue','vfinT','vfinF','verrIn','noises','verrN');
fprintf('  E4 OK.\n');
end

% ============ auxiliares ============
function z = plant_lin(u, A, B)
nu=numel(u); z=zeros(nu+1,2); z(1,:)=[0 0];
for k=1:nu
    z(k+1,:) = (A*z(k,:)' + B*u(k))';
end
z=z(1:nu,:);
end

function [errhist, verr, v] = train_linid(z, u, eta, niter, seed, vtrue, tf)
% Red lineal de una capa: out = v'*[x;u], w=I fija. v contiene [A';B'].
%   tf=false: free-run (x=out) -> recursion de derivadas totales (output error)
%   tf=true : teacher forcing (x=estado medido) -> derivada instantanea (equation error)
rng(seed);
ndata=size(z,1); ns=2; ne=3;
v = 0.1*randn(ne,ns);
w = eye(ns);
outsum2total = sum(sum(z.^2));
errhist=zeros(niter,1); verr=zeros(niter,1);
for iter=1:niter
    ersum2=zeros(ns,1);
    dy1dv_t=zeros(ne,ns); dy2dv_t=zeros(ne,ns);
    dJdv_t=zeros(ne,ns);
    x=z(1,:)';
    for k=1:ndata-1
        if tf, x=z(k,:)'; end               % teacher forcing: estado medido
        in_red=[x; u(k)];
        out=v'*in_red;
        dndm=eye(ns);
        dy1dv_s=in_red*w(:,1)'*dndm;
        dy2dv_s=in_red*w(:,2)'*dndm;
        if tf
            dy1dv_t=dy1dv_s; dy2dv_t=dy2dv_s;   % sin recursion (x no depende de v)
        else
            jacob=w'*dndm*v(1:ne-1,:)';
            p1=dy1dv_t; p2=dy2dv_t;             % actualizacion simultanea (correcta)
            dy1dv_t = dy1dv_s + jacob(1,1).*p1 + jacob(1,2).*p2;
            dy2dv_t = dy2dv_s + jacob(2,1).*p1 + jacob(2,2).*p2;
        end
        er = out - z(k+1,:)';
        dJdv_t = dJdv_t + er(1).*dy1dv_t + er(2).*dy2dv_t;
        ersum2 = ersum2 + er.^2;
        if ~tf, x = out; end
    end
    v = v - eta*dJdv_t/ndata;
    errhist(iter)=sqrt(sum(ersum2)/outsum2total);
    verr(iter)=norm(v-vtrue,'fro');
end
end
