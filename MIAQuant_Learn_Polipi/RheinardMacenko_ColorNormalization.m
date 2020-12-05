function RheinardMacenko_ColorNormalization

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
     clc, clear all, close all;
    addpath(genpath('.\stain_normalisation_toolbox')); 
    %% Display results of each method
    verbose = 0;
    %% Load Source & Target images
    sourcePath = uigetdir(cd(),'Select folder of Images to be normalized');
    RheinardDir = 'RheinardNorm';
    if ~exist(fullfile(sourcePath, RheinardDir),'dir'); mkdir(fullfile(sourcePath, RheinardDir)); end
%     MacenkoDir = 'MacenkoNorm';
%     if ~exist(fullfile(sourcePath, MacenkoDir),'dir'); mkdir(fullfile(sourcePath, MacenkoDir)); end
%     
    [fnT,targetPath] = uigetfile('C:\DATI\Elab_Imgs_Mediche\MIA\immagini_MIA\*.*','Select Target Image');
    targetImage = imread(fullfile(targetPath, fnT));
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
            copyfile(fullfile(targetPath,fnT),fullfile(sourcePath, RheinardDir,fnT)); 
            movefile(fullfile(sourcePath,RheinardDir,fnT), fullfile(sourcePath,RheinardDir,[nameT, '_TARGET' ext])); 
           
%             copyfile(fullfile(targetPath,fnT),fullfile(sourcePath,MacenkoDir,fnT)); 
%             movefile(fullfile(sourcePath,MacenkoDir,fnT), fullfile(sourcePath,MacenkoDir,[nameT, '_TARGET' ext]));
        else
            sourceImage = imread(fullfile(sourcePath,sourceName ));
        %% Stain Normalisation using Reinhard Method
            disp('Stain Normalisation using Reinhard''s Method');
            [ NormRH ] = Norm( sourceImage, targetImage, 'Reinhard', verbose );
            imwrite(NormRH, fullfile(sourcePath, RheinardDir, sourceName));
            

            %% Stain Normalisation using Macenko's Method
%             disp('Stain Normalisation using Macenko''s Method');
%             [ NormMM ] = Norm(sourceImage, targetImage, 'Macenko', 255, 0.15, 1, verbose);
%             imwrite(NormMM, fullfile(sourcePath, MacenkoDir, sourceName));
%             close all

        end
    end

        %% End of Demo
    disp('End of Demo');
end