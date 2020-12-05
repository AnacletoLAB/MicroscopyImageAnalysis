function markersBIN=par_trees_svm_knn24(I,maskReg,dimLimit,dirClassifiers, colorName,basicColorName, thrArea,slash)
    
    strClassMarkers='Markers';
    strClassCritical='CriticalMarkers';
    if ~isempty(basicColorName); strClassBasic='BasicColor'; end
    n1=5; n2=7;
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
            subImgs(i,j).irgb=I(miny:maxy,minx:maxx,:);  
            subImgs(i,j).range=[miny,maxy,minx,maxx]; %taglioC, taglioR];
            subImgs(i,j).reg=maskReg(miny:maxy, minx:maxx);
            %% classificatori per markers
            if ((i==1) && (j==1)) 
                if ~isempty(basicColorName) && exist([dirClassifiers slash 'Mdltree_' strClassBasic '_' basicColorName '.mat'],'file')
                    mdltreeRoughStr=load([dirClassifiers slash 'Mdltree_' strClassBasic '_' basicColorName '.mat']);
                    flagBasic=true;
                else; flagBasic=false; end
                mdltreeStr=load([dirClassifiers slash 'Mdltree' num2str(numFeat) '_' ...
                        strClassMarkers '_' colorName '.mat']); 
                mdlKNNStr=load([dirClassifiers slash 'MdlKNN' num2str(numFeat) '_' ...
                        strClassMarkers '_' colorName '.mat']);
            end
            if flagBasic; subImgs(i,j).roughTreeClass={mdltreeRoughStr.Mdltree;}; end
            subImgs(i,j).treeClass={mdltreeStr.Mdltree;};
            subImgs(i,j).KNNClass={mdlKNNStr.MdlKNN};
            if numel(dir([dirClassifiers slash 'Mdl*' strClassCritical '_' colorName '.mat']))>0 
                flagCritical=true;
            %% classificatori per critici
                if ((i==1) && (j==1))
                    mdltreeCriticalStr=load([dirClassifiers slash 'Mdltree' num2str(numFeat) '_' ...
                        strClassCritical '_' colorName '.mat']); 
                    init=1; iend=numFeat;
                    mdlsvmCriticalStr=load([dirClassifiers slash 'Mdlsvm' ...
                        num2str(init) '-' num2str(iend) '_' ...
                        strClassCritical '_' colorName '.mat']);
                end
                subImgs(i,j).treeCriticalClass={mdltreeCriticalStr.Mdltree;};
                subImgs(i,j).svmCriticalClass={mdlsvmCriticalStr.Mdlsvm};
            else; flagCritical=false; end
        end
    end
    clear i j;
    clear mdlsvmColorsStr mdltreeColorsStr mdltreeDivStr;
    clear mdlsvmColorsCriticalStr mdlsvmDivCriticalStr mdltreeColorsCriticalStr mdltreeDivCriticalStr;
    markersBIN=false(sz);
    
    for ii=uint32(1):uint32(stepCut(1))
        macrCol=[];
        miny=(ii-1)*taglioR+1;
        maxy=ii*taglioR;
        for jj=uint32(1):uint32(stepCut(2))
      %  parfor jj=uint32(1):uint32(stepCut(2))
            markSubCol=false(size(subImgs(ii,jj).reg));
            if any(any(subImgs(ii,jj).reg>0))       
               if flagBasic; MdltreeRough=subImgs(ii,jj).roughTreeClass; end
               Mdltree=subImgs(ii,jj).treeClass; 
               MdlKNN=subImgs(ii,jj).KNNClass;
               if flagCritical
                   MdltreeCritical=subImgs(ii,jj).treeCriticalClass; 
                   mdlsvm=subImgs(ii,jj).svmCriticalClass;
               end
              
               Ifeats=cat(3,subImgs(ii,jj).irgb,...
                            imboxfilt(subImgs(ii,jj).irgb,[n1 n1]),...
                            rangefilt(subImgs(ii,jj).irgb,ones1),...
                            stdfilt(subImgs(ii,jj).irgb,ones1),...
                            imboxfilt(subImgs(ii,jj).irgb,[n2 n2]),...
                            rangefilt(subImgs(ii,jj).irgb,ones2),...
                            stdfilt(subImgs(ii,jj).irgb,ones2),...
                            cat(3,...
                            subImgs(ii,jj).irgb(:,:,1)./subImgs(ii,jj).irgb(:,:,2),...
                            subImgs(ii,jj).irgb(:,:,1)./subImgs(ii,jj).irgb(:,:,3),...
                            subImgs(ii,jj).irgb(:,:,2)./subImgs(ii,jj).irgb(:,:,3))); 
               indTrue=find(subImgs(ii,jj).reg);
               featsColors=double(computePtsVals(indTrue,Ifeats)); 
               Ifeats=[];
               if flagBasic 
                   labsOff=predict(MdltreeRough{1,1}, [featsColors(:,1:3) featsColors(:,22:24)])==0;
                   featsColors(labsOff,:)=[];  
                   indTrue(labsOff)=[]; labsOff=[]; end               
               labsOff=predict(Mdltree{1,1}, featsColors)==0 ;
               featsColors(labsOff,:)=[];  
               indTrue(labsOff)=[]; labsOff=[];
               if flagCritical
                     %%% DT
                     labsOff=predict(MdltreeCritical{1,1},featsColors)==0 ;
                     indTrue(labsOff)=[]; 
                     featsColors(labsOff,:)=[]; labsOff=[];
                     %%% svms
                     labsOff=(uint8(predict(mdlsvm{1,1},featsColors))==0);
                     indTrue(labsOff)=[]; 
                     featsColors(labsOff,:)=[]; labsOff=[];
                     %%% KNN 
%                      labsOff=predict(MdlKNN{1,1},featsColors(:,1:3))==0; 
%                      featsColors(labsOff,:)=[];
%                      indTrue(labsOff)=[]; labsOff=[];
                end
               markSubCol(indTrue)=true;    
            end
            range=subImgs(ii,jj).range;
            minyOrig=range(1); maxyOrig=range(2); 
            minxOrig=range(3); maxxOrig=range(4);
            
            minx=(jj-1)*taglioC+1;
            maxx=jj*taglioC; 
            if (minyOrig<miny);  markSubCol=markSubCol(2:end,:); end
            if (maxyOrig>maxy);  markSubCol=markSubCol(1:end-1,:); end
            if (minxOrig<minx);  markSubCol=markSubCol(:,2:end); end
            if (maxxOrig>maxx);  markSubCol=markSubCol(:,1:end-1); end
            macrCol=[macrCol markSubCol];
            taglioCC=[]; taglioRR=[];
        end
        markersBIN(((ii-1)*taglioR)+1:min(ii*taglioR,sz(1)),:)=macrCol;
    end
    markersBIN=activecontour(I,imopen(markersBIN,stSmall)) & maskReg;
    Ifeats=cat(3,I,...
               I(:,:,1)./I(:,:,2),...
                I(:,:,1)./I(:,:,3),...
                I(:,:,2)./I(:,:,3));  
    indTrue=find(markersBIN);
    featsColors=double(computePtsVals(indTrue,Ifeats));
    labsOff=predict(MdlKNN{1,1},featsColors(:,1:3))==0; 
    featsColors(labsOff,:)=[];
    indTrue(labsOff)=[]; labsOff=[];
    markersBIN(:,:)=false;
    markersBIN(indTrue)=true;
    markersBIN=bwareaopen(markersBIN,thrArea);
end
