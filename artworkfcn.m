% -------------------------------------------------------------------------
% artworkfcn.m
%
% Defines the helper functions shared by autoart.m, randart.m, and
% collectResultsPaper.m, and injects them into the caller workspace with
% assignin. Each script that uses these functions must call artworkfcn;
% once, before calling any of them.
% -------------------------------------------------------------------------
function artworkfcn

getfromfile = @(filename,varname) getfield(load(filename,varname),varname);

assignin('caller','genRawData',@genRawData);
assignin('caller','getfromfile',getfromfile);
assignin('caller','costGLOBAL',@costGLOBAL);
assignin('caller','costEDGE',@costEDGE);
assignin('caller','costLOCAL',@costLOCAL);
assignin('caller','rendercolor',@rendercolor);
assignin('caller','renderindexed',@renderindexed);
assignin('caller','renderbinary',@renderbinary);
assignin('caller','mutationrndswap',@mutationrndswap);
assignin('caller','mutationlswap',@mutationlswap);
assignin('caller','mutationrswap',@mutationrswap);
assignin('caller','mutationtswap',@mutationtswap);
assignin('caller','mutationbswap',@mutationbswap);
assignin('caller','mutationflipud',@mutationflipud);
assignin('caller','mutationfliplr',@mutationfliplr);

end
% -------------------------------------------------------------------------
% Reads the 306 raw tile PNGs from rawimgdir, builds the 26 binary
% primitive masks, and builds the table of 2x2 primitive patterns.
% -------------------------------------------------------------------------
function [IMGTC,IMGIND,IMGBIN,PRIM,PATT,Pr_PRIM,I_PRIM] = genRawData(rawimgdir)

nfigs = 306;
nrowfig = 520; % Number of rows per image
ncolfig = 590; % Number of cols per image
nprim = 26;
filelist = struct2cell(dir([rawimgdir '*.png']))';
filelist = filelist(:,1);

IMGTC = zeros(nrowfig,ncolfig,3,nfigs,'uint8');
IMGIND = zeros(nrowfig,ncolfig,nfigs,'uint16');
IMGBIN = false(nrowfig,ncolfig,nfigs);
for ii=1:nfigs
    aux = imread([rawimgdir filelist{ii}]);
    IMGTC(:,:,:,ii) = aux(51:570,101:690,:);
    IMGIND(:,:,ii) = rgb2ind(IMGTC(:,:,:,ii),parula(2^16),'nodither');
    IMGBIN(:,:,ii) = IMGIND<=1e4;
end
m = ncolfig/nrowfig;
b1 = 100;
b2 = -100;
[YY,XX] = meshgrid(1:ncolfig,1:nrowfig);
PRIM = false(nrowfig,ncolfig,nprim);                                                % PRIM1 (ALL BLACK)
PRIM(:,:,2) = true;                                                        % PRIM2 (ALL WHITE)
PRIM(:,:,3) = ((m.*XX)+b1)>=YY & ((m.*XX)+b2)<=YY;                         % PRIM3 (DESCEND DIAG)
PRIM(:,:,4) = flipud(PRIM(:,:,3));                                        % PRIM4 (ASCEND DIAG)
PRIM(:,:,5) = PRIM(:,:,3) | PRIM(:,:,4);                                 % PRIM5 (CROSS)
PRIM(:,:,6) = PRIM(:,:,5) & ((m.*XX)+b1)>=YY & fliplr(((m.*XX)+b1)>=YY);  % PRIM6 (UP CORNER)
PRIM(:,:,7) = flipud(PRIM(:,:,6));                                        % PRIM7 (DOWN CORNER)
PRIM(:,:,8) = PRIM(:,:,5) & ((m.*XX)+b1)>=YY & flipud(((m.*XX)+b1)>=YY);  % PRIM8 (LEFT CORNER)
PRIM(:,:,9) = fliplr(PRIM(:,:,8));                                        % PRIM9 (RIGHT CORNER)
PRIM(:,:,10) = XX<=round(nrowfig/2);                                          % PRIM10 (UP WHITE)
PRIM(:,:,11) = ~PRIM(:,:,10);                                             % PRIM11 (DOWN WHITE)
PRIM(:,:,12) = YY<=round(ncolfig/2);                                          % PRIM12 (LEFT WHITE)
PRIM(:,:,13) = ~PRIM(:,:,12);                                             % PRIM13 (RIGHT WHITE)
PRIM(:,:,14) = PRIM(:,:,10) & PRIM(:,:,12);
PRIM(:,:,15) = fliplr(PRIM(:,:,14));
PRIM(:,:,16) = flipud(PRIM(:,:,15));
PRIM(:,:,17) = fliplr(PRIM(:,:,16));
PRIM(:,:,18) = PRIM(:,:,14) | PRIM(:,:,16);
PRIM(:,:,19) = fliplr(PRIM(:,:,18));
PRIM(:,:,20) = m*XX>=YY;
PRIM(:,:,21) = fliplr(PRIM(:,:,20));
PRIM(:,:,22) = flipud(PRIM(:,:,21));
PRIM(:,:,23) = fliplr(PRIM(:,:,22));
PRIM(:,:,24) = XX>=round(nrowfig/2 - 50) & XX<=round(nrowfig/2 + 50);
PRIM(:,:,25) = YY>=round(ncolfig/2 - 50) & YY<=round(ncolfig/2 + 50);
PRIM(:,:,26) = PRIM(:,:,24) | PRIM(:,:,25);

