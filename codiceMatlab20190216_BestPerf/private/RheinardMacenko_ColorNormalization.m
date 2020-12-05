function dirS = RheinardMacenko_ColorNormalization(sourcePath, method, dirS)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % A demonstration of the included Stain Normalisation methods.
    %
    %
    % Adnan Khan and Nicholas Trahearn
    % Department of Computer Science, 
    % University of Warwick, UK.
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Clear all previous data
    close all;
    addpath(genpath('.\private\stain_normalisation_toolbox')); 
    %% Load Source & Target images
    if nargin<2 || numel(method)==0 
        method=input('Rheinard Method (R) or Macenko (any other key)? ','s');
    end
    if nargin<1 || numel(sourcePath)==0
        sourcePath = uigetdir(cd(),'Select folder of Images to be normalized');
    end

    %% Display results of each method
    verbose = 0;
    if (nargin<3 || numel(dirS)<1)
        if strcmpi(method, 'R'); dirS='Reinhard';
        else; dirS='MacenkoNorm'; end
    end
    dirS = fullfile(sourcePath, dirS);
    if ~exist(dirS,'dir'); mkdir(dirS); end
            
    [fnT,targetPath] = uigetfile([sourcePath '\*.*'],'Select Target Image');
    targetImage = imread(fullfile(targetPath, fnT));
    targetImage = targetImage(:,:,1:3);
    fnS= [dir(fullfile(sourcePath, '*.tif'));dir(fullfile(sourcePath , '*.tiff'))
                dir(fullfile(sourcePath, '*.jpg'));
                dir(fullfile(sourcePath, '*.png'));
                dir(fullfile(sourcePath, '*.svs'));];
    
    for numI=1:numel(fnS)
        sourceName = fnS(numI,1).name;
        if strcmp(fnT,sourceName)
            ind=strfind(fnT,'.');
            nameT=fnT(1:ind-1);
            ext=fnT(ind:end);
            copyfile(fullfile(targetPath,fnT),fullfile(dirS,fnT));            
        else
            if ~exist(fullfile(dirS, sourceName), 'file')
                sourceImage = imread(fullfile(sourcePath,sourceName ));
                sourceImage = sourceImage(:,:,1:3);
                if strcmp(method, 'R')
                    %% Stain Normalisation using Reinhard Method
                    disp('Stain Normalisation using Reinhard''s Method');
                    [ NormImage ] = Norm( sourceImage, targetImage, 'Reinhard', verbose );             
                else
                    %% Stain Normalisation using Macenko's Method
                    disp('Stain Normalisation using Macenko''s Method');
                    [ NormImage ] = Norm(sourceImage, targetImage, 'Macenko', 255, 0.15, 1, verbose);
                end
                imwrite(NormImage, fullfile(dirS, sourceName));
                close all
            end
        end
    end

        %% End of Demo
    disp('End of Demo');
end