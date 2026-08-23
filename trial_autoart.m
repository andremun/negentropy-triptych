% -------------------------------------------------------------------------
% trial_autoart.m
%
% SLURM array-job wrapper around autoart.m. Reads the array task ID from
% SLURM_ARRAY_TASK_ID. Maps it to one (seed, cost function type, minmax)
% combination. The 60 combinations cover all 10 seeds, 3 cost function
% types, and 2 search directions.
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
minmax = iid(tid,3)==1;
nswaps = 1e4;
autoart(nseed,ftype,minmax,nswaps);