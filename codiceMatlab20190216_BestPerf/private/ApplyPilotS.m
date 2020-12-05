function ApplyPilotS()
   
    %% Load Source & Target images
    sourcePath = uigetdir('.\..\Images','Select folder of Images to process');
  %  sourcePath = RheinardMacenko_ColorNormalization(sourcePath, 'R', 'Rheinard');
  %  sourcePath = splitImgsInDir(sourcePath, [512, 512, 50, 50]);
    
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
    st3 = strel('disk',2); st1 = strel('disk',1);
    gaussDev=0.5;
    resDir = fullfile(sourcePath,'Results');
    if ~exist(resDir, 'dir'); mkdir(resDir); end
    StressDir = fullfile(sourcePath,'Stress');
    if ~exist(resDir, 'dir'); mkdir(StreesDir); end
    origClass=load(fullfile(sourcePath, 'DataColor_3Class', 'MdlKNN_2Class.mat'), 'MdlKNN2');
    stressClass=load(fullfile(sourcePath, 'DataColor_3ClassStress', 'MdlTree_3Class.mat'), 'MdlTree3');
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
    
    for nf = 1:numel(fnS)
        name = fnS(nf).name;
        info = parseName(name);
        I = imread(fullfile(sourcePath, name));
        I=I(:,:,1:3);
        sz = size(I);
        IFilt = uint8(zeros(size(I)));
        for ch = 1: size(IFilt,3); IFilt(:,:,ch) = imgaussfilt(medfilt2(I(:,:,ch)), gaussDev); end
