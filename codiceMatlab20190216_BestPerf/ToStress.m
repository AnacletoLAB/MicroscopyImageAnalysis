function ToStress()   
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
    StressDir = fullfile(sourcePath,'Stress');
    if ~exist(StressDir, 'dir'); mkdir(StressDir); end
    sizeR =Inf;
    sizeR2 = 30;
    sizeR3 = 5;
    
%     sizeR2 = 20;
%     sizeR3 = 30; % raggio stimato dalle immagini
    
    for nf = 1:numel(fnS)
        name = fnS(nf).name;
        info = parseName(name);
        I = imread(fullfile(sourcePath, name));
        I=I(:,:,1:3);
        IFilt = uint8(zeros(size(I)));
        for ch = 1: size(IFilt,3); IFilt(:,:,ch) = imgaussfilt(medfilt2(I(:,:,ch)), gaussDev); end
%         if exist(fullfile(resDir, [info.imgname 'ACE' info.ext]), 'file')
%             Iace=imread(fullfile(resDir, [info.imgname 'ACE' info.ext]));
%         else; Iace = ace(IFilt,maxRad*2,'E',[],'G',[], 'L'); 
%             imwrite(Iace, fullfile(resDir, [info.imgname 'ACE' info.ext])); 
%         end
         if ~exist(fullfile(StressDir, [info.imgname '_R' num2str(sizeR) info.ext]), 'file') 
             [IStress,~,~]=rsr_stress(IFilt, 128, 8, sizeR);
             imwrite(IStress, fullfile(StressDir, [info.imgname '_R' num2str(sizeR) info.ext])); 
         end
         if ~exist(fullfile(StressDir, [info.imgname '_R' num2str(sizeR2) info.ext]), 'file') 
             [IStress,~,~]=rsr_stress(IFilt, 128, 8, sizeR2);
             imwrite(IStress, fullfile(StressDir, [info.imgname '_R' num2str(sizeR2) info.ext])); 
         end
         if ~exist(fullfile(StressDir, [info.imgname '_R' num2str(sizeR3) info.ext]), 'file') 
             [IStress,~,~]=rsr_stress(IFilt, 128, 8, sizeR3);
             imwrite(IStress, fullfile(StressDir, [info.imgname '_R' num2str(sizeR3) info.ext])); 
         end
         close all
    end
end