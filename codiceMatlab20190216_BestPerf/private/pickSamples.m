function irgbVals=pickSamples(imgList, baseColor)
    global slash optMsg
    global medFilterSz gaussFilterSigma
    global fScreen scrsz FigPosition msgPosition
    global handles
    
    irgbVals=[];
    for index=1:numel(imgList)
        img=imread([imgList(index).folder slash imgList(index).name]);
        
        for nC=1:size(img,3)
            imgCh=medfilt2(img(:,:,nC),[medFilterSz,medFilterSz]);
            imgCh=imgaussfilt(imgCh,gaussFilterSigma);
            img(:,:,nC)=imgCh; clear imgCh;
        end   
        info=parseName(imgList(index).name);
        imgname=info.imgname;
        for i=1:numel(info.markerColor)
            if strcmpi(info.markerColor{i}.BaseColor,baseColor)
                markerColor=info.markerColor{i}.Color;
                break; end
        end
       
        % se sono già stati selezionati punti on per questa immagine;
        dirMarker=[imgList(index).folder slash 'DataColor_' markerColor];
        if exist([dirMarker slash imgname '_pts.mat'],'file')
            load([dirMarker slash imgname '_pts.mat']);
        else; ptsOn=[]; ptsOff=[]; ptsNothing=[]; cellAreas=[]; end
        if size(ptsOn,1)>0
            ind=sub2ind([size(img,1),size(img,2)],ptsOn(:,2),ptsOn(:,1));
            for nC=1:size(img,3)
                imCh=img(:,:,nC);
                imCh(ind)=255; imgShow(:,:,nC)=imCh; end
        end
        close all;
        fig=figure('Name', ['Select center of areas to be clicked '...
                            'for baseColor = ' baseColor],...
                            'OuterPosition',FigPosition); 
        imshow(img); 
        handles{end+1}=msgbox(['From the shown figure select center of areas where to select '...
                            'some pixels with baseColor' baseColor]);
        h=handles{end}; h.Position(1:2)=msgPosition;
        [Xareas,Yareas]=getpts(fig); close(fig);
        if ((numel(Xareas)>0) && (numel(Yareas)>0)) 
            for i=1: size(Xareas,1)
               xc=Xareas(i); yc=Yareas(i);
               xs=max(xc-(scrsz(3)/fScreen),1); xe=min(xc+(scrsz(3)/fScreen)-1,size(img,2));
               ys=max(yc-(scrsz(4)/fScreen),1); ye=min(yc+(scrsz(4)/fScreen-1),size(img,1));
               figTitle = ['select Cell pixels with baseColor ' baseColor];
               msg = ['From the shown figure select Cell pixels' ...
                 ' with baseColor \bf' baseColor '\rm' newline...
                 ' (double-click or Enter to end insertion)'];
               strPoly = pointsInPoly(img(ys:ye,xs:xe,:), figTitle, msg);
               if numel(strPoly.points)>0
                   X = strPoly.points(:,1);
                   Y = strPoly.points(:,2);
                   if ((numel(X)>0) && (numel(Y)>0)) 
                       pts=[uint32(X)+xs uint32(Y)+ys];
                       clear X Y;
                       indDel=find(pts(:,1)==0 | pts(:,1)>size(img,2) |...
                           pts(:,2)==0 | pts(:,2)>size(img,1));
                       if numel(indDel)>0; pts(indDel,:)=[]; clear indDel; end
                       ptsOn=[ptsOn; pts]; clear pts;
                       cellAreas = [cellAreas; strPoly.areas];
                   end
               end
               clear X Y xs xe ys ye;
            end
            ptsOn=unique(ptsOn,'rows');
            save([dirMarker slash imgname  '_pts.mat'],'ptsOn','ptsOff','ptsNothing', 'cellAreas');
            removeDialogs();
        end
        clear Xareas Yareas;
        if size(ptsOn,1)>0
            irgbVals=[irgbVals;computePtsVals(ptsOn,img)];
        end
    end
    irgbVals=unique(irgbVals,'rows');
    removeDialogs()
    h=msgbox(['Base Color = ' baseColor newline ...
        'min rgb values: \bf' num2str(min(irgbVals)) '\rm' newline ...
        'max rgb values: \bf' num2str(max(irgbVals)) '\rm'], 'Title','none',optMsg);
    h.Position(1:2)=[msgPosition(1) msgPosition(2)-400];
    close all;
end

