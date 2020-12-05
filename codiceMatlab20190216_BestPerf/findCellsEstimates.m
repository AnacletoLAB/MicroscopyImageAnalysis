function findCellsEstimates()
   
    %% Load Source & Target images
    sourcePath = uigetdir('.\..\Images','Select folder of Images to process');
 %   sourcePath = RheinardMacenko_ColorNormalization(sourcePath, 'R', 'Rheinard');
%     sourcePath = 'C:\DATI\ace\Images\nuove\Rheinard';
%    offset = 50
%     sourcePath = splitImgsInDir(sourcePath, [256, 256, offset, offset]);
    
    fnS= [dir(fullfile(sourcePath, '*.tif')); ...
                dir(fullfile(sourcePath , '*.tiff')); ...
                dir(fullfile(sourcePath , '*.bmp')); ...
                dir(fullfile(sourcePath, '*.jpg')); ...
                dir(fullfile(sourcePath, '*.png')); ...
                dir(fullfile(sourcePath, '*.svs'));];
    
%     for i=1: 15 %numel(fnS)
%        colorConstancy(sourcePath, fnS(i).name, 'ace', []) 
%     end
    
   
    StressDir = fullfile(sourcePath,'Stress');
    if ~exist(StressDir, 'dir'); mkdir(StressDir); end
    
    twoClass=load(fullfile(sourcePath, 'DataColor_3Class', 'MdlKNN_2Class.mat'), 'MdlKNN2');
  %  threeClass=load(fullfile(sourcePath, 'DataColor_3Class', 'MdlTree_3Class.mat'), 'MdlTree3');
  %  stressClass=load(fullfile(sourcePath, 'DataColor_3ClassStress', 'MdlTree_3Class.mat'), 'MdlTree3');
    %% prendo il nome di una immagine per estrarre i dati dei colori da analizzare
    name = fnS(1).name;
    info = parseName(name);
    names(1).name = [info.patName '_' info.markerNames '_' info.markerColors];
    names(1).ext = info.ext;
    names(1).numFette = [str2double(info.NumFetta)];
    
    for nf = 2:numel(fnS)
        name = fnS(nf).name;
        info = parseName(name);
        nameStr = [info.patName '_' info.markerNames '_' info.markerColors];
        i = 1;
        while i <= numel(names) 
            if ~strcmpi(names(i).name,nameStr); i = i+1;
            else; names(i).numFette = [names(i).numFette str2double(info.NumFetta)]; 
                break; end
        end
        if i > numel(names); names(i).name = nameStr; 
            names(i).numFette = []; names(i).ext = info.ext; end
    end
    for i=1:numel(names)
        names(i).numFette = sort(names(i).numFette);
    end
%     areas.maxArea=[];
%     areas.minArea=[];
%     areas.medianArea=[];
%     areas.maxRad=[];
%     areas.minRad=[];
%     areas.medianRad=[];
    
    thrArea = 4; 
    areas = [];
    for nC=1: numel(info.markerColor)
       load(fullfile(sourcePath, ['DataColor_' info.markerColor{nC}.Color], ...
           ['areas_' info.markerColor{nC}.Color '.mat']), 'allAreas');
       allAreas(allAreas<thrArea)=[];
       areas(nC).medianArea= round(median(allAreas));
       areas(nC).stdArea = std(allAreas);
       areas(nC).medianRad = floor(sqrt(areas(nC).medianArea/pi));
       areas(nC).maxArea = max(allAreas);
       areas(nC).maxRad = floor(sqrt(areas(nC).maxArea/pi));
       areas(nC).minArea = min(allAreas);
       areas(nC).minRad = floor(sqrt(areas(nC).minArea/pi)); 
       if areas(nC).minRad == 0; areas(nC).minRad = 1; end
    end  
    
    conn=4; 
    factorComp = 2; thrEcc = 0.9; thrEquivDiam = 0.25; 
    st3 = strel('disk',3); st1 = strel('disk',1);
    gaussDev = 0.5; medfltsz = 3;
    R = max(round(max( ...
        sqrt(([areas.medianArea]+3*[areas.stdArea])/pi), max([areas.maxRad])))); N = 128; M = 8; fRed = 0.5; % R=Inf 
    resDir = fullfile(sourcePath,['Results_' num2str(R)]);
    if ~exist(resDir, 'dir'); mkdir(resDir); end
    nameEstimate=fullfile(resDir, 'Estimations.txt');
    fidEst = fopen(nameEstimate,'w');
    strTitle=['Img Name' sprintf('\t') ...
                'Ki67PosArea' sprintf('\t') 'Ki67NegArea' sprintf('\t') '%Area' sprintf('\t') ...
                'Estimated #Ki67Pos' sprintf('\t') 'Estimated #Ki67Neg' sprintf('\t') '%Estimated' sprintf('\t') ];
    disp(strTitle);
    fprintf(fidEst, '%s\n',strTitle); clear strTitle;
    
    
    for nf = 1:numel(names)
      imgName = names(i).name;
      numFette = names(i).numFette;
      ext = names(i).ext;
      for nF = 1:numel(numFette)
        name = [imgName '_' num2str(numFette(nF)) ext];
        disp([num2str(nf) ')' name]);
        info = parseName(name);
        I = imread(fullfile(sourcePath, name));
        I=I(:,:,1:3);
        sz = size(I);
        IFilt = uint8(zeros(size(I)));
        for ch = 1: size(IFilt,3); IFilt(:,:,ch) = imgaussfilt(medfilt2(I(:,:,ch), [medfltsz medfltsz]), gaussDev); end
        [mask,~] = regTissue(IFilt,false, min(areas.minArea));
        
        if exist(fullfile(StressDir, [info.imgname '_R' num2str(R) info.ext]), 'file')
             IStress=imread(fullfile(StressDir, [info.imgname '_R' num2str(R) info.ext]));
             load(fullfile(StressDir, [info.imgname '_R' num2str(R) '.mat']));
        else
