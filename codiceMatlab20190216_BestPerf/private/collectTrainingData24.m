function collectTrainingData24(imgDir,dirSavePts)
% Last Update 17 Ago 2018
%% Tutte le features sono calcolate dai valori nello spazio color L*a*b*
    global medFilterSz gaussFilterSigma

    warning off;
    pos=strfind(dirSavePts,'_'); markerColor=dirSavePts(pos(end)+1:end);
    allAreas=[];
    ptsOnColors=[]; ptsOffColors=[]; ptsNothingColors=[]; 
       
    imgList=dir(fullfile(dirSavePts, '*_pts.mat'));
    disp('List of sample points files:')
    for numI=1:size(imgList,1); disp(imgList(numI,1).name); end
    n1=3;
    for numI=1:size(imgList,1)
        imgName=imgList(numI,1).name;
        if ~strcmpi(imgName(1:6),'Colors')
            pos=strfind(imgName,'_pts.mat');
            baseName=imgName(1:pos-1);
            imgN=dir(fullfile(imgDir,[baseName '*']));
            info=parseName(imgN(1,1).name);
            if strcmpi(info.ext,'.mat')  %#ok<*ALIGN>
                load(imgN(1,1).name);
            else; IRGB=imread(fullfile(imgDir,imgN(1,1).name)); end
          %% load the positions of points already clicked on this image 
          %% to collect again their color     
            if exist(fullfile(dirSavePts, [baseName '_pts.mat']),'file') 
                load(fullfile(dirSavePts, [baseName '_pts.mat']));
            else; ptsOn=[]; ptsOff=[]; ptsNothing=[]; cellAreas=[]; end
            allAreas=[allAreas; cellAreas];
            IRGB=uint8(IRGB(:,:,1:3));
            for i=1:size(IRGB,3)
                img=medfilt2(IRGB(:,:,i),[medFilterSz,medFilterSz]);
                img=imgaussfilt(img,gaussFilterSigma);
                IRGB(:,:,i)=img;
            end
            IRGB=double(IRGB);
%             Ilab=rgb2lab(IRGB);
%             Ilab(Ilab==0)=min(abs(Ilab(:)))/100;
%             IlabDiv=cat(3,Ilab(:,:,1)./Ilab(:,:,2),Ilab(:,:,1)./Ilab(:,:,3),Ilab(:,:,2)./Ilab(:,:,3));
%             IlabMean5=imboxfilt(Ilab,[n1 n1]);
%             IlabStd5=stdfilt(Ilab,ones1);
%             IlabMean7=imboxfilt(Ilab,[n2 n2]);
%             IlabStd7=stdfilt(Ilab,ones2);
%             Ilabrange5=rangefilt(Ilab,ones1);
%             Ilabrange7=rangefilt(Ilab,ones2);
%             Ifeats=cat(3,Ilab,IlabMean5,Ilabrange5,IlabStd5,IlabMean7,...
%                         Ilabrange7,IlabStd7,IlabDiv);
            IHSV=rgb2hsv(IRGB);
            IRGBMean1=imboxfilt(IRGB,[n1 n1]);
            IRGBMean2=imboxfilt(IRGB,[n1*2+1 n1*2+1]);
            if mod(n1*3,2)==0; IRGBMean3=imboxfilt(IRGB,[n1*3+1 n1*3+1]);
            else;  IRGBMean3=imboxfilt(IRGB,[n1*3 n1*3]); end
            IRGBMean4=imboxfilt(IRGB,[n1*4+1 n1*4+1]); 
            %1-3 = RGB
            %4-6 = RGB3
            %7-9 = RGB7
            %10-12 = RGB9
            %13-15 = RGB13
            Ifeats=cat(3,IRGB(:,:,1),IRGB(:,:,3),IHSV(:,:,1));
%            Ifeats=cat(3,IRGB,IRGBMean1, IRGBMean2, IRGBMean3, IRGBMean4);
            clear IRGB IRGBMean1 IRGBMean2 IRGBMean3 IlabMean5 Ilabrange5 IlabStd5 IlabMean7 ...
                        Ilabrange7 IlabStd7 IlabDiv;
            if (size(ptsOn,2)>0)
                valsOnColors=computePtsVals(ptsOn,Ifeats);
                ptsOnColors=[ptsOnColors; valsOnColors]; clear valsOnColors;
                
            end
            if (size(ptsOff,2)>0); valsOffColors=computePtsVals(ptsOff,Ifeats);
                ptsOffColors=[ptsOffColors; valsOffColors]; clear valsOffColors;
            end
            if (size(ptsNothing,2)>0); valsNothingColors=computePtsVals(ptsNothing,Ifeats);
                ptsNothingColors=[ptsNothingColors; valsNothingColors]; clear valsNothingColors;
            end
            clear ptsOn ptsOff ptsNothing;
            clear Ifeats;
        end
    end
    ptsOffColors=unique(ptsOffColors,'rows');
    ptsOnColors=unique(ptsOnColors,'rows');
    ptsNothingColors=unique(ptsNothingColors,'rows');
    
    save(fullfile(dirSavePts, ['dataColor24_' markerColor '.mat']), ...
        'ptsOnColors','ptsOffColors','ptsNothingColors');
    save(fullfile(dirSavePts, ['areas_' markerColor '.mat']),'allAreas');
end


