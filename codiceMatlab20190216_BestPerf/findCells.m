function findCells()
   
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
    factorComp = 2; thrEcc = 0.9; thrEquivDiam = 0.3; factorMinArea=1; 
    val = min(areas(nC).medianArea+areas(nC).stdArea, ...
                mean([areas(nC).medianArea,areas(nC).maxArea]));
    factorMaxArea = val/areas(nC).maxArea;
    st3 = strel('disk',3); st1 = strel('disk',1);
    gaussDev = 0.5; medfltsz = 3;
    R = max(round(max( ...
        sqrt(([areas.medianArea]+3*[areas.stdArea])/pi), max([areas.maxRad])))); N = 128; M = 8; fRed = 0.5; % R=Inf 
    resDir = fullfile(sourcePath,['Results_' num2str(R)]);
    if ~exist(resDir, 'dir'); mkdir(resDir);  end
   
    
    nameCellQuant=fullfile(resDir, 'Quantifications.txt');
    fid = fopen(nameCellQuant,'w');
    strTitle=['Img Name' sprintf('\t') ...
                'Segmented #Ki67Pos' sprintf('\t') 'Segmented #Ki67Neg' sprintf('\t') '%Segmented' sprintf('\t')...
                'MixSegmented #Ki67Pos' sprintf('\t') 'Mix #Ki67Neg' sprintf('\t') '%Mix' sprintf('\t') ...
                'MaxOk #Ki67Pos' sprintf('\t') 'MaxOk #Ki67Neg' sprintf('\t') '%MaxOk'];
    disp(strTitle);
    fprintf(fid, '%s\n',strTitle); clear strTitle;
    
    for nf = 1:numel(names)
      imgName = names(i).name;
      numFette = names(i).numFette;
      ext = names(i).ext;
      for nF = 1:numel(numFette)
        %nf = randi(numel(fnS));
        %nf = 4100;
        numCells = zeros(1,numel(areas));
        numCellsFido = zeros(1,numel(areas));
        numCellsMix = zeros(1,numel(areas));
        
        name = [imgName '_' num2str(numFette(nF)) ext];
        str = [name sprintf('\t')];
        strMix = sprintf('\t');
        strFido = sprintf('\t');
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
             [IStress,~,~] = rsr_stress(imresize(IFilt,fRed), N, M, double(R)*fRed);
             IStress = imresize(IStress, 1/fRed);
             imwrite(IStress, fullfile(StressDir, [info.imgname '_R' num2str(R) info.ext])); 
             save(fullfile(StressDir, [info.imgname '_R' num2str(R) '.mat']), 'IStress');
        end
        
        for ch=1:size(IStress,3); IStress(:,:,ch) = imgaussfilt(medfilt2(IStress(:,:,ch)), gaussDev); end
        Ilog = []; IlogStress=[];
        iGray = rgb2gray(IFilt); iGrayStress = rgb2gray(IStress);
        for r = max(min(areas.minRad),1):round(max(areas.maxRad)*3)
            imgLog = imfilter(double(iGray), fspecial('log', round(r),r),'replicate');
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
        BrownBlue(cells)=predict(twoClass.MdlKNN2, double(feats)); clear feats;
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
        
        figOrig = figure('Name',name,'Position',[0 0 size(IFilt,2)*3  size(IFilt,1)]); 
        subplot(1,4,1); imshow(I);
        
        ImgS = IStress; 
        ImgS(cat(3,bwperim(regs1 | regs2), bwperim(regs1 | regs2) , bwperim(regs1 | regs2))) = 0;
        ImgS(cat(3,bwperim(regs1), bwperim(regs1) , false(sz(1),sz(2)))) = max(ImgS(:)); 
        ImgS(cat(3,false(sz(1),sz(2)), bwperim(regs2) , false(sz(1),sz(2)))) = max(ImgS(:)); 
        imwrite(ImgS, fullfile(resDir, [info.imgname 'cellsStress_R' num2str(R) info.ext]));
        
        IS0 = I;
        clear bin ImgS;

        for nC = 1: numel(info.markerColor) 
            cells = BrownBlue == nC;
            okNew = zeros(size(cells));           
            [cells, okNew] = analizeRegs(cells, okNew, areas(nC), factorComp, thrEcc, ...
                                    thrEquivDiam, factorMinArea,factorMaxArea);   
            ok = zeros(size(cells));
            for radius = size(Ilog,3):-1:1
                rStress = Ilog(:,:,radius);
                thrData = smooth(rStress(cells));
                th = prctile(thrData,35);
                regs = imfill(bwareaopen(imopen(rStress>th & ...
                                cells,st1), areas(nC).minArea, conn),'holes');
                regs = imfill(regs,'holes');                           
                cells(okNew>0) = 0;
                ok = ok  + double(regs);
                clear res regs th thrData
            end
            ok = uint8(round(255*(ok-min(ok(:)))/(max(ok(:))-min(ok(:)))));

 %          Innanzi tutto considero tutte le regioni che si formano
 %          sogliando ok a zero (ovvero le regioni che sono state toccate
 %          almeno una volta dalla operazione multiscala
            altreRegs=imopen(ok>0,st1);
            [~, okNew] = analizeRegs(altreRegs, okNew, areas(nC), factorComp, thrEcc, ...
                                    thrEquivDiam, factorMinArea,factorMaxArea);          
            % butto via le parti di regione sui bordi delle regioni già
            % prese
            cells = cells & ~(okNew>0);
%         
            % in ok lascio solo le cose da analizzare
            % Procedo con procedo con sogliature successive su ok
            % e tengo le zone circolari
            [cells, okNew] = analizeAttachedRegs(cells, okNew, areas(nC), factorComp, thrEcc, ...
                                     thrEquivDiam, factorMinArea,factorMaxArea); 
            ok(~cells | okNew>0) = 0;
            labs = bwlabel(cells, conn);
            for nR =1:max(labs(:))
                RR = (labs == nR);
                for prctNow = 25: +15 :85
                    nTH =  prctile(ok(RR),prctNow);
                    regs = imfill(bwareaopen(ok>=nTH & RR,areas(nC).minArea,conn),'holes');
                    NotRegs = RR & ~regs & ~(okNew>0);
                    if any(regs(:))
                        [~, okNew] = analizeRegs(regs, okNew, areas(nC), factorComp, thrEcc, ...
                                        0.3, factorMinArea,factorMaxArea);
                        cells(okNew>0) = false;
                        [~, okNew] = analizeRegs(NotRegs, okNew, areas(nC), factorComp, thrEcc, ...
                                        0.3, factorMinArea,factorMaxArea);
                        cells(okNew>0) = false;
                        [cells, okNew] = analizeAttachedRegs(cells, okNew, areas(nC), factorComp, ...
                                 thrEcc,0.3,factorMinArea,factorMaxArea); 

                        % magari salvo qualcosa in cells perchè ora si
                                % è staccato qualcosa
                        [cells, okNew] = analizeRegs(cells, okNew, areas(nC), factorComp, thrEcc, ...
                                        thrEquivDiam, factorMinArea,factorMaxArea);    
                        ok(~cells | okNew>0) = 0;
                    end
                end
                clear RR;
            end
            clear labs;

            % siccome il passo sopra butta qualcosa, magari stacca dei
            % nuclei che analizzo
            [cells, okNew] = analizeRegs(cells, okNew, areas(nC), factorComp, thrEcc, ...
                                    thrEquivDiam, factorMinArea,factorMaxArea);             

            % se qualcos è ancora rimasto per dividere cluster attaccati
            % applico stress solo in quelle regioni e soglio!
            if any(cells(:))
                labs = bwlabel(cells, conn);
                stats = regionprops(bwconncomp(cells,conn),'Image');
                for nR =1:max(labs(:))
                    RR = (labs == nR);
                    distI = bwdist(bwskel(stats(nR).Image));
                    medR = median(distI(bwperim(stats(nR).Image)));
                    minR = min(distI(bwperim(stats(nR).Image)));
                    for fRadius = medR:-1:minR 
                        rrStress = rgb2gray(...
                            masked_stress(IFilt,64,8,fRadius,RR));
                        for prctNow = 85:-10:15                            
                            nTH =  prctile(rrStress(RR(:)),prctNow);    
                            regs = imfill(imopen(rrStress<=nTH & RR,st1),'holes');
                            
                            if any(regs(:))
                                [~, okNew] = analizeRegsSimple(regs, okNew, areas(nC));
                                cells(okNew>0) = false;
                                RR(imdilate(okNew>0,st3)) = false;
                                RR = bwareaopen(RR, areas(nC).minArea, conn);
                            end
                        end
                        
                    end
                    [cells, okNew] = analizeAttachedRegs(cells, okNew, areas(nC), factorComp, ...
                                                thrEcc,thrEquivDiam,factorMinArea,factorMaxArea);   
                          
                    clear RR;
                end  
                clear labs;
            end

            estNo = round(double(sum(uint8(cells(:))))/areas(nC).medianArea);
            numCellsMix(nC) = numel(unique(okNew(:)))-1 + estNo;
            strMix = [strMix num2str(numCellsMix(nC)) sprintf('\t')];
            
            
            estNo = round(double(sum(uint8(cells(:))))/areas(nC).medianArea);
            cells = imdilate(bwulterode(cells), strel('disk', round(areas(nC).minRad)));
            estNo = min(max(max(bwlabel(cells))), estNo);

           
            centsImg = false(size(IFilt,1),size(IFilt,2));
            okSave= zeros(size(okNew));
            nRNew = 1;
            for nR = min(okNew(okNew>0)):max(okNew(okNew>0))
                rr = bwareaopen(imopen(imclose(okNew==nR,st1),st1),areas(nC).minRad);
                if any(rr(:))
                     okSave(rr)=nRNew; nRNew = nRNew+1;
                     cents = bwulterode(rr);
                     centsImg(cents) = true;
                else; disp(['reg no: ' num2str(nR) ' not existent']); end
            end
            %regioni che sono più vicine di minRad le unisco
            centsImg = imerode(bwdist(centsImg)<=max([areas(nC).minRad-3,round(areas(nC).minRad/2)+2]), strel('disk',round(areas(nC).minRad/2))) ;
           % centsImg = centsImg | bwperim(cells);
            IS0(cat(3, centsImg, centsImg, centsImg)) = 0;
            if nC==1
                IS0(cat(3, centsImg, centsImg, false(size(okNew)))) = 255;
            else
                IS0(cat(3, centsImg, false(size(okNew)), false(size(okNew)))) = 255;
            end
            
          %  IS0(cat(3, ~(okNew>0 | cells), ~(okNew>0 | cells), ~(okNew>0 | cells)))=0;
            
            set(0,'CurrentFigure',figOrig);
            subplot(1,4,nC+2); imshow(IS0);
           
            imwrite(IS0, fullfile(resDir, [info.imgname '_img' info.markerColor{nC}.Color info.ext])); 
            clear IS;
            save(fullfile(resDir, [info.imgname '_' info.markerColor{nC}.Color '.mat']),'okNew','cells');
            
            disp([info.imgname ':about' num2str(estNo) ' cells still attached']);
            numCells(nC) = max(okSave(:)) + estNo;
            numCellsFido(nC) = max(okNew(:)) + estNo;
            
            str = [str num2str(numCells(nC)) sprintf('\t')];
            strFido = [strFido num2str(numCellsFido(nC)) sprintf('\t')];
            clear ok1 okNew;
        end
        perc = double(numCells(1))/double(sum(numCells));
        str = [str num2str(perc)];
        percFido = double(numCellsFido(1))/double(sum(numCellsFido));
        strFido = [strFido  num2str(percFido)];
        percMix = double(numCellsMix(1))/double(sum(numCellsMix));
        strMix = [strMix num2str(percMix)];
        
        fprintf(fid, '%s%s%s\n',str,strMix,strFido);
        clear str;
        set(0,'CurrentFigure',figOrig);
        subplot(1,4,2); imshow(IS0); 
        saveas(figOrig, fullfile(resDir, [info.imgname info.ext]));
        close all;
    end
  end
end