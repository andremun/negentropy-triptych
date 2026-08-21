% -------------------------------------------------------------------------
% trial_autoart.m
%
% SLURM array-job wrapper around autoart.m. Reads the array task ID from
% SLURM_ARRAY_TASK_ID and maps it to one (seed, cost function type,
% minmax) combination, covering all 10 seeds x 3 cost function types x 2
% search directions (60 combinations total).
%
% Run one job per task ID, for example: sbatch --array=1-60 <job script>
% that calls this script.
% -------------------------------------------------------------------------
tid = getenv('SLURM_ARRAY_TASK_ID');
disp(['Trial number: ' tid]);
[XX,YY,ZZ] = meshgrid(1:10,[2 5 6],[0 1]);
iid = [XX(:) YY(:) ZZ(:)];
tid = str2double(tid);
nseed = iid(tid,1);
ftype = iid(tid,2);
minmax = iid(tid,2)==1; % NOTE: always false, since ftype is 2, 5, or 6;
                        % this looks like it should read iid(tid,3)==1
                        % (the search-direction column). See README.md,
                        % "Known limitations".
nswaps = 1e4;
autoart(nseed,ftype,minmax,nswaps);