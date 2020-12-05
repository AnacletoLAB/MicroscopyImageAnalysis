function ApplyPilot()
   
    %% Load Source & Target images
    sourcePath = uigetdir('.\..\Images','Select folder of Images to process');
 %   sourcePath = RheinardMacenko_ColorNormalization(sourcePath, 'R', 'Rheinard');
 %   sourcePath = splitImgsInDir(sourcePath, [512, 512, 50, 50]);
    
    fnS= [dir(fullfile(sourcePath, '*.tif')); ...
                dir(fullfile(sourcePath , '*.tiff')); ...
                dir(fullfile(sourcePath , '*.bmp')); ...
                dir(fullfile(sourcePath, '*.jpg')); ...
                dir(fullfile(sourcePath, '*.png')); ...
                dir(fullfile(sourcePath, '*.svs'));];
    
%     for i=1: 15 %numel(fnS)
%        colorConstancy(sourcePath, fnS(i).name, 'ace', []) 
%     end
    n1 = 3;  conn=4; offset = 3;
    thrArea = 4;
    st3 = strel('disk',3); st2 = strel('disk',2); st1 = strel('disk',1);
    gaussDev=0.5;
    resDir = fullfile(sourcePath,'Results');
    if ~exist(resDir, 'dir'); mkdir(resDir); end
    StressDir = fullfile(sourcePath,'Stress');
    if ~exist(StressDir, 'dir'); mkdir(StressDir); end
    aceDir = fullfile(sourcePath,'Ace');
    if ~exist(aceDir, 'dir'); mkdir(aceDir); end
    origClass=load(fullfile(sourcePath, 'DataColor_3Class', 'MdlKNN_2Class.mat'), 'MdlKNN2');
  %  stressClass=load(fullfile(sourcePath, 'DataColor_3ClassStress', 'MdlTree_3Class.mat'), 'MdlTree3');
    %% prendo il nome di una immagine per estrarre i dati dei colori da analizzare
    name = fnS(1).name;
    info = parseName(name);
    areas.maxArea=[];
    areas.minArea=[];
    areas.medianArea=[];
    areas.maxRad=[];
    areas.minRad=[];
    areas.medianRad=[];
    for nC=1: numel(info.markerColor)
       load(fullfile(sourcePath, ['DataColor_' info.markerColor{nC}.Color], ...
           ['areas_' info.markerColor{nC}.Color '.mat']), 'allAreas');
       allAreas(allAreas<thrArea)=[];
       areas.medianArea(nC)= median(allAreas);
       areas.medianRad(nC) = floor(sqrt(areas.medianArea(nC)/pi));
       areas.maxArea(nC)=max(allAreas);
       areas.maxRad(nC) = floor(sqrt(areas.maxArea(nC)/pi));
       areas.minArea(nC)=min(allAreas);
       areas.minRad(nC) = floor(sqrt(areas.minArea(nC)/pi)); 
       if areas.minRad(nC) == 0; areas.minRad(nC) = 1;end
    end  
    R=Inf;
%    R = max(areas.maxRad); R=R*5;
%    Race = max(areas.maxRad)*2;
    for nf = 1:numel(fnS)
        name = fnS(nf).name;
        info = parseName(name);
        I = imread(fullfile(sourcePath, name));
        I=I(:,:,1:3);
        sz = size(I);
        IFilt = uint8(zeros(size(I)));
        for ch = 1: size(IFilt,3); IFilt(:,:,ch) = imgaussfilt(medfilt2(I(:,:,ch)), gaussDev); end
