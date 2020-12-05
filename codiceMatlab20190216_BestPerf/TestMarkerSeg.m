function TestMarkerSeg()
   
    %% Load Source & Target images
    sourcePath = uigetdir('.\..\Images','Select folder of Images to process');
%     sourcePath = RheinardMacenko_ColorNormalization(sourcePath, 'R', 'Rheinard');
%     sourcePath = splitImgsInDir(sourcePath, [512, 512, 50, 50]);
    
    fnS= [dir(fullfile(sourcePath, '*.tif')); ...
                dir(fullfile(sourcePath , '*.tiff')); ...
                dir(fullfile(sourcePath , '*.bmp')); ...
                dir(fullfile(sourcePath, '*.jpg')); ...
                dir(fullfile(sourcePath, '*.png')); ...
                dir(fullfile(sourcePath, '*.svs'));];
    
%     for i=1: 15 %numel(fnS)
%        colorConstancy(sourcePath, fnS(i).name, 'ace', []) 
%     end
    gaussDev=0.5; conn=4;
    resDir = fullfile(sourcePath,'Results');
    if ~exist(resDir, 'dir'); mkdir(resDir); end
    StressDir = fullfile(sourcePath,'Stress');
    if ~exist(StressDir, 'dir'); mkdir(StressDir); end
    R=Inf; thrArea=3; thrStress=100;
    twoClass=load(fullfile(sourcePath, 'DataColor_3Class', 'MdlKNN_2Class.mat'), 'MdlKNN2');
    threeClass=load(fullfile(sourcePath, 'DataColor_3Class', 'MdlTree_3Class.mat'), 'MdlTree3');

    for nf = numel(fnS):-1:1
        name = fnS(nf).name;
        info = parseName(name);
        I = imread(fullfile(sourcePath, name));
        I=I(:,:,1:3);
        sz = size(I);
        IFilt = uint8(zeros(size(I)));
        for ch = 1: size(IFilt,3); IFilt(:,:,ch) = imgaussfilt(medfilt2(I(:,:,ch)), gaussDev); end

        if exist(fullfile(StressDir, [info.imgname '_R' num2str(R) info.ext]), 'file')
             IStress=imread(fullfile(StressDir, [info.imgname '_R' num2str(R) info.ext]));
        else 
             [IStress,~,~]=rsr_stress(IFilt, 128, 8, double(R));
             imwrite(IStress, fullfile(StressDir, [info.imgname '_R' num2str(R) info.ext])); 
        end
        for ch=1:size(IStress,3); IStress(:,:,ch) = imgaussfilt(medfilt2(IStress(:,:,ch)), gaussDev); end
        
        cells = bwareaopen(rgb2gray(IStress)<=thrStress, thrArea ,conn);
        IHSV = rgb2hsv(IFilt);
        imgFeat = cat(3, IFilt(:,:,1),IFilt(:,:,3),IHSV(:,:,1));
        [Y,X] = find(cells);
        
        feats = computePtsVals([X,Y], imgFeat);
        clear X Y;
        
        RedBlue2 = zeros(size(cells)); 
        RedBlue2(cells) = predict(twoClass.MdlKNN2, double(feats));
        RedBlue2(cells) = RedBlue2(cells) .* predict(threeClass.MdlTree3, double(feats));
        
        red = (RedBlue2==1); 
        blue = (RedBlue2==2);
        blue = ~red & blue;
  
        % salva Res  su img
        ImgS = IFilt;
        ImgS(cat(3,bwperim(red),bwperim(red), bwperim(red))) = max(ImgS(:)); 
        ImgS(cat(3,bwperim(blue),bwperim(blue), bwperim(blue))) = min(ImgS(:)); 
        imwrite(ImgS,fullfile(resDir, [info.imgname info.ext]));
        clear ImgS;
        
        ImgS = IStress;
        ImgS(cat(3,bwperim(red),bwperim(red), bwperim(red))) = max(ImgS(:)); 
        ImgS(cat(3,bwperim(blue),bwperim(blue), bwperim(blue))) = min(ImgS(:)); 
        imwrite(ImgS,fullfile(resDir, [info.imgname '_stress' info.ext]));
        
        clear ImgS;
        close all;
        
    end
end