function trainBaseColorTree(baseColor, dirSavePts,imgListTest)
    global slash
    global indFeatBaseTree
    global msgPosition 
   
    
    if nargin<1; dirSave=['.']; end
    
    disp([newline ...
          '----------------------------------------' newline ...
          'TRAINING CLASSIFIER TO PICK BASE COLOR: ' upper(baseColor) newline ...
          '----------------------------------------' newline]);
    maxnum=9;
    if ~exist([dirSavePts slash 'trainingColors_pts.mat'],'file')
        irgbVals=pickSamples(imgListTest,baseColor);
        ptsOnRGB=[];
        ptsOnGray=[];
        ptsOffRGB=[];
        ptsOffGray=[];
        startV=0; Offset=25; endV=255;
        
        imgList=dir(['private' slash 'Colors_*.tif']);
        st=strel('disk',3);
        irgbVals=unique(irgbVals,'rows');
        irgbVals(irgbVals(:,3)<0)=[];
        irgbVals(irgbVals(:,3)>255)=[];
        clear sumV;
        if ~exist(dirSavePts,'dir'); mkdir(dirSavePts); end

        for numF=1:numel(imgList)
            imgColor=imread([imgList(numF).folder slash imgList(numF).name]);
            sz=size(imgColor);
            info=parseName(imgList(numF).name);
            xx=reshape(imgColor,size(imgColor,1)*size(imgColor,2),3);
            ind=reshape(ismember(xx,irgbVals,'rows'),sz(1),sz(2));
            if any(ind(:)); for nC=1:3
                    im=imgColor(:,:,nC);
                    im(ind)=255;
                    imgColor(:,:,nC)=im;
                end; end; clear ind;
    %         ind=reshape(ismember(xx,newVals,'rows'),sz(1),sz(2));
    %         if any(ind(:)); for nC=1:3
    %                 im=imgColor(:,:,nC);
    %                 im(ind)=128;
    %                 imgColor(:,:,nC)=im;
    %             end; end; clear ind;

            imgGray=rgb2gray(imgColor);
            sz=size(imgColor);

            if ~exist([dirSavePts slash info.patName '_' info.markerNames '_pts.mat'],'file')
                h=msgbox([newline newline 'Use normal button clicks to add points to the polyline.' newline ...
                'A shift-, right-, or double-click adds a final point and ends the polyline selection.' newline ...
                'Pressing Return or Enter ends the polyline selection without adding a final point.' newline ...
                'Pressing Backspace or Delete removes the previously selected point from the polyline.' newline newline]);
                h.Position(1:2)=msgPosition;
                fig=figure('Name', ['blue value= ' num2str(info.markerNames) '; select ' baseColor ' Areas by drawing a polygon']);
                hold on; imshow(imgColor);
                [XX,YY]=getline(fig, 'closed'); close(fig);
                XX=round(XX); YY=round(YY);
                X=XX-min(XX)+1; Y=YY-min(YY)+1;
                szX=max(X); szY=max(Y);
                if numel(X)>0
                    imgShape=false(szY,szX);
                    for j=1:size(X,1)-1
                        imgShape=imgShape | drawLine(imgShape,X(j,1),Y(j,1),X(j+1,1),Y(j+1,1));
                    end
                    imgShape=imgShape | drawLine(imgShape,X(1,1),Y(1,1),X(end,1),Y(end,1));
                    imgShape=imdilate(imgShape,st);
                    imgShape=imerode(imfill(imdilate(imgShape, st),'holes'), st);
                    clear Y X;
                    [Y, X]= find(imgShape);
                    X=X+min(XX)-1; Y=Y+min(YY)-1;
                    indDel=find(X<1 | X>sz(2));
                    X(indDel)=[]; Y(indDel)=[];
                    indDel=find(Y<1 | Y>sz(1));
                    X(indDel)=[]; Y(indDel)=[];
                    ptsOn=[X Y]; clear X Y;
                    ptsOnRGB=[ptsOnRGB; computePtsVals(ptsOn,imgColor)]; 
                    ptsOnGray=[ptsOnGray;  computePtsVals(ptsOn,imgGray)];
                    negs=true(sz(1),sz(2));
                    negs(sub2ind(sz,ptsOn(:,2),ptsOn(:,1)))=false;
                    [Y,X]=find(negs);
                    clear imgShape;
                    X=X+min(XX)-1; Y=Y+min(YY)-1;
                    indDel=find(X<1 | X>sz(2));
                    X(indDel)=[]; Y(indDel)=[];
                    indDel=find(Y<1 | Y>sz(1));
                    X(indDel)=[]; Y(indDel)=[];          
                    ptsOff= [X Y]; clear X Y;
                    ptsOffRGB=[ptsOffRGB;  computePtsVals(ptsOff,imgColor)];
                    ptsOffGray=[ptsOffGray;  computePtsVals(ptsOff,imgGray)];
                    clear XX YY;
                    clear negs imgShape;
                else
                   ptsOn=[];
                   Y=repmat((1:sz(1))',sz(2),1);
                   X=reshape(repmat(1:sz(2),sz(1),1),sz(1)*sz(2),1);
                   ptsOff= [X Y]; clear X Y;
                   ptsOffRGB=[ptsOffRGB;  computePtsVals(ptsOff,imgColor)];
                   ptsOffGray=[ptsOffGray;  computePtsVals(ptsOff,imgGray)];

                end
                save([dirSavePts slash info.patName '_' info.markerNames '_pts.mat'],'ptsOn','ptsOff');
                clear ptsOn ptsOff;
                delete(h);
            else
                load([dirSavePts slash info.patName '_' info.markerNames '_pts.mat'])
                ptsOnRGB=[ptsOnRGB; computePtsVals(ptsOn,imgColor)]; 
                ptsOnGray=[ptsOnGray;  computePtsVals(ptsOn,imgGray)];
                ptsOffRGB=[ptsOffRGB;  computePtsVals(ptsOff,imgColor)];
                ptsOffGray=[ptsOffGray;  computePtsVals(ptsOff,imgGray)];
                clear ptsOn ptsOff;
            end
        end
        [ptsOnColors, iOnRGB]=unique(ptsOnRGB,'rows');
        ptsOnGray=double(ptsOnGray(iOnRGB)); clear iOnRGB;
        [ptsOffColors, iOffRGB]=unique(ptsOffRGB,'rows');
        ptsOffGray=double(ptsOffGray(iOffRGB)); clear iOffRGB;
        ptsOnColors=double(ptsOnColors);
        ptsOffColors=double(ptsOffColors);
        save([dirSavePts slash 'trainingColors_pts.mat'],...
            'ptsOnColors','ptsOnGray','ptsOffGray','ptsOffColors');
        clear ptsOffRGB ptsOnRGB;
    else
        disp('loading already collected training data...');
        load([dirSavePts slash 'trainingColors_pts.mat']);
    end
    ptsOnRGB=[ptsOnColors];
    ptsOffRGB=[ptsOffColors];
    szOn=size(ptsOnRGB,1);
    szOff=size(ptsOffRGB,1);
    costTree= [0 1.0-(double(szOff)/double(szOn+szOff)); ...
             1.0-(double(szOn)/double(szOn+szOff)) 0]; 
    MdlBasetree=fitctree([ptsOnRGB(:,indFeatBaseTree);ptsOffRGB(:,indFeatBaseTree)],...
            [true(szOn,1); false(size(ptsOffRGB,1),1)],...
            'Cost',costTree,'MaxNumSplits',maxnum,...
            'OptimizeHyperparameters','auto'); %#ok<*NASGU>
        
   save([dirSavePts slash 'Mdltree_' baseColor '.mat'],'MdlBasetree');
   testbaseColorOnDir(imgListTest, MdlBasetree); 
end