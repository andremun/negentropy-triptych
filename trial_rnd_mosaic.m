% -------------------------------------------------------------------------
% trial_rnd_mosaic.m
%
% SLURM array-job wrapper. Evaluates cost function type 4 (the "E0"
% edge-entropy baseline) on a 1000-layout slice of a pre-generated set of
% 1e6 random layouts. The array task ID selects the slice.
%
% Calls test_random_mosaics_clust.m, which is in this repository.
%
% Reads ./autoart_1e6_cost/img_idx_1e6.mat, which this repository does
% not include (see README.md), and
% ./autoart_1e6_cost/result_gen_rand_mosaics_E0.mat, which it does.
% Writes one ./autoart_1e6_cost/result_gen_rand_mosaics_TID<n>.mat file
% per task ID.
% -------------------------------------------------------------------------
%
% Copyright (c) 2026 Mario Andres Munoz Acosta
% The University of Melbourne
%
% Date: August 2026
%
% This software is licensed under the PolyForm Noncommercial License 1.0.0.
% You may use, copy, modify, and distribute this software for any
% non-commercial purpose. Commercial use is prohibited.
% Full license text: https://polyformproject.org/licenses/noncommercial/1.0.0
%
% Required Notice: Copyright (c) 2026 Mario Andres Munoz Acosta
%                  The University of Melbourne
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