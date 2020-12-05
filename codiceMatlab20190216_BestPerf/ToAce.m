function ToAce()   
    %% Split Images into subImages and convert them with Stress
    sourcePath = uigetdir('.\..\Images','Select folder of Images to process');
%     sourcePath = splitImgsInDir(sourcePath, [512, 512, 50, 50]);
%     sourcePath = RheinardMacenko_ColorNormalization(sourcePath, 'R', 'Rheinard');
%     
%    sourcePath = fullfile(sourcePath,'subImages');
    fnS= [dir(fullfile(sourcePath, '*.tif')); ...
                dir(fullfile(sourcePath , '*.tiff')); ...
                dir(fullfile(sourcePath , '*.bmp')); ...
                dir(fullfile(sourcePath, '*.jpg')); ...
                dir(fullfile(sourcePath, '*.png')); ...
                dir(fullfile(sourcePath, '*.svs'));];
    
    gaussDev=0.5;
    aceDir = fullfile(sourcePath,'Ace');
    if ~exist(aceDir, 'dir'); mkdir(aceDir); end
    Race = 60;
%     sizeR3 = 30; % raggio stimato dalle immagini
    
    for nf = 1:numel(fnS)
        name = fnS(nf).name;
        info = parseName(name);
        I = imread(fullfile(sourcePath, name));
        I=I(:,:,1:3);
        IFilt = uint8(zeros(size(I)));
        for ch = 1: size(IFilt,3); IFilt(:,:,ch) = imgaussfilt(medfilt2(I(:,:,ch)), gaussDev); end
        if exist(fullfile(aceDir, [info.imgname '_R' num2str(Race) info.ext]), 'file')
            Iace=imread(aceDir, [info.imgname '_R' num2str(Race) info.ext]);
        else; Iace = ace(IFilt,Race,'E',[],'G',[], 'L'); 
            imwrite(Iace, fullfile(aceDir, [info.imgname '_R' num2str(Race) info.ext])); 
        end
        
         close all
    end
end