%              rescaled = imresize(IFilt, 0.5);
%              ISum = double(rescaled-rescaled);
%              for rr = min(areas.minRad):max(areas.maxRad)
%                  [IStress,~,~]=rsr_stress(rescaled, N, M, double(rr));
%                  ISum = ISum+double(IStress);
%              end
%              ISumUint8 = imresize(uint8(round(imscale(ISum)*255)),2);
             [IStress,~,~] = rsr_stress(imresize(IFilt,fRed), N, M, double(R)*fRed);
             IStress = imresize(IStress, 1/fRed);
             imwrite(IStress, fullfile(StressDir, [info.imgname '_R' num2str(R) info.ext])); 
             save(fullfile(StressDir, [info.imgname '_R' num2str(R) '.mat']), 'IStress');
        end
        
        for ch=1:size(IStress,3); IStress(:,:,ch) = imgaussfilt(medfilt2(IStress(:,:,ch)), gaussDev); end
        Ilog = []; IlogStress=[];
        iGray = rgb2gray(IFilt); iGrayStress = rgb2gray(IStress);
        for r = max(min(areas.minRad),1):round(max(areas.maxRad)*3)
            imgLog = r^2*imfilter(double(iGray), fspecial('log', round(r*1.5),r*3/2));
            Ilog = cat(3, Ilog, imgLog);
            IlogStress = cat(3,IlogStress, r^2*imfilter(double(iGrayStress), fspecial('log', round(r*1.5),r/2)));
            clear imgLog
        end
        
        IHSV = rgb2hsv(IFilt);
        imgFeat = cat(3, IFilt(:,:,1),IFilt(:,:,3),IHSV(:,:,1));
        cells = bwareaopen((sum(double(IStress),3)/3)<=225, min(areas.minArea),conn) & mask;
        [Y,X] = find(cells);
        
        feats = computePtsVals([X,Y], imgFeat);
        clear X Y;
        
        BrownBlue = zeros(size(cells)); 
        
        BrownBlue(cells)=predict(twoClass.MdlKNN2, double(feats));
        nC = 1;
        stMarker = strel('disk',round(areas(nC).minRad/2)); 
        brown = imclose(bwareaopen(BrownBlue==nC, min(areas.minArea),conn), st1);
        holes = imfill(brown, 'holes') & (~brown);
        brown = bwareaopen(imopen(brown | (holes & ~bwareaopen(holes, min(areas.medianArea),conn)),...
                        stMarker),areas(nC).minArea,conn); clear holes;
        nC = 2;
        stMarker = strel('disk',round(areas(nC).minRad/2)); 
        blue = ~brown & imclose(bwareaopen(BrownBlue==nC, min(areas.minArea),conn), st1);
        holes = imfill(blue, 'holes') & (~blue) & (~brown);
        blue = bwareaopen(imopen(blue | (holes & ~bwareaopen(holes, min(areas.medianArea),conn)),...
                            stMarker),areas(nC).minArea,conn); 
        clear holes;
        BrownBlue(:) = 0;
        BrownBlue(brown) = 1; BrownBlue(blue) = 2;
        PercAree = double(sum(BrownBlue(:)==1))/double(sum(BrownBlue(:)>0));
        fprintf(fidEst,'%s\t%g\t%g\t%g\t',name,sum(BrownBlue(:)==1),sum(BrownBlue(:)==2),PercAree);
        EstBrown = double(sum(BrownBlue(:)==1))/double(areas(1).medianArea);
        EstBlue = double(sum(BrownBlue(:)==2))/double(areas(2).medianArea);
        EstPerc = EstBrown/(EstBrown+EstBlue);
        fprintf(fidEst,'%g\t%g\t%g\n',EstBrown,EstBlue,EstPerc); 
        
        
        % salva Res  su img
        ImgS = I;
        regs1 = BrownBlue==1;
        regs1 = imclose(regs1,st1);
        regs2 = BrownBlue==2;
        regs2 = imclose(regs2,st1);
        ImgS(cat(3,bwperim(regs1 | regs2), bwperim(regs1 | regs2) , bwperim(regs1 | regs2))) = 0;
        ImgS(cat(3,bwperim(regs1), bwperim(regs1) , false(sz(1),sz(2)))) = max(ImgS(:)); 
        ImgS(cat(3,false(sz(1),sz(2)), bwperim(regs2) , false(sz(1),sz(2)))) = max(ImgS(:)); 
        imwrite(ImgS, fullfile(resDir, [info.imgname 'cellsOrig' info.ext]));
        
        ImgS = IStress; 
        ImgS(cat(3,bwperim(regs1 | regs2), bwperim(regs1 | regs2) , bwperim(regs1 | regs2))) = 0;
        ImgS(cat(3,bwperim(regs1), bwperim(regs1) , false(sz(1),sz(2)))) = max(ImgS(:)); 
        ImgS(cat(3,false(sz(1),sz(2)), bwperim(regs2) , false(sz(1),sz(2)))) = max(ImgS(:)); 
        imwrite(ImgS, fullfile(resDir, [info.imgname 'cellsStress_R' num2str(R) info.ext]));
     
            
        clear name EstBrown EstBlue EstPerc PercAree BrownBlue brown blue ImgS
    end
  end
end