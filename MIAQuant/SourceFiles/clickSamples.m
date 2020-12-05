function clickSamples(imgDir)
% Last Update 11 Jun 2017
    warning off;
    imgDirS='';
    if (nargin<1); imgDir=...
            uigetdir(imgDirS,'Select Folder of Sample Images'); end;
    
    dirS=uigetdir(imgDir,'IF EXISTING select saving directory');
    if isa(dirS,'double');
        strName=input('Enter the name of the point sample ','s');
        dirS=[imgDir '\ptsVals_' strName];
    else
        pos=strfind(dirS,'_');
        strName=dirS(pos(end)+1:end);
    end
    if ~exist(dirS,'dir'); mkdir(dirS); end;
    
    filter=input('Enter the image filter (e.g. .tif, myImgFilter.jpg, .mat, _IRGB.mat) ','s');
    
    disp(['Image Directory: ' imgDir]);
    disp(['Saving Directory:' dirS]);
    fScreen=7;
    imgList=dir([imgDir '\*' filter]);
    imgList(:,1).name
    if exist([dirS '\ptsSamples.mat'],'file'); load([dirS '\ptsSamples.mat']);
    else ptsOnColors=[]; ptsOffColors=[]; end;
    Nhood=8; strMethod='nearest'; fZoom=1.0;
    for numI=1:size(imgList,1)
        imgName=imgList(numI,1).name;
        pos=strfind(imgName,'.');
        imgFormat=imgName(pos+1:end);
        baseName=imgName(1:pos-1);
        answer=input(['img to process: ->' baseName '<- process image? (Y to process this image, N to skip it) '],'s');
        if  strcmpi(answer,'N'); 
            answerStop=input('continue processing? (Y for continuing /N for stopping) ','s');
            if strcmpi(answerStop,'N'); break; else continue; end;
        else
            if strcmpi(imgFormat,'mat') 
                load([imgDir '\' imgName]);
            else IRGB=imread([imgDir '\' imgName]); end;
            if exist([dirS '\' baseName '_pts.mat'],'file') %#ok<ALIGN>
                load([dirS '\' baseName '_pts.mat']);
            else ptsOn=[]; ptsOff=[]; end;
            IRGB=uint8(IRGB);
            scrsz = get(groot,'ScreenSize');
            IYcbcr=rgb2ycbcr(IRGB); Icbcr=IYcbcr(:,:,2:3); clear IYcbcr;
            ILab=lab2uint8(rgb2lab(IRGB)); Iab=ILab(:,:,2:3); clear ILab;
            Ifeats=cat(3,IRGB,Icbcr,Iab); clear Iab;
    %% SELECT centers of areas where to select ON-marker pixels
            fig=figure('Name', 'SELECT centers of areas where to select ON-marker pixels (double-click or Enter to end insertion)', ...
                'Position',[1 scrsz(4) scrsz(3) scrsz(4)]);
            hold on; imshow(IRGB); 
            [Xareas , Yareas]= getpts;
            Xareas=uint32(Xareas);
            Yareas=uint32(Yareas);
            if ((numel(Xareas)>0) && (numel(Yareas)>0)) 
                close(fig);
                for i=1: size(Xareas,1)
                   xc=Xareas(i); yc=Yareas(i);
                   xs=max(xc-scrsz(3)/fScreen,1); xe=min(xs+scrsz(3)-1,size(IRGB,2));
                   ys=max(yc-scrsz(4)/fScreen,1); ye=min(ys+scrsz(4)-1,size(IRGB,1));
                   fig=figure('Name', 'select MARKER pixels (double-click or Enter to end insertion)', ...
                    'Position',[1 scrsz(4) scrsz(3) scrsz(4)]);
                   hold on; imshow(imresize(IRGB(ys:ye,xs:xe,:),fZoom,strMethod));
                   [X,Y]=getpts(fig); close(fig); 
                   X=uint32(round(X/fZoom)); Y=uint32(round(Y/fZoom));
                   pts=[uint32(X)+xs uint32(Y)+ys]; clear xs xe ys ye; 
                   if ((numel(X)>0) && (numel(Y)>0)) 
                       ptsOn=[ptsOn; pts; ptsNeighs(pts,Nhood)]; pts=[];
                       indDel=find(ptsOn(:,1)==0 | ptsOn(:,1)>size(IRGB,2) |...
                           ptsOn(:,2)==0 | ptsOn(:,2)>size(IRGB,1));
                       if numel(indDel)>0; ptsOn(indDel,:)=[]; end; indDel=[]; end; 
                end
                Xareas=[]; Yareas=[];
                if (size(ptsOn,2)>0); valsOnColors=computePtsVals(ptsOn,Ifeats);
                    ptsOnColors=[ptsOnColors; valsOnColors]; valsOnColors=[];
                end        
                % save data up to now, just in case something goes wrong later
                save([dirS '\ptsSamples.mat'],'ptsOnColors','ptsOffColors');
                save([dirS '\' baseName '_pts.mat'],'ptsOn','ptsOff');
            end
     %% SELECT centers of areas where to select OFF-NOT marker pixels
            fig=figure('Name', 'SELECT centers of areas where to select OFF-NOT marker pixels (double-click or Enter to end insertion)', ...
                'Position',[1 scrsz(4) scrsz(3) scrsz(4)]);
            hold on; imshow(IRGB); 
            [Xareas , Yareas]= getpts;
            Xareas=uint32(Xareas);
            Yareas=uint32(Yareas);
            if ((numel(Xareas)>0) && (numel(Yareas)>0)) 
                close(fig);
                for i=1: size(Xareas,1)
                   xc=Xareas(i); yc=Yareas(i);
                   xs=max(xc-scrsz(3)/fScreen,1); xe=min(xs+scrsz(3)-1,size(IRGB,2));
                   ys=max(yc-scrsz(4)/fScreen,1); ye=min(ys+scrsz(4)-1,size(IRGB,1));
                   fig=figure('Name', 'select NOT MARKER pixels (double-click or Enter to end insertion)', ...
                    'Position',[1 scrsz(4) scrsz(3) scrsz(4)]);
                   hold on; imshow(imresize(IRGB(ys:ye,xs:xe,:),fZoom,strMethod));
                   rect=getrect(fig);
                   xmin=uint32(round(rect(1))); ymin=uint32(round(rect(2))); 
                   width=uint32(round(rect(3))); height=uint32(round(rect(4))); clear rect;
                   if (width>10 || height>10) %#ok<ALIGN>
                       X=reshape(repmat((xmin:xmin+width-1)',height,1),height*width,1);
                       Y=reshape(repmat((ymin:ymin+height-1)',width,1),height*width,1);
                   else [X,Y]=getpts(fig); end; 
                   close(fig);
                   X=uint32(round(X/fZoom)); Y=uint32(round(Y/fZoom));
                   pts=[uint32(X)+xs uint32(Y)+ys]; clear xs xe ys ye; 
                   if ((numel(X)>0) && (numel(Y)>0));
                       ptsOff=[ptsOff; pts; ptsNeighs(pts,Nhood)]; pts=[];
                       indDel=find(ptsOff(:,1)==0 | ptsOff(:,1)>size(IRGB,2) |...
                           ptsOff(:,2)==0 | ptsOff(:,2)>size(IRGB,1));
                       if numel(indDel)>0; ptsOff(indDel,:)=[]; end; indDel=[]; end;
                end
                Xareas=[]; Yareas=[];
                if (size(ptsOff,2)>0)           
                    valsOffColors=computePtsVals(ptsOff,Ifeats);
                    ptsOffColors=[ptsOffColors; valsOffColors];
                    clear valsOffColors;
                end   
                save([dirS '\' baseName '_pts.mat'],'ptsOn','ptsOff');
                % save data up to now, just in case something goes wrong later
                save([dirS '\ptsSamples.mat'],'ptsOnColors','ptsOffColors');
            end
            answerStop=input('continue processing? (Y for continuing /N for stopping) ','s');
            if strcmpi(answerStop,'N'); break; end;
        end
        clear RegsF IRGB;
    end
    
    save([dirS '\ptsSamples.mat'],'ptsOnColors','ptsOffColors');
    save(['ptsSamples_' strName '.mat'], 'ptsOnColors', 'ptsOffColors');
    answerLearn=input('Learn classifiers? Y/N ', 's');
    if strcmpi(answerLearn,'y')
        DataAnalisys(ptsOnColors,ptsOffColors, strName);
    else disp('Saving examples withouth learning'); end;
end


