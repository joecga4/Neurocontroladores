here=fileparts(mfilename('fullpath'));
files={'C1_metrics.mat','C2_metrics.mat','C3_metrics.mat','C4_metrics.mat'};
for i=1:numel(files)
    f=fullfile(here,files{i});
    if exist(f,'file')
        fprintf('\n===== %s =====\n',files{i}); S=load(f); fn=fieldnames(S);
        for j=1:numel(fn)
            v=S.(fn{j});
            if isnumeric(v)&&numel(v)<=30, fprintf('%s = ',fn{j}); fprintf('%.4g ',v(:)); fprintf('\n'); end
        end
    end
end
