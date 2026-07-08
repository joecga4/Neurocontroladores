function z = plant_nl2(u, z0)
% Sistema no lineal 1 entrada / 2 estados (fiel a DynamicBPModelamiento2v.m):
%   z1(k+1) = 0.3 z1 - 0.4 z2
%   z2(k+1) = 0.4 z2 + 0.1 z1 u + 0.5 u    (termino bilineal z1*u)
nu = numel(u);
z1 = zeros(nu+1,1); z2 = zeros(nu+1,1);
z1(1) = z0(1); z2(1) = z0(2);
for k=1:nu
    z1(k+1) = 0.3*z1(k) - 0.4*z2(k);
    z2(k+1) = 0.4*z2(k) + 0.1*z1(k)*u(k) + 0.5*u(k);
end
z = [z1(1:nu) z2(1:nu)];
end
