function MIAQuant_Learn(dirImgs,templates)
% Last Update 05 December 2017
% % Copyright: Elena Casiraghi
% % This software is described in 
% % 
% % A novel computational method for automatic segmentation, quantification 
% % and comparative analysis of immunohistochemically labeled tissue sections
% % Authors: Elena Casiraghi(1), Veronica Huber(2), Marco Frasca(1), Mara Cossa(2), 
% % Matteo Tozzi(3), Licia Rivoltini(2), Biagio Eugenio Leone(4), 
% % Antonello Villa(4,5) and Barbara Vergani(4,5)
% % (1)Department of Computer Science “Giovanni Degli Antoni”, 
% %         Università degli Studi di Milano, Milan, Italy.
% % (2)Unit of Immunotherapy of Human Tumors, Department of Experimental Oncology and Molecular Medicine, 
% %         Fondazione IRCCS Istituto Nazionale dei Tumori, Milan, Italy.
% % (3)Department of medicine and surgery, Vascular Surgery, 
% %         University of Insubria Hospital, Varese, Italy.
% % (4)School of Medicine and Surgery, 
% %         University of Milano Bicocca, Monza, Italy.
% % (5)Consorzio MIA – Microscopy and Image Analysis, 
% %         University of Milano Bicocca, Monza, Italy.
% %
% % BMC BioInformatics
% % 
% % MIAQuant_Learn is freely available for clinical studies, pathological research, and diagnosis.
% % For any trouble refer to 
% % casiraghi@di.unimi.it
% % 
% % If MIAQuant is helpful for your studies/research, please cite the above mentioned article.

    warning off;
    curDir=cd;
    slash='\';
    k = strfind(curDir, slash);
    if numel(k)==0; slash='/'; end
    
    if (nargin==0); dirImgs=uigetdir(...
            ['C:' slash],...
        'Select the img folder'); end %#ok<ALIGN>

    %% CREA LA LISTA DEI MARKERS (cell array templates)
    if (nargin<2)
        lineMarkers=input([newline '-------------------' newline 'Insert the '...
            '(space separated) marker Names (e.g. CD3 CD68 CD163) ' newline],'s');
        pos=strfind(lineMarkers,' ');
        templates={};
        oldPos=0;
        for i=1:numel(pos); templates{i,1}=lineMarkers(oldPos+1:pos(i)-1); oldPos=pos(i); end
        templates{end+1,1}=lineMarkers(oldPos+1:end);
    end
    disp(['DIRECTORY PATHNAME: ' dirImgs]);
    dirInfoImgs=[dirImgs slash 'InfoImgs'];
  %  dirClassifiers=uigetdir([],'Select the folder containing trained classifiers'); 
    dirClassifiers=['.' slash 'TrainedClassifiers'];
    startM=1; startR=1; dimLimitOut=12000; dimLimitIn=3000;  
    factorRed=input([newline '-------------------' newline 'If wanted insert the reduction factor'...
        newline 'e.g: 0.1 for reduction at 10% image size, 0.5 to halve the image size,... ' newline]);
    if numel(factorRed)==0; factorRed=1; end
    dd=input(['insert the experiment identification' newline],'s');
    dirSave=[dirImgs slash 'Exp_Reduction_' num2str(factorRed*100) '_' dd]; 
    methodRed='nearest'; 
    
   
    %% per regTissue;
    threshSmallAreas=round(10*(factorRed)^2);
    crop=true; gaussDev=0.5*factorRed; 
    fsz=round(25*factorRed); if (mod(fsz,2)==0); fsz=fsz+1; end
    %% per aree di massima concentrazione!
    %thrAreaConc=round(1500*(factorRed*1.25)^2);
    thrArea=round(3*(factorRed*1.25)^2);
    %stBig=strel('disk',max(1,double(round(15*factorRed))));
    %stBig2=strel('disk',max(1,double(round(30*factorRed))));
    offset=8;
    answerOnlySeg=input([newline '-------------------' newline 'Do you want REGISTRATION of images +'...
        ' Biomarker Segmentation (press R)' newline ... 
        'or ONLY Biomarker Segmentation (press S)? R/S ' newline],'s');    
   % regFillAnswer=input('Fill holes in tissue areas (Y/N)','s');
   % regFill=strcmpi(regFillAnswer,'Y');
    regFill=true;
    %% per calcolare gli istogrammi!
    thr=input([newline '-------------------' newline ...
            'Insert the distance threshold (thrDist) for computing the minimum-distance histograms' newline...
            '(distance histograms will be computed by considering markers at a distance <= thrDist)' newline]);  
    if numel(thr)==0; threshDist(1)=Inf;
    else; threshDist(1)=thr; end
    threshDist(2)=threshDist(1);
    maxSz=[-1 -1]; fStep=20; fRound=2; fSmooth=round(max(threshDist)/10.);
    templateHists={};
    if strcmpi(answerOnlySeg,'S') 
        manualLandmarks=false;
        automaticRegister=false; answerRegister=false;
        overImgs=input([newline '-------------------' newline ...
        'Estimate markers co-localization and Overlap images for visual marker comparison? (Y/N)' newline],'s');  
        overlapImgs=strcmpi(overImgs,'Y');
        if overlapImgs
            selectROIans=input([newline '-------------------' newline ...
            'Compute co-localization in ROIs selected from overlapped Images ? (Y/N)' newline],'s');  
            selectROI=strcmpi(selectROIans,'Y');
        else; selectROI=false; end
    else
        overlapImgs=true;
        answerRegister=true;
        automaticReg=input([newline '-------------------' newline 'Do you want AUTOMATIC REGISTRATION ' newline 'based on TISSUE SHAPES? Y/N ' newline],'s'); 
        automaticRegister=strcmpi(strtrim(automaticReg),'Y');
        answerManualLand=input([newline '-------------------' newline 'Do you want AUTOMATIC REGISTRATION  ' newline 'based on user-selected LANDMARKS? Y/N ' newline],'s');
        manualLandmarks=strcmpi(strtrim(answerManualLand),'Y');
        selectROIans=input([newline '-------------------' newline ...
            'Compute co-localization in ROIs selected from overlapped Images ? (Y/N)' newline],'s');  
        selectROI=strcmpi(selectROIans,'Y');        
        stReg{1}.factorRed=0.1;
        stReg{2}.factorRed=0.5;
        stReg{3}.factorRed=1;
        stReg{1}.soglia={0.5};
        stReg{2}.soglia={0.5};
        stReg{3}.soglia={0.5};
        stReg{1}.step=0.00001;
        stReg{2}.step=0.00001;
        stReg{3}.step=0.00001;
        stReg{1}.st=strel('disk',max(round(100*factorRed^2),1));
        stReg{2}.st=strel('disk',max(round(23*factorRed^2),1));
        stReg{3}.st=strel('disk',max(round(11*factorRed^2),1));
        regMethod={'translation';'rigid'; 'similarity';'affine'};   
    end
    
    
    if ~exist(dirSave,'dir'); mkdir(dirSave); end
    disp(dirSave);
    dirSaveMarker=[dirSave slash 'Markers'];
    if ~exist(dirSaveMarker,'dir'); mkdir(dirSaveMarker); end
    
    dirSaveHists=[dirSave slash 'Histograms'];
    if ~exist(dirSaveHists,'dir'); mkdir(dirSaveHists); end
    
    nameDensity=[dirSaveMarker slash 'MarkerDensityData.txt'];
    if ~exist(nameDensity,'file'); fidDensity = fopen(nameDensity,'w');
    else; fidDensity = fopen(nameDensity,'a'); end
    fprintf(fidDensity,'directory pathname: %s\n',dirImgs); 
   
    
    nameColoc=[dirSave slash 'MarkerColocalization.txt'];
    if ~exist(nameColoc,'file'); fidColoc = fopen(nameColoc,'w');
    else; fidColoc = fopen(nameColoc,'a'); end
    fprintf(fidColoc,'directory pathname: %s\n',dirImgs); 
   
    
    nameDiffHists=[dirSaveHists slash 'DistanceHistogramDifferences.txt'];
    if ~exist(nameDiffHists,'file'); fidDiffHists = fopen(nameDiffHists,'w');
    else; fidDiffHists = fopen(nameDiffHists,'a'); end
    fprintf(fidDiffHists,'directory pathname: %s\n',dirImgs); 
   
    numZero=2;
    %% SEGMENTO TUTTE LE TISSUE REGIONS e i manual landmarks
    trailer='01';
    fnsAll=[dir([dirImgs slash '*_' templates{1} '_*_' trailer '.tif']);
                dir([dirImgs slash '*_' templates{1} '_*_' trailer '.jpg']);
                dir([dirImgs slash '*_' templates{1} '_*_' trailer '.png']);];
    for numTemp=2: numel(templates)
           tempMarker=templates{numTemp};
           fns=[dir([dirImgs slash '*_' tempMarker '_*_' trailer '.tif']);
               dir([dirImgs slash '*_' tempMarker '_*_' trailer '.jpg']);
               dir([dirImgs slash '*_' tempMarker '_*_' trailer '.png'])];
           fnsAll=[fnsAll; fns];
    end
    strAdd='A';
    for numI=1:numel(fnsAll)
        fName=fnsAll(numI,1).name;
        info=parseName(fName);
        disp(['imgName=' info.patName ...
            ' - #SubImg=' info.numFetta ...
            ' - Marker=' info.markerName ' - Color=' info.markerColor]);
        baseName=[info.patName '_' info.markerName '_' info.markerColor];
        disp(baseName)
        if ~exist([dirSave slash baseName '_' strAdd 'Regs.mat'],'file') || ...
                ~exist([dirSave slash baseName '_' strAdd 'RegsF.mat'],'file') || ...
                ~exist([dirSave slash baseName '_' strAdd 'Ipoly.mat'],'file') || ...
                ~exist([dirSave slash baseName '_' strAdd 'Size.mat'],'file') || ...
                ~exist([dirSave slash baseName '_' strAdd 'bordersOI.mat'],'file') 
            if (factorRed~=1) 
                I=[]; InfoImg=[]; numF=1; strNumF=num2str(numF);
                while(numel(strNumF)<numZero); strNumF=['0' strNumF]; end
                strFetta=[baseName '_' strNumF ]; clear strNumF;
                while exist([dirImgs slash strFetta '.' info.ext],'file')
                    I=[I imresize(imread([dirImgs slash strFetta '.' info.ext]),factorRed,methodRed)];
                    if exist([dirInfoImgs slash strFetta '.' info.ext],'file') 
                        InfoImg=[InfoImg ...
                            imresize(imread([dirInfoImgs slash strFetta '.' info.ext]),factorRed,methodRed)];
                    end; clear strFetta strNumF;
                    numF=numF+1; strNumF=num2str(numF); 
                    while(numel(strNumF)<numZero); strNumF=['0' strNumF]; end 
                    strFetta=[baseName '_' strNumF];
                end
            else I=[]; InfoImg=[]; numF=1; strNumF=num2str(numF);
                while(numel(strNumF)<numZero); strNumF=['0' strNumF]; end %#ok<*AGROW>
                strFetta=[baseName '_' strNumF ]; clear str
                while exist([dirImgs slash strFetta '.' info.ext],'file')
                    I=[I imread([dirImgs slash strFetta '.' info.ext])]; 
                    if exist([dirInfoImgs slash strFetta '.' info.ext],'file')
                        InfoImg=[InfoImg imread([dirInfoImgs slash strFetta '.' info.ext])];
                    end; clear strNumF strFetta;
                    numF=numF+1; strNumF=num2str(numF); 
                    while(numel(strNumF)<numZero); strNumF=['0' strNumF]; end 
                    strFetta=[baseName '_' strNumF];
                end
            end
            I=I(:,:,1:3);
            sz=regTissue(I,InfoImg,baseName, dirSave,strAdd, crop,regFill,fsz,gaussDev, threshSmallAreas,slash);
            clear I;
            maxSz=max(maxSz, sz);
            save([dirSave slash strAdd 'maxSz.mat'],'maxSz');
        end
    end
    
    if numel(templates)>1 && (overlapImgs)
        maxSz=[-1,-1];
        %% PROCESS ALL THE IMAGES OF THE SAME PATIENT IN ORDER
        %% TO MAKE THE SIZE OF ALL THE BIOMARKER IMAGES EQUAL
        %% the same patient will have images of the same size
        fnsFirst=[dir([dirImgs slash '*' templates{1} '_*_' trailer '.tif']);
                    dir([dirImgs slash '*' templates{1} '_*_' trailer '.jpg']);
                    dir([dirImgs slash '*' templates{1} '_*_' trailer '.png'])];
        oldstrAdd=strAdd; strAdd='B';
        for numI=1:numel(fnsFirst)
            fName=fnsFirst(numI,1).name;
            info=parseName(fName);
            strMarker=[info.patName];
            listImgs=dir([dirSave slash strMarker '_*_*_' strAdd 'RegsF.mat']); clear strMarker;
            if size(listImgs,1)<size(templates,1)
                % non ci sono imgs con questa estensione e devo quindi
                % portarle tutte alla stessa estensione!
                szM=[0 0];
                disp(['-------------------------------------------'...
                    newline 'Make all the size equals for imgs of sample ' newline ...
                    info.patName  '_anyMarker_anyColor'   newline ....
                      '-------------------------------------------']);
                for numTemp=1: numel(templates)
                    tempMarker=templates{numTemp};
                    strMarker=[info.patName '_' tempMarker '_*'];
                    fnsImg=dir([dirSave slash strMarker '_' oldstrAdd 'Size.mat']);
                    if numel(fnsImg)>0
                        strR=load([dirSave slash fnsImg(1,1).name]);
                        szM=max(szM,strR.sz); clear strR; clear fnsImg;
                    else
                        disp(['file ' '...\' strMarker '_' oldstrAdd 'Size.mat' ' not existent']);
                    end
                end    
                maxSz=max(maxSz, szM);
                save([dirSave slash strAdd 'maxSz.mat'],'maxSz');
                Regs=false(maxSz);
                RegsF=false(maxSz);
                Ipoly=false(maxSz);
                bordersOI=false(maxSz);
                IRGB=uint8(zeros(maxSz(1),maxSz(2),3)); 
                % porto immagini della stessa fetta ma di marker diversi alla
                % stessa dimensione!
                for numTemp=1: numel(templates)
                    tempMarker=templates{numTemp};
                    strMarker=[info.patName '_' tempMarker '_*'];
                    fnsImg=dir([dirSave slash strMarker '_' oldstrAdd 'Regs.mat']);
                    if numel(fnsImg)>0
                        clear strMarker;
                        infMarker=parseName(fnsImg(1,1).name);
                        strMarker=[info.patName '_' tempMarker '_' infMarker.markerColor];
                        clear infMarker fnsImg;
                        strR=load([dirSave slash strMarker '_' oldstrAdd 'Regs.mat']);
                        R=strR.Regs; 
                        szR=size(R); Regs(1:szR(1),1:szR(2))=R;
                        save([dirSave slash strMarker '_' strAdd 'Regs.mat'],'Regs');
                        Regs(:,:)=false; clear StrR R;
                        strR=load([dirSave slash strMarker '_' oldstrAdd 'RegsF.mat']);
                        R=strR.RegsF; RegsF(1:szR(1),1:szR(2))=R;
                        save([dirSave slash strMarker '_' strAdd 'RegsF.mat'],'RegsF');
                        RegsF(:,:)=false; clear R StrR;
                        strR=load([dirSave slash strMarker '_' oldstrAdd 'Ipoly.mat']);
                        R=strR.Ipoly; Ipoly(1:szR(1),1:szR(2))=R;
                        save([dirSave slash strMarker '_' strAdd 'Ipoly.mat'],'Ipoly');
                        Ipoly(:,:)=false; clear StrR R;
                        strR=load([dirSave slash strMarker '_' oldstrAdd 'bordersOI.mat']);
                        R=strR.bordersOI; bordersOI(1:szR(1),1:szR(2))=R;
                        save([dirSave slash strMarker '_' strAdd 'bordersOI.mat'],'bordersOI');
                        bordersOI(:,:)=false; clear StrR R;
                        str1=load([dirSave slash strMarker  '_' oldstrAdd 'IRGB1.mat']);
                        str2=load([dirSave slash strMarker  '_' oldstrAdd 'IRGB2.mat']);
                        str3=load([dirSave slash strMarker  '_' oldstrAdd 'IRGB3.mat']);
                        str4=load([dirSave slash strMarker  '_' oldstrAdd 'IRGB4.mat']);
                        IRGB(1:szR(1),1:szR(2),:)=[str1.IRGB1 str2.IRGB2; str3.IRGB3 str4.IRGB4];
                        clear str1 str2 str3 str4;
                        IRGB1=IRGB(1:round(szM(1)/2),1:round(szM(2)/2),:);
                        IRGB2=IRGB(1:round(szM(1)/2),round(szM(2)/2)+1:end,:);
                        IRGB3=IRGB(round(szM(1)/2)+1:end,1:round(szM(2)/2),:);
                        IRGB4=IRGB(round(szM(1)/2)+1:end,round(szM(2)/2)+1:end,:);
                        IRGB(:)=0;
                        save([dirSave slash strMarker  '_' strAdd 'IRGB1.mat'], 'IRGB1');
                        save([dirSave slash strMarker  '_' strAdd 'IRGB2.mat'], 'IRGB2');
                        save([dirSave slash strMarker  '_' strAdd 'IRGB3.mat'], 'IRGB3');
                        save([dirSave slash strMarker  '_' strAdd 'IRGB4.mat'], 'IRGB4');
                        clear IRGB1 IRGB2 IRGB3 IRGB4;
                    end
                end
                clear IRGB Regs RegsF Ipoly bordersOI;
            else 
                disp(['-------------------------------------------'...
                    newline 'Size equal for Imgs: ' newline ...
                    info.patName  '_anyMarker_'   newline ....
                      '-------------------------------------------']);
            end
            clear listImgs strMarker;
        end
        
        maxSz=[-1 -1]; 
        clear fnsFirst; 
    end

    if answerRegister && numel(templates)>1
        if (automaticRegister)
            %% IF REQUESTED PERFORM Multiscalle Hierarchical shape registration
            val=uint8(round(255/3)*2);
            valcheck=val;
            disp(['Multiscale Registration with ' ...
                num2str(numel(stReg)) ' detail levels']);
            %% COPY ALL THE IMAGES TO CHANGE PREEXTENSION ("B" into "C")
             oldstrAdd=strAdd; strAdd='C';
             
            copyfile([dirSave slash oldstrAdd 'maxSz.mat'],[dirSave slash strAdd 'maxSz.mat']);
            for numI=1:numel(fnsAll)
                fName=fnsAll(numI,1).name;
                info=parseName(fName);
                baseName=[info.patName '_' info.markerName '_' info.markerColor];
                strMarker=[info.patName];
                listImgs=dir([dirSave slash strMarker '_*_*_' strAdd 'RegsF.mat']); clear strMarker;
                if size(listImgs,1)<size(templates,1)
                    disp([ num2str(numI) '-> copying img:' baseName ' from ext ' oldstrAdd ' to ext ' strAdd]);
                    copyfile([dirSave slash baseName '_' oldstrAdd 'IRGB1.mat'],...
                        [dirSave slash baseName  '_' strAdd 'IRGB1.mat']);  
                    copyfile([dirSave slash baseName '_' oldstrAdd 'IRGB2.mat'],...
                        [dirSave slash baseName  '_' strAdd 'IRGB2.mat']);  
                    copyfile([dirSave slash baseName '_' oldstrAdd 'IRGB3.mat'],...
                        [dirSave slash baseName  '_' strAdd 'IRGB3.mat']);  
                    copyfile([dirSave slash baseName '_' oldstrAdd 'IRGB4.mat'],...
                        [dirSave slash baseName  '_' strAdd 'IRGB4.mat']);  
                    copyfile([dirSave slash baseName '_' oldstrAdd 'Regs.mat'],...
                        [dirSave slash baseName  '_' strAdd 'Regs.mat']);  
                    copyfile([dirSave slash baseName '_' oldstrAdd 'RegsF.mat'],...
                        [dirSave slash baseName  '_' strAdd 'RegsF.mat']);  
                    copyfile([dirSave slash baseName '_' oldstrAdd 'Ipoly.mat'],...
                        [dirSave slash baseName  '_' strAdd 'Ipoly.mat']);
                    copyfile([dirSave slash baseName '_' oldstrAdd 'bordersOI.mat'],...
                        [dirSave slash baseName  '_' strAdd 'bordersOI.mat']);
                else
                    disp(['-------------------------------------------'...
                            newline 'Registration Steps have been already executed on sample ' newline ...
                            info.patName  '_anyMarker_'   newline ....
                          '-------------------------------------------']);
                end
                clear listImgs strMarker;
            end
            maxSz=[-1,-1];
            if manualLandmarks; endR=numel(stReg);
            else; endR=numel(stReg); end
            templatesUse=templates;
            for numFactorRed=startR:endR
                fRedRegister=stReg{numFactorRed}.factorRed;
                disp(['Registration at detail level=' num2str(fRedRegister)]);
                clear st; st=stReg{numFactorRed}.st;
                ind=randperm(numel(templatesUse),numel(templatesUse));
                if numFactorRed==startR
                    % al primo giro tengo fisso il primo template
                    ind(ind==1)=[];
                    ind=[1 ind]; end
                templatesUse=templatesUse(ind);
                clear ind;
                disp(['ordered templates:'; templatesUse]);
                for numTemp=startM: numel(templatesUse)
                    tempMarker=templatesUse{numTemp};
                    %% Allinea ogni immagine al template!
                    for numI=1:numel(fnsAll) 
                        fName=fnsAll(numI,1).name;
                        info=parseName(fName);
                        strMarker=[info.patName];
                        listImgs=dir([dirSave slash strMarker '_*_*_' 'DRegsF.mat']); clear strMarker;
                        if size(listImgs,1)<size(templates,1)
                            baseName=[info.patName '_' info.markerName '_' info.markerColor];
                            if (~strcmp(info.markerName,tempMarker))     
                               %%% se non il template uso le Areas in template e le cerco con template matching 
                               %%% vicino a quelle segnate, MA dopo che ho
                               %%% registrato le imgs alla corrispettiva template!        
                               %disp(['Align to marker']);
                               %%% RegsF_marker
                               strBef=[info.patName];
                               fnsImg=dir([dirSave slash  strBef '_' tempMarker '_*_' strAdd 'Regs.mat']);
                               infMarker=parseName(fnsImg(1,1).name);
                               strAfter=infMarker.markerColor; clear infMarker fnsImg;
                               StrRegs_marker=load([dirSave slash  strBef '_' tempMarker '_' strAfter '_' strAdd 'Regs.mat']);
                               Regs_marker=logical(StrRegs_marker.Regs);  
                               StrRegsF_marker=load([dirSave slash  strBef '_' tempMarker '_' strAfter '_' strAdd 'RegsF.mat']);
                               RegsF_marker=logical(StrRegsF_marker.RegsF); 
                               clear StrRegs_marker StrRegsF_marker; 
                               % carico le var della img da analizzare
                               load([dirSave slash baseName '_'  strAdd 'Regs.mat']); 
                               load([dirSave slash baseName '_'  strAdd 'RegsF.mat']);  
                               load([dirSave slash baseName '_'  strAdd 'Ipoly.mat']);  
                               load([dirSave slash baseName '_'  strAdd 'bordersOI.mat']);
                               load([dirSave slash baseName '_'  strAdd 'IRGB1.mat']);
                               load([dirSave slash baseName '_'  strAdd 'IRGB2.mat']);
                               load([dirSave slash baseName '_'  strAdd 'IRGB3.mat']);
                               load([dirSave slash baseName '_'  strAdd 'IRGB4.mat']);
                               IRGB=[IRGB1 IRGB2; IRGB3 IRGB4];
                               clear IRGB1 IRGB2 IRGB3 IRGB4;                  
                               Regs=logical(Regs); 
                               RegsF=logical(RegsF);
                               Ipoly=logical(Ipoly);
                               bordersOI=logical(bordersOI);
                               szTemp=size(Regs_marker);
                               szImg=size(Regs);
                               if ((szTemp(1)~=size(Regs,1)) || (szTemp(2)~=size(Regs,2)))
                                   disp('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
                                   disp('!!!TEMPLATE DIMENSIONS DIFFER FROM IMAGE DIMENSION!!!');
                                   disp('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
                               end
                               ROut=imref2d(szTemp);               
                               imgtemp=uint8(Regs_marker)*val/2+uint8(RegsF_marker)*val/2+...
                                   (uint8(RegsF_marker)-uint8(imerode(RegsF_marker,st)))*val/2;%+...
                               % uint8(Ipoly_marker)+...
                               imgmove=uint8(Regs)*val/2+uint8(RegsF)*val/2+...
                                   (uint8(RegsF)-uint8(imerode(RegsF,st)))*val/2; %+...
                                   % uint8(Ipoly);
                               if isfinite(valcheck) %#ok<ALIGN>
                                   imove=imresize(imgmove,fRedRegister,'Method',methodRed);
                                   itemp=imresize(imgtemp,fRedRegister,'Method',methodRed);
                                   resStruct=kappa(confusionmat(imove(:)>0,itemp(:)>0));             
                                   resStruct2=kappa(confusionmat(imove(:)==val,itemp(:)==val));
                                   kappaBOld=mean([resStruct2.k;resStruct.k]); clear resStruct;
                                   corrOld=mean([corr2(imove,itemp);corr2(imove==val,itemp==val)]);
                               else; kappaBOld=0; corrOld=0; end
                               %% applica tutti i metodi di registrazione gerarchicamente
                               for nReg=1:numel(regMethod)
                                   strMethod=regMethod{nReg};
                                   RegStruct=registrazioneSingola(imgtemp,imgmove,...
                                       strMethod,fRedRegister,methodRed,valcheck);
                                   if isfinite(valcheck) %#ok<ALIGN>
                                       kappaB=RegStruct.kappa; corr=RegStruct.corr; 
                                       flagKappa=(kappaB>=kappaBOld+stReg{numFactorRed}.step);
                                       flagCorr=(corr>=corrOld+stReg{numFactorRed}.step);
                                   else; flagKappa=true; flagCorr=true; end
                                   moving=double(RegStruct.moved);
                                   flagStd=(std(moving(:))>0.1);
                                   if ((flagKappa || flagCorr) && flagStd) 
                                       disp(['REGISTRATION WITH ' upper(strMethod)]);
                                       if isfinite(valcheck); kappaBOld=kappaB; corrOld=corr; end
                                       tform=RegStruct.tform;
                                       RIn=imref2d(szImg);
                                       Regs=logical(imwarp(Regs,RIn,tform,methodRed,...
                                           'OutputView',ROut));
                                       Regs=logical(bwareaopen(Regs,threshSmallAreas));
                                       RegsF=logical(imwarp(RegsF,RIn,tform,methodRed,...
                                       'OutputView',ROut));               
                                       RegsF=logical(bwareaopen(RegsF,threshSmallAreas));
                                       Ipoly=logical(imwarp(Ipoly,RIn,tform,methodRed,...
                                       'OutputView',ROut));               
                                       Ipoly=logical(bwareaopen(Ipoly,threshSmallAreas));
                                       bordersOI=logical(imwarp(bordersOI,RIn,tform,methodRed,...
                                       'OutputView',ROut));    
                                       if any(bordersOI(:))
                                        bordersOI=logical(bwareaopen(bordersOI,threshSmallAreas)); end
                                       for ch=1:size(IRGB,3)  %#ok<ALIGN>
                                           img(:,:,ch)=uint8(imwarp(IRGB(:,:,ch),RIn,...
                                               tform,methodRed,'OutputView',ROut)); end
                                       clear IRGB; IRGB=img; clear img; 
                                       clear RIn tform kappaB moving RegStruct imgmove;
                                       % imgtemp rimane uguale ma imgmove cambia!!
                                       imgmove=uint8(Regs)*val/2+uint8(RegsF)*val/2+...
                                            (uint8(RegsF)-uint8(imerode(RegsF,st)))*val/2;
                                   else;  disp(['no registration with ' strMethod]); end
                                   clear szImg;  szImg=size(Regs);
                                   clear RegStruct moving flagKappa flagCorr flagStd;
                                   maxSz=max(maxSz, szImg); 
                                   save([dirSave slash strAdd 'maxSz.mat'],'maxSz');
                               end
                               %% ora controlla che non ci siano probs di dimensione 
                               if ((szTemp(1)~=size(Regs,1)) || (szTemp(2)~=size(Regs,2)))
                                   disp('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
                                   disp('!!!TEMPLATE DIMENSIONS DIFFER FROM IMAGE DIMENSION!!!');
                                   disp('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');           
                               else
                                   save([dirSave slash baseName '_' strAdd 'Regs.mat'],'Regs'); 
                                   save([dirSave slash baseName '_' strAdd 'RegsF.mat'],'RegsF'); 
                                   save([dirSave slash baseName '_' strAdd 'Ipoly.mat'],'Ipoly');
                                   save([dirSave slash baseName '_' strAdd 'bordersOI.mat'],'bordersOI'); 
                                   sz=size(Regs); 
                                   IRGB1=IRGB(1:round(sz(1)/2),1:round(sz(2)/2),:);
                                   IRGB2=IRGB(1:round(sz(1)/2),round(sz(2)/2)+1:end,:);
                                   IRGB3=IRGB(round(sz(1)/2)+1:end,1:round(sz(2)/2),:);
                                   IRGB4=IRGB(round(sz(1)/2)+1:end,round(sz(2)/2)+1:end,:);
                                   save([dirSave slash baseName  '_' strAdd 'IRGB1.mat'], 'IRGB1');
                                   save([dirSave slash baseName  '_' strAdd 'IRGB2.mat'], 'IRGB2');
                                   save([dirSave slash baseName  '_' strAdd 'IRGB3.mat'], 'IRGB3');
                                   save([dirSave slash baseName  '_' strAdd 'IRGB4.mat'], 'IRGB4');  
                                   clear IRGB1 IRGB2 IRGB3 IRGB4 sz Regs RegsF;
                                   clear RegsF_marker Regs_marker Ipoly_marker Regs RegsF Ipoly;
                               end
                           end
                           clear szImg szTemp;
                           clear Regs RegsF IRGB Ipoly bordersOI;
                           close all
                           save([dirSave slash strAdd 'maxSz.mat'],'maxSz');
                        else
                            disp(['-------------------------------------------'...
                            newline 'Images of sample ' newline ...
                            info.patName  ' have been already registered'   newline ....
                                '-------------------------------------------']);
                        end
                        clear listImgs strMarker;
                    end    
                    close all; clear fns;
                end
            end 
            %% TERMINATA LA REGISTRAZIONE CON PROCUSTE!!

            maxSz=[-1 -1]; 
            oldstrAdd=strAdd; strAdd='D';
            copyfile([dirSave slash oldstrAdd 'maxSz.mat'],[dirSave slash strAdd 'maxSz.mat']);
            for numI=1:numel(fnsAll)
                fName=fnsAll(numI,1).name;
                info=parseName(fName);
                strMarker=[info.patName];
                listImgs=dir([dirSave slash strMarker '_*_*_' strAdd 'RegsF.mat']); clear strMarker;
                if size(listImgs,1)<size(templates,1)
                    baseName=[info.patName '_' info.markerName '_' info.markerColor];   
                    copyfile([dirSave slash baseName '_' oldstrAdd 'IRGB1.mat'],...
                        [dirSave slash baseName  '_' strAdd 'IRGB1.mat']);  
                    copyfile([dirSave slash baseName '_' oldstrAdd 'IRGB2.mat'],...
                        [dirSave slash baseName  '_' strAdd 'IRGB2.mat']);  
                    copyfile([dirSave slash baseName '_' oldstrAdd 'IRGB3.mat'],...
                        [dirSave slash baseName  '_' strAdd 'IRGB3.mat']);  
                    copyfile([dirSave slash baseName '_' oldstrAdd 'IRGB4.mat'],...
                        [dirSave slash baseName  '_' strAdd 'IRGB4.mat']);  
                    copyfile([dirSave slash baseName '_' oldstrAdd 'Regs.mat'],...
                        [dirSave slash baseName  '_' strAdd 'Regs.mat']);  
                    copyfile([dirSave slash baseName '_' oldstrAdd 'RegsF.mat'],...
                        [dirSave slash baseName  '_' strAdd 'RegsF.mat']);  
                    copyfile([dirSave slash baseName '_' oldstrAdd 'Ipoly.mat'],...
                        [dirSave slash baseName  '_' strAdd 'Ipoly.mat']); 
                    copyfile([dirSave slash baseName '_' oldstrAdd 'bordersOI.mat'],...
                        [dirSave slash baseName  '_' strAdd 'bordersOI.mat']);
                    load([dirSave slash baseName '_' strAdd 'Ipoly.mat']);
                    if ~any(Ipoly(:)) 
                        disp(['No registration with manually selected landmarks for ' baseName]); end
                end
                clear listImgs strMarker;
            end

            if ~(manualLandmarks); clear templatesUse; end
           
        else; disp(['No automatic registration of shapes']); end
        
        if (manualLandmarks) %#ok<ALIGN>
            %% USO I TRIANGOLI MANUALI ORA!!!
            %% COPY ALL THE IMAGES TO CHANGE PREEXTENSION 
            %% ("B" into "E-F" if MH registration has not been performed)
            %% ("D" into "E-F" if MH registration has been performed)
            if automaticRegister; oldstrAdd=strAdd; strAdd='F';
            else; oldstrAdd=strAdd; strAdd='E'; end
            
            copyfile([dirSave slash oldstrAdd 'maxSz.mat'],[dirSave slash strAdd 'maxSz.mat']);
            for numI=1:numel(fnsAll)
                fName=fnsAll(numI,1).name;
                info=parseName(fName);
                strMarker=[info.patName];
                listImgs=dir([dirSave slash strMarker '_*_*_' strAdd 'RegsF.mat']); clear strMarker;
                baseName=[info.patName '_' info.markerName '_' info.markerColor];     
                if size(listImgs,1)<size(templates,1)
                    flagManual='true'; 
                    copyfile([dirSave slash baseName '_' oldstrAdd 'IRGB1.mat'],...
                        [dirSave slash baseName  '_' strAdd 'IRGB1.mat']);  
                    copyfile([dirSave slash baseName '_' oldstrAdd 'IRGB2.mat'],...
                        [dirSave slash baseName  '_' strAdd 'IRGB2.mat']);  
                    copyfile([dirSave slash baseName '_' oldstrAdd 'IRGB3.mat'],...
                        [dirSave slash baseName  '_' strAdd 'IRGB3.mat']);  
                    copyfile([dirSave slash baseName '_' oldstrAdd 'IRGB4.mat'],...
                        [dirSave slash baseName  '_' strAdd 'IRGB4.mat']);  
                    copyfile([dirSave slash baseName '_' oldstrAdd 'Regs.mat'],...
                        [dirSave slash baseName  '_' strAdd 'Regs.mat']);  
                    copyfile([dirSave slash baseName '_' oldstrAdd 'RegsF.mat'],...
                        [dirSave slash baseName  '_' strAdd 'RegsF.mat']);  
                    copyfile([dirSave slash baseName '_' oldstrAdd 'Ipoly.mat'],...
                        [dirSave slash baseName  '_' strAdd 'Ipoly.mat']); 
                    copyfile([dirSave slash baseName '_' oldstrAdd 'bordersOI.mat'],...
                        [dirSave slash baseName  '_' strAdd 'bordersOI.mat']);
                    load([dirSave slash baseName '_' strAdd 'Ipoly.mat']);
                    if ~any(Ipoly(:)) 
                        disp(['No registration with manually selected landmarks for ' baseName]); end
                else
                    flagManual=false;
                end
                save([dirSave slash baseName '_' strAdd 'flagManual.mat'],'flagManual');
                clear listImgs strMarker;
            end
            val=255;
            numFactorRed=numel(stReg);
            if ~automaticRegister; templatesUse=templates; end
            fRedRegister=stReg{numFactorRed}.factorRed;
            disp(['Hierarchical registration based on Manual Landmarks at detail level=' num2str(fRedRegister)]);
            ind=randperm(numel(templatesUse),numel(templatesUse));
            ind(ind==1)=[];
            ind=[1 ind];
            templatesUse=templatesUse(ind);
            clear ind;
            disp(['ordered templates:'; templatesUse]);
            for numTemp=startM: numel(templatesUse)
                tempMarker=templatesUse{numTemp};
                for numI=1:numel(fnsAll) 
                    fName=fnsAll(numI,1).name;
                    info=parseName(fName);
                    load([dirSave slash baseName '_' strAdd 'flagManual.mat']);
                    if flagManual
                        baseName=[info.patName '_' info.markerName '_' info.markerColor];
                        if (~strcmp(info.markerName,tempMarker))                         
                           strBef=[info.patName ];
                           fnsImg=dir([dirSave slash  strBef '_' tempMarker '_*_' strAdd 'Ipoly.mat']);
                           infMarker=parseName(fnsImg(1,1).name);
                           strAfter=infMarker.markerColor; clear infMarker fnsImg;
                           StrTr_marker=load([dirSave slash  strBef '_' tempMarker '_' strAfter '_' strAdd 'Ipoly.mat']);
                           Ipoly_marker=logical(StrTr_marker.Ipoly);
                           if ~any(Ipoly_marker(:))
                               clear StrTr_marker Ipoly_marker strBef;
                               continue; end %questo marker non va usato come template perchè non ha manual landmarks 
                           StrRegs_marker=load([dirSave slash  strBef '_' tempMarker '_' strAfter '_' strAdd 'Regs.mat']);
                           Regs_marker=logical(StrRegs_marker.Regs);  
                           StrRegsF_marker=load([dirSave slash  strBef '_' tempMarker '_' strAfter '_' strAdd 'RegsF.mat']);
                           RegsF_marker=logical(StrRegsF_marker.RegsF); 
                           clear StrRegs_marker StrRegsF_marker;
                           clear StrRegs_marker StrRegsF_marker StrTr_marker; 
                           Ipoly_marker(~RegsF_marker)=false;
                           load([dirSave slash baseName '_'  strAdd 'Ipoly.mat']); 
                           if ~any(Ipoly(:)); clear Ipoly RegsF_marker Regs_marker; 
                               continue; end %questa marker non ha manual landmarks ... 
                                                %non si può registrare con i poligoni!
                           % carico le var della img da analizzare
                           load([dirSave slash baseName '_'  strAdd 'bordersOI.mat']); 
                           load([dirSave slash baseName '_'  strAdd 'Regs.mat']); 
                           load([dirSave slash baseName '_'  strAdd 'RegsF.mat']);  
                           load([dirSave slash baseName '_'  strAdd 'IRGB1.mat']);
                           load([dirSave slash baseName '_'  strAdd 'IRGB2.mat']);
                           load([dirSave slash baseName '_'  strAdd 'IRGB3.mat']);
                           load([dirSave slash baseName '_'  strAdd 'IRGB4.mat']);
                           IRGB=[IRGB1 IRGB2; IRGB3 IRGB4];
                           clear IRGB1 IRGB2 IRGB3 IRGB4;
                           Regs=logical(Regs); 
                           RegsF=logical(RegsF);
                           Ipoly=logical(Ipoly);
                           Ipoly(~RegsF)=false;
                           szTemp=size(Regs_marker);
                           szImg=size(Regs);
                           if ((szTemp(1)~=size(Regs,1)) || (szTemp(2)~=size(Regs,2)))
                                disp('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
                               disp('!!!TEMPLATE DIMENSIONS DIFFER FROM IMAGE DIMENSION!!!');
                               disp('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
                               dbstop; end
                           ROut=imref2d(szTemp);  
                           %scalatura a scala del marker
                           propsTemp=regionprops(Ipoly_marker,'MajorAxisLength');
                           props=regionprops(Ipoly,'MajorAxisLength');
                           scaling=propsTemp.MajorAxisLength/props.MajorAxisLength;
                           Ipoly=imresize(Ipoly,scaling,'method','nearest');
                           RegsF=imresize(RegsF,scaling,'method','nearest');
                           Regs=imresize(Regs,scaling,'method','nearest');
                           bordersOI=imresize(bordersOI,scaling,'method','nearest');
                           IRGB=imresize(IRGB,scaling,'method','nearest');
                           %rotazione a rotazione del marker
                           propsTemp=regionprops(Ipoly_marker,'Orientation');
                           props=regionprops(Ipoly,'Orientation');
                           rotAngle=propsTemp.Orientation-props.Orientation;
                           Ipoly=imrotate(Ipoly,rotAngle,'nearest');
                           RegsF=imrotate(RegsF,rotAngle,'nearest');
                           Regs=imrotate(Regs,rotAngle,'nearest');
                           bordersOI=imrotate(bordersOI,rotAngle,'nearest'); 
                           IRGB=imrotate(IRGB,rotAngle,'nearest');
                           [y,x]=find(RegsF);
                           Ipoly=Ipoly(min(y):max(y),min(x):max(x));
                           RegsF=RegsF(min(y):max(y),min(x):max(x));
                           Regs=Regs(min(y):max(y),min(x):max(x));
                           bordersOI=bordersOI(min(y):max(y),min(x):max(x));
                           IRGB=IRGB(min(y):max(y),min(x):max(x),:);
                           %resize a dimensione del marker
                           Ipoly=imresize(Ipoly,[size(Ipoly_marker,1),size(Ipoly_marker,2)]);
                           RegsF=imresize(RegsF,[size(Ipoly_marker,1),size(Ipoly_marker,2)]);
                           Regs=imresize(Regs,[size(Ipoly_marker,1),size(Ipoly_marker,2)]);
                           bordersOI=imresize(bordersOI,[size(Ipoly_marker,1),size(Ipoly_marker,2)]);
                           IRGB=imresize(IRGB,[size(Ipoly_marker,1),size(Ipoly_marker,2)]);
                           % registrazione
                           imgtemp=uint8(Ipoly_marker)*val;
                           imgmove=uint8(Ipoly)*val;
                           strfactk=kappa(confusionmat(imgtemp(:)>0,imgmove(:)>0));
                           factk=strfactk.k; clear strfactk;
                           for nReg=1:numel(regMethod)
                               strMethod=regMethod{nReg};
                               RegStruct=registrazioneSingola(imgtemp,imgmove,...
                                   strMethod,fRedRegister,methodRed,NaN);
                               moving=double(RegStruct.moved);
                               strfactk=kappa(confusionmat(imgtemp(:)>0,moving(:)>0));
                               flagStd=(std(moving(:))>0.1) && (strfactk.k>factk);
                               if (flagStd) 
                                   factk=strfactk.k;
                                   clear strfactk;
                                   disp(['REGISTRATION WITH ' upper(strMethod)]);
                                   tform=RegStruct.tform;
                                   RIn=imref2d(szImg);
                                   Regs=logical(imwarp(Regs,RIn,tform,methodRed,...
                                       'OutputView',ROut));
                                   Regs=logical(bwareaopen(Regs,threshSmallAreas));
                                   RegsF=logical(imwarp(RegsF,RIn,tform,methodRed,...
                                   'OutputView',ROut));               
                                   RegsF=logical(bwareaopen(RegsF,threshSmallAreas));
                                   Ipoly=logical(imwarp(Ipoly,RIn,tform,methodRed,...
                                       'OutputView',ROut));               
                                   Ipoly=logical(bwareaopen(Ipoly,threshSmallAreas));
                                   bordersOI=logical(imwarp(bordersOI,RIn,tform,methodRed,...
                                   'OutputView',ROut));               
                                   if any(bordersOI(:)) 
                                       bordersOI=logical(bwareaopen(bordersOI,threshSmallAreas)); end
                                   for ch=1:size(IRGB,3)    %#ok<ALIGN>
                                       img(:,:,ch)=uint8(imwarp(IRGB(:,:,ch),RIn,...
                                           tform,methodRed,'OutputView',ROut)); end
                                   clear IRGB; IRGB=img; clear img; 
                                   clear RIn tform kappaB moving RegStruct;
                                   clear imgmove;
                                   % imgtemp rimane uguale ma imgmove cambia!!
                                   imgmove=uint8(Ipoly)*val;
                               else
                                   disp(['no registration with ' strMethod]);
                               end 
                               clear szImg; szImg=size(Regs);
                               maxSz=max(maxSz, szImg);
                               save([dirSave slash strAdd 'maxSz.mat'],'maxSz');
                               clear RegStruct moving flagKappa flagCorr flagStd;
                           end

                           if ((szTemp(1)~=size(Regs,1)) || (szTemp(2)~=size(Regs,2)))
                               disp('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
                               disp('!!!TEMPLATE DIMENSIONS DIFFER FROM IMAGE DIMENSION!!!');
                               disp('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');            
                           else
                               save([dirSave slash baseName '_' strAdd 'Regs.mat'],'Regs'); 
                               save([dirSave slash baseName '_' strAdd 'RegsF.mat'],'RegsF'); 
                               save([dirSave slash baseName '_' strAdd 'Ipoly.mat'],'Ipoly');
                               save([dirSave slash baseName '_' strAdd 'bordersOI.mat'],'bordersOI');
                               sz=size(Regs);
                               IRGB1=IRGB(1:round(sz(1)/2),1:round(sz(2)/2),:);
                               IRGB2=IRGB(1:round(sz(1)/2),round(sz(2)/2)+1:end,:);
                               IRGB3=IRGB(round(sz(1)/2)+1:end,1:round(sz(2)/2),:);
                               IRGB4=IRGB(round(sz(1)/2)+1:end,round(sz(2)/2)+1:end,:);
                               save([dirSave slash baseName  '_' strAdd 'IRGB1.mat'], 'IRGB1');
                               save([dirSave slash baseName  '_' strAdd 'IRGB2.mat'], 'IRGB2');
                               save([dirSave slash baseName  '_' strAdd 'IRGB3.mat'], 'IRGB3');
                               save([dirSave slash baseName  '_' strAdd 'IRGB4.mat'], 'IRGB4');  
                               clear IRGB1 IRGB2 IRGB3 IRGB4 sz Regs RegsF;
                               clear RegsF_marker Regs_marker Ipoly bordersOI Ipoly_marker Regs RegsF Ipoly;
                           end
                       end
                       clear szImg szTemp;
                       clear Regs RegsF IRGB Ipoly bordersOI;
                       close all
                    else
                        disp(['-------------------------------------------'...
                            newline 'Images of sample ' newline ...
                            info.patName  'have been already manually registered'   newline ....
                             '-------------------------------------------']);
                    end
                end    
                close all; 
            end 
            save([dirSave slash strAdd 'maxSz.mat'],'maxSz');
            %% END MANUAL LANDMARKS REGISTRATION
           clear fns;
        else; disp('No Registration with manual landmarks'); end
        clear templatesUse;
    else
        if numel(templates)==1; disp('No registration with only one template!'); end
    end
    
    %% MARKER SEGMENTATION AND DENSITY ESTIMATION 
    %% AFTER ANY REGISTRATION
    disp('Marker segmentation and density estimation After Registration');
    
    load([dirSave slash strAdd 'maxSz.mat']); 
    if isinf(threshDist(1))
        threshDist(1)=round(((maxSz(1)^2+maxSz(2)^2)^0.5)*(0.1));
    end
    
    delete(gcp('nocreate')); parpool;
    strTitle=['--------------marker Density per Img----------------' newline ...
              '-----------------------' strAdd '-------------------------' newline...
        'Img Name' sprintf('\t') 'Tissue Area' sprintf('\t') ...
        'Marker Area' sprintf('\t') 'Marker Density w.r.t tissue' sprintf('\t') ...
        'Concentrated-Marker Area' sprintf('\t') 'Concentrated-Marker Density w.r.t tissue'...
         sprintf('\t') 'Concentrated-Marker Density w.r.t Conc.Areas'];
    disp(strTitle);
    fprintf(fidDensity, '%s\n',strTitle); clear strTitle;
    
    for numI=1:numel(fnsAll)
        fName=fnsAll(numI,1).name;
        info=parseName(fName);
        baseName=[info.patName '_' info.markerName '_' info.markerColor];
        disp([num2str(numI) '->' baseName '<-']);
        load([dirSave slash baseName '_' strAdd 'RegsF.mat']);
        load([dirSave slash baseName '_' strAdd 'Regs.mat']);  
        load([dirSave slash baseName '_' strAdd 'bordersOI.mat']);
        load([dirSave slash baseName '_' strAdd 'IRGB1.mat']);
        load([dirSave slash baseName '_' strAdd 'IRGB2.mat']);
        load([dirSave slash baseName '_' strAdd 'IRGB3.mat']);
        load([dirSave slash baseName '_' strAdd 'IRGB4.mat']);
        IRGB=[IRGB1 IRGB2; IRGB3 IRGB4];
        clear IRGB1 IRGB2 IRGB3 IRGB4; 
        if exist('RegsF','var') && exist('IRGB','var')
            if ~exist([dirSave slash baseName '_' strAdd 'markers.mat'],'file') %#ok<ALIGN>
                %% se una immagine ha nome colore= presetCol-addCol
                %% presetCol è il colore più selettivo che permette di selezionare 
                %% solo porzioni di regioni di marker, 
                %% ma tali regioni vengono spesso sottosegmentate
                %% addCol è un colore più generico che prende di più ma permette di ottenere
                %% zone di marker meglio definite
                %% quindi prendo le regioni di marker cercando zone con colore presetCol
                %% e poi uso le forme date dalla ricerca di zone di colore addCol
                presetmarkerColor=[];
                basemarkerColor=[];
                sz=size(RegsF);
                if numel(presetmarkerColor)==0 
                    presetmarkerColor=info.markerColor; 
                    disp(['Segment markers with color ' presetmarkerColor]);
                end
                ind=strfind(presetmarkerColor,'-');
                if numel(ind)>0 
                    basemarkerColor=presetmarkerColor(ind+1:end);
                    presetmarkerColor=presetmarkerColor(1:ind-1);
                    disp(['discard most not marker by Base marker Color =  ' basemarkerColor]);
                    disp(['then select markers with color ' presetmarkerColor]);  
                end
                stepCut(2)=uint32(ceil(double(sz(2))/double(dimLimitOut)));
                stepCut(1)=uint32(ceil(double(sz(1))/double(dimLimitOut)));
                taglioC=uint32(ceil(double(sz(2))/double(stepCut(2))));
                taglioR=uint32(ceil(double(sz(1))/double(stepCut(1))));
                markers=false(sz(1),sz(2));
                for i=uint32(1):uint32(stepCut(1))
                    for j=uint32(1):uint32(stepCut(2))
                        miny=max((i-1)*taglioR+1-offset,1);
                        maxy=min(i*taglioR+offset,sz(1));
                        minx=max((j-1)*taglioC+1-offset,1);
                        maxx=min(j*taglioC+offset,sz(2));
                        img=double(IRGB(miny:maxy,minx:maxx,:));  
                        reg=Regs(miny:maxy,minx:maxx);
                        mark=logical(par_trees_svm_knn24(img,reg,dimLimitIn,...
                                dirClassifiers, presetmarkerColor,basemarkerColor,thrArea,slash));
                        clear img reg;
                        if (miny>1); miny=miny+offset; mark=mark(1+offset:end,:); end
                        if (maxy<sz(1)); maxy=maxy-offset; mark=mark(1:end-offset,:); end
                        if (minx>1); minx=minx+offset; mark=mark(:,offset+1:end); end
                        if (maxx<sz(2)); maxx=maxx-offset; mark=mark(:,1:end-offset); end
                        markers(miny:maxy,minx:maxx)=mark;
                    end
                end                
                save([dirSave slash baseName '_' strAdd 'markers.mat'],'markers');
            else; load([dirSave slash baseName '_' strAdd 'markers.mat']); end
            if any(bordersOI(:)); markers(bordersOI(:))=false; end
            areaReg=double(sum(RegsF(:)));
            areaMarkers=double(sum(markers(:)));
            percArea=areaMarkers/areaReg;     
            if exist([dirSave slash baseName '_' strAdd 'markersConc.mat'],'file')
                load([dirSave slash baseName '_' strAdd 'markersConc.mat']);
            else 
                resConc=creaConc(markers,Regs);
                markersConc=resConc.imgConc;
                RConc=resConc.R;  %#ok<NASGU>
                save([dirSave slash baseName '_' strAdd 'markersConc.mat'],'markersConc');
                save([dirSave slash baseName '_' strAdd 'RConc.mat'],'RConc');
            end   
            areaMarkersConc=double(sum(markersConc(:) & markers(:)));
            percAreaConcInReg=areaMarkersConc/areaReg;
            percAreaConcInConcArea=areaMarkersConc/sum(markersConc(:));
            str=[baseName sprintf('\t') num2str(areaReg) sprintf('\t')...
                num2str(areaMarkers) sprintf('\t') num2str(percArea) sprintf('\t')...
                num2str(areaMarkersConc) sprintf('\t') num2str(percAreaConcInReg)...
                sprintf('\t') num2str(percAreaConcInConcArea)];
            fprintf(fidDensity, '%s\n',str); clear str;
            clear areaReg areaMarkers percArea areaMarkersConc perAreaConc str;
            imgMarkers=cat(3,uint8(markers),uint8(markers),uint8(markers));
            imgMarkers=imgMarkers.*IRGB;
            imgMarkersConc=cat(3,uint8(markersConc),uint8(markersConc),uint8(markersConc));
            imgMarkersConc=imgMarkersConc.*IRGB;
            imwrite(imgMarkers,[dirSaveMarker slash baseName '_' strAdd 'RGBMarkers.tif']);
            imwrite(imgMarkersConc,[dirSaveMarker slash baseName '_' strAdd 'RGBMarkersCONC.tif']);
            imwrite(uint8(markers)*255,[dirSaveMarker slash baseName '_' strAdd 'BINmarkers.tif']);
            clear imgMarkers markersConc;
            hists=calcolaDistHist(markers, imfill(RegsF,'holes'),...
                bordersOI,threshDist, fStep, fRound, baseName,dirSaveHists,slash);
            indM=find(strcmpi(templates,info.markerName)); 
             %% aggiungo alla media del template
            if numel(templateHists)<indM
                templateHists{indM}.HBorder=smooth(double(hists.histBorder.Values),fSmooth);
                templateHists{indM}.xAxisBorder=hists.xAxisBorder;
                if any(bordersOI(:)) %#ok<ALIGN>
                    templateHists{indM}.HROI=smooth(double(hists.histROI.Values),fSmooth);
                    templateHists{indM}.xAxisROI=hists.xAxisROI;
                else 
                    templateHists{indM}.HROI=zeros(size(hists.histBorder.Values)); 
                    templateHists{indM}.xAxisROI=NaN; end
            else
                templateHists{indM}.HBorder=templateHists{indM}.HBorder+...
                    smooth(double(hists.histBorder.Values),fSmooth);
                if any(any(bordersOI))
                    templateHists{indM}.HROI=...
                        templateHists{indM}.HROI+...
                            smooth(double(hists.histROI.Values),fSmooth);
                    if any(~isfinite(templateHists{indM}.xAxisROI))
                        templateHists{indM}.xAxisROI=hists.xAxisROI; end
                end
            end       
            save([dirSaveHists slash baseName '_' strAdd 'hists.mat'],'hists');
            clear hists cent  markers RegsF;
        end
    end
    clear fnsAll;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%% HIST MEDIDIIIII!!!!!!!!
    for indM=1: numel(templates)
        templateHists{indM}.HBorder=smooth(templateHists{indM}.HBorder/...
            double(sum(templateHists{indM}.HBorder)), fSmooth);
        templateHists{indM}.HROI=smooth(templateHists{indM}.HROI/...
            double(sum(templateHists{indM}.HROI)), fSmooth);
    end
    
    str=['------------DIFF HIST MEDI----------------' newline ...
        '----------------' strAdd '-----------------' newline...
        'base Marker (B)' sprintf('\t') ...
        'OverlappingMarker (O)' sprintf('\t') ...
        'Intersection Border dist mean  prb (from O to B)' sprintf('\t') ...
        'Intersection ROI dist mean prb (from O to B)'];
    fprintf(fidDiffHists,'%s\n',str); clear str;
    
    for numTemp=startM: numel(templates)
        tempHBorder=templateHists{numTemp}.HBorder;
        tempHROI=templateHists{numTemp}.HROI;
        for numOver=1:numel(templates)
            if numOver ~=numTemp
                str=[templates{numTemp} sprintf('\t') ...
                    templates{numOver} sprintf('\t')];
                overHBorder=templateHists{numOver}.HBorder;
                overHROI=templateHists{numOver}.HROI;
                
                histBorderIntersect=fIntersect(tempHBorder,overHBorder);
                if (any(isfinite(overHROI)) && any(isfinite(tempHROI))) %#ok<ALIGN>
                    histROIIntersect=fIntersect(tempHROI,overHROI);
                else; histROIIntersect=NaN; end
                str=[str    num2str(histBorderIntersect) sprintf('\t') ...
                            num2str(histROIIntersect)];   
                    clear overHROI  overHBorder;
                    fprintf(fidDiffHists,'%s\n',str); clear str;
                    clear histBorderIntersect histROIIntersect;        
            end
        end
        clear tempHROI tempHPOI tempHBorder;
    end
    
    fig=figure('Name', 'probability estimate of Border distance');
    for indM=1: numel(templates)
        hold on; 
        plot(templateHists{indM}.xAxisBorder,templateHists{indM}.HBorder);
    end  
    legend(templates);
    saveas(fig,[dirSaveHists slash strAdd '_BorderDistanceMeanH_' num2str(threshDist(1)) '.jpg']);
    close(fig); clear fig;
    
    fig=figure('Name', 'Cumulative probability estimate of Border distance');
    for indM=1: numel(templates)
        hold on; 
        plot(templateHists{indM}.xAxisBorder,cumsum(templateHists{indM}.HBorder));
    end  
    legend(templates);
    saveas(fig,[dirSaveHists slash strAdd '_CumBorderDistanceMeanH_' num2str(threshDist(1)) '.jpg']);
    close(fig); clear fig;
        
    if any(isfinite(templateHists{indM}.HROI))
        fig=figure('Name', 'probability estimate of ROI distance');
        for indM=1: numel(templates)
            hold on; 
            plot(templateHists{indM}.xAxisROI,smooth(templateHists{indM}.HROI,10));
        end    
        legend(templates);
        saveas(fig,[dirSaveHists slash strAdd '_ROIDistanceMeanH_' num2str(threshDist(2)) '.jpg']);
        close(fig); clear fig;
    end
    if overlapImgs
         if numel(templates)>1 && overlapImgs
            while mod(numel(templates),3)>0
                ind=randi(numel(templates));
                templates{end+1,1}=templates{ind,1};
            end
            tempTriplets=reshape(templates,3,numel(templates)/3);
            flagSegPrima=(~automaticRegister) & (~manualLandmarks);
            flagAutomatic=automaticRegister;
            flagManual=manualLandmarks;
            SaveOverlaps(dirImgs,dirSave,tempTriplets, ...
                [flagSegPrima,flagAutomatic,flagManual],selectROI,slash); 
         end   

        str=['--------------DIFF PER IMG----------------' newline ...
            '----------------' strAdd '-----------------' newline...
            'Img Name' sprintf('\t') 'base Marker (B)' sprintf('\t')  ...
            'BDens=BMarkers Density in Tissue Area' sprintf('\t') ...
            '% BMarkers in BConc (BMarkersConc)' sprintf('\t') ...
            'BMarkersConc Density in Tissue' sprintf('\t') ....
            'BMarkersConc Density in BConc' sprintf('\t') ....
            'OverlappingMarker (O)' sprintf('\t') ...
            'ODens=OMarkers Density in Tissue Area' sprintf('\t') ...
            '% OMarkers in OConc (OMarkersConc)' sprintf('\t') ...
            'OMarkersConc Density in Tissue' sprintf('\t') ....
            'OMarkers Density in OConc' sprintf('\t') ....
            'w=min(BDens,ODens)/max(BDens,ODens)' sprintf('\t') ....
            'DensBInO=density(BMarker in OConc) in OConc' sprintf('\t') ...
            'DensOInB=density (OMarkersConc in BConc) in BConc' sprintf('\t') ...
            'mean(DensBInO, DensOInB)' sprintf('\t') ...
            'mean(DensBInO, DensOInB)*w' sprintf('\t') ...
            'PercBInO=(BMarkerConc in OConc) / BMarkerConc' sprintf('\t') ...
            'PercOInB=(OMarkersConc in BConc) / OMarkerConc' sprintf('\t') ...
            'mean(PercBInO, PercOInB)' sprintf('\t') ...
            'mean(PercBInO, PercOInB)*w' sprintf('\t') ...
            'Dens B In Conc(O,RB)' sprintf('\t') ...
            'Dens O In Conc(B,RO)' sprintf('\t') ...
            'Mean Ratio DensBInO/DensB,DensOInB/DensO' sprintf('\t') ...
            ' w Mean Ratio DensBInO/DensB,DensOInB/DensO' sprintf('\t') ...
            'PercBIn Conc(O,RB)' sprintf('\t') ...
            'PercOIn Conc(B,RO)' sprintf('\t') ...
            'Mean Ratio PercBInO/PercB,PercOInB/PercO' sprintf('\t') ...
            'w Mean Ratio PercBInO/PercB,PercOInB/PercO '];
        
        fprintf(fidColoc, '%s\n',str); clear str;
        legendPlot="";
        for numTemp=startM: numel(templates)
            tempmarker=templates{numTemp};
            fnsMarker=dir([dirSave slash '*_' tempmarker '_*' strAdd 'markers.mat']); 
            legendPlot=[legendPlot; {[tempmarker newline]}];
            for numI=1:numel(fnsMarker)
                fName=fnsMarker(numI,1).name;
                info=parseName(fName);
                imgName=info.patName;           
                baseNameB=[imgName '_' tempmarker '_' info.markerColor];
                disp(['Base Marker = ' tempmarker]);
                strR=load([dirSave slash baseNameB '_' strAdd 'markersConc.mat']); 
                BMarkersConc=strR.markersConc; clear strR;
                strR=load([dirSave slash baseNameB '_' strAdd 'RConc.mat']); 
                BRConc=strR.RConc; clear strR;
                strR=load([dirSave slash baseNameB '_' strAdd 'markers.mat']); 
                BMarkers=strR.markers; clear strR;
                strR=load([dirSave slash baseNameB '_' strAdd 'IpolyDil.mat']); 
                BMarkerPoly=strR.Ipoly; clear strR;
                if any(BMarkerPoly(:))
                    BMarkersConc(~BMarkerPoly)=false; 
                    BMarkers(~BMarkerPoly)=false; 
                    BRegsF=BMarkerPoly;
                else
                    strR=load([dirSave slash baseNameB '_' strAdd 'RegsF.mat']); 
                    BRegsF=strR.RegsF; clear strR;
                end
                if exist([dirSave slash baseNameB '_' strAdd 'ROI.mat'],'file')
                    load([dirSave slash baseNameB '_' strAdd 'ROI.mat']);
                    BRegsF=ROI;
                end
                %% confronto regioni concentrate
                areaBReg=sum(BRegsF(:)); 
                BMarkers=BMarkers & BRegsF;
                BMarkersConc=BMarkersConc & BRegsF;
                
                BDens=sum(BMarkers(:))/areaBReg;
                PercBMarkersConc=sum(BMarkersConc(:) & BMarkers(:))/sum(BMarkers(:));
                areaBMConc=sum(BMarkersConc(:) & BMarkers(:));   
                BConcDensityTissue=double(areaBMConc)/areaBReg;
                BConcDensityArea=double(areaBMConc)/sum(BMarkersConc(:));
                strBase=[imgName sprintf('\t') tempmarker sprintf('\t') ...
                        num2str(BDens) sprintf('\t') ...
                        num2str(PercBMarkersConc) sprintf('\t') ...
                        num2str(BConcDensityTissue) sprintf('\t') ...
                        num2str(BConcDensityArea) sprintf('\t') ];
                clear areaBReg areaBMConc BConcDensityTissue;    
                for numOver=numTemp+1: numel(templates)
                    overM=templates{numOver};
                    if ~strcmpi(tempmarker,overM)
                        fnsImg=dir([dirSave slash imgName '_' overM '_*_' strAdd 'markersConc.mat']); 
                        if numel(fnsImg)>0
                            infImg=parseName(fnsImg(1,1).name); clear fnsImg;
                            baseNameOverM=[imgName '_' overM '_' infImg.markerColor];
                            clear infImg;
                            legendPlot=[legendPlot; {[overM newline]}];
                            disp(['Overlapping Marker = ' overM]);
                            strR=load([dirSave slash baseNameOverM '_' strAdd 'markers.mat']);
                            OMarkers=strR.markers; clear strR;
                            strR=load([dirSave slash baseNameOverM '_' strAdd 'IpolyDil.mat']); 
                            OMarkerPoly=strR.Ipoly; clear strR;
                            strR=load([dirSave slash baseNameOverM '_' strAdd 'RegsF.mat']); 
                            ORegsF=strR.RegsF; clear strR;
                            strR=load([dirSave slash baseNameOverM '_' strAdd 'markersConc.mat']);
                            OMarkersConc=strR.markersConc; clear strR;
                            strR=load([dirSave slash baseNameOverM '_' strAdd  'RConc.mat']); 
                            ORConc=strR.RConc; clear strR;
                            strConc=creaConc(BMarkers,BRegsF,ORConc);
                            
                            %BMarker dilatato con raggio di Omarker
                            BMarkersORConc=strConc.imgConc; clear strConc;
                            BMarkersORConc=BMarkersORConc & BRegsF;
                            
                            %OMarker dilatato con raggio di Bmarker
                            strConc=creaConc(OMarkers,ORegsF,BRConc);
                            OMarkersBRConc=strConc.imgConc; clear strConc;
                            if any(OMarkerPoly(:))
                                OMarkersBRConc(~OMarkerPoly)=false;
                                OMarkers(~OMarkerPoly)=false;
                                ORegsF=OMarkerPoly;
                            else
                                strR=load([dirSave slash baseNameOverM '_' strAdd 'RegsF.mat']); 
                                ORegsF=strR.RegsF; clear strR;
                            end
                            if exist([dirSave slash baseNameOverM '_' strAdd 'ROI.mat'],'file')
                                load([dirSave slash baseNameOverM '_' strAdd 'ROI.mat']);
                                ORegsF=ROI;
                            end
                            %% confronto regioni concentrate
                            OMarkers=OMarkers & ORegsF;
                            OMarkersBRConc=OMarkersBRConc & ORegsF;
                            OMarkersConc=OMarkersConc & ORegsF;
                            areaOReg=sum(ORegsF(:));
                            ODens=sum(OMarkers(:))/areaOReg;
                            PercOMarkersConc=sum(OMarkersConc(:) & OMarkers(:))/sum(OMarkers(:));
                            areaOMConc=sum(OMarkersConc(:) & OMarkers(:));   
                            OConcDensityTissue=double(areaOMConc)/areaOReg;
                            OConcDensityArea=double(areaOMConc)/sum(OMarkersConc(:));
                            str=[strBase overM sprintf('\t') ...
                                num2str(ODens) sprintf('\t') ...
                                num2str(PercOMarkersConc) sprintf('\t') ...
                                num2str(OConcDensityTissue) sprintf('\t')...
                                num2str(OConcDensityArea)  sprintf('\t')];
                            clear areaOReg areaOMConc OConcDensityTissue;
                            w=(min(BDens,ODens)/max(BDens,ODens));
                            DensBInOConc=sum(BMarkers(:) & OMarkersConc(:))/sum(OMarkersConc(:));
                            DensOInBConc=sum(OMarkers(:) & BMarkersConc(:))/sum(BMarkersConc(:));
                            meanDensBOConc=mean([DensBInOConc,DensOInBConc]);
                            wMeanDensBO=meanDensBOConc*w;
                            str=[str num2str(w) sprintf('\t')  num2str(DensBInOConc) sprintf('\t') ...
                                num2str(DensOInBConc) sprintf('\t') num2str(meanDensBOConc) sprintf('\t') ...
                                num2str(wMeanDensBO)];
                            clear DensOInB DensBInO DensPercBO wMeandensBO;
                            PercBInOConc=sum(BMarkers(:) &  OMarkersConc(:))/sum(BMarkers(:) );
                            PercOInBConc=sum(OMarkers(:) &  BMarkersConc(:))/sum(OMarkers(:) );
                            meanPercBO=mean([PercBInOConc,PercOInBConc]);   
                            wMeanPercBO=meanPercBO*w;  
                            str=[str sprintf('\t')  num2str(PercBInOConc) sprintf('\t') ...
                                num2str(PercOInBConc) sprintf('\t') num2str(meanPercBO) sprintf('\t') ...
                                num2str(wMeanPercBO)];
                            clear PercOInB PercBInO meanPercBO wMeanPercBO;
                            DensBInOConcFair=sum(BMarkers(:) & OMarkersBRConc(:))/sum(OMarkersBRConc(:));
                            DensOInBConcFair=sum(OMarkers(:) & BMarkersORConc(:))/sum(BMarkersORConc(:));
                            RatioDensB=DensBInOConcFair/BConcDensityArea;
                            RatioDensO=DensOInBConcFair/OConcDensityArea;
                            meanRatioDensBOConcFair=mean([RatioDensB,RatioDensO]);
                            wMeanRatioDensBOConcFair=w*meanRatioDensBOConcFair;
                            str=[str sprintf('\t')  num2str(DensBInOConcFair) sprintf('\t') ...
                                num2str(DensOInBConcFair) sprintf('\t') num2str(meanRatioDensBOConcFair) sprintf('\t') ...
                                num2str(wMeanRatioDensBOConcFair)];
                            clear DensBInOConcFair DensOInBConcFair RatioDensB RatioDensO;
                            clear meanRatioDensBOConcFair wMeanRatioDensBOConcFair;
                            PercBInOConc=sum(BMarkers(:) &  OMarkersBRConc(:))/sum(BMarkers(:) );
                            PercOInBConc=sum(OMarkers(:) &  BMarkersORConc(:))/sum(OMarkers(:) );
                            ratioPercO=PercOInBConc/PercOMarkersConc;
                            ratioPercB=PercBInOConc/PercBMarkersConc;
                            meanRatioPercBO=mean([ratioPercO,ratioPercB]);   
                            wMeanRatioPercBO=meanRatioPercBO*w;  
                            str=[str sprintf('\t')  num2str(PercBInOConc) sprintf('\t') ...
                                num2str(PercOInBConc) sprintf('\t') num2str(meanRatioPercBO) sprintf('\t') ...
                                num2str(wMeanRatioPercBO)];
                            clear PercOInB ratioPercB ratioPercO PercBInO meanRatioPercBO wMeanRatioPercBO;
                            
                            clear OMarkers OMarkersConc ORegsF OMarkerPoly OConcDensityArea;
                            fprintf(fidColoc,'%s\n',str); clear str;
                       end
                    end 
                    
                end
                clear areaTempReg areatempMConc ;
                clear BMarkers BMarkersConc BRegsF BMarkerPoly BConcDensityArea;
            end
        end      
    end
    fclose(fidDiffHists);
    fclose(fidColoc);
    fclose(fidDensity);

   
        
end

