% -------------------------------------------------------------------------
% autoart.m
%
% Runs a local search that arranges the 306 tile images into an 18x17
% mosaic layout, optimizing one of six visual order/disorder cost
% functions (see costGLOBAL in artworkfcn.m). Starts from the layout
% stored in data/poster_idx.mat and applies nswaps local search moves,
% keeping each move only when it improves the cost.
%
% Inputs:
%   nseed  - integer 1-100, selects one of 100 fixed random seeds
%   ftype  - cost function type, 1-6 (see README.md)
%   minmax - true to maximize the cost function, false to minimize it
%   nswaps - number of local search iterations
%
% Reads data/raw_image_data.mat (rebuilt from raw PNGs if missing; see
% README.md) and data/poster_idx.mat.
%
% Writes the final mosaic image to data/images/ and the layout, cost
% trace, and mutation-operator usage counts to data/autoresults/. Both
% folders must exist before this function runs; it does not create them.
% -------------------------------------------------------------------------
function autoart(nseed,ftype,minmax,nswaps)

global IMGTC IMGBIN IMGIND PRIM PATT Pr_PRIM I_PRIM fcntype data Hx

warning('off','images:initSize:adjustingMag');
artworkfcn;
datadir = './data/';
imagedir = [datadir 'images/'];
resultdir = [datadir 'autoresults/'];

fcntype = ftype;

I = getfromfile([datadir 'poster_idx.mat'],'idx');
I = I(:,3);
nfigs = length(I);
nimgrow = 18; % Number of images per row
nimgcol = 17; % Number of images per col
nrowfig = 520; % Number of rows per image
ncolfig = 590; % Number of cols per image
Nrow = nimgrow*nrowfig; % Number of rows in the final figure
Ncol = nimgcol*ncolfig; % Number of cols in the final figure
X = reshape(I,nimgrow,nimgcol);
J = NaN.*ones(nswaps,1);
noptypes = 7;
nops = zeros(noptypes,1);
neffops = nops;

if exist([datadir 'raw_image_data.mat'],'file')==2
    IMGTC = getfromfile([datadir 'raw_image_data.mat'],'IMGTC');
    IMGIND = getfromfile([datadir 'raw_image_data.mat'],'IMGIND');
    IMGBIN = getfromfile([datadir 'raw_image_data.mat'],'IMGBIN');
    PRIM = getfromfile([datadir 'raw_image_data.mat'],'PRIM');
    PATT = getfromfile([datadir 'raw_image_data.mat'],'PATT');
    Pr_PRIM = getfromfile([datadir 'raw_image_data.mat'],'Pr_PRIM');
    I_PRIM = getfromfile([datadir 'raw_image_data.mat'],'I_PRIM');
else
    rawimgdir = 'C:\Users\mariom1\OneDrive - The University of Melbourne\Documents\Research Files\Posters\NewBBOBInstances\';
    [IMGTC,IMGIND,IMGBIN,PRIM,PATT,Pr_PRIM,I_PRIM] = genRawData(rawimgdir);
    save([datadir 'raw_image_data.mat'],'IMGTC','IMGIND','IMGBIN','PRIM','PATT','Pr_PRIM','I_PRIM');
end

etime_exp = tic;
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

rng('default');
rseeds = randi(100,100,1);
rng(rseeds(nseed));

J(1) = costGLOBAL(X);
for ii=2:nswaps
    tic;
    selop = randi(noptypes);
    nops(selop) = nops(selop) + 1;
    switch selop
        case 1
            [X,J(ii)] = mutationrndswap(X,J(ii-1),minmax);
        case 2
            [X,J(ii)] = mutationlswap(X,J(ii-1),minmax);
        case 3
            [X,J(ii)] = mutationrswap(X,J(ii-1),minmax);
        case 4
            [X,J(ii)] = mutationtswap(X,J(ii-1),minmax);
        case 5
            [X,J(ii)] = mutationbswap(X,J(ii-1),minmax);
        case 6
            [X,J(ii)] = mutationfliplr(X,J(ii-1),minmax);
        case 7
            [X,J(ii)] = mutationflipud(X,J(ii-1),minmax);
    end
    
    if (minmax && (J(ii)>J(ii-1))) || (~minmax && (J(ii)<J(ii-1)))
        neffops(selop) = neffops(selop) + 1;
    end
        
    if mod(ii,1e1)==0
        disp(['-> Iteration No. ' num2str(ii) ...
              ' | Elapsed time: ' num2str(toc,'%.2f\n') ...
              ' | Cost Function value: ' num2str(J(ii))]);
    end
end

imshow(rendercolor(X));
print(gcf,'-dpng',[imagedir 'autoart_S' num2str(nseed) '_E' num2str(ftype) '_M' num2str(minmax) '.png']);
save([resultdir 'result_S' num2str(nseed) '_E' num2str(ftype) '_M' num2str(minmax) '.mat'],'IMGTC',...
     'IMGBIN','X','J','neffops','nops');

disp('-------------------------------------------------------------------------');
disp(['-> Total elapsed time: ' num2str(toc(etime_exp),'%.2f\n')]);
disp('-------------------------------------------------------------------------');

warning('on','images:initSize:adjustingMag');

end