Pr = zeros(nfigs,nprim);
for ii=1:nfigs
    for jj=1:nprim
        Pr(ii,jj) = mean(mean(IMGBIN(:,:,ii)==PRIM(:,:,jj)));
    end
end
[Pr_PRIM,I_PRIM] = max(Pr,[],2); % Probability that a given tile looks like a PRIM

PATT = [     1     4     4     1;
             1     4     5     1;
             1     4     7     1;
             1     4     9     1;
             1     5     4     1;
             1     6     4     1;
             1     8     4     1;
             1    21    21     2;
             1    25    24    26;
             2    23    23     1;
             3     1     1     3;
             3     1     1     5;
             3     1     1     7;
             3     1     1     8;
             3     4     4     3;
             4     3     3     4;
             5     1     1     3;
             6     1     1     3;
             9     1     1     3;
            20     1     2    20;
            22     2     1    22;
            24    26     1    25;
            25     1    26    24;
            26    24    25     1];

PATT = reshape(PATT',[2 2 size(PATT,1)]);
PATT = permute(PATT,[2 1 3]);

end
% -------------------------------------------------------------------------
% Cost function dispatcher. Computes one of six order/disorder measures
% for the layout X, selected by the global fcntype (1-6, see README.md).
% -------------------------------------------------------------------------
function J = costGLOBAL(X)

global Pr_PRIM I_PRIM PATT fcntype data Hx

switch fcntype
    case 1
        IND = double(renderindexed(X))./(2.^16-1);
        % Mutual information of the axes vs intensity
        data(:,3) = IND(:);
        J = Hx + kdpee(data(1:2:end,3)) - kdpee(data(1:2:end,:));
    case 2
        % Mutual information of the axes vs difference on intensity
        % WORKS ON THE THREE FRAMES
        L = del2(double(renderindexed(X))./(2.^16-1));
        data(:,3) = L(:);
        J = Hx + kdpee(data(1:2:end,3)) - kdpee(data(1:2:end,:));
    case 3
        % Maximize the joint entropies for disorder
        [nrows,ncols] = size(X);
        J = 0.*X;
        for ii=1:nrows
            for jj=1:ncols
                aux = NaN.*ones(4,1);
                if jj>1 % The element has a left neighboor
                    aux(1) = data(X(ii,jj), X(ii,jj-1));
                end
                if jj<ncols % The image has a right neighboor
                    aux(2) = data(X(ii,jj), X(ii,jj+1));
                end
                if ii>1 % The element has a top neighboor
                    aux(3) = data(X(ii,jj), X(ii-1,jj));
                end
                if ii<nrows % The image has a bottom neighboor
                    aux(4) = data(X(ii,jj), X(ii+1,jj));
                end
                J(ii,jj) = nanmean(aux);
            end
        end
        J = nanmean(J(:));
    case 4
        % Minimize the edge joint entropies for order
        [nrows,ncols] = size(X);
        J = 0.*X;
        for ii=1:nrows
            for jj=1:ncols
                aux = NaN.*ones(4,1);
                if jj>1 % The element has a left neighboor
                    aux(1) = data(X(ii,jj-1), X(ii,jj), 2);
                end
                if jj<ncols % The image has a right neighboor
                    aux(2) = data(X(ii,jj), X(ii,jj+1), 2);
                end
                if ii>1 % The element has a top neighboor
                    aux(3) = data(X(ii-1,jj), X(ii,jj), 1);
                end
                if ii<nrows % The image has a bottom neighboor
                    aux(4) = data(X(ii,jj), X(ii+1,jj), 1);
                end
                J(ii,jj) = nanmean(aux);
            end
        end
        J = nanmean(J(:));
    case 5
        % Connected area
        % ORIGINAL AND DISORDERED ALMOST THE SAME
        BW = renderbinary(X,true);
        props = regionprops('table',bwareafilt(BW,1),'Area');
        J = props.Area./numel(BW); % We maximize the connected area
    case 6
        [nrows,ncols] = size(X);
        Pr_mosaic = Pr_PRIM(X);
        mosaic = I_PRIM(X);
        npatt = size(PATT,3);

        Pr_pt = zeros(nrows-1,ncols-1,npatt);
        for ii=1:nrows-1
            for jj=1:ncols-1
                for kk=1:npatt
                    cost = Pr_mosaic(ii:ii+1,jj:jj+1).*(mosaic(ii:ii+1,jj:jj+1)==PATT(:,:,kk));
                    Pr_pt(ii,jj,kk) = mean(cost(:));
                end
            end
        end

        Pr_patt = max(Pr_pt,[],3);
        J = mean(Pr_patt(:));
end

end
% -------------------------------------------------------------------------
% Joint entropy between the touching edge of tile A and tile B, used by
% cost function type 4. Rotates both tiles 90 degrees first if dorot.
% -------------------------------------------------------------------------
function J = costEDGE(A,B,dorot)

global IMGBIN

% Always assume that A is on the left and B on the right. This can be
% generalized for top and bottom with a flag
V_A = IMGBIN(:,:,A); % This is the figure in the left
V_B = IMGBIN(:,:,B); % This is the figure in the right
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
% Joint entropy between all foreground pixels of tile A and tile B, used
% by cost function type 3.
% -------------------------------------------------------------------------
function J = costLOCAL(A,B)

global IMGBIN 

V_A = IMGBIN(:,:,A); % This is the figure in the left
V_B = IMGBIN(:,:,B); % This is the figure in the right
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
% Renders layout X as an 18x17 true-color mosaic image.
% -------------------------------------------------------------------------
function CIMG = rendercolor(X)

global IMGTC

[row,col,~,nfigs] = size(IMGTC);
X = X(:);
CIMG = zeros(18*row,17*col,3,'uint8');
x1 = 1;
x2 = row;
y1 = 1;
y2 = col;
for jj=1:nfigs
    CIMG(x1:x2,y1:y2,:) = IMGTC(:,:,:,X(jj));
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
% -------------------------------------------------------------------------
% Renders layout X as an 18x17 indexed-color mosaic image.
% -------------------------------------------------------------------------
function CIMG = renderindexed(X)

global IMGIND

[row,col,nfigs] = size(IMGIND);
X = X(:);
CIMG = zeros(18*row,17*col,'uint16');
x1 = 1;
x2 = row;
y1 = 1;
y2 = col;
for jj=1:nfigs
    CIMG(x1:x2,y1:y2,:) = IMGIND(:,:,X(jj));
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
% -------------------------------------------------------------------------
% Renders layout X as an 18x17 binary mosaic image: the tile foreground
% masks if flag is true, or the matching primitive masks if flag is
% false.
% -------------------------------------------------------------------------
function CIMG = renderbinary(X,flag)

global IMGBIN PRIM

nfigs = numel(X);
if flag
    [row,col] = size(IMGBIN(:,:,1));
else
    [row,col] = size(PRIM(:,:,1));
end
X = X(:);
CIMG = false(18*row,17*col);
x1 = 1;
x2 = row;
y1 = 1;
y2 = col;
for jj=1:nfigs
    if flag
        CIMG(x1:x2,y1:y2) = IMGBIN(:,:,X(jj));
    else
        CIMG(x1:x2,y1:y2) = PRIM(:,:,X(jj));
    end
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
% -------------------------------------------------------------------------
% Local search move: swaps two randomly chosen tiles. Keeps the swap only
% if it improves the cost.
% -------------------------------------------------------------------------
function [X,J] = mutationrndswap(X,J,minmax)

[nrows, ncols] = size(X);
nfigs = max(X(:));
A = zeros(2,1);
B = zeros(2,1);
[A(1), A(2)] = ind2sub([nrows, ncols], randi(nfigs));
[B(1), B(2)] = ind2sub([nrows, ncols], randi(nfigs));

X_S = X;
aux = X(A(1),A(2));
X_S(A(1),A(2)) = X_S(B(1),B(2));
X_S(B(1),B(2)) = aux;
Jnew = costGLOBAL(X_S);

if (minmax && (Jnew>J)) || (~minmax && (Jnew<J))
    X = X_S;
    J = Jnew;
end

end
% -------------------------------------------------------------------------
% Local search move: swaps a randomly chosen tile with its left neighbor.
% Keeps the swap only if it improves the cost.
% -------------------------------------------------------------------------
function [X,J] = mutationlswap(X,J,minmax)

[nrows, ncols] = size(X);
nfigs = max(X(:));
[row, col] = ind2sub([nrows, ncols], randi(nfigs));
C = [row col  ];
L = [row col-1];

aux = X(C(1),C(2));
if col>1 % The element has a left neighboor
    X_L = X;
    X_L(C(1),C(2)) = X_L(L(1),L(2));
    X_L(L(1),L(2)) = aux;
    Jnew = costGLOBAL(X_L); % Global result of changing left
elseif minmax
    Jnew = -Inf;
else
    Jnew =  Inf;
end

if (minmax && (Jnew>J)) || (~minmax && (Jnew<J))
    X = X_L;
    J = Jnew;
end

end
% -------------------------------------------------------------------------
% Local search move: swaps a randomly chosen tile with its right
% neighbor. Keeps the swap only if it improves the cost.
% -------------------------------------------------------------------------
function [X,J] = mutationrswap(X,J,minmax)

[nrows, ncols] = size(X);
nfigs = max(X(:));
[row, col] = ind2sub([nrows, ncols], randi(nfigs));
C = [row col  ];
R = [row col+1];

aux = X(C(1),C(2));
if col<ncols % The image has a right neighboor
    X_R = X;
    X_R(C(1),C(2)) = X_R(R(1),R(2));
    X_R(R(1),R(2)) = aux;
    Jnew = costGLOBAL(X_R); % Global result of changing 
elseif minmax
    Jnew = -Inf;
else
    Jnew =  Inf;
end

if (minmax && (Jnew>J)) || (~minmax && (Jnew<J))
    X = X_R;
    J = Jnew;
end

end
% -------------------------------------------------------------------------
% Local search move: swaps a randomly chosen tile with its top neighbor.
% Keeps the swap only if it improves the cost.
% -------------------------------------------------------------------------
function [X,J] = mutationtswap(X,J,minmax)

[nrows, ncols] = size(X);
nfigs = max(X(:));
[row, col] = ind2sub([nrows, ncols], randi(nfigs));
C = [row col  ];
T = [row-1 col];

aux = X(C(1),C(2));
if row>1 % The element has a top neighboor
    X_T = X;
    X_T(C(1),C(2)) = X_T(T(1),T(2));
    X_T(T(1),T(2)) = aux;
    Jnew = costGLOBAL(X_T); % Global result of changing top
elseif minmax
    Jnew = -Inf;
else
    Jnew =  Inf;
end

if (minmax && (Jnew>J)) || (~minmax && (Jnew<J))
    X = X_T;
    J = Jnew;
end

end
% -------------------------------------------------------------------------
% Local search move: swaps a randomly chosen tile with its bottom
% neighbor. Keeps the swap only if it improves the cost.
% -------------------------------------------------------------------------
function [X,J] = mutationbswap(X,J,minmax)

[nrows, ncols] = size(X);
nfigs = max(X(:));
[row, col] = ind2sub([nrows, ncols], randi(nfigs));
C = [row col  ];
B = [row+1 col];

aux = X(C(1),C(2));
if row<nrows % The image has a bottom neighboor
    X_B = X;
    X_B(C(1),C(2)) = X_B(B(1),B(2));
    X_B(B(1),B(2)) = aux;
    Jnew = costGLOBAL(X_B); % Global result of changing bottom
elseif minmax
    Jnew = -Inf;
else
    Jnew =  Inf;
end

if (minmax && (Jnew>J)) || (~minmax && (Jnew<J))
    X = X_B;
    J = Jnew;
end

end
% -------------------------------------------------------------------------
% Local search move: flips a randomly chosen tile image upside down.
% Keeps the flip only if it improves the cost.
% -------------------------------------------------------------------------
function [X,J] = mutationflipud(X,J,minmax)

global IMGTC IMGBIN PRIM Pr_PRIM I_PRIM

[nrows, ncols] = size(X);
nfigs = max(X(:));
A = zeros(2,1);
[A(1), A(2)] = ind2sub([nrows, ncols], randi(nfigs));
aux = X(A(1), A(2));
IMGBIN(:,:,aux) = flipud(IMGBIN(:,:,aux));
nprim = size(PRIM,3);
Pr = zeros(1,nprim);
for jj=1:nprim
    Pr(jj) = mean(mean(IMGBIN(:,:,aux)==PRIM(:,:,jj)));
end
[Pr_PRIM(aux),I_PRIM(aux)] = max(Pr); % Probability that a given tile looks like a PRIM
Jnew = costGLOBAL(X);

if (minmax && (Jnew>J)) || (~minmax && (Jnew<J))
    for ii=1:3
        IMGTC(:,:,ii,aux) = flipud(IMGTC(:,:,ii,aux));
    end
else
    IMGBIN(:,:,aux) = flipud(IMGBIN(:,:,aux));
    for jj=1:nprim
        Pr(jj) = mean(mean(IMGBIN(:,:,aux)==PRIM(:,:,jj)));
    end
    [Pr_PRIM(aux),I_PRIM(aux)] = max(Pr,[],2); % Probability that a given tile looks like a PRIM
end

end
% -------------------------------------------------------------------------
% Local search move: flips a randomly chosen tile image left-right.
% Keeps the flip only if it improves the cost.
% -------------------------------------------------------------------------
function [X,J] = mutationfliplr(X,J,minmax)

global IMGTC IMGBIN PRIM Pr_PRIM I_PRIM

[nrows, ncols] = size(X);
nfigs = max(X(:));
A = zeros(2,1);
[A(1), A(2)] = ind2sub([nrows, ncols], randi(nfigs));
aux = X(A(1), A(2));
IMGBIN(:,:,aux) = fliplr(IMGBIN(:,:,aux));
nprim = size(PRIM,3);
Pr = zeros(1,nprim);
for jj=1:nprim
    Pr(jj) = mean(mean(IMGBIN(:,:,aux)==PRIM(:,:,jj)));
end
[Pr_PRIM(aux),I_PRIM(aux)] = max(Pr); % Probability that a given tile looks like a PRIM
Jnew = costGLOBAL(X);

if (minmax && (Jnew>J)) || (~minmax && (Jnew<J))
    for ii=1:3
        IMGTC(:,:,ii,aux) = fliplr(IMGTC(:,:,ii,aux));
    end
else
    IMGBIN(:,:,aux) = fliplr(IMGBIN(:,:,aux));
    for jj=1:nprim
        Pr(jj) = mean(mean(IMGBIN(:,:,aux)==PRIM(:,:,jj)));
    end
    [Pr_PRIM(aux),I_PRIM(aux)] = max(Pr); % Probability that a given tile looks like a PRIM
end

end