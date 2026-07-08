here = fileparts(mfilename('fullpath'));
files = {'E1_metrics.mat','E2_metrics.mat','E3_metrics.mat','E4_metrics.mat','E56_metrics.mat'};
for i=1:numel(files)
    f = fullfile(here,files{i});
    if exist(f,'file')
        fprintf('\n===== %s =====\n', files{i});
        S = load(f);
        fn = fieldnames(S);
        for j=1:numel(fn)
            val = S.(fn{j});
            if isnumeric(val) && numel(val)<=30
                fprintf('%s = ', fn{j}); fprintf('%.4g ', val(:)); fprintf('\n');
            end
        end
    end
end