%         if exist(fullfile(aceDir, [info.imgname '_R' num2str(Race) info.ext]), 'file')
%             Iace=imread(fullfile(aceDir, [info.imgname '_R' num2str(Race) info.ext]));
%         else; Iace = ace(IFilt,Race,'E',[],'G',[], 'L'); 
%             imwrite(Iace, fullfile(aceDir, [info.imgname '_R' num2str(Race) info.ext])); 
%         end
         
         if exist(fullfile(StressDir, [info.imgname '_R' num2str(R) info.ext]), 'file')
             IStress=imread(fullfile(StressDir, [info.imgname '_R' num2str(R) info.ext]));
         else 
             [IStress,~,~]=rsr_stress(IFilt, 128, 8, double(R));
             imwrite(IStress, fullfile(StressDir, [info.imgname '_R' num2str(R) info.ext])); 
         end
         for ch=1:size(IStress,3); IStress(:,:,ch) = imgaussfilt(medfilt2(IStress(:,:,ch)), gaussDev); end
%         IMean1=imboxfilt(IStress,[n1 n1]);
%         IMean2=imboxfilt(IStress,[n1*2+1 n1*2+1]);
%         if mod(n1*3,2)==0; IMean3=imboxfilt(IStress,[n1*3+1 n1*3+1]);
%         else;  IMean3=imboxfilt(IStress,[n1*3 n1*3]); end
%         IMean4=imboxfilt(IStress,[n1*4+1 n1*4+1]);             
%         feats15 = double(cat(3, IFilt, IMean1, IMean2, IMean3, IMean4));
        %cells = reshape(predict(stressClass.MdlTree3, double(reshape(feats15,sz(1)*sz(2),15))), sz(1), sz(2));
        Ilog=[];
        iGray = rgb2gray(IFilt);
        for r=min(areas.minRad):max(areas.maxRad)
            imgLog = imfilter(double(iGray), fspecial('log', r*3,r/2));
%            imgLog = imgLog - min(imgLog(:)); imgLog = imgLog/max(imgLog(:));
%            Ilog = cat(3, Ilog, uint8(255*imgLog));
            Ilog = cat(3, Ilog, imgLog);
            clear imgLog
        end
        
        IHSV=rgb2hsv(IFilt);
        cells = zeros(size(IStress,1),size(IStress,2));
        cells = cells | bwareaopen((sum(double(IStress),3)/3)<=235, min(areas.minArea));
        
        [Y,X] = find(cells);
%         IMean1=imboxfilt(IFilt,[n1 n1]);
%         IMean2=imboxfilt(IFilt,[n1*2+1 n1*2+1]);
%         if mod(n1*3,2)==0; IMean3=imboxfilt(IFilt,[n1*3+1 n1*3+1]);
%         else;  IMean3=imboxfilt(IFilt,[n1*3 n1*3]); end
%         IMean4=imboxfilt(IFilt,[n1*4+1 n1*4+1]);             
%        feats = computePtsVals([X,Y],cat(3, IFilt, IMean1, IMean2, IMean3, IMean4));
        feats = computePtsVals([X,Y],cat(3, IFilt(:,:,1),IFilt(:,:,3),IHSV(:,:,1)));
        clear X Y;
        BrownBlue = zeros(size(cells)); 
        BrownBlue(cells)=predict(origClass.MdlKNN2, double(feats));
        
        brown = imclose(bwareaopen(BrownBlue==1, min(areas.minArea),conn), st1);
        holes = imfill(brown, 'holes') & (~brown);
        brown = bwareaopen(imopen(brown | (holes & ~bwareaopen(holes, min(areas.minArea))), st1),min(areas.minArea),conn); clear holes;
        blue = ~brown & imclose(bwareaopen(BrownBlue==2, min(areas.minArea),conn), st1);
        holes = imfill(blue, 'holes') & (~blue) & (~brown);
        blue = bwareaopen(imopen(blue | (holes & ~bwareaopen(holes, min(areas.minArea))),st1),min(areas.minArea),conn); 
        clear holes;
        BrownBlue(:) = 0;
        BrownBlue(brown) = 1; BrownBlue(blue) = 2;
        
        % salva Res  su img
        ImgS = I;
        ImgS(cat(3,bwperim(BrownBlue == 1), bwperim(BrownBlue == 1) , false(sz(1),sz(2)))) = max(ImgS(:)); 
        ImgS(cat(3,false(sz(1),sz(2)), bwperim(BrownBlue == 2) , false(sz(1),sz(2)))) = max(ImgS(:)); 
        figure; imshow(ImgS);
        imwrite(ImgS, fullfile(resDir, [info.imgname 'cellsImg' info.ext]));
        
        ImgS = IStress; 
        ImgS(cat(3,bwperim(BrownBlue == 1), bwperim(BrownBlue == 1) , false(sz(1),sz(2)))) = max(ImgS(:)); 
        ImgS(cat(3,false(sz(1),sz(2)), bwperim(BrownBlue == 2) , false(sz(1),sz(2)))) = max(ImgS(:)); 
        imwrite(ImgS, fullfile(resDir, [info.imgname 'cellsStress' info.ext]));
        clear bin ImgS;
        % 
        ok = false(sz(1),sz(2)); 
        for nC = 1: numel(info.markerColor)
            ok(:,:) = false; 
            medianArea = areas.medianArea(nC);
            medianRad = areas.medianRad(nC);
            maxArea = areas.maxArea(nC); 
            maxRad = areas.maxRad(nC);
            minArea = areas.minArea(nC); 
            minRad = areas.minRad(nC);
            cells = BrownBlue == nC;
            cc = bwconncomp(cells,conn); 
            labs = labelmatrix(cc);
            stats = regionprops(cc, 'Area','Eccentricity'); 
            % se sono grandi ma circolari le tengo
            idx = find(([stats.Area]<medianArea*1.15) | ...
                    ([stats.Area]< maxArea*1.15 & [stats.Area]>= maxArea &...
                                        [stats.Eccentricity] < 0.65) | ...
               ([stats.Area] < maxArea & [stats.Eccentricity] < 0.8)); 
            if numel(idx)>0 % le rimuovo da notOk e le metto in ok!
                okNew = bwlabel(ismember(labs, idx), conn); 
                cells = cells & ~(okNew>0);
            end
            clear cc idx stats labs
