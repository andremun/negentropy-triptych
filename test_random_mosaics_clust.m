% -------------------------------------------------------------------------
% test_random_mosaics_clust.m
%
% Evaluates cost function type 4 (edge joint entropy) on a slice of
% pre-generated random layouts. trial_rnd_mosaic.m calls this function
% for the 1e6-layout random-mosaic baseline experiment (see README.md).
%
% This function has its own copies of costGLOBAL, costEDGE, costLOCAL,
% and renderbimg. It does not call artworkfcn.m. Its costGLOBAL only
% ever runs case 4, since the outer loop fixes fcntype to 4. Cases 1, 2,
% and 3, and the "otherwise" branch, exist in the code but never run.
%
% Inputs:
%   datadir - folder holding imagedata.mat, the 306 tile images in
%             binary form (same content as data/raw_image_data.mat in
%             this repository, under the historical flat filename this
%             function expects)
%   idx     - matrix of layouts, one 306-element layout per column
%   J       - vector of cost values to fill in. This function leaves an
%             entry already set (not NaN) unchanged, and skips it
%
% Output:
%   J - the input vector, with a value for every entry that was still
%       NaN
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
function J = test_random_mosaics_clust(datadir,idx,J)

warning('off','images:initSize:adjustingMag');

global IMGBIN fcntype data

getfromfile = @(filename,varname) getfield(load(filename,varname),varname);

[nfigs,ntries] = size(idx);
nrowfig = 520; % Number of rows per image
ncolfig = 590; % Number of cols per image
nimgrow = 18; % Number of images per row
nimgcol = 17; % Number of images per col
Nrow = nimgrow*nrowfig; % Number of rows in the final figure
Ncol = nimgcol*ncolfig; % Number of cols in the final figure

IMGBIN = getfromfile([datadir 'imagedata.mat'],'IMGBIN');

etime_exp = tic;
for fcntype=4
    if fcntype==1
        [X1,X2] = meshgrid(1:Ncol,1:Nrow);
        data = [X1(:) X2(:) zeros(numel(X1),1)]./[Ncol Nrow 1]; % Coordinates of each point
    elseif fcntype==2
        [X1,X2] = meshgrid(1:Ncol-1,1:Nrow-1);
        data = [X1(:) X2(:) zeros(numel(X1),1)]./[Ncol-1 Nrow-1 1]; % Coordinates of each point
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

    for ii=1:ntries
        tic;
        if ~isnan(J(ii))
            continue;
        end
        J(ii) = costGLOBAL(reshape(idx(:,ii),nimgrow,nimgcol));
        if mod(ii,1e1)==0
            disp(['-> Function Type ' num2str(fcntype) ...
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
% -------------------------------------------------------------------------
% Cost function dispatcher local to this file. The global fcntype
% selects the measure. Only case 4 ever runs (see the file header).
% -------------------------------------------------------------------------
function J = costGLOBAL(X)

global fcntype data

BW = renderbimg(X);
init = round(rand)+1;
switch fcntype
    case 1
        % Mutual information of the axes vs intensity.
        data(:,3) = double(BW(:));
        J = -kdpee(data(init:2:end,:)); % Minimizes the entropy to maximize order
    case 2
        % Entropy on the differences.
        DBWhv = diff(diff(BW,1,1),1,2);
        data(:,3) = DBWhv(:);
        J = -kdpee(data(init:2:end,:)); % Minimizes the entropy
    case 3
        % Maximize the joint entropies for disorder.
        [nrows,ncols] = size(X);
        J = 0.*X;
        for ii=1:nrows
            for jj=1:ncols
                aux = NaN.*ones(4,1);
                if jj>1 % The element has a left neighbor
                    aux(1) = data(X(ii,jj), X(ii,jj-1));
                end
                if jj<ncols % The image has a right neighbor
                    aux(2) = data(X(ii,jj), X(ii,jj+1));
                end
                if ii>1 % The element has a top neighbor
                    aux(3) = data(X(ii,jj), X(ii-1,jj));
                end
                if ii<nrows % The image has a bottom neighbor
                    aux(4) = data(X(ii,jj), X(ii+1,jj));
                end
                J(ii,jj) = nanmean(aux);
            end
        end
        J = nanmean(J(:));
    case 4
        % Minimize the edge joint entropies for order.
        [nrows,ncols] = size(X);
        J = 0.*X;
        for ii=1:nrows
            for jj=1:ncols
                aux = NaN.*ones(4,1);
                if jj>1 % The element has a left neighbor
                    aux(1) = data(X(ii,jj-1), X(ii,jj), 2);
                end
                if jj<ncols % The image has a right neighbor
                    aux(2) = data(X(ii,jj), X(ii,jj+1), 2);
                end
                if ii>1 % The element has a top neighbor
                    aux(3) = data(X(ii-1,jj), X(ii,jj), 1);
                end
                if ii<nrows % The image has a bottom neighbor
                    aux(4) = data(X(ii,jj), X(ii+1,jj), 1);
                end
                J(ii,jj) = nanmean(aux);
            end
        end
        J = -nanmean(J(:));
    otherwise
        % Connected area.
        props = regionprops('table',bwareafilt(BW,1),'Area');
        J = props.Area./93880800; % Maximizes the connected area
end

end
% -------------------------------------------------------------------------
% Computes the joint entropy between the touching edge of tile A and
% tile B. Rotates both tiles 90 degrees first if dorot.
% -------------------------------------------------------------------------
function J = costEDGE(A,B,dorot)

global IMGBIN

% Assumes A is on the left and B is on the right. You could generalize
% this for top and bottom with a flag.
V_A = IMGBIN(:,:,A); % This is the figure on the left
V_B = IMGBIN(:,:,B); % This is the figure on the right
if dorot
    V_A = rot90(V_A);
    V_B = rot90(V_B);
end
P = zeros(1,4);
P(1) = mean(~V_A(end,:) & ~V_B(1,:));
P(2) = mean(~V_A(end,:) &  V_B(1,:));
P(3) = mean( V_A(end,:) & ~V_B(1,:));
P(4) = mean( V_A(end,:) &  V_B(1,:));
P = P.*(log(P)./log(4));
P(isnan(P)) = 0;
J = -sum(P);

end
% -------------------------------------------------------------------------
% Computes the joint entropy between all foreground pixels of tile A and
% tile B.
% -------------------------------------------------------------------------
function J = costLOCAL(A,B)

global IMGBIN

V_A = IMGBIN(:,:,A); % This is the figure on the left
V_B = IMGBIN(:,:,B); % This is the figure on the right
P = zeros(1,4);
P(1) = mean(~V_A(:) & ~V_B(:));
P(2) = mean(~V_A(:) &  V_B(:));
P(3) = mean( V_A(:) & ~V_B(:));
P(4) = mean( V_A(:) &  V_B(:));
P = P.*(log(P)./log(4));
P(isnan(P)) = 0;
J = -sum(P);

end
% -------------------------------------------------------------------------
% Renders layout X as an 18x17 binary mosaic image.
% -------------------------------------------------------------------------
function CIMG = renderbimg(X)

global IMGBIN

[row,col,nfigs] = size(IMGBIN);
X = X(:);
CIMG = false(18*row,17*col);
x1 = 1;
x2 = row;
y1 = 1;
y2 = col;
for jj=1:nfigs
    CIMG(x1:x2,y1:y2) = IMGBIN(:,:,X(jj));
    x1 = x2+1;
    x2 = x2+row;
    if x1>(18*row)
        x1 = 1;
        x2 = row;
        y1 = y2+1;
        y2 = y2+col;
    end
end

end
