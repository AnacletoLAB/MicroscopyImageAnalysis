function markersBIN=par_trees_svm_knn24(I,maskReg,dimLimit,dirClassifiers, colorName, thrArea) 
    sz=size(maskReg);  
    if (sz(2)>dimLimit); stepCut(1)=uint32(round(sz(2)/dimLimit)); else; stepCut(1)=1; end
    if (sz(1)>dimLimit); stepCut(2)=uint32(round(sz(1)/dimLimit)); else; stepCut(2)=1; end
    taglioC=uint32(ceil(double(sz(2))/double(stepCut(2))));
    taglioR=uint32(ceil(double(sz(1))/double(stepCut(1))));
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
                mdltreeRoughStr=load([dirClassifiers filesep 'MdltreeRough_' colorName '.mat']);
%                mdltreeStr=load([dirClassifiers filesep 'Mdltree_' colorName '.mat']); 
                mdltreeStrBasic=load([dirClassifiers filesep 'MdltreeBasic_' colorName '.mat']); 
            end
            subImgs(i,j).roughTreeClass={mdltreeRoughStr.mdltree;};
%            subImgs(i,j).treeClass={mdltreeStr.Mdltree};
            subImgs(i,j).treeBasicClass={mdltreeStrBasic.MdltreeBasic};
        end
    end
    clear i j;
    clear mdlsvmColorsStr mdltreeColorsStr mdltreeDivStr;
    clear mdlsvmColorsCriticalStr mdlsvmDivCriticalStr mdltreeColorsCriticalStr mdltreeDivCriticalStr;
    markersBIN=zeros(sz);
    numFeatBasic = 6;
    numFeatRough = 3;
    for ii=uint32(1):uint32(stepCut(1))
        macrCol=[];
        miny=(ii-1)*taglioR+1;
        maxy=ii*taglioR;
        for jj=uint32(1):uint32(stepCut(2))
      %  parfor jj=uint32(1):uint32(stepCut(2))
            markSubCol=zeros(size(subImgs(ii,jj).reg));
            indTrue=find(subImgs(ii,jj).reg);
            if any(any(subImgs(ii,jj).reg>0))       
               MdltreeRough=subImgs(ii,jj).roughTreeClass; 
              % Mdltree=subImgs(ii,jj).treeClass;
               MdltreeBasic=subImgs(ii,jj).treeBasicClass;
               %Mdlsvm=subImgs(ii,jj).treeClass; 
               Ifeats = ComputeFeatures(subImgs(ii,jj).irgb);
              
               indTrue=find(subImgs(ii,jj).reg);
               featsColors=double(computePtsVals(indTrue,Ifeats)); 
               Ifeats=[]; featsCol = featsColors; indT = indTrue;
              
               labsOff=predict(MdltreeRough{1,1}, [featsColors(:,1:numFeatRough)])==0;
               featsColors(labsOff,:)=[];  
               indTrue(labsOff)=[]; labsOff=[]; 
                   
                markSubCol(indTrue)=markSubCol(indTrue)+1;   
                
                 labsOff=predict(MdltreeBasic{1,1}, featsColors(:,1:numFeatBasic))==0 ;
                 featsColors(labsOff,:)=[];  
                indTrue(labsOff)=[]; labsOff=[];
                markSubCol(indTrue)=markSubCol(indTrue)+1;  
                
%                 labsOff=predict(Mdltree{1,1}, featsColors)==0 ;
%                 featsColors(labsOff,:)=[];  
%                indTrue(labsOff)=[]; labsOff=[];
%                markSubCol(indTrue)=markSubCol(indTrue)+1;    
               
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
            macrCol=[macrCol markSubCol>1];
            taglioCC=[]; taglioRR=[];
        end
        markersBIN(((ii-1)*taglioR)+1:min(ii*taglioR,sz(1)),:)=macrCol;
    end
    
%     markersBIN=activecontour(I,imopen(markersBIN,stSmall)) & maskReg;
%     Ifeats=IRGB;  
%     indTrue=find(markersBIN);
%     featsColors=double(computePtsVals(indTrue,Ifeats));
% %     labsOff=predict(MdlKNN{1,1},featsColors(:,1:3))==0; 
% %     featsColors(labsOff,:)=[];
% %     indTrue(labsOff)=[]; labsOff=[];
%     markersBIN(:,:)=false;
%     markersBIN(indTrue)=true;
   markersBIN=bwareaopen(markersBIN,thrArea);
end
