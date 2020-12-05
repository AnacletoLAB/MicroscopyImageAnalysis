function trainBasicColorTree(dirSave,markerColor,slash)
    
    if nargin<1; dirSave=['.' slash 'TrainedClassifiers']; end
    %% first Rough Tree
    disp([newline ...
          '----------------------------------------' newline ...
          'TRAINING CLASSIFIER TO PICK BASE COLOR' newline ...
          '----------------------------------------' newline]);
    strClassDef = 'BasicColor';
    ptsOnRGB=[];
    ptsOffRGB=[];
    startV=5; Offset=10; endV=255;
    maxnum=9;
    strAdd=['B'];
    st=strel('disk',3); stBig=strel('disk',7);
    stBiggest=strel('disk', 100);
    dirSavePts=[dirSave slash 'DataBasicColor_' markerColor];
    if ~exist(dirSavePts,'dir'); mkdir(dirSavePts); end
    for i=startV:Offset:endV
        for strNum=1:numel(strAdd)
            strA=strAdd(strNum);
            imgColor=imread(['.' slash 'private' slash 'Colors_' strA num2str(i) '.tif']);
            if exist([dirSavePts slash 'Colors_' strA  num2str(i) '_pts.mat'],'file')
                load([dirSavePts slash 'Colors_' strA num2str(i) '_pts.mat']);
                ptsOnRGB=[ptsOnRGB; computePtsVals(ptsOn,imgColor)];
                ptsOffRGB=[ptsOffRGB; computePtsVals(ptsOff,imgColor)];
                clear ptsOn ptsOff;
            end
            sz=size(imgColor);
            disp([newline newline 'Use normal button clicks to add points to the polyline.' newline ...
                'A shift-, right-, or double-click adds a final point and ends the polyline selection.' newline ...
                'Pressing Return or Enter ends the polyline selection without adding a final point.' newline ...
                'Pressing Backspace or Delete removes the previously selected point from the polyline.' newline newline]);
            fig=figure('Name', 'select Marker Color Areas by drawing a free polygon');
            hold on; imshow(imgColor);
            [X,Y]=getline(fig, 'closed'); close(fig);
            X=round(X); Y=round(Y);
            if numel(X)>0
                imgShape=false(sz(1),sz(2));
                for j=1:size(X,1)-1
                    imgShape=imgShape | drawLine(imgShape,X(j,1),Y(j,1),X(j+1,1),Y(j+1,1));
                end
                imgShape=imgShape | drawLine(imgShape,X(1,1),Y(1,1),X(end,1),Y(end,1));
                if any(X<1 | Y<1 | X>size(imgColor,2) | Y>size(imgColor,1))
                    X(X<1)=1; Y(Y<1)=1; 
                    X(X>size(imgColor,2))=size(imgColor,2); 
                    Y(Y>size(imgColor,1))=size(imgColor,1); 
                    for j=1:size(X,1)-1
                        imgShape=imgShape | drawLine(imgShape,X(j,1),Y(j,1),X(j+1,1),Y(j+1,1));
                    end
                    imgShape=imgShape | drawLine(imgShape,X(1,1),Y(1,1),X(end,1),Y(end,1));
                end
                imgShape=imdilate(imgShape,st);
                imgShape=imerode(imfill(imdilate(imgShape, st),'holes'), st);
                [Y, X]= find(imgShape);
                ptsOn=[X Y]; clear X Y;
                ptsOnRGB=[ptsOnRGB; computePtsVals(ptsOn,imgColor)]; 
                negs=imerode(~imgShape,stBig);
                imgEroded=imerode(negs,stBiggest);
                [Y,X]=find(imgEroded);
                if size(X,1)>size(ptsOn,1)
                    indRand=randi(size(X,1),min(size(ptsOn,1)*1000,size(X,1)),1);
                    X=X(indRand,:); Y=Y(indRand,:); clear indRand;
                end
                ptsOff= [X Y]; clear X Y;
                negs=logical(uint8(negs)-uint8(imgEroded));
                [Y,X]=find(negs);
                ptsOff=[ptsOff;  X Y]; %#ok<*AGROW>
                ptsOffRGB=[ptsOffRGB;  computePtsVals(ptsOff,imgColor)]; 
                fig=figure; imshow(uint8(cat(3,imgShape,imgShape,imgShape)).*imgColor);
                close(fig); 
            else
               ptsOn=[];
               Y=repmat((1:sz(1))',sz(2),1);
               X=reshape(repmat(1:sz(2),sz(1),1),sz(1)*sz(2),1);
               ptsOff= [X Y]; clear X Y;
               ptsOffRGB=[ptsOffRGB;  computePtsVals(ptsOff,imgColor)];
            end
            save([dirSavePts slash 'Colors_' strA num2str(i) '_pts.mat'],'ptsOn','ptsOff');
            clear ptsOn ptsOff;
        end

    end
    ptsOnRGB=double(unique(ptsOnRGB,'rows'));
    ptsOffRGB=double(unique(ptsOffRGB,'rows'));
    szOn=size(ptsOnRGB,1);
    szOff=size(ptsOffRGB,1);
    ptsOnRGB=[ptsOnRGB ptsOnRGB(:,1)./ptsOnRGB(:,2) ptsOnRGB(:,1)./ptsOnRGB(:,3) ptsOnRGB(:,2)./ptsOnRGB(:,3)];
    ptsOffRGB=[ptsOffRGB ptsOffRGB(:,1)./ptsOffRGB(:,2) ptsOffRGB(:,1)./ptsOffRGB(:,3) ptsOffRGB(:,2)./ptsOffRGB(:,3)];
    costTree= [0 1.0-(double(szOff)/double(szOn+szOff)); ...
            1.0-(double(szOn)/double(szOn+szOff)) 0]; 
    Mdltree=fitctree([ptsOnRGB;ptsOffRGB],...
            [true(szOn,1); false(size(ptsOffRGB,1),1)],...
            'Cost',costTree,'MaxNumSplits',maxnum,...
            'OptimizeHyperparameters','auto'); %#ok<*NASGU>
   
    save([dirSave slash 'Mdltree_' strClassDef '_' markerColor '.mat'],'Mdltree');
    
end