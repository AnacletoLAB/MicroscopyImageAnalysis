function HistsdiTutti(threshDist,histStepBig,dirImgs)
   histStep=0.01;
   if (nargin<3); dirImgs=uigetdir(...
           'F:\MIA\immagini_MIA\TUMORI\Lavoro_MARA\Estratte50%\divisein4',...
           'Seleziona la dir con i dati .mat degli istogrammi'); end;    %#ok<ALIGN>
   strInfo=load([dirImgs '\InfoHists.mat']);
   NormDist=strInfo.NormDist;
   lW=1;
   maxvB=-1;
   markers={'CD163';'CD3';'CD68'};
   fns=dir([dirImgs '\*_bDists.mat']);
   for numI=1:size(fns,1)
       HName=fns(numI,1).name;
       baseName=HName(1:end-4);         
       posMarker=strfind(upper(baseName),upper(markerName));
       imgName=[baseName(1:posMarker-2) '_' markerName];
       disp([num2str(numI) '->' strtrim(imgName) '<-'])
       disp(['Marker: ' strtrim(markerName)]);
       HM=load([dirImgs '\' HName]);
       if (~isempty(HM.bDists) && any(isfinite(HM.bDists))); 
           maxvB=max([maxvB,HM.maxvBorder]); end
   end
   if ((nargin<2) || isempty(histStepBig)); histStepBig=100; end;
   if ((nargin<1) || isempty(threshDist)); threshDist=[0 maxvB]; end;
   nameSave=['thrDist' strrep(num2str(threshDist),'  ','_') '_step' num2str(histStepBig)];
   if exist(dirImgs,'dir'); disp(['DIRECTORY PATHNAME: ' dirImgs]); 
       dirSave=[dirImgs '\' nameSave]; end
   if ~exist(dirSave,'dir'); mkdir(dirSave); end;
   if (~NormDist)
       if isfinite(threshDist)
           xAxis=0:+histStepBig:(threshDist(2)+(histStepBig)*2); 
       else  xAxis=0:+histStepBig:maxvB; end;
   else xAxis=0:histStep:1; end 
   bDists=[]; legendMat=[]; str=''; HBorder=[]; cumHBorder=[];
   disp(['stepSize = ' num2str(histStepBig) '- thrDist = ' num2str(threshDist)]);
   
   for numM=1: numel(markers)
       markerName=markers{numM};
       fns=dir([dirImgs '\*' markerName '_bDists.mat']);
       for numI=1:size(fns,1)
           HName=fns(numI,1).name;
           baseName=HName(1:end-4);         
           posMarker=strfind(upper(baseName),upper(markerName));
           imgName=[baseName(1:posMarker-2) '_' markerName];
           disp([num2str(numI) '->' strtrim(imgName) '<-'])
           disp(['Marker: ' strtrim(markerName)]);
           HM=load([dirImgs '\' HName]);
           if (~isempty(HM.bDists) && any(isfinite(HM.bDists)))
               bDists=[bDists; HM.bDists]; end 
       end
       HB=computaHists(bDists,xAxis,threshDist);
       HBorder=[HBorder;HB.NormValues];
       cumHBorder=[cumHBorder;cumsum(HB.NormValues)];
       legendMat=[legendMat; {sprintf('%s\n',markerName)}]; str=[str '_' markerName];
   end
   export(mat2dataset(HBorder),'XLSfile',[dirSave '\HBorder' str '.xls']);
   export(mat2dataset(cumHBorder),'XLSfile',[dirSave '\cumHBorder' str '.xls']);
   figHistsBorder=figure('Name', 'Overlaid Histograms of Border Distance',...
       'Position',[25 25 1700 800]); 
   title('Histograms of Border Distance');
   ylabel('Estimated probability (percentage)'); 
   for numM=1: numel(markers)
       stairs(xAxis,HBorder(numM,:),'LineWidth',lW); hold on;
   end
   legend(legendMat,'Location','southoutside'); hold off;
   saveas(figHistsBorder,[dirSave '\BorderDistHistograms.jpg']);
   saveas(figHistsBorder,[dirSave '\BorderDistHistograms.fig']);
   
   figCumHistsBorder=figure('Name', 'Overlaid Histograms of Border Distance',...
       'Position',[25 25 1700 800]); 
   title('Cumulative Histograms of Border Distance');
   ylabel('Estimated probability (percentage)'); 
   for numM=1: numel(markers)
       stairs(xAxis,cumHBorder(numM,:),'LineWidth',lW); hold on;
   end
   legend(legendMat,'Location','southoutside'); hold off;
   saveas(figCumHistsBorder,[dirSave '\BorderDistCumHistograms.jpg']);
   saveas(figCumHistsBorder,[dirSave '\BorderDistCumHistograms.fig']);
   close all;
   clear all;
end


function HBorder=computaHists(bDists,xAxis,threshDist)
    indOn=(bDists>threshDist(1)) & (bDists<=threshDist(2));
    bDists=bDists(indOn);
    numCampioni=double(numel(bDists));
    %%%%%%%%%%%%%%ISTOGRAMMI delle Distanze
    HBorder=histogram(bDists,xAxis);
    HBorder.Values=[HBorder.Values HBorder.Values(end)];
    HBorder.NormValues=HBorder.Values/numCampioni; 
end