%             if exist(fullfile(StressDir, [info.imgname '_' info.markerColor{nC}.Color 'StressMask.mat']),'file')
%                 load(fullfile(StressDir, [info.imgname '_' info.markerColor{nC}.Color 'StressMask.mat']),'IStressMask');
%             else            
%                 IStressMask=masked_stress(IFilt,128,32,Inf,cells);
%                 save(fullfile(StressDir, [info.imgname '_' info.markerColor{nC}.Color 'StressMask.mat']),'IStressMask');
%                 imwrite(IStressMask, fullfile(StressDir,[info.imgname '_' info.markerColor{nC}.Color 'StressMask' info.ext])); 
%             end
            % estraggo tutte le regioni notOk e le oriento lungo il loro asse
            % maggiore; le salvo estraendo l'aspetto da IStress
            cc = bwconncomp(cells,conn); 
            labs = labelmatrix(cc);
            notOkDir = fullfile(sourcePath,'Results','notOk');
            if ~exist(notOkDir, 'dir'); mkdir(notOkDir); end
            stats = regionprops(cc, 'BoundingBox','Area'); 
            % sistemo le notOk
            ok = uint8(ok);
            for nR = 1:max(labs(:))
                bb = uint32(round(stats(nR).BoundingBox));
                maxNoReg = round(stats(nR).Area/minArea);
                minNoReg = round(stats(nR).Area/maxArea);
                %medianNoReg = round(stats(nR).Area/medianArea);
                regImg = IFilt(bb(2):bb(2)+bb(4)-1,bb(1):bb(1)+bb(3)-1,:);
                regLab = imdilate(labs(bb(2):bb(2)+bb(4)-1,bb(1):bb(1)+bb(3)-1) == nR,st2); 
                mySkel = bwskel(regLab);
                distImg = bwdist(mySkel); 
                distSkel = distImg(bwperim(regLab));
                hMax = round(max(distSkel)); 
                hMin = round(min(distSkel));
                hMax = min(max(hMax,min(areas.minRad)), max(areas.maxRad));
                hMin = min(max(hMin,min(areas.minRad)), max(areas.maxRad));
                for radius = hMax:-1:hMin
                    imgLog = Ilog(:,:,radius-min(areas.minRad)+1);
                    rStress=imgLog(bb(2):bb(2)+bb(4)-1,bb(1):bb(1)+bb(3)-1);
                    thrData = smooth(rStress(regLab));
                    for th = prctile(thrData,25:2.5:65)
                        regs = imopen(bwareaopen(rStress>th & ...
                                        regLab, minArea, conn),st1);
                        regs = imfill(regs,'holes');
