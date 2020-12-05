function collectTrainingData24(imgDir,dirSavePts, dirSaveClassifiers,slash)
% Last Update 11 Sept 2017
    warning off;
    pos=strfind(dirSavePts,'_'); markerColor=dirSavePts(pos(end)+1:end);
    
    ptsOnColors=[]; ptsOffColors=[]; 
    ptsCriticalOffColors=[]; 
    if ~exist(dirSaveClassifiers,'dir'); mkdir(dirSaveClassifiers); end
    
    imgList=dir([dirSavePts slash '*_pts.mat']);
    disp('List of sample points files:')
    for numI=1:size(imgList,1); disp(imgList(numI,1).name); end
    n1=5; ones1=ones(n1); n2=7; ones2=ones(n2);
    for numI=1:size(imgList,1)
        imgName=imgList(numI,1).name;
        if ~strcmpi(imgName(1:6),'Colors')
            pos=strfind(imgName,'_pts.mat');
            baseName=imgName(1:pos-1);
            imgN=dir([imgDir slash baseName '*']);
            info=parseName(imgN(1,1).name);
            if strcmpi(info.ext,'.mat')  %#ok<*ALIGN>
                load(imgN(1,1).name);
            else; IRGB=imread([imgDir slash imgN(1,1).name]); end
          %% load the positions of points already clicked on this image 
          %% to collect again their color     
            if exist([dirSavePts slash baseName '_pts.mat'],'file') 
                load([dirSavePts slash baseName '_pts.mat']);
            else; ptsOn=[]; ptsOff=[]; ptsCriticalOff=[]; end

            IRGB=uint8(IRGB(:,:,1:3));
            IRGB=double(IRGB);
            IRGB(IRGB==0)=1;
            IRGBDiv=cat(3,IRGB(:,:,1)./IRGB(:,:,2),IRGB(:,:,1)./IRGB(:,:,3),IRGB(:,:,2)./IRGB(:,:,3));
            IRGBMean5=imboxfilt(IRGB,[n1 n1]);
            IRGBStd5=stdfilt(IRGB,ones1);
            IRGBMean7=imboxfilt(IRGB,[n2 n2]);
            IRGBStd7=stdfilt(IRGB,ones2);
            IRGBrange5=rangefilt(IRGB,ones1);
            IRGBrange7=rangefilt(IRGB,ones2);
            Ifeats=cat(3,IRGB,IRGBMean5,IRGBrange5,IRGBStd5,IRGBMean7,...
                        IRGBrange7,IRGBStd7,IRGBDiv); 
            clear IRGB IRGBMean5 IRGBrange5 IRGBStd5 IRGBMean7 ...
                        IRGBrange7 IRGBStd7 IRGBDiv;
            if (size(ptsOn,2)>0)
                valsOnColors=computePtsVals(ptsOn,Ifeats);
                ptsOnColors=[ptsOnColors; valsOnColors]; clear valsOnColors;
            end
            if (size(ptsOff,2)>0); valsOffColors=computePtsVals(ptsOff,Ifeats);
                ptsOffColors=[ptsOffColors; valsOffColors]; clear valsOffColors;
            end

            if (size(ptsCriticalOff,2)>0); valsOffColors=computePtsVals(ptsCriticalOff,Ifeats);
                ptsCriticalOffColors=[ptsCriticalOffColors; valsOffColors]; 
                clear valsOffColors;
            end
            clear ptsOn ptsOff ptsCriticalOff=[];
            clear Ifeats;
        end
    end
    ptsCriticalOffColors=unique(ptsCriticalOffColors,'rows');
    ptsOffColors=unique(ptsOffColors,'rows');
    ptsOnColors=unique(ptsOnColors,'rows');
    save([dirSavePts slash 'dataColor24_' markerColor '.mat'],'ptsOnColors','ptsOffColors','ptsCriticalOffColors');
end


