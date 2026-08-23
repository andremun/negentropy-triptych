% -------------------------------------------------------------------------
% randart.m
%
% Evaluates cost function type 6 (primitive pattern match) on a set of
% pre-generated random layouts. collectResultsPaper.m uses these values
% as the random baseline. It compares this baseline against the
% optimized layouts from autoart.m.
%
% Inputs:
%   idx - matrix of layouts, one 306-element layout per column
%   J   - matrix of cost values to fill in. randart leaves an entry
%         already set (not NaN) unchanged, and skips it
%
% Output:
%   J - the input matrix. Row 6 now holds a value for every column that
%       was still NaN
%
% Reads data/raw_image_data.mat.
% -------------------------------------------------------------------------
function J = randart(idx,J)

global IMGBIN IMGIND PRIM PATT Pr_PRIM I_PRIM fcntype data Hx

disp('-------------------------------------------------------------------------');
disp('-> Initializing ');
datadir = './data/';

warning('off','images:initSize:adjustingMag');
artworkfcn;

[nfigs,ntries] = size(idx);
nrowfig = 520; % Number of rows per image
ncolfig = 590; % Number of cols per image
nimgrow = 18; % Number of images per row
nimgcol = 17; % Number of images per col
Nrow = nimgrow*nrowfig; % Number of rows in the final figure
Ncol = nimgcol*ncolfig; % Number of cols in the final figure

disp('-------------------------------------------------------------------------');
disp('-> Loading Image Data');
IMGBIN = getfromfile([datadir 'raw_image_data.mat'],'IMGBIN');
IMGIND = getfromfile([datadir 'raw_image_data.mat'],'IMGIND');
PRIM = getfromfile([datadir 'raw_image_data.mat'],'PRIM');
PATT = getfromfile([datadir 'raw_image_data.mat'],'PATT');
Pr_PRIM = getfromfile([datadir 'raw_image_data.mat'],'Pr_PRIM');
I_PRIM = getfromfile([datadir 'raw_image_data.mat'],'I_PRIM');

etime_exp = tic;
for fcntype=6
    disp('-------------------------------------------------------------------------');
    disp(['-> Cost Function Type: ' num2str(fcntype)]);
    disp('-------------------------------------------------------------------------');
    disp( '-> Loading the necessary data.');
    if (fcntype==1) || (fcntype==2) 
        [X1,X2] = meshgrid(1:Ncol,1:Nrow);
        data = [X1(:) X2(:) zeros(numel(X1),1)]./[Ncol Nrow 1]; % Coordinates of each point
        Hx = kdpee(data(1:2:end,1:2));
    elseif fcntype==3
        data = zeros(nfigs);
        for ii=1:nfigs
            for jj=ii+1:nfigs
                data(ii,jj) = costLOCAL(ii,jj);
            end
        end
        data = data + data';
    elseif fcntype==4
        data = zeros(nfigs,nfigs,2);
        for ii=1:nfigs
            for jj=1:nfigs
                data(ii,jj,1) = costEDGE(ii,jj,0);
                data(ii,jj,2) = costEDGE(ii,jj,1);
            end
        end
    end
    disp('-------------------------------------------------------------------------');
    disp('-> Completed. Starting random evaluations.');
    disp('-------------------------------------------------------------------------');
    for ii=1:ntries
        tic;
        if ~isnan(J(fcntype,ii))
            continue;
        end
        J(fcntype,ii) = costGLOBAL(reshape(idx(:,ii),nimgrow,nimgcol));
        if mod(ii,1e1)==0
            disp(['  -> Function Type ' num2str(fcntype) ...
                  ' | Iteration No. ' num2str(ii) ...
                  ' | Elapsed time: ' num2str(toc,'%.2f\n')]);
        end
    end
    
end

disp('-------------------------------------------------------------------------');
disp(['-> Total elapsed time: ' num2str(toc(etime_exp),'%.2f\n')]);
disp('-------------------------------------------------------------------------');

warning('on','images:initSize:adjustingMag');

end
