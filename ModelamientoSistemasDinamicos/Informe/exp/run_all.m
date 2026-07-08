% Driver maestro: ejecuta todos los experimentos y genera las figuras del informe.
clear; clc;
here = fileparts(mfilename('fullpath'));
addpath(here);
figdir = fullfile(here, '..', 'figs');
if ~exist(figdir,'dir'); mkdir(figdir); end

exps = {@() E1_static_motor(figdir), @() E2_dynamic_2v(figdir), ...
        @() E3_static_vs_dynamic(figdir), @() E4_linear_id(figdir), ...
        @() E56_arch(figdir)};
names = {'E1','E2','E3','E4','E56'};

for i=1:numel(exps)
    try
        tic; exps{i}(); fprintf('[%s] terminado en %.1f s\n', names{i}, toc);
    catch ME
        fprintf(2,'[%s] ERROR: %s\n', names{i}, ME.message);
        for j=1:numel(ME.stack)
            fprintf(2,'   en %s (linea %d)\n', ME.stack(j).name, ME.stack(j).line);
        end
    end
end
fprintf('\n==== run_all terminado ====\n');
