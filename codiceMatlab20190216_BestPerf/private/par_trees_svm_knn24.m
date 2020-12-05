function cellBIN=par_trees_svm_knn24(I,maskReg, dimLimit, color, thrArea)
    global slash dirImgs
    if ~isempty(color.BaseColor)
        flagBase=true;
        load([dirImgs slash 'DataBaseColor_' color.BaseColor slash ...
            'Mdltree_' color.BaseColor '.mat']);
    else; flagBase=false; end
    load([dirImgs slash ...
                    'DataColor_' color.Color slash...
                    'Mdltree_'  color.Color '.mat']); 
%     load([dirImgs slash ...
%                     'DataColor_' color.Color slash...
%                     'MdlKNN_'  color.Color '.mat']);
%     load([dirImgs slash ...
%                     'DataColor_' color.Color slash...
%                     'Mdlsvm_'  color.Color '.mat']);
                
    n1=5; n2=9; nFeatSVM=1:12;
    ones1=ones(n1); numFeat=24;
    ones2=ones(n2);
    sz=size(maskReg);  
    stSmall=strel('disk',1); 
    if (sz(2)>dimLimit); stepCut(1)=uint32(round(sz(2)/dimLimit)); else; stepCut(1)=1; end
    if (sz(1)>dimLimit); stepCut(2)=uint32(round(sz(1)/dimLimit)); else; stepCut(2)=1; end
    taglioC=uint32(ceil(double(sz(2))/double(stepCut(2))));
    taglioR=uint32(ceil(double(sz(1))/double(stepCut(1))));
    I=double(I);
    subImgs(stepCut(1),stepCut(2)).irgb=[];
    subImgs(stepCut(1),stepCut(2)).reg=[];          
    for i=uint32(1):uint32(stepCut(1))
        for j=uint32(1):uint32(stepCut(2))
            miny=max((i-1)*taglioR,1);
            maxy=min(i*taglioR+1,sz(1));
            minx=max((j-1)*taglioC,1);
            maxx=min(j*taglioC+1,sz(2));
            subImgs(i,j).irgb=double(I(miny:maxy,minx:maxx,:));
            subImgs(i,j).ilab=rgb2lab(double(I(miny:maxy,minx:maxx,:)));  
            subImgs(i,j).range=[miny,maxy,minx,maxx]; %taglioC, taglioR];
            subImgs(i,j).reg=maskReg(miny:maxy, minx:maxx);
            if flagBase; subImgs(i,j).BasetreeClass=MdlBasetree; end
            subImgs(i,j).treeClass=Mdltree;
%             subImgs(i,j).KNNClass=MdlKNN;
%             subImgs(i,j).SVMClass=Mdlsvm;
        end
    end
    clear i j;
    cellBIN=false(sz);
    for ii=uint32(1):uint32(stepCut(1))
        cellCol=[];
        miny=(ii-1)*taglioR+1;
        maxy=ii*taglioR;
        for jj=uint32(1):uint32(stepCut(2))
        %parfor jj=uint32(1):uint32(stepCut(2))
            cellSubCol=false(size(subImgs(ii,jj).reg));
            markSubCol2=false(size(subImgs(ii,jj).reg));
            if any(any(subImgs(ii,jj).reg>0))       
               Mdltree=subImgs(ii,jj).treeClass; 
               Ifeats=cat(3,subImgs(ii,jj).ilab,...
                            imboxfilt(subImgs(ii,jj).ilab,[n1 n1]),...
                            rangefilt(subImgs(ii,jj).ilab,ones1),...
                            stdfilt(subImgs(ii,jj).ilab,ones1),...
                            imboxfilt(subImgs(ii,jj).ilab,[n2 n2]),...
                            rangefilt(subImgs(ii,jj).ilab,ones2),...
                            stdfilt(subImgs(ii,jj).ilab,ones2),...
                            cat(3,...
                            subImgs(ii,jj).ilab(:,:,1)./subImgs(ii,jj).ilab(:,:,2),...
                            subImgs(ii,jj).ilab(:,:,1)./subImgs(ii,jj).ilab(:,:,3),...
                            subImgs(ii,jj).ilab(:,:,2)./subImgs(ii,jj).ilab(:,:,3))); 
               indTrue=find(subImgs(ii,jj).reg);
               featsColors=double(computePtsVals(indTrue,Ifeats)); 
               Ifeats=[];
               if flagBase 
                   IfeatsBase=computePtsVals(indTrue,subImgs(ii,jj).irgb); 
                   labsOff=predict(subImgs(ii,jj).BasetreeClass, IfeatsBase)==0;
                   featsColors(labsOff,:)=[];  
                   indTrue(labsOff)=[]; labsOff=[]; 
                   cellSubCol(indTrue)=true;
                   markSubCol2=bwareaopen(cellSubCol,thrArea);
                   labsOff=find(markSubCol2(cellSubCol)==0);
                   indTrue(labsOff)=[];
                   featsColors(labsOff,:)=[]; 
                   cellSubCol(:)=false;
                   markSubCol2(:)=false;
               end               
               labsOff=predict(Mdltree, featsColors)==0 ;
               featsColors(labsOff,:)=[];  
               indTrue(labsOff)=[]; labsOff=[];
%                
%                
%                      labsOff=(uint8(predict(mdlsvm{1,1},featsColors(:,nFeatSVM)))==0);
%                      indTrue(labsOff)=[]; 
%                      featsColors(labsOff,:)=[]; labsOff=[];
                     %%% KNN 
%                      labsOff=predict(MdlKNN{1,1},featsColors(:,1:3))==0; 
%                      featsColors(labsOff,:)=[];
%                      indTrue(labsOff)=[]; labsOff=[];
               cellSubCol(indTrue)=true;    
            end
            range=subImgs(ii,jj).range;
            minyOrig=range(1); maxyOrig=range(2); 
            minxOrig=range(3); maxxOrig=range(4);
            
            minx=(jj-1)*taglioC+1;
            maxx=jj*taglioC; 
            if (minyOrig<miny);  cellSubCol=cellSubCol(2:end,:); end
            if (maxyOrig>maxy);  cellSubCol=cellSubCol(1:end-1,:); end
            if (minxOrig<minx);  cellSubCol=cellSubCol(:,2:end); end
            if (maxxOrig>maxx);  cellSubCol=cellSubCol(:,1:end-1); end
            cellCol=[cellCol cellSubCol];
            taglioCC=[]; taglioRR=[];
        end
        cellBIN(((ii-1)*taglioR)+1:min(ii*taglioR,sz(1)),:)=cellCol;
    end
%    markersBIN=activecontour(I,imopen(markersBIN,stSmall)) & maskReg;
%     Ifeats=cat(3,I,...
%                I(:,:,1)./I(:,:,2),...
%                 I(:,:,1)./I(:,:,3),...
%                 I(:,:,2)./I(:,:,3));  
%     indTrue=find(markersBIN);
%     featsColors=double(computePtsVals(indTrue,Ifeats));
%     labsOff=predict(MdlKNN,featsColors(:,1:3))==0; 
%     featsColors(labsOff,:)=[];
%     indTrue(labsOff)=[]; labsOff=[];
%     markersBIN(:,:)=false;
%     markersBIN(indTrue)=true;
    cellBIN=bwareaopen(cellBIN,thrArea);
    cellBIN=~bwareaopen(~cellBIN,thrArea);
                
end
