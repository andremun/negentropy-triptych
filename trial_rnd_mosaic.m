% -------------------------------------------------------------------------
% trial_rnd_mosaic.m
%
% SLURM array-job wrapper. Evaluates cost function type 4 (the "E0"
% edge-entropy baseline) on a 1000-layout slice of a pre-generated set of
% 1e6 random layouts. The array task ID selects the slice.
%
% Calls test_random_mosaics_clust. This repository does not include that
% function. See https://github.com/andremun/negentropy-triptych/issues/1
% for details.
%
% Reads ./autoart_1e6_cost/img_idx_1e6.mat and
% ./autoart_1e6_cost/result_gen_rand_mosaics_E0.mat. This repository
% does not include either file. Writes one
% ./autoart_1e6_cost/result_gen_rand_mosaics_TID<n>.mat file per task ID.
% -------------------------------------------------------------------------
tid = str2double(getenv('SLURM_ARRAY_TASK_ID'));
disp(['Trial number: ' num2str(tid)]);

a = 1:1000:1e6;
b = a(2)-1:1000:1e6;
range = a(tid):b(tid);

datadir = './autoart_1e6_cost/';
getfromfile = @(filename,varname) getfield(load(filename,varname),varname);

idx = getfromfile([datadir 'img_idx_1e6.mat'],'idx');
ntries = size(idx,2);
J = NaN.*ones(5,ntries);
J(4,:) = getfromfile([datadir 'result_gen_rand_mosaics_E0.mat'],'J');

Jaux = test_random_mosaics_clust(datadir,idx(:,range),J(:,range));
save([datadir 'result_gen_rand_mosaics_TID' num2str(tid) '.mat'],'Jaux');