%         if exist(fullfile(resDir, [info.imgname 'ACE' info.ext]), 'file')
%             Iace=imread(fullfile(resDir, [info.imgname 'ACE' info.ext]));
%         else; Iace = ace(IFilt,maxRad*2,'E',[],'G',[], 'L'); 
%             imwrite(Iace, fullfile(resDir, [info.imgname 'ACE' info.ext])); 
%         end
         if exist(fullfile(StressDir, [info.imgname info.ext]), 'file')
             IStress=imread(fullfile(StressDir, [info.imgname info.ext]));
         else 
             [IStress,~]=rsr_stress(IFilt, 128, 8, 0.5);
             IStress = uint8(255*IStress);
             imwrite(IStress, fullfile(StressDir, [info.imgname info.ext])); 
         end
        Iproc=IStress;
        IMean1=imboxfilt(IStress,[n1 n1]);
        IMean2=imboxfilt(IStress,[n1*2+1 n1*2+1]);
        if mod(n1*3,2)==0; IMean3=imboxfilt(IStress,[n1*3+1 n1*3+1]);
        else;  IMean3=imboxfilt(IStress,[n1*3 n1*3]); end
        IMean4=imboxfilt(IStress,[n1*4+1 n1*4+1]);             
        feats15 = double(cat(3, IFilt, IMean1, IMean2, IMean3, IMean4));
        %cells = reshape(predict(stressClass.MdlTree3, double(reshape(feats15,sz(1)*sz(2),15))), sz(1), sz(2));
        cells = zeros(size(Iproc,1),size(Iproc,2));
        cells = cells | bwareaopen((sum(double(IStress),3)/3)<=225, min(areas.minArea));
        
        [Y,X] = find(cells);
        IMean1=imboxfilt(IFilt,[n1 n1]);
        IMean2=imboxfilt(IFilt,[n1*2+1 n1*2+1]);
        if mod(n1*3,2)==0; IMean3=imboxfilt(IFilt,[n1*3+1 n1*3+1]);
        else;  IMean3=imboxfilt(IFilt,[n1*3 n1*3]); end
        IMean4=imboxfilt(IFilt,[n1*4+1 n1*4+1]);             
        feats = computePtsVals([X,Y],cat(3, IFilt, IMean1, IMean2, IMean3, IMean4));
        BrownBlue = zeros(size(cells)); 
        BrownBlue(cells)=predict(origClass.MdlKNN2, double(feats));
        
        brown = imclose(bwareaopen(BrownBlue==1, min(areas.minArea),conn), st1);
        holes = imfill(brown, 'holes') & (~brown);
        brown = brown | (holes & ~bwareaopen(holes, min(areas.minArea))); clear holes;
        blue = ~brown & imclose(bwareaopen(BrownBlue==2, min(areas.minArea),conn), st1);
        holes = imfill(blue, 'holes') & (~blue) & (~brown);
        blue = blue | (holes & ~bwareaopen(holes, min(areas.minArea))); clear holes;
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
        OkCells = zeros(size(BrownBlue));
        NotOkCells = zeros(size(BrownBlue));
        ok = false(sz(1),sz(2)); notOk = ok;
        for nC = 1: numel(info.markerColor)
           ok(:,:) = false; notOk(:,:) = false;
           medianArea = areas.medianArea(nC);
           medianRad = areas.medianRad(nC);
           maxArea = areas.maxArea(nC); 
           maxRad = areas.maxRad(nC);
           minArea = areas.minArea(nC); 
           minRad = areas.minRad(nC);
           cells = BrownBlue == nC;
           notOk = bwareaopen(cells, medianArea);
           ok = cells & (~notOk);
           %            
           cc = bwconncomp(notOk,conn); 
           labs = labelmatrix(cc);
           stats = regionprops(cc, 'Area','Eccentricity'); 
           % se sono grandi ma circolari le tengo
           idx = find(([stats.Area]> maxArea*1.15 &  [stats.Eccentricity] < 0.65) | ...
               ([stats.Area] < maxArea & [stats.Eccentricity] < 0.7)); 
           if numel(idx)>0 % le rimuovo da notOk e le metto in ok!
               ok = ok | ismember(labs, idx); notOk(ismember(labs, idx)) = false;
           end
           clear cc idx stats labs
           
           Iproc = IStress;
            % estraggo tutte le regioni notOk e le oriento lungo il loro asse
            % maggiore; le salvo estraendo l'aspetto da IStress
           cc = bwconncomp(notOk,conn); 
           labs = labelmatrix(cc);
           notOkDir = fullfile(sourcePath,'Results','notOk');
           if ~exist(notOkDir, 'dir'); mkdir(notOkDir); end
           stats = regionprops(cc, 'BoundingBox'); 
           % sistemo le notOk
           for nR= 1:max(labs(:))
               bb = uint32(round(stats(nR).BoundingBox));
               regStress = Iproc(bb(2):bb(2)+bb(4)-1,...
                                 bb(1):bb(1)+bb(3)-1,:);
               regLab = labs(bb(2):bb(2)+bb(4)-1,...
                             bb(1):bb(1)+bb(3)-1) == nR; 
               rStress = regStress(:,:,1);
               regs = bwareaopen(imopen(...
                   rStress<=graythresh(rStress(regLab))*max(rStress(regLab)),...
                            st1), minArea);
               figure; imshow(uint8(regs)*128+uint8(regLab>0)*128);
               ccReg = bwconncomp(regs,conn); 
               newLabs = labelmatrix(ccReg);
               newStats = regionprops(ccReg, 'Area','Eccentricity'); 
               idx = find([newStats.Area] < medianArea | ...
                    ([newStats.Area] <= maxArea & [newStats.Eccentricity]<0.85) | ...
                    ([newStats.Area] > maxArea*1.15 & [newStats.Eccentricity]<0.75));
               if numel(idx)>0 
                        % metto le regioni buone in ok e le tolto da
                        % notOk;
                    ok(max(bb(2),1): min(bb(2)+bb(4)-1,sz(1)),...
                       max(bb(1),1): min(bb(1)+bb(3)-1,sz(2)))= ok(max(bb(2),1): min(bb(2)+bb(4)-1,sz(1)),...
                       max(bb(1),1): min(bb(1)+bb(3)-1,sz(2))) | ismember(newLabs, idx); 
                    regs(ismember(newLabs, idx)) = false;
               end
               clear ccReg newLabs newStats idx 
               
               % se rimangono altre regioni in regs vado a vedere se 
               % la forma ha delle strettoie nella forma
               % lo faccio tracciando la perpendicolare allo scheletro
               % della regione e vedendo quandi punti della regione trapassa
               if any(regs(:))
                   ccReg = bwconncomp(regs,conn); 
                   newLabs = labelmatrix(ccReg);
                   newStats = regionprops(ccReg, 'Area','Orientation','Centroid','BoundingBox');
                   for nRS = 1: max(newLabs(:))
                       bbR = round(newStats(nRS).BoundingBox);
                       centroidR = round(newStats(nRS).Centroid);
                       minXR = centroidR(1)-bbR(1); maxXR = bbR(1)+bbR(3)-1-centroidR(1); 
                       minYR = centroidR(2)-bbR(2); maxYR = bbR(2)+bbR(4)-1-centroidR(2);
                       theta = newStats(nRS).Orientation;
                       regNow = (newLabs == nRS);
                       regOri = imrotate(regNow, -theta)>0;
                       [YS,XS] = find(bwskel(regOri));
                    %   YS = round(interp1(XS(1:+3:numel(XS)),YS(1:+3:numel(YS)),XS));
                       [YR,XR] = find(regOri);
                       vecX = [min(XR):max(XR)]';
                       vecY = [min(YR):max(YR)]';
                       h = zeros(numel(XS),1);
                       fig=figure();
                       for xx = 2: numel(XS)-1
                           if YS(xx+1) == YS(xx); h(xx)=sum(uint8(XR==XS(xx)));
                           elseif XS(xx+1)==XS(xx); h(xx)=sum(uint8(YR==YS(xx)));
                           else
                               mlinePerp = -double(XS(xx+1)-XS(xx))/double(YS(xx+1)-YS(xx));
                               qlinePerp = YS(xx)-mlinePerp*XS(xx);
                               vecYN=[min(max(round(vecX*mlinePerp+qlinePerp),1), size(regOri,1)); vecY];
                               vecXN=[vecX; min(max(round((vecY-qlinePerp)/mlinePerp),1), size(regOri,2))];
                               pts=unique([vecXN vecYN],'rows');
                               vecXN = pts(:,1); vecYN = pts(:,2);
                               regLine = ismember([vecXN vecYN],[XR YR],'rows');
                               % visualizzo per sicurezza
                               rS=uint8(regOri);
                               rS(sub2ind(size(regOri),vecYN,vecXN))=2;
                               rS(sub2ind(size(regOri),vecYN(regLine),vecXN(regLine)))=4;                           
                               imshow(255/4*rS);
                               ccLine = bwconncomp(regLine); 
                               if ccLine.NumObjects>1
                                   idx = find(ismember([vecXN, vecYN],[XS(xx),YS(xx)], 'rows'));
                                   regLine = bwselect(regLine, 1, idx,4);
                               end
                               h(xx)=sum(uint8(regLine));
                               clear vecXN vecYN regLine pts mlinePerp qlinePerp;
                           end   
                       end
                       [~,pos]=findpeaks(smooth(smooth(max(h)-h)));
                       pos(pos<=offset)=[]; pos(pos>=numel(h)-offset)=[]; 
                       for nP = 1 : numel(pos)
                           [~,indM]= min(h(pos(nP)-offset:pos(nP)+offset));
                           pos(nP) = pos(nP)-offset+indM-1;
                       end
                       Y0 = YS(pos); X0 = XS(pos);
                       Y1 = YS(pos+1); X1 = XS(pos+1);
                       regDel = false(size(regOri));
                       for nL = 1:numel(pos)
                           mlinePerp = -double(X1(nL)-X0(nL))/double(Y1(nL)-Y0(nL));
                           qlinePerp = Y0(nL)-mlinePerp.*X0(nL);
                           vecYN=[min(max(round(vecX*mlinePerp+qlinePerp),1), size(regOri,1)); vecY];
                           vecXN=[vecX; min(max(round((vecY-qlinePerp)/mlinePerp),1), size(regOri,2))];
                           regDel(sub2ind(size(regOri),vecYN,vecXN)) = true;
                       end      
                       regOri = imrotate(regOri,theta)>0;
                       regDel = imrotate(bwselect(imdilate(regDel, st1), X0,Y0), theta)>0;
                       %regDel = imfill(regDel,'holes') & ~regDel;
                       regC = regionprops(bwconncomp(regOri,conn), 'Centroid');
                       regC = round(regC(1).Centroid);
                       regOri = bwareaopen(regOri & ~regDel, minArea, conn);
                       imshow(regOri);
                       regOri = regOri(regC(2)-minYR:regC(2)+maxYR,regC(1)-minXR:regC(1)+maxXR);
                       rr = regs(centroidR(2)-minYR:centroidR(2)+maxYR,centroidR(1)-minXR:centroidR(1)+maxXR);
                       rr(rr==nRS) = false; rr = rr | regOri;
                       regs(centroidR(2)-minYR:centroidR(2)+maxYR,...
                           centroidR(1)-minXR:centroidR(1)+maxXR) = rr;

                       clear rr regC centroidR;

    %                    regOri=regOri(min(yyOri):min(yyOri)+bbR(4)-1,min(xxOri):min(xxOri)+bbR(3)-1);
    %                    
    %                    regs(max(bbR(2),1): min(bbR(2)+bbR(4)-1,size(regs,1)),...
    %                        max(bbR(1),1): min(bbR(1)+bbR(3)-1,size(regs,2))) = false;
    %                    regs(max(bbR(2),1): min(bbR(2)+bbR(4)-1,size(regs,1)),...
    %                        max(bbR(1),1): min(bbR(1)+bbR(3)-1,size(regs,2))) = ...
    %                        regs(max(bbR(2),1): min(bbR(2)+bbR(4)-1,size(regs,1)),...
    %                        max(bbR(1),1): min(bbR(1)+bbR(3)-1,size(regs,2))) | regOri;
                       close all;
                   end
               end
               ok(bb(2):bb(2)+bb(4)-1,bb(1):bb(1)+bb(3)-1) = ... 
                        ok(bb(2):bb(2)+bb(4)-1,bb(1):bb(1)+bb(3)-1) | regs;
               regStress(cat(3,bwperim(regs),bwperim(regs),bwperim(regs))) = max(regStress(:));
               imwrite(regStress, fullfile(notOkDir,[info.imgname,'_notOk_',...
                   num2str(nC),'_',num2str(nR),info.ext])) ;
           end
           notOk = cells & (~imdilate(ok,st3));
           OkCells = OkCells + BrownBlue .* double(ok);
           NotOkCells = NotOkCells + BrownBlue .* double(notOk);
           clear cells labs cc stats
        end
        
        BrownBlue = OkCells;
        clear OkCells;
        brown = bwperim(BrownBlue == 1);
        ImgS = I; ImgS(cat(3,brown,brown,brown)) = 255;
        blue = bwperim(BrownBlue == 2);
        ImgS(cat(3,blue,blue,blue)) = 0;
        imwrite(ImgS, fullfile(resDir, [info.imgname 'Brown_Blue' info.ext])); 
        close all;
    end
end