% Driver maestro de los experimentos de REDES ESTATICAS. Genera todas las figuras.
clear; clc;
here=fileparts(mfilename('fullpath')); addpath(here);
figdir=fullfile(here,'..','figs'); if ~exist(figdir,'dir'), mkdir(figdir); end
exps={@() RA_line(figdir), @() RB_cubic(figdir), @() RC_scaling(figdir), @() RD_mimo(figdir)};
names={'RA','RB','RC','RD'};
for i=1:numel(exps)
    try, tic; exps{i}(); fprintf('[%s] terminado en %.1f s\n',names{i},toc);
    catch ME
        fprintf(2,'[%s] ERROR: %s\n',names{i},ME.message);
        for j=1:numel(ME.stack), fprintf(2,'  en %s (linea %d)\n',ME.stack(j).name,ME.stack(j).line); end
    end
end
fprintf('\n==== run_all (redes) terminado ====\n');
