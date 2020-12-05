function ClickSamples_TrainClassifiers
% Last Update 04 Oct 2017

    global medFilterSz gaussFilterSigma
    global fScreen scrsz FigPosition msgPosition magFactor handles
    global optMsg
    global indFeatBaseTree
    
    medFilterSz=3;
    gaussFilterSigma=0.5;
    indFeatBaseTree=1:3;
    optMsg.Interpreter = 'tex';
    optMsg.WindowStyle = 'normal';
    warning off;
    curDir=cd;
    
    fScreen=10; scrsz = get(groot,'ScreenSize'); 
    FigPosition=[1 1 scrsz(3)*3 scrsz(4)*3];
    msgPosition=[100 scrsz(4)/2];
    
    magFactor=4000;
    %% faccio selezionare la directory all'utente e raccolgo 
    %% i nomi di tutte le immagini
    imgList=[];
    handles={};
    while numel(imgList)==0
        imgDir=uigetdir('C:\DATI\ace\Images', 'Select folder of training samples');
        imgList=[dir(fullfile(imgDir, '*.tif'));...
            dir(fullfile(imgDir, '*.tiff')); ...
            dir(fullfile(imgDir, '*.jpg')); ...
            dir(fullfile(imgDir, '*.png')); ...
            dir(fullfile(imgDir, '*.svs')); ...
            dir(fullfile(imgDir, '*.bmp'))];
        if numel(imgList)==0; handles{end+1}=msgbox(['no images in folder.' newline...
                '\bfRun again\rm to select another folder'],'Title','ERROR!',optMsg); 
            h=handles{end}; h.Position(1:2)=msgPosition;
        end
    end
     
    Allcolors={};
    %% dai nomi delle immagini di esempio in questa directory
    %% estraggo tutti i colori da imparare 
    for numI=1:size(imgList,1)
            imgName=imgList(numI,1).name;
            pos=strfind(imgName,'.');
            info=parseName(imgName);
            Allcolors=[Allcolors; info.markerColor';];
    end
    AllColors=removeDuplicateColors(Allcolors);
    clear Allcolors;
    for numI=1:numel(AllColors)
        if numel(AllColors{numI}.BaseColor)>0
            if ~exist(fullfile(imgDir,[ 'DataBaseColor_' AllColors{numI}.BaseColor]),'dir')
                mkdir(fullfile(imgDir,[ 'DataBaseColor_' AllColors{numI}.BaseColor]))
            end
        end
        if ~exist(fullfile(imgDir,['DataColor_' AllColors{numI}.Color]),'dir')
            mkdir(fullfile(imgDir,['DataColor_' AllColors{numI}.Color]))
        end
    end
    
    %% Impara tutti i baseColor se non sono già stati imparati
   % showedColors={};
    for numC=1:numel(AllColors)
        baseColor=AllColors{numC}.BaseColor; 
    %    if ismember(baseColor,showedColors); continue; 
    %    else; showedColors{end+1}=baseColor; end
        markerColor=AllColors{numC}.Color; 
        if numel(baseColor)>0
            imgListColor=[dir(fullfile(imgDir, ['*-' baseColor '*.tif'])); ...
            dir(fullfile(imgDir, ['*-' baseColor '*.tiff'])); ...
            dir(fullfile(imgDir, ['*-' baseColor '*.jpg'])); ... 
            dir(fullfile(imgDir, ['*-' baseColor '*.png'])); ...
             dir(fullfile(imgDir, ['*-' baseColor '*.svs']))];
            imgListColor=removeDuplicateFiles(imgListColor);
            disp(['Base Cell Color =  ' baseColor]);
            disp(['Cell Color ' markerColor]);
            dirSaveBase=fullfile(imgDir, ['DataBaseColor_' baseColor]);   
            if exist(fullfile(dirSaveBase, ['Mdltree_' baseColor '.mat']),'file')
                load(fullfile(dirSaveBase, ['Mdltree_' baseColor '.mat']))
                answbaseCol=questdlg(['Base color classifier ' baseColor ...
                    ' already exist' newline...
                    'Train a novel base color classifier, ' ... 
                    'Test this classifier before any decision, ', newline...
                    'skip to next base Color' ...
                    'or quit (Cancel)?'], '', 'Train Novel Classifier', 'Test this classifier',...
                    'Continue to Next Classifier','Continue to Next Classifier');
                close all;
                if (strcmpi(answbaseCol,'Test this classifier'))
                    testbaseColorOnDir(imgListColor,MdlBasetree);
                    answbaseCol=questdlg(['After watching the classifier results for ' baseColor ...
                    'Train a novel base color classifier, ' ... 
                    'skip to next base Color' newline ...
                    'or quit (Cancel)?'], '', 'Train Novel Classifier',...
                    'Continue to Next Classifier','');
                end
                if (strcmpi(answbaseCol,'Train Novel Classifier'))
                    if numel(dir(fullfile(dirSaveBase,'*Colors*_pts.mat')))>0
                        delete(fullfile(dirSaveBase, '*Colors*_pts.mat')); end
                    if exist(fullfile(dirSaveBase,['Mdltree_' baseColor '.mat']),'file')
                        delete(fullfile(dirSaveBase,['Mdltree_' baseColor '.mat']))
                    end
                    trainBaseColorTree(baseColor, dirSaveBase,imgListColor); 
                    clear  Mdltree;
                    load(fullfile(dirSaveBase , ['Mdltree_' baseColor '.mat']));
                    close all;
                elseif (strcmpi(answbaseCol,'')); return;
                else; continue; end
            else
                if ~exist(dirSaveBase ,'dir')
                    mkdir(dirSaveBase)
                end
                if numel(dir(fullfile(dirSaveBase,'*Colors*_pts.mat')))>0
                        answbaseCol=questdlg(['Color Data have been already'...
                    ' collected from artificial images!' newline ...
                    'Collect new color data before training classifier, ' ...
                    'use the already collected data,' newline ...
                    'or quit program (Cancel)?'], '', 'Collect new data', ...
                    'Just train','');
                    if strcmpi(answbaseCol,'Just train') 
                        maxnum=9;
                        load(fullfile(dirSaveBase , 'trainingColors_pts.mat'));
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
                        save(fullfile(dirSaveBase,['Mdltree_' baseColor '.mat']),'MdlBasetree');
                    elseif strcmpi(answbaseCol,'return'); end 
                end
                trainBaseColorTree(baseColor, dirSaveBase,imgListColor); 
                clear mdlTreeBase Mdltree;
            end
            close all;
            clear imgListColor;
        else
            disp('No Base Color');
            disp(['Cell Color ' markerColor]);
        end
    end
   % clear showedColors;
    removeDialogs();
    
    %% Prendi ogni immagine e clicca i suoi samples... alla
    %% fine impari tutti i colori se l'utente vuole
    disp(['List of sample images'])
    for numI=1:size(imgList,1); disp(imgList(numI,1).name); end
    for numI=1:size(imgList,1)
        imgName=imgList(numI,1).name;
        info=parseName(imgName);
        baseName=info.imgname;
        
        if strcmpi(info.ext,'mat')  %#ok<*ALIGN>
            load(fullfile(imgDir , imgName)); %#ok<LOAD>
        else; IRGB=imread(fullfile(imgDir, imgName)); end
        IRGB=uint8(IRGB(:,:,1:3));
        
        for ch = 1: size(IRGB,3); IRGB(:,:,ch) = imgaussfilt(medfilt2(IRGB(:,:,ch), [medFilterSz medFilterSz]), gaussFilterSigma); end
        
        imgShow=IRGB;
        for numC=1:numel(info.markerColor)
            markerColor=info.markerColor{numC}.Color;
            baseColor=info.markerColor{numC}.BaseColor;
            dirSavePts=fullfile(imgDir, ['DataColor_' markerColor]);
            if exist(fullfile(dirSavePts, [baseName '_pts.mat']),'file') 
                    load(fullfile(dirSavePts, [baseName '_pts.mat'])); %#ok<LOAD>
                    ptsNothing=unique([ptsNothing;],'rows');
            else; ptsOn=[]; ptsOff=[]; ptsNothing=[]; cellAreas=[]; end
             
       
            if size(ptsOn,1)>0
                ind=sub2ind([size(IRGB,1),size(IRGB,2)],ptsOn(:,2),ptsOn(:,1));
                bin=false(size(IRGB,1),size(IRGB,2));
                bin(ind)=true; bin = bwperim(bin);
                imgShow(cat(3,bin,bin,bin)) = 255;
                clear ind;
            end
            if size(ptsOff,1)>0
                ind=sub2ind([size(IRGB,1),size(IRGB,2)],ptsOff(:,2),ptsOff(:,1));
                bin=false(size(IRGB,1),size(IRGB,2));
                bin(ind)=true; bin =  bwperim(bin);
                imgShow(cat(3,bin,bin,bin)) = 255;
                clear ind;
            end
            if size(ptsNothing,1)>0
                ind=sub2ind([size(IRGB,1),size(IRGB,2)],ptsNothing(:,2),ptsNothing(:,1));
                bin=false(size(IRGB,1),size(IRGB,2));
                bin(ind)=true; bin = bwperim(bin);
                imgShow(cat(3,bin,bin,bin)) = 0;
                clear ind;
            end
        end
        figure('Name', baseName,'OuterPosition', FigPosition); imshow(imgShow);
        
        answProcImg=questdlg(['img to process: ' baseName newline ...
            'select sample points from this img,' newline ...
            'continue to next img, or ' ...
            'quit program (Cancel)?'],'','Select samples from this image',...
            'Next image','Next image');
        if strcmpi(answProcImg,'Next image')
            continue; 
        elseif strcmpi(answProcImg,''); return; end
        removeDialogs();
        %% SELEZIONO I CENTRI DELLE AREEE DA CUI VERRANNO ESTRATTI I training pixels    
        close all
        msg=['Select centers of areas where ' ...
            'to select pixels belonging to background (not belonging to any cells ' ...
            ' and not marked!) ' ...
            '(double-click or Enter to end insertion)'];
        handles{end+1}=msgbox(msg, 'Title', 'none');
        h=handles{end}; h.Position(1:2)=msgPosition;
        fig=figure('Name', 'SELECT centers of areas for negative training samples selection', ...
            'OuterPosition', FigPosition); hold on; imshow(imgShow, ...
                                'InitialMagnification', magFactor);
        [Xareas , Yareas]= getpts; Xareas=uint32(Xareas); Yareas=uint32(Yareas);
        handles{end+1}=msgbox([num2str(numel(Xareas)) ' areas selected'], 'Title', 'none');
        h=handles{end}; h.Position(1:2)=[msgPosition(1) msgPosition(2)-100];
        if ((numel(Xareas)>0) && (numel(Yareas)>0)) 
            %% SELEZIONO I PUNTI CHE NON CONTENGONO NULLA: SOLO TESSUTO
            close(fig);
            ptsNull=[];
            for i=1: size(Xareas,1)
               xc=Xareas(i); yc=Yareas(i);
               xs=max(xc-(scrsz(3)/fScreen),1); xe=min(xc+(scrsz(3)/fScreen)-1,size(IRGB,2));
               ys=max(yc-(scrsz(4)/fScreen),1); ye=min(yc+(scrsz(4)/fScreen)-1,size(IRGB,1));
               
               figTitle = ['draw polygons areas containing no cells/no colors pixels'];
               msg = ['From the shown figure draw polygons containing' newline ...
                   'tissue pixels containing \bf no cells/no colors \rm' newline ...
                   '(after drawing polygon double-click closes it, ending insertion' newline ...
                   'one-click to avoid drawing polygon' newline ...
                   'one double-click lets you choose to click on each not-marker pixels)'];
               
               resPoly = pointsInPoly(IRGB(ys:ye,xs:xe,:), figTitle, msg);
               if numel(resPoly.points)>0
                   X=resPoly.points(:,1); Y=resPoly.points(:,2);
                   if ((numel(X)>0) && (numel(Y)>0)) 
                       pts=[uint32(X)+xs uint32(Y)+ys];
                       indDel=find(pts(:,1)==0 | pts(:,1)>size(IRGB,2) |...
                           pts(:,2)==0 | pts(:,2)>size(IRGB,1));
                       if numel(indDel)>0; pts(indDel,:)=[]; clear indDel; end
                        ptsNull=[ptsNull;pts]; clear pts indDel X Y;
                   end
               end
               clear X Y xs xe ys ye resPoly;
               
            end
            ptsNothing=unique([ptsNothing; ptsNull],'rows');
            handles{end+1}=msgbox(['Processed Image: ->' baseName newline...
            'clicked pixels with no important color =' ...
                    num2str(size(ptsNull,1))]);
            h=handles{end}; h.Position(1:2)=msgPosition;    
            
        else; ptsNull=[]; end
        removeDialogs()
        clear Xareas Yareas msg
        
        removeDialogs();
        
        labels=true(size(IRGB,1),size(IRGB,2));
        for numC=1:numel(info.markerColor)
            baseColor=info.markerColor{numC}.BaseColor;
            %% se c'è un colore di base mostro solo i pixel non scartati da quel colore!
            if numel(baseColor)>0 
                dirSaveBase=fullfile(imgDir , ['DataBaseColor_' baseColor]);   
                if exist(fullfile(dirSaveBase,['Mdltree_' baseColor '.mat']),'file')
                    load(fullfile(dirSaveBase, ['Mdltree_' baseColor '.mat']))
                    labels=labels | reshape(classifyWithBase(IRGB,MdlBasetree),size(IRGB,1),size(IRGB,2));
                end
            end
        end
        imgShow=IRGB;
        if any(labels(:)); imgShow(~cat(3,labels,labels,labels))=0; end
        
        msg=['From the shown figure select centers of areas where ' ...
            'to select pixels belonging to marked/not marked cells ' ...
            '(double-click or Enter to end insertion)'];
        handles{end+1}=msgbox(msg, 'Title', 'none');
        h=handles{end}; h.Position(1:2)=msgPosition;
        fig=figure('Name', 'SELECT centers of areas for positive training samples selection', ...
            'OuterPosition', FigPosition); hold on; imshow(imgShow, ...
                                'InitialMagnification', magFactor);
        [Xareas , Yareas]= getpts; Xareas=uint32(Xareas); Yareas=uint32(Yareas);
        handles{end+1}=msgbox([num2str(numel(Xareas)) ' areas selected'], 'Title', 'none');
        h=handles{end}; h.Position(1:2)=[msgPosition(1) msgPosition(2)-100];    
        for numC=1:numel(info.markerColor)
            markerColor=info.markerColor{numC}.Color;
            baseColor=info.markerColor{numC}.BaseColor;
            dirSavePts=fullfile(imgDir, ['DataColor_' markerColor]);
            %% load the positions of points already clicked on this image 
            %% to show their number and eventually collect again their color     
            if exist(fullfile(dirSavePts, [baseName '_pts.mat']),'file') 
                load(fullfile(dirSavePts, [baseName '_pts.mat'])); %#ok<LOAD>
                ptsNothing=unique([ptsNothing; ptsNull],'rows');
            else; ptsOn=[]; ptsOff=[]; ptsNothing=ptsNull; cellAreas=[]; end
             
            imgShow=IRGB;
            if size(ptsOn,1)>0
                ind=sub2ind([size(IRGB,1),size(IRGB,2)],ptsOn(:,2),ptsOn(:,1));
                bin=false(size(IRGB,1),size(IRGB,2));
                bin(ind)=true; bin = bwperim(bin);
                imgShow(cat(3,bin,bin,bin)) = 255;
                clear ind;
            end
            if size(ptsNothing,1)>0
                ind=sub2ind([size(IRGB,1),size(IRGB,2)],ptsNothing(:,2),ptsNothing(:,1));
                bin=false(size(IRGB,1),size(IRGB,2));
                bin(ind)=true; bin = bwperim(bin);
                imgShow(cat(3,bin,bin,bin)) = 0;
                clear ind;
            end
            
            if size(ptsOff,1)>0
                ind=sub2ind([size(IRGB,1),size(IRGB,2)],ptsOff(:,2),ptsOff(:,1));
                bin=false(size(IRGB,1),size(IRGB,2));
                bin(ind)=true; bin =  bwperim(bin);
                imgShow(cat(3,bin,bin,bin)) = 128;
                clear ind;
            end
            %% seleziono pixel di cellule con il colore = markerColor
            for i=1: size(Xareas,1)
               X=[]; Y=[];
               xc=Xareas(i); yc=Yareas(i);
               xs=max(xc-(scrsz(3)/fScreen),1); xe=min(xc+(scrsz(3)/fScreen)-1,size(IRGB,2));
               ys=max(yc-(scrsz(4)/fScreen),1); ye=min(yc+(scrsz(4)/fScreen-1),size(IRGB,1));
               szY=ye-ys+1; szX=xe-xs+1;
               
               figTitle = ['select '  markerColor ' colored Cell pixels '];
               msg = ['From the shown figure select \bf'  markerColor newline ...
                   ' \rm colored \bf Cells \rm ' newline ...
                   'by drawing polygons ' ...
                 '(double-click or Enter to close the polygon)' newline ...
                 'drawing cells allows computing the cell area estimate'];
               resPoly = pointsInPoly(imgShow(ys:ye,xs:xe,:), figTitle, msg); 
               if numel(resPoly.points)>0
                   X=resPoly.points(:,1); Y=resPoly.points(:,2);
                   areas=resPoly.areas;
                   if ((numel(X)>0) && (numel(Y)>0)) 
                       pts=[uint32(X)+xs uint32(Y)+ys];
                       clear X Y;
                       indDel=find(pts(:,1)==0 | pts(:,1)>size(IRGB,2) |...
                           pts(:,2)==0 | pts(:,2)>size(IRGB,1));
                       if numel(indDel)>0; pts(indDel,:)=[]; clear indDel; end                       
                       indpts=sub2ind([size(IRGB,1),size(IRGB,2)],pts(:,2),pts(:,1));
                       pts=[pts(labels(indpts),1),pts(labels(indpts),2)];  
                       clear indpts;
                       ptsOn=[ptsOn; pts]; clear pts;
                       cellAreas=[cellAreas; areas]; clear areas;
                   end
               end
               clear xs xe ys ye resPoly;
               
            end
            ptsColors{numC}.ptsNothing=unique(ptsNothing,'rows');
            ptsColors{numC}.ptsOn=unique(ptsOn,'rows');
            ptsOn=unique(ptsOn,'rows');                
            ptsNothing=unique(ptsNothing,'rows');  
            
            save(fullfile(dirSavePts, [baseName '_pts.mat']),'ptsOn','ptsOff','ptsNothing', 'cellAreas');
            
            removeDialogs();
            handles{end+1}=msgbox(['Processed Image: ->' baseName newline...
            'clicked pixels with color ' markerColor ' =' ...
                    num2str(size(ptsOn,1))]);
            h=handles{end}; h.Position(1:2)=msgPosition;    
            clear ptsOn ptsOff;
        end
        clear Xareas Yareas;
        for numC=1:numel(info.markerColor)
            markerColor=info.markerColor{numC}.Color;
            dirSavePts=fullfile(imgDir, ['DataColor_' markerColor]);
            load(fullfile(dirSavePts, [baseName '_pts.mat'])); %#ok<LOAD>
            %% i pixel on degli altri colori presi da questa immagine, sono per forza gli off 
            %% del colore markerColor presi per questa immagine
            for numOtherC=1:numel(info.markerColor)
                if numOtherC~=numC
                    ptsOff=[ptsOff; ptsColors{numOtherC}.ptsOn];
                end
            end
            ptsOff=unique(ptsOff,'rows');
            save(fullfile(dirSavePts, [ baseName '_pts.mat']),'ptsOn','ptsOff','ptsNothing','cellAreas')
        end
        
        clear ptsColors;
        clear IRGB;
        close all;
        answerStop=questdlg(['continue processing, stop collecting training points,' newline ...
            'or quit program (Cancel)?'],'', 'Continue Processing','Stop','Continue Processing');
        if strcmpi(answerStop,'Stop'); break; 
        elseif strcmpi(answerStop,''); return; end
        
    end

   % showedColors={};
    ptsOnKNN = [];
    labs = [];
    flagTrain = true;
    for numC=1:numel(AllColors)
        markerColor=AllColors{numC}.Color;
       % if ismember(markerColor,showedColors); continue; 
       % else; showedColors{end+1}=markerColor; end
        baseColor=AllColors{numC}.BaseColor;
        nameDirPts=['DataColor_' markerColor];
        dirSavePts=fullfile(imgDir ,  nameDirPts );
        if numel(baseColor)>0; dirSaveBase=fullfile(imgDir, ['DataBaseColor_' baseColor]); end
        handles{end+1}=msgbox(['------------------------------' newline ...
            'working on Classifiers for color \bf' markerColor '\rm'...
            newline '------------------------------'], 'Title','none',optMsg);
        
        disp(['------------------------------' newline ...
            'working on Classifiers for color ' markerColor newline...
              '------------------------------']);
        
        if ~exist(dirSavePts,'dir')
            handles{end+1}=msgbox(['Directory: ' dirSavePts ' not existing!!'],'Title', 'WARNING!!'); continue; 
            h=handles{end}; h.Position(1:2)=msgPosition;
        end
        
        ptsList=dir(fullfile(dirSavePts, ['*' markerColor '*_pts.mat']));
        classList=[dir(fullfile(dirSavePts , ['*Mdltree*' markerColor '.mat']))];
        if (numel(classList)>0) 
            answ = questdlg(['Classifiers already trained!' newline...
                        'RETRAIN THEM, ' ...
                        'continue to \bf next color \m,' newline ...
                        'or quit (Cancel)?'],'','Retrain Classifiers',...
                        'Continue to next color','Continue to next color');
            if strcmpi(answ,'Continue to next color') 
                disp('continuo con il prossimo classificatore'); flagTrain=false; 
            elseif strcmpi(answ,''); disp('exit'); return; end 
            
        elseif numel(ptsList)==0
            handles{end+1}=msgbox('No sample points: cannot train any classifier!','Title', 'ERROR!'); 
            h=handles{end}; h.Position(1:2)=msgPosition;
            continue; 
        end
       
        disp('Collecting training data...');
        collectTrainingData24(imgDir,dirSavePts);
        load(fullfile(dirSavePts, ['dataColor24_' markerColor '.mat']));
        testD=[]; testLab=[];
        if size(ptsOnColors,1)>0
            testD=[testD; ptsOnColors(:,1:3)];
            testLab=[testLab; true(size(ptsOnColors,1),1)];
        end
        meanPos=mean(ptsOnColors);
        if size(ptsOffColors,1)>0
            testD=[testD; ptsOffColors(:,1:3)];
            testLab=[testLab; false(size(ptsOffColors,1),1)];
        end
        meanOff=mean(ptsOffColors);
        if size(ptsNothingColors,1)>0
            testD=[testD; ptsNothingColors(:,1:3)];
            testLab=[testLab; false(size(ptsNothingColors,1),1)];
        end
        meanNothing=mean(ptsNothingColors);
        
        save(fullfile(dirSavePts ,['meansDataColor24_' markerColor '.mat']),...
                'meanPos', 'meanOff','meanNothing');

        if size(testD,1)>0 && numel(baseColor)>0
            load(fullfile(dirSaveBase, ['Mdltree_' baseColor '.mat']));     
            disp([newline 'Test Base Color Classifier on training data']);
            testBaseColorClassifier(MdlBasetree,testD, testLab);
        end
        
        labs = [labs; ones(size(ptsOnColors,1),1)*numC];
        ptsOnKNN = [ptsOnKNN; ptsOnColors];
        if flagTrain; dataAnalisys24Feat(ptsOnColors,ptsOffColors, markerColor,dirSavePts); end
        removeDialogs()
    end
    ptsOffKNN=ptsNothingColors;    
    npos=size(ptsOnKNN,1);
    nneg=size(ptsOffKNN,1);
    respKNN=[labs>0;zeros(nneg,1)];
    if nneg>1.5*npos || npos>1.5*nneg %#ok<ALIGN>
        disp(['unbalanced data! npos = ' num2str(npos) ', nneg = ' num2str(nneg)])
        costTree= [0 1.0-(double(nneg)/double(npos+nneg)); ...
                1.0-(double(npos)/double(npos+nneg)) 0]; 
    else; costTree= [0 1; ...
                    1 0]; end
            
    MdlKNN3=fitcknn([ptsOnKNN;ptsOffKNN],respKNN,'NumNeighbors',8);
    MdlKNN2=fitcknn(ptsOnKNN,labs,'NumNeighbors',4);
    maxnum = 15;
    MdlTree3=fitctree([ptsOnKNN;ptsOffKNN],respKNN,'MaxNumSplits',...
        maxnum,'OptimizeHyperparameters','auto');
    MdlTree2=fitctree(ptsOnKNN,labs,'MaxNumSplits',...
        maxnum,'OptimizeHyperparameters','auto');
    nameDirPts=['DataColor_3Class'];
    dirSavePts=fullfile(imgDir,nameDirPts);
    if ~exist(dirSavePts,'dir'); mkdir(dirSavePts); end
    save(fullfile(dirSavePts,'MdlKNN_3Class.mat'),'MdlKNN3');
    save(fullfile(dirSavePts,'MdlKNN_2Class.mat'),'MdlKNN2');
    save(fullfile(dirSavePts,'MdlTree_2Class.mat'),'MdlTree2');
    save(fullfile(dirSavePts,'MdlTree_3Class.mat'),'MdlTree3');
    
    view(MdlTree3,'Mode','graph')
    view(MdlTree2,'Mode','graph')
   
    
    clear ptsOnKNN ptsOffKNN;

end
                                                                                                                          