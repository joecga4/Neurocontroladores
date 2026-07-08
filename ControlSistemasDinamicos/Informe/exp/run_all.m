% Driver maestro de los experimentos de CONTROL. Genera todas las figuras.
clear; clc;
here=fileparts(mfilename('fullpath')); addpath(here);
figdir=fullfile(here,'..','figs'); if ~exist(figdir,'dir'), mkdir(figdir); end
exps={@() C1_static_reg(figdir), @() C2_robust_dist(figdir), ...
      @() C3_static_vs_dyn(figdir), @() C4_dyn_partial_noise(figdir)};
names={'C1','C2','C3','C4'};
for i=1:numel(exps)
    try, tic; exps{i}(); fprintf('[%s] terminado en %.1f s\n',names{i},toc);
    catch ME
        fprintf(2,'[%s] ERROR: %s\n',names{i},ME.message);
        for j=1:numel(ME.stack), fprintf(2,'  en %s (linea %d)\n',ME.stack(j).name,ME.stack(j).line); end
    end
end
fprintf('\n==== run_all (control) terminado ====\n');
