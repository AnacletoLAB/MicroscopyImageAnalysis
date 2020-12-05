function collectTrainingData24(imgDir,dirSavePts, dirSaveClassifiers,slash)
% Last Update 11 Sept 2017
    warning off;
    pos=strfind(dirSavePts,'_'); markerColor=dirSavePts(pos(end)+1:end);
    
    ptsOnColors=[]; ptsOffColors=[]; 
    ptsCOffColors=[]; 
    if ~exist(dirSaveClassifiers,'dir'); mkdir(dirSaveClassifiers); end
    
    imgList=dir([dirSavePts slash '*_pts.mat']);
    disp('List of sample points files:')
    for numI=1:size(imgList,1); disp(imgList(numI,1).name); end
    n1=5; ones1=ones(n1); n2=7; ones2=ones(n2); n3=11; ones3=ones(n3);
    for numI=1:size(imgList,1)
        imgName=imgList(numI,1).name;
        disp(imgName);
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
                load([dirSavePts slash baseName '_pts.mat'],'ptsOn','ptsOff','ptsCOff');
            else; ptsOn=[]; ptsOff=[]; ptsCOff=[]; end
            IRGB = uint8(IRGB(:,:,1:3));
            Ifeats = ComputeFeatures(IRGB); 
           
            if (size(ptsOn,2)>0)
                valsOnColors=computePtsVals(ptsOn,Ifeats);
                ptsOnColors=[ptsOnColors; valsOnColors]; clear valsOnColors;
            end
            if (size(ptsOff,2)>0); valsOffColors=computePtsVals(ptsOff,Ifeats);
                ptsOffColors=[ptsOffColors; valsOffColors]; clear valsOffColors;
            end
            if (size(ptsCOff,2)>0); valsOffColors=computePtsVals(ptsCOff,Ifeats);
                ptsCOffColors=[ptsCOffColors; valsOffColors]; clear valsOffColors;
            end
            clear ptsOn ptsOff ptsCOff;
            clear Ifeats;
        end
    end
    ptsOffColors=unique(ptsOffColors,'rows');
    ptsOnColors=unique(ptsOnColors,'rows');
    ptsCOffColors=unique(ptsCOffColors,'rows');
    
    save([dirSavePts slash 'dataColor24_' markerColor '.mat'],'ptsOnColors','ptsOffColors','ptsCOffColors');
end


