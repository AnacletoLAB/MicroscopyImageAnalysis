function ClickSamples_TrainClassifiers
% Last Update 04 Oct 2017
    warning off;
    curDir=cd;
    slash='\';
    k = strfind(curDir, slash);
    if numel(k)==0; slash='/'; end
    imgDir=uigetdir(cd, 'Select folder of training samples');
    dirSaveClassifiers=['.' slash 'TrainedClassifiers'];
    
    if ~exist(dirSaveClassifiers,'dir'); mkdir(dirSaveClassifiers); end
    
    imgList=[dir([imgDir slash '*.tif']); dir([imgDir slash '*.jpg']); dir([imgDir slash '*.png'])];
    info=parseName(imgList(1,1).name);
    %% enter the image format and the marker name
    presetmarkerColor=info.markerColor; 
    ind=strfind(presetmarkerColor,'-');
    if numel(ind)>0 
        baseColor=presetmarkerColor(ind+1:end);
        markerColor=presetmarkerColor(1:ind-1);
        disp(['Base marker Color =  ' baseColor]);
        disp(['Marker Color ' markerColor]);
        if exist([dirSaveClassifiers slash 'Mdltree_BasicColor_' baseColor '.mat'],'file')
            disp(['Basic color classifier ' baseColor ' already exist']);
            basicCol=input(['Train novel basic color classifier? (Y/N)' newline],'s');
            if (strcmpi(basicCol,'Y')); trainBasicColorTree(dirSaveClassifiers, baseColor,slash); end
        else
            if exist([dirSaveClassifiers slash 'DataColor_' baseColor],'dir')
                disp(['Basic color data already existing. Basic classifier will be updated with new points' newline]);
            end
            trainBasicColorTree(dirSaveClassifiers, baseColor,slash);     
        end
    else
        markerColor=presetmarkerColor;
        baseColor='';
        disp(['No Base Color']);
        disp(['Marker Color ' markerColor]);
    end
    
    nameDirPts=['DataColor_' markerColor];
    dirSavePts=[imgDir slash  nameDirPts ];
    disp(['Training points to learn color ' markerColor ' will be saved in folder: ' '.' slash   nameDirPts newline ]);
    if ~exist(dirSavePts,'dir'); mkdir(dirSavePts); 
        classList=dir([dirSaveClassifiers slash '*' markerColor '.mat']);
        if (numel(classList)==4)
            ansClass=input(['Classifiers already trained from unknown trained points, overwrite them (Y) or stop (N)?' newline],'s');
            if strcmpi(ansClass, 'N')
                disp(['Ending training data collection and classifiers training']);
                return; end
        end
    else
        disp([nameDirPts ' directory already exist: samples selection will add more training points!' newline]);
    end
    fScreen=5;
    
    disp('List of sample images:')
    for numI=1:size(imgList,1); disp(imgList(numI,1).name); end
  
    %Nhood=8; 
    for numI=1:size(imgList,1)
        imgName=imgList(numI,1).name;
        pos=strfind(imgName,'.');
        info=parseName(imgName);
        
        baseName=imgName(1:pos-1);
        %% load the positions of points already clicked on this image 
        %% to show their number and eventually collect again their color     
        if exist([dirSavePts slash  baseName '_pts.mat'],'file') %#ok<ALIGN>
            load([dirSavePts slash  baseName '_pts.mat']);
        else; ptsOn=[]; ptsOff=[]; ptsCriticalOff=[]; end
        
        answer=input(['img to process: ->' baseName newline...
            'already selected training MARKER points=' num2str(size(ptsOn,1)) newline ...
            'already selected training NOT-MARKER points=' num2str(size(ptsOff,1)) newline...
            'already selected training CRITICAL-NOT-MARKER points=' num2str(size(ptsCriticalOff,1)) newline ...
            'PROCESS THIS IMAGE (Y) or continue with next (N)? (Y/N)' newline ],'s');
        if  strcmpi(answer,'N')
            answerStop=input(['continue processing?'...
                ' (Y for continuing /N for stopping)' newline],'s');
            ptsOn=[]; ptsOff=[]; ptsCriticalOff=[];
            if strcmpi(answerStop,'N'); break; else; continue; end
        else
            if strcmpi(info.ext,'mat')  %#ok<*ALIGN>
                load([imgDir slash imgName]);
            else; IRGB=imread([imgDir slash imgName]); end
      %% load the positions of points already clicked on this image 
      %% to collect again their color     
            IRGB=uint8(IRGB(:,:,1:3));
            scrsz = get(groot,'ScreenSize'); 
    %% SELECT centers of areas where to select ON-marker pixels
            fig=figure('Name', 'SELECT centers of areas where to select ON-marker pixels (double-click or Enter to end insertion)', ...
                'Position',[1 scrsz(4) scrsz(3) scrsz(4)]); hold on; imshow(IRGB); 
            [Xareas , Yareas]= getpts; Xareas=uint32(Xareas);Yareas=uint32(Yareas);
            if ((numel(Xareas)>0) && (numel(Yareas)>0)) 
                close(fig);
                for i=1: size(Xareas,1)
                   xc=Xareas(i); yc=Yareas(i);
                   xs=max(xc-(scrsz(3)/fScreen),1); xe=min(xc+(scrsz(3)/fScreen)-1,size(IRGB,2));
                   ys=max(yc-(scrsz(4)/fScreen),1); ye=min(yc+(scrsz(4)/fScreen-1),size(IRGB,1));
                   fig=figure('Name', 'select MARKER pixels (double-click or Enter to end insertion)', ...
                    'Position',[1 scrsz(4) scrsz(3) scrsz(4)]);
                   clear xc yc; hold on; imshow(IRGB(ys:ye,xs:xe,:));
                   [X,Y]=getpts(fig); close(fig); 
                   pts=[uint32(X)+xs uint32(Y)+ys]; 
                   if ((numel(X)>0) && (numel(Y)>0)) 
                       newpts=pts; clear pts;
                       indDel=find(newpts(:,1)==0 | newpts(:,1)>size(IRGB,2) |...
                           newpts(:,2)==0 | newpts(:,2)>size(IRGB,1));
                       if numel(indDel)>0; newpts(indDel,:)=[]; clear indDel; end
                       ptsOn=[ptsOn;newpts]; clear newpts;
                   end
                   clear X Y xs xe ys ye;
                end
                clear Xareas Yareas;
                ptsOn=unique(ptsOn,'rows');                
            % save data up to now, just in case something goes wrong later
                save([dirSavePts slash baseName '_pts.mat'],'ptsOn','ptsOff','ptsCriticalOff');
            end
     %% SELECT centers of areas where to select OFF-NOT marker pixels
            fig=figure('Name', 'SELECT centers of areas where to select OFF-NOT marker pixels (double-click or Enter to end insertion)', ...
                'Position',[1 scrsz(4) scrsz(3) scrsz(4)]);
            hold on; imshow(IRGB); 
            [Xareas , Yareas]= getpts;
            Xareas=uint32(Xareas); Yareas=uint32(Yareas);
            if ((numel(Xareas)>0) && (numel(Yareas)>0)) 
                close(fig);
                for i=1: size(Xareas,1)
                   xc=Xareas(i); yc=Yareas(i);
                   xs=max(xc-(scrsz(3)/fScreen),1); xe=min(xc+(scrsz(3)/fScreen)-1,size(IRGB,2));
                   ys=max(yc-(scrsz(4)/fScreen),1); ye=min(yc+(scrsz(4)/fScreen)-1,size(IRGB,1));
                   fig=figure('Name', ['select rectangular areas containing NOT MARKER pixels' ...
                       '(click ones to choose clicking on not marker pixels)'], ...
                    'Position',[1 scrsz(4) scrsz(3) scrsz(4)]);
                   clear xc yc; hold on; imshow(IRGB(ys:ye,xs:xe,:));
                   rect=getrect(fig); 
                   xmin=uint32(rect(1)); ymin=uint32(rect(2)); 
                   width=uint32(rect(3)); height=uint32(rect(4));
                   if (width>3 && height>3)
                       X=repmat((xmin:xmin+width-1)',height,1);
                       Y=(repmat((ymin:ymin+height-1)',1,width))'; Y=Y(:);
                       close(fig); flagAreas=true;
                   else; fig.Name=[ 'select NOT MARKER pixels ' ...
                       '(double-click ends insertion)'];
                       [X,Y]=getpts(fig); close(fig); flagAreas=false;
                   end
                   pts=[uint32(X)+xs uint32(Y)+ys]; 
                   if ((numel(X)>0) && (numel(Y)>0)) 
                       if flagAreas; newpts=pts; 
                       else %newpts=[pts; ptsNeighs(pts,Nhood)];
                        newpts=pts; 
                       end
                       clear pts;
                       indDel=find(newpts(:,1)==0 | newpts(:,1)>size(IRGB,2) |...
                           newpts(:,2)==0 | newpts(:,2)>size(IRGB,1));
                       if numel(indDel)>0; newpts(indDel,:)=[]; clear indDel; end
                       ptsOff=[ptsOff;newpts]; clear newpts;
                   end
                   clear X Y;
            %% select NOT MARKED pixels similar to markED pixels or "strange" NOT MARKED PIXELS
            %% THAT SHOULD ABSOLUTELY BE AVOIDED
                   fig=figure('Name', ['select CRITICAL NOT-MARKER pixels (e.g.: similar to marker pixels)' ...
                       '(double-click or Enter to end insertion)'], ...
                    'Position',[1 scrsz(4) scrsz(3) scrsz(4)]);
                   hold on; imshow(IRGB(ys:ye,xs:xe,:));
                   [X,Y]=getpts(fig); close(fig); 
                   pts=[uint32(X)+xs uint32(Y)+ys];
                   clear xs xe ys ye;
                   if ((numel(X)>0) && (numel(Y)>0)) 
                       %newpts=[pts; ptsNeighs(pts,Nhood)]; clear pts;
                       newpts=pts; clear pts;
                       indDel=find(newpts(:,1)==0 | newpts(:,1)>size(IRGB,2) |...
                           newpts(:,2)==0 | newpts(:,2)>size(IRGB,1));
                       if numel(indDel)>0; newpts(indDel,:)=[]; clear indDel; end
                       ptsCriticalOff=[ptsCriticalOff;newpts]; clear newpts;
                   end
                   clear X Y;
                end
                clear Xareas Yareas; 
                ptsOff=unique(ptsOff,'rows');
                ptsCriticalOff=unique(ptsCriticalOff,'rows');
                save([dirSavePts slash baseName '_pts.mat'],'ptsOn','ptsOff','ptsCriticalOff');
                
                disp(['Processed Image: ->' baseName newline...
                'signed ptsMarkers=' num2str(size(ptsOn,1)) newline ...
                'signed ptsNOTMarkers=' num2str(size(ptsOff,1)) newline...
                'signed CRITICAL ptsNOTMarked=' num2str(size(ptsCriticalOff,1))]);
                clear ptsOn ptsOff ptsCriticalOff;
            end
            answerStop=input('continue processing? (Y for continuing /N for stopping) ','s');
            if strcmpi(answerStop,'N'); break; end
        end
        clear RegsF IRGB;
    end

    disp('Collecting training data...');
      collectTrainingData24(imgDir,dirSavePts, dirSaveClassifiers,slash);
    load([dirSavePts slash 'dataColor24_' markerColor '.mat']);
    load([dirSaveClassifiers slash 'Mdltree_BasicColor_' baseColor '.mat']);
    testD=[]; testLab=[];
    if size(ptsOnColors,1)>0
        testD=[testD; ptsOnColors(:,1:3)];
        testLab=[testLab; true(size(ptsOnColors,1),1)];
    end
    if size(ptsOffColors,1)>0
        testD=[testD; ptsOffColors(:,1:3)];
        testLab=[testLab; false(size(ptsOffColors,1),1)];
    end
    if size(ptsCriticalOffColors,1)>0
        testD=[testD; ptsCriticalOffColors(:,1:3)];
        testLab=[testLab; false(size(ptsCriticalOffColors,1),1)];
    end
    if size(testD,1)>0
        disp([newline 'Test Basic Color Classifier on training data']);
        testBasicColorClassifier(Mdltree,testD, testLab);
    end
    
    answerLearn=input('Train Classifiers? Y/N ', 's');
    if strcmpi(answerLearn,'Y')
        dataAnalisys24Feat(ptsOnColors,ptsOffColors,ptsCriticalOffColors, markerColor,dirSaveClassifiers,slash);    
    else; disp('Saving Training set withouth Training the classifiers'); end
end