%                        imshow(uint8(regs)*128+uint8(regLab>0)*128);
                        ccReg = bwconncomp(regs,conn); 
                        if ccReg.NumObjects>1
                            newLabs = labelmatrix(ccReg);
                            newStats = regionprops(ccReg, 'Area','Eccentricity'); 
                            idx = find([newStats.Area] < min(radius*1.5,max(areas.maxRad)) | ...
                                ([newStats.Area] <= maxArea & [newStats.Eccentricity]<0.90));
                            if numel(idx)>0 
                                    % metto le regioni buone in ok e le tolto da
                                    % notOk;
                                ok(bb(2):bb(2)+bb(4)-1,bb(1):bb(1)+bb(3)-1) = ...
                                    uint8(ok(bb(2):bb(2)+bb(4)-1,bb(1):bb(1)+bb(3)-1)) + ...
                                    uint8(ismember(newLabs, idx)); 
                         %       imshow(uint8(regs)*50+uint8(newLabs>0)*100+uint8(regLab>0)*100);
                            end
                            clear ccReg newLabs newStats idx
                        end 
                        clear regs ccReg
                    end 
                    clear thrData rStress imgLog
                end
                
                rr = ok(bb(2):bb(2)+bb(4)-1,bb(1):bb(1)+bb(3)-1);
                thrData = rr(regLab);
                regSel = zeros(size(rr));
                for th = prctile(thrData,50:2.5:75)
                    regs = rr>=th & regLab & (~(regSel>0));
                    ccReg = bwconncomp(regs,conn); 
                    newStats = regionprops(ccReg, 'Area','Eccentricity');
                    newLabs = labelmatrix(ccReg);
                    if ccReg.NumObjects<=maxNoReg && ccReg.NumObjects>=minNoReg
                        idx = find(([newStats.Area] < medianArea) | ...
                                ([newStats.Area] <= maxArea & [newStats.Eccentricity]<0.75));
                        if numel(idx)>0 
                            rr2 = bwlabel(imerode(ismember(newLabs, idx),st1),conn);
                            rr2(rr2>0) = rr2(rr2>0) + max(regSel(:));
                            regSel = regSel +  rr2; clear rr2; end
                    end
                    clear newLabs newStats ccReg regs;
                end
                rr = okNew(bb(2):bb(2)+bb(4)-1,bb(1):bb(1)+bb(3)-1);
                rr(regSel>0) = max(okNew(:)); rr = rr + regSel;
                okNew(bb(2):bb(2)+bb(4)-1,bb(1):bb(1)+bb(3)-1) = rr;
                clear rr;
                % se dopo l'ultima iterazione ho altre regioni in regs vado a vedere se 
                % la forma ha delle strettoie 
                % lo faccio tracciando la perpendicolare allo scheletro
                % della regione e vedendo quandi punti della regione trapassa
                regsLeft = imopen(bwareaopen(imerode(regLab,st2) & ...
                    (~imdilate(okNew(bb(2):bb(2)+bb(4)-1,bb(1):bb(1)+bb(3)-1)>0,st3)), minArea*2),st3);
                if any(regsLeft(:))
                    ccReg = bwconncomp(regsLeft,conn); 
                    newLabs = labelmatrix(ccReg);
                    newStats = regionprops(ccReg, 'Eccentricity', 'Area','Orientation','Centroid','BoundingBox');
                    
                    for nRS = 1: max(newLabs(:))
                        eccR = newStats(nRS).Eccentricity;
                        areaR =  newStats(nRS).Area;
                        if areaR> medianRad && eccR < 0.9
                            bbR = round(newStats(nRS).BoundingBox);
                            centroidR = round(newStats(nRS).Centroid);
                            minXR = centroidR(1)-bbR(1); maxXR = bbR(1)+bbR(3)-1-centroidR(1); 
                            minYR = centroidR(2)-bbR(2); maxYR = bbR(2)+bbR(4)-1-centroidR(2);
                            theta = newStats(nRS).Orientation;
                            regNow = (newLabs == nRS);
                            regOri = imrotate(regNow, -theta)>0;
                            [YS,XS] = find(bwskel(regOri));
                            [Y,X] = find(regOri);
                            if numel(XS)>3
                                distImg=bwdist(bwperim(regOri));
                                h = distImg(bwskel(regOri));
                                [~,pos]=findpeaks(smooth(smooth(max(h)-h)));
                                pos(pos<=offset)=[]; pos(pos>=numel(h)-offset)=[]; 
                                for nP = 1 : numel(pos)
                                   [~,indM]= min(h(pos(nP)-offset:pos(nP)+offset));
                                   pos(nP) = pos(nP)-offset+indM-1;
                                end
                                Y0 = YS(pos); X0 = XS(pos);
                                Y1 = YS(pos+1); X1 = XS(pos+1);
                                regDel = false(size(regOri));
                                vecX = [min(X):max(X)]';
                                vecY = [min(Y):max(Y)]';
                                for nL = 1:numel(pos)
                                    mline = double(Y1(nL)-Y0(nL))/double(X1(nL)-X0(nL));
                                    mlinePerp = -1/mline;
                                    qlinePerp = Y0(nL)-mlinePerp.*X0(nL);
                                    vecYNPerp=[min(max(round(vecX*mlinePerp+qlinePerp),1), size(regOri,1)); vecY];
                                    vecXNPerp=[vecX; min(max(round((vecY-qlinePerp)/mlinePerp),1), size(regOri,2))];
                                    regDel(sub2ind(size(regOri),vecYNPerp,vecXNPerp)) = true;
                                end      
                                regOri = imrotate(regOri,theta)>0;
                                regDel = imrotate(bwselect(imdilate(regDel, st1), X0,Y0), theta)>0;
                            else
                                regDel = false(size(regOri));
                            end
                            regC = regionprops(bwconncomp(regOri,conn), 'Centroid');
                            regC = round(regC(1).Centroid);
                            regOri = bwareaopen(regOri & ~regDel, minArea, conn);
                            imshow(regOri);
                            regOri = regOri(regC(2)-minYR:regC(2)+maxYR,regC(1)-minXR:regC(1)+maxXR);
                            rr = regsLeft(centroidR(2)-minYR:centroidR(2)+maxYR,centroidR(1)-minXR:centroidR(1)+maxXR);
                            rr(rr==nRS) = false; rr = rr | regOri;
                            regsLeft(centroidR(2)-minYR:centroidR(2)+maxYR,...
                                centroidR(1)-minXR:centroidR(1)+maxXR)=rr;
                            clear rr; 
                            rr = okNew(bb(2):bb(2)+bb(4)-1,bb(1):bb(1)+bb(3)-1);
                            rr(regsLeft) = max(okNew(:)); rr = rr + bwlabel(regsLeft,conn);
                            okNew(bb(2):bb(2)+bb(4)-1,bb(1):bb(1)+bb(3)-1) = rr;
                            clear rr regDel regC bbR centroidR minXR minYR 
                            clear theta RegNow RegOri XS YS X Y;
                            close all;
                        end
                    end
                end
            end
            figure; imshow(label2rgb(okNew));
            save(fullfile(resDir, [info.imgname '_' info.markerColor{nC}.Color '.mat']),'ok', 'okNew');
            imwrite(ok, fullfile(resDir, [info.imgname '_' info.markerColor{nC}.Color info.ext])); 
            clear ok1 okNew;
        end 
        close all;
    end
end