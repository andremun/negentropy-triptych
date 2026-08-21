% -------------------------------------------------------------------------
% downloadRawImages.m
%
% Downloads the 306 tile images from the figshare dataset in Munoz
% Acosta (2026), "Individual images without axes" [3], and saves them as
% PNG files in outdir. Called automatically by autoart.m the first time
% data/raw_image_data.mat is missing and data/raw_images/ is empty; can
% also be called directly to pre-populate that folder.
%
% Input:
%   outdir - destination folder (default: 'data/raw_images/')
%
% Uses the public figshare API (https://api.figshare.com/v2), which does
% not need an API key for a published, public article. Needs internet
% access and MATLAB's webread/websave (base MATLAB, no toolbox needed).
%
% This script could not be run inside the sandboxed environment that
% wrote it, since that environment blocks outbound requests to figshare.
% Test it once on a machine with normal internet access before relying
% on it.
% -------------------------------------------------------------------------
function downloadRawImages(outdir)

if nargin<1
    outdir = fullfile('data','raw_images');
end
if ~exist(outdir,'dir')
    mkdir(outdir);
end

articleId = 13082474;
apiurl = sprintf('https://api.figshare.com/v2/articles/%d/files',articleId);

disp('-------------------------------------------------------------------------');
disp(['-> Fetching file list for figshare article ' num2str(articleId)]);
filelist = webread(apiurl);

if isempty(filelist)
    error('downloadRawImages:noFiles', ...
        ['No files were returned for figshare article ' num2str(articleId) ...
         '. Check https://doi.org/10.6084/m9.figshare.13082474 by hand.']);
end

nfiles = numel(filelist);
for ii=1:nfiles
    f = filelist(ii);
    outfile = fullfile(outdir,f.name);
    if exist(outfile,'file')
        continue;
    end
    disp(['-> Downloading ' f.name ' (' num2str(ii) '/' num2str(nfiles) ')']);
    websave(outfile,f.download_url);
end

% If the dataset ships as one or more archives, unpack them here.
archives = [dir(fullfile(outdir,'*.zip')); dir(fullfile(outdir,'*.tar.gz'))];
for ii=1:numel(archives)
    archivefile = fullfile(outdir,archives(ii).name);
    disp(['-> Extracting ' archives(ii).name]);
    if endsWith(archivefile,'.zip')
        unzip(archivefile,outdir);
    else
        untar(archivefile,outdir);
    end
end

npng = numel(dir(fullfile(outdir,'*.png')));
disp('-------------------------------------------------------------------------');
disp(['-> Done. ' num2str(npng) ' PNG file(s) in ' outdir]);
disp('-------------------------------------------------------------------------');

end
