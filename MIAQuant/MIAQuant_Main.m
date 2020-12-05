function MIAQuant_Main(templates)
% Last Update 20 July 2017
% % Copyright: Elena Casiraghi
% % This software is described in 
% % 
% % "MIAQuant, a novel system for automatic segmentation, measurement, and localization 
% % comparison of different biomarkers from serialized histological slices: 
% % application to immune infiltrate in atherosclerotic plaques and tumor specimens"
% % Authors: Elena Casiraghi, Mara Cossa, Matteo Tozzi, Licia Rivoltini, 
% % 	Antonello Villa and Barbara Vergani.
% % European Journal of Histochemistry
% % 
% % MIAQuant is freely available for clinical studies, pathological research, and diagnosis.
% % For any trouble refer to 
% % casiraghi@di.unimi.it
% % 
% % If MIAQuant is helpful for your studies/research, please cite the above mentioned article.

    addpath('.\SourceFiles');
    warning off;
    if (nargin<1)
        lineMarkers=input([sprintf('\n') '-------------------' sprintf('\n') 'Insert the '...
            '(space separated) marker Names (e.g. CD3 CD68 CD163) ' sprintf('\n')],'s');
        pos=strfind(lineMarkers,' ');
        templates={};
        oldPos=0;
        for i=1:numel(pos); templates{i,1}=lineMarkers(oldPos+1:pos(i)-1); oldPos=pos(i); end
        templates{end+1,1}=lineMarkers(oldPos+1:end);
    end
    dirImgs='.\ToBeAnalized';
    newFolder=input([sprintf('\n') '-------------------' sprintf('\n') 'MIAQuant will '...
            'process images in folder ' sprintf('\n') dirImgs  sprintf('\n') ...
            'do you want to select another folder? Y/N '],'s');
    if strcmpi(newFolder,'Y')
        dirImgs=uigetdir('Select the img folder'); 
        disp(['Selected Folder: ' dirImgs]);
    end
    dirPunti=[dirImgs '\manualLandmarks'];
    load('SelectedMdlKNN8');
    startM=1; startR=1; dimLimit=20000; stepFR=1; stepFC=1;
    factorRed=input([sprintf('\n') '-------------------' sprintf('\n') 'If wanted insert the reduction factor'...
        sprintf('\n') 'e.g: 0.1 for reduction at 10% image size, 0.5 to halve the image size,... ' sprintf('\n')]);
    if numel(factorRed)==0; factorRed=1; end
    methodRed='nearest'; 
    dd=date;
    threshSmallAreas=round(1000*(factorRed)^2);
    thrAreaConc=round(1800*(factorRed)^2);
    thrArea=round(16*(factorRed)^2);
    stBig=strel('disk',max(1,double(round(10*factorRed))));
    st=strel('disk',max(1,round(2*factorRed)));
    answerOnlySeg=input([sprintf('\n') '-------------------' sprintf('\n') 'Do you want REGISTRATION of images +'...
        ' Biomarker Segmentation (press R)' sprintf('\n') ... 
        'or ONLY Biomarker Segmentation (press S)? R/S ' sprintf('\n')],'s');    
    if strcmpi(answerOnlySeg,'S') 
        answerRegister=false; 
        flagPrima=true; manualLandmarks=false;
        automaticRegister=false; answerRegister=false;
        dirSave=[dirImgs '\Segmentation_' num2str(factorRed*100) 'Reduction_' dd];  
    else
        answerRegister=true;
        segPrima=input([sprintf('\n') '-------------------' sprintf('\n') 'Do you want Biomarker SEGMENTATION' sprintf('\n') 'BEFORE registration? Y/N ' sprintf('\n')],'s');
        if strcmpi(segPrima,'Y'); flagPrima=true; else flagPrima=false; end
        automaticReg=input([sprintf('\n') '-------------------' sprintf('\n') 'Do you want AUTOMATIC REGISTRATION ' sprintf('\n') 'based on TISSUE SHAPES? Y/N ' sprintf('\n')],'s'); 
        automaticRegister=strcmpi(strtrim(automaticReg),'Y');
        answerManualLand=input([sprintf('\n') '-------------------' sprintf('\n') 'Do you want AUTOMATIC REGISTRATION  ' sprintf('\n') 'based on user-selected LANDMARKS? Y/N ' sprintf('\n')],'s');
        manualLandmarks=strcmpi(strtrim(answerManualLand),'Y');
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
        if automaticRegister; strReg=['MHReg_']; else; strReg=''; end
        if manualLandmarks; strPoints='PolyReg_'; else; strPoints=''; end 
        dirSave=[dirImgs '\' strReg strPoints num2str(factorRed*100) 'Reduction_' dd];    
    end
    if ~exist(dirSave,'dir'); mkdir(dirSave); end
    disp(dirSave);
    dirSaveMarker=[dirSave '\Markers'];
    if ~exist(dirSaveMarker,'dir'); mkdir(dirSaveMarker); end
    nameDensity=[dirSaveMarker '\MarkerDensityData.txt'];
    fidDensity = fopen(nameDensity,'w');
    fprintf(fidDensity,'directory pathname: %s\n',dirImgs); 
    strTitle=['Img Name' sprintf('\t') 'Tissue Area' sprintf('\t') ...
        'Marker Area' sprintf('\t') 'Marker Density' sprintf('\t') ...
        'Concentrated-Marker Area' sprintf('\t') 'Concentrated-Marker Density'];
    fprintf(fidDensity, '%s\n',strTitle); clear str;
    %% SEGMENTO TUTTE LE TISSUE REGIONS e i manual landmarks
    fnsAll=dir([dirImgs '\*_' templates{1} '*_0001.tif']); 
    for numTemp=2: numel(templates)
           tempMarker=templates{numTemp};
           fns=dir([dirImgs '\*_' tempMarker '*_0001.tif']);
           fnsAll=[fnsAll; fns];
    end
    for numI=1:numel(fnsAll)
        fName=fnsAll(numI,1).name;
        info=parseName(fName);
        disp(['imgName=' info.patName ...
            ' - #SubImg=' info.numFetta ...
            ' - Marker=' info.markerName ' - Color=' info.markerColor]);
        baseName=[info.patName '_' info.markerName '_' info.markerColor];
        disp(baseName)
        if ~exist([dirSave '\' baseName '_ORegs.mat'],'file') || ...
                ~exist([dirSave '\' baseName '_ORegsF.mat'],'file') || ...
                ~exist([dirSave '\' baseName '_OItriangle.mat'],'file') 
            if (factorRed~=1) 
                I=[]; Ipunti=[]; numF=1; strNumF=num2str(numF);
                while(numel(strNumF)<4); strNumF=['0' strNumF]; end
                strFetta=[baseName '_' strNumF ]; clear strNumF;
                while exist([dirImgs '\' strFetta '.tif'],'file')
                    I=[I imresize(imread([dirImgs '\' strFetta '.tif']),factorRed,methodRed)];
                    if (exist([dirPunti '\' strFetta '.tif'],'file') && manualLandmarks)
                        Ipunti=[Ipunti ...
                            imresize(imread([dirPunti '\' strFetta '.tif']),factorRed,methodRed)];
                    end; clear strFetta strNumF;
                    numF=numF+1; strNumF=num2str(numF); 
                    while(numel(strNumF)<4); strNumF=['0' strNumF]; end %#ok<AGROW>
                    strFetta=[baseName '_' strNumF];
                end
            else I=[]; Ipunti=[]; numF=1; strNumF=num2str(numF);
                while(numel(strNumF)<4); strNumF=['0' strNumF]; end %#ok<*AGROW>
                strFetta=[baseName '_' strNumF ]; clear str
                while exist([dirImgs '\' strFetta '.tif'],'file')
                    I=[I imread([dirImgs '\' strFetta '.tif'])]; %#ok<AGROW>
                    if (exist([dirPunti '\' strFetta '.tif'],'file') && manualLandmarks)
                        Ipunti=[Ipunti imread([dirPunti '\' strFetta '.tif'])]; %#ok<AGROW>
                    end; clear strNumF strFetta;
                    numF=numF+1; strNumF=num2str(numF); 
                    while(numel(strNumF)<4); strNumF=['0' strNumF]; end 
                    strFetta=[baseName '_' strNumF];
                end
            end
            if numel(Ipunti(:))>0 %#ok<ALIGN>
                Ip0=logical(Ipunti(:,:,1)<10 & Ipunti(:,:,2)>250 & Ipunti(:,:,3)<10);
                cent=regionprops(logical(Ip0),'Centroid');
                Ip=Ip0;
                Ip0(:,:)=uint8(0);
                for nC1=1:numel(cent)
                    p1=cent(nC1,1).Centroid; 
                    Ip0(p1(2)-1:p1(2)+1,p1(1)-1:p1(1)+1)=1;
                    for nC2=nC1+1:numel(cent)
                        p2=cent(nC2,1).Centroid;
                        Ip=drawLine(Ip,p1(1),p1(2),p2(1),p2(2),st);
                    end
                    p1=cent(1,1).Centroid; p2=cent(numel(cent),1).Centroid;
                    Ip=drawLine(Ip,p1(1),p1(2),p2(1),p2(2),st);
                end
                Ip=uint8(imerode(imfill(Ip,'holes'),st))*128;
                Ip=128*uint8(imdilate(Ip0,stBig))+Ip;
            else Ip=NaN; end
            RegTumori(I,Ip,baseName, dirSave); clear I Ip;
        end
    end
    strAdd='O';
    if numel(templates)>1
        %% PROCESS ALL THE IMAGES OF THE SAME PATIENT IN ORDER
        %% TO MAKE THE SIZE OF ALL THE BIOMARKER IMAGES EQUAL
        %% the same patient will have images of the same size
        fnsFirst=dir([dirImgs '\*' templates{1} '*_0001.tif']);
        for numI=1:numel(fnsFirst)
            fName=fnsFirst(numI,1).name;
            info=parseName(fName);
            sz=[0 0];
            disp(['-------------------------------------------'...
                sprintf('\n') 'Make all the size equals for imgs: ' sprintf('\n') ...
                info.patName  '_anyMarker_' info.markerColor  sprintf('\n') ....
                  '-------------------------------------------']);
            for numTemp=1: numel(templates)
                tempMarker=templates{numTemp};
                strMarker=[info.patName '_' ...
                    tempMarker '_' info.markerColor];
                if exist([dirSave '\' strMarker '_' strAdd 'RegsF.mat'],'file')
                    strR=load([dirSave '\' strMarker '_' strAdd 'RegsF.mat']);
                    sz=max(sz,size(strR.RegsF)); clear strR;
                else
                    disp(['file ' dirSave '\' strMarker '_' strAdd 'RegsF.mat' ' not existent']);
                end
            end        
            Regs=false(sz);
            RegsF=false(sz);
            Itriangle=false(sz);
            IRGB=uint8(zeros(sz(1),sz(2),3)); 
            % porto immagini della stessa fetta ma di marker diversi alla
            % stessa dimensione!
            for numTemp=1: numel(templates)
                tempMarker=templates{numTemp};
                strMarker=[info.patName '_' ...
                    tempMarker '_' info.markerColor];
                if exist([dirSave '\' strMarker '_' strAdd 'Regs.mat'],'file')
                    strR=load([dirSave '\' strMarker '_' strAdd 'Regs.mat']);
                    R=strR.Regs; 
                    szR=size(R); Regs(1:szR(1),1:szR(2))=R;
                    save([dirSave '\' strMarker '_' strAdd 'Regs.mat'],'Regs');
                    RegsF(:,:)=false; clear StrR R;
                    strR=load([dirSave '\' strMarker '_' strAdd 'RegsF.mat']);
                    R=strR.RegsF; RegsF(1:szR(1),1:szR(2))=R;
                    save([dirSave '\' strMarker '_' strAdd 'RegsF.mat'],'RegsF');
                    RegsF(:,:)=false; clear R StrR;
                    strR=load([dirSave '\' strMarker '_' strAdd 'Itriangle.mat']);
                    R=strR.Itriangle; Itriangle(1:szR(1),1:szR(2))=R;
                    save([dirSave '\' strMarker '_' strAdd 'Itriangle.mat'],'Itriangle');
                    Itriangle(:,:)=false; clear StrR R;
                    str1=load([dirSave '\' strMarker '_' strAdd 'IRGB1.mat']);
                    str2=load([dirSave '\' strMarker  '_' strAdd 'IRGB2.mat']);
                    str3=load([dirSave '\' strMarker  '_' strAdd 'IRGB3.mat']);
                    str4=load([dirSave '\' strMarker  '_' strAdd 'IRGB4.mat']);
                    IRGB(1:szR(1),1:szR(2),:)=[str1.IRGB1 str2.IRGB2; str3.IRGB3 str4.IRGB4];
                    clear str1 str2 str3 str4;
                    IRGB1=IRGB(1:round(sz(1)/2),1:round(sz(2)/2),:);
                    IRGB2=IRGB(1:round(sz(1)/2),round(sz(2)/2)+1:end,:);
                    IRGB3=IRGB(round(sz(1)/2)+1:end,1:round(sz(2)/2),:);
                    IRGB4=IRGB(round(sz(1)/2)+1:end,round(sz(2)/2)+1:end,:);
                    IRGB(:)=0;
                    save([dirSave '\' strMarker  '_' strAdd 'IRGB1.mat'], 'IRGB1');
                    save([dirSave '\' strMarker  '_' strAdd 'IRGB2.mat'], 'IRGB2');
                    save([dirSave '\' strMarker  '_' strAdd 'IRGB3.mat'], 'IRGB3');
                    save([dirSave '\' strMarker  '_' strAdd 'IRGB4.mat'], 'IRGB4');
                    clear IRGB1 IRGB2 IRGB3 IRGB4;
                end
            end
            clear IRGB Regs RegsF Itriangle;
        end
        clear fnsFirst; 
    end
    
    %% IF REQUESTED BEFORE REGISTRATION SEGMENT BIOMARKERS
    if flagPrima
        disp(strTitle);
        fprintf(fidDensity,'%s\n','Before Registration');
        disp('Marker segmentation and density estimation Before Registration');
        for numI=1:numel(fnsAll)
            fName=fnsAll(numI,1).name;
            info=parseName(fName);
            baseName=[info.patName '_' ...
                info.markerName '_' info.markerColor];
            disp([num2str(numI) '->' baseName '<-']);
            load([dirSave '\' baseName '_' strAdd 'RegsF.mat']); 
            load([dirSave '\' baseName '_' strAdd 'IRGB1.mat']);
            load([dirSave '\' baseName '_' strAdd 'IRGB2.mat']);
            load([dirSave '\' baseName '_' strAdd 'IRGB3.mat']);
            load([dirSave '\' baseName '_' strAdd 'IRGB4.mat']);
            IRGB=[IRGB1 IRGB2; IRGB3 IRGB4];
            clear IRGB1 IRGB2 IRGB3 IRGB4;        
            sz=size(RegsF);
            if (sz(2)>dimLimit); stepFC=uint32(round(sz(2)/dimLimit)); end
            if (sz(1)>dimLimit); stepFR=uint32(round(sz(1)/dimLimit)); end
            if strcmpi(info.markerColor,'R') %#ok<ALIGN>
                    markers=logical(redMarkers(IRGB,RegsF,MdlKNN8Str,stepFR,stepFC,thrArea));
                else; if strcmpi(info.markerColor,'M')
                    markers=logical(brownMarkers(IRGB,RegsF,stepFR,stepFC,thrArea)); end; end
            markersConc=imdilate(markers,stBig);
            markersConc=bwareaopen(markersConc,thrAreaConc);
            if exist('RegsF','var') && exist('IRGB','var')
                sz=size(RegsF);
                areaMarkers=double(sum(uint8(markers(:))));
                areaReg=double(sum(uint8(RegsF(:))));
                percArea=areaMarkers/areaReg; 
                areaMarkersConc=double(sum(uint8(markersConc(:))));
                percAreaConc=areaMarkersConc/areaReg;  
                str=[baseName sprintf('\t') num2str(areaReg) sprintf('\t')...
                    num2str(areaMarkers) sprintf('\t') num2str(percArea) sprintf('\t')...
                    num2str(areaMarkersConc) sprintf('\t') num2str(percAreaConc)];
                disp(str);
                fprintf(fidDensity, '%s\n',str);
                clear areaReg areaMarkers percArea areaMarkersConc perAreaConc str;
                imgMarkers=cat(3,uint8(markers),uint8(markers),uint8(markers));
                imgMarkers=imgMarkers.*IRGB;
                imgMarkersConc=cat(3,uint8(markersConc),uint8(markersConc),uint8(markersConc));
                imgMarkersConc=imgMarkersConc.*IRGB;
                if (sz(2)>dimLimit); stepFC=uint32(round(sz(2)/dimLimit)); end
                if (sz(1)>dimLimit); stepFR=uint32(round(sz(1)/dimLimit)); end
                stepFC=1; stepFR=1;
                taglioC=sz(2)/uint32(stepFC);
                taglioR=sz(1)/uint32(stepFR);                
                BBR=(1:taglioR:sz(1));
                BBC=(1:taglioC:sz(2));
                if (BBR(end)~=sz(1)) && ((sz(1)-BBR(end))<2); BBR(end)=sz(1);
                else if (BBR(end)~=sz(1)); BBR=[BBR sz(1)]; end; end
                if (BBC(end)~=sz(2)) && ((sz(2)-BBC(end))<2); BBC(end)=sz(2);    
                else if (BBC(end)~=sz(2)); BBC=[BBC sz(2)]; end; end
                strCut='';
                for i=1: length(BBC)-1
                    for j=1:length(BBR)-1
                        if (stepFR>1 || stepFC>1); strCut=['_' num2str(i) '_' num2str(j)];end
                        imwrite(IRGB(BBR(j):BBR(j+1),BBC(i):BBC(i+1),:),...
                              [dirSaveMarker '\' baseName '_subIRGBPreReg' strCut  '.tif']);
                        regs=RegsF(BBR(j):BBR(j+1),BBC(i):BBC(i+1));
                        mark=markers(BBR(j):BBR(j+1),BBC(i):BBC(i+1));
                        markConc=markersConc(BBR(j):BBR(j+1),BBC(i):BBC(i+1));
                        imwrite(mark,[dirSaveMarker '\' baseName '_BINmarkerPreReg' ...
                                    strCut  '.tif']);
%                         imwrite(markConc,[dirSaveMarker '\' baseName '_BINmarkerConcPreReg' ...
%                                     strCut  '.tif']);
                        regs(mark)=false;
                        r=cat(3,regs,regs,regs);
                        imark=imgMarkers(BBR(j):BBR(j+1),BBC(i):BBC(i+1),:);
                        imark(r)=uint8(round(max(imark(:))/3)); 
                        imwrite(imark,[dirSaveMarker '\' baseName '_RGBmarkerPreReg'...
                            strCut '.tif']); 
                        clear imark;
                        imark=imgMarkersConc(BBR(j):BBR(j+1),BBC(i):BBC(i+1),:);
                        imark(r)=uint8(round(max(imark(:))/3)); clear r;
                        imwrite(imark,[dirSaveMarker '\' baseName '_RGBmarkerConcPreReg'...
                            strCut '.tif']); 
                        clear imark;
                        clear markConc mark; 
                    end
                end
                clear imgMarkers markers IRGB;           
            end
        end
    end
    if answerRegister && numel(templates)>1
        if (automaticRegister)
            %% IF REQUESTED PERFORM Multiscalle Hierarchical shape registration
            val=uint8(round(255/3)*2);
            valcheck=val;
            disp(['Multiscale Registration with' ...
                num2str(numel(stReg)) ' detail levels']);
            %% COPY ALL THE IMAGES TO CHANGE PREEXTENSION ("O" into "")
            oldstrAdd=strAdd; strAdd='';
            for numI=1:numel(fnsAll)
                fName=fnsAll(numI,1).name;
                info=parseName(fName);
                baseName=[info.patName  '_' info.markerName '_' info.markerColor];                
                copyfile([dirSave '\' baseName '_' oldstrAdd 'IRGB1.mat'],...
                    [dirSave '\' baseName  '_' strAdd 'IRGB1.mat']);  
                copyfile([dirSave '\' baseName '_' oldstrAdd 'IRGB2.mat'],...
                    [dirSave '\' baseName  '_' strAdd 'IRGB2.mat']);  
                copyfile([dirSave '\' baseName '_' oldstrAdd 'IRGB3.mat'],...
                    [dirSave '\' baseName  '_' strAdd 'IRGB3.mat']);  
                copyfile([dirSave '\' baseName '_' oldstrAdd 'IRGB4.mat'],...
                    [dirSave '\' baseName  '_' strAdd 'IRGB4.mat']);  
                copyfile([dirSave '\' baseName '_' oldstrAdd 'Regs.mat'],...
                    [dirSave '\' baseName  '_' strAdd 'Regs.mat']);  
                copyfile([dirSave '\' baseName '_' oldstrAdd 'RegsF.mat'],...
                    [dirSave '\' baseName  '_' strAdd 'RegsF.mat']);  
                copyfile([dirSave '\' baseName '_' oldstrAdd 'Itriangle.mat'],...
                    [dirSave '\' baseName  '_' strAdd 'Itriangle.mat']);            
            end
            
            for numFactorRed=startR:numel(stReg)
                fRedRegister=stReg{numFactorRed}.factorRed;
                disp(['Registration at detail level=' num2str(fRedRegister)]);
                clear st; st=stReg{numFactorRed}.st;
                templates=templates(randperm(numel(templates),numel(templates)));
                disp(['ordered templates:'; templates]);
                for numTemp=startM: numel(templates)
                    tempMarker=templates{numTemp};
                    %% Allinea ogni immagine al template!
                    for numI=1:numel(fnsAll) 
                        fName=fnsAll(numI,1).name;
                        info=parseName(fName);
                        baseName=[info.patName '_' info.markerName '_' info.markerColor];
                        if (~strcmp(info.markerName,tempMarker))     
                           %%% se non il template uso le Areas in template e le cerco con template matching 
                           %%% vicino a quelle segnate, MA dopo che ho
                           %%% registrato le imgs alla corrispettiva template!        
                           %disp(['Align to marker']);
                           %%% RegsF_marker
                           strBef=[info.patName];
                           strAfter=[info.markerColor];
                           StrRegs_marker=load([dirSave '\'  strBef '_' tempMarker '_' strAfter '_' strAdd 'Regs.mat']);
                           Regs_marker=logical(StrRegs_marker.Regs);  
                           StrRegsF_marker=load([dirSave '\'  strBef '_' tempMarker '_' strAfter '_' strAdd 'RegsF.mat']);
                           RegsF_marker=logical(StrRegsF_marker.RegsF); 
                           clear StrRegs_marker StrRegsF_marker; 
                           % carico le var della img da analizzare
                           load([dirSave '\' baseName '_'  strAdd 'Regs.mat']); 
                           load([dirSave '\' baseName '_'  strAdd 'RegsF.mat']);  
                           load([dirSave '\' baseName '_'  strAdd 'Itriangle.mat']);  
                           load([dirSave '\' baseName '_'  strAdd 'IRGB1.mat']);
                           load([dirSave '\' baseName '_'  strAdd 'IRGB2.mat']);
                           load([dirSave '\' baseName '_'  strAdd 'IRGB3.mat']);
                           load([dirSave '\' baseName '_'  strAdd 'IRGB4.mat']);
                           IRGB=[IRGB1 IRGB2; IRGB3 IRGB4];
                           clear IRGB1 IRGB2 IRGB3 IRGB4;                  
                           Regs=logical(Regs); 
                           RegsF=logical(RegsF);
                           Itriangle=logical(Itriangle);
                           Itriangle(~RegsF)=false;   
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
                           % uint8(Itriangle_marker)+...
                           imgmove=uint8(Regs)*val/2+uint8(RegsF)*val/2+...
                               (uint8(RegsF)-uint8(imerode(RegsF,st)))*val/2; %+...
                               % uint8(Itriangle);
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
                                  % disp(['TRANSFORMATION CON ' upper(strMethod)]);
                                   if isfinite(valcheck); kappaBOld=kappaB; corrOld=corr; end;
                                   tform=RegStruct.tform;
                                   RIn=imref2d(szImg);
                                   Regs=logical(imwarp(Regs,RIn,tform,methodRed,...
                                       'OutputView',ROut));
                                   Regs=logical(bwareaopen(Regs,threshSmallAreas));
                                   RegsF=logical(imwarp(RegsF,RIn,tform,methodRed,...
                                   'OutputView',ROut));               
                                   RegsF=logical(bwareaopen(RegsF,threshSmallAreas));
                                   Itriangle=logical(imwarp(Itriangle,RIn,tform,methodRed,...
                                   'OutputView',ROut));               
                                   Itriangle=logical(bwareaopen(Itriangle,threshSmallAreas));
                                   for ch=1:3  %#ok<ALIGN>
                                       img(:,:,ch)=uint8(imwarp(IRGB(:,:,ch),RIn,...
                                           tform,methodRed,'OutputView',ROut)); end;
                                   clear IRGB; IRGB=img; clear img; 
                                   clear RIn tform kappaB moving RegStruct imgmove;
                                   % imgtemp rimane uguale ma imgmove cambia!!
                                   imgmove=uint8(Regs)*val/2+uint8(RegsF)*val/2+...
                                        (uint8(RegsF)-uint8(imerode(RegsF,st)))*val/2;
                               else
                                  % disp(['No TRansformation con ' strMethod ':'...
                                  % 'flagKappa= ' num2str(flagKappa) ' - flagCorr= ' ...
                                  %     num2str(flagCorr) ' - flagStd= ' ...
                                   %    num2str(flagStd)]); 
                               end
                               clear szImg; szImg=size(Regs);
                               clear RegStruct moving flagKappa flagCorr flagStd;
                           end
                           %% ora controlla che non ci siano probs di dimensione 
                           if ((szTemp(1)~=size(Regs,1)) || (szTemp(2)~=size(Regs,2)))
                               disp('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
                               disp('!!!TEMPLATE DIMENSIONS DIFFER FROM IMAGE DIMENSION!!!');
                               disp('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');           
                           else
                               save([dirSave '\' baseName '_Regs.mat'],'Regs'); 
                               save([dirSave '\' baseName '_RegsF.mat'],'RegsF'); 
                               save([dirSave '\' baseName '_Itriangle.mat'],'Itriangle'); 
                               sz=size(Regs);
                               IRGB1=IRGB(1:round(sz(1)/2),1:round(sz(2)/2),:);
                               IRGB2=IRGB(1:round(sz(1)/2),round(sz(2)/2)+1:end,:);
                               IRGB3=IRGB(round(sz(1)/2)+1:end,1:round(sz(2)/2),:);
                               IRGB4=IRGB(round(sz(1)/2)+1:end,round(sz(2)/2)+1:end,:);
                               save([dirSave '\' baseName  '_IRGB1.mat'], 'IRGB1');
                               save([dirSave '\' baseName  '_IRGB2.mat'], 'IRGB2');
                               save([dirSave '\' baseName  '_IRGB3.mat'], 'IRGB3');
                               save([dirSave '\' baseName  '_IRGB4.mat'], 'IRGB4');  
                               clear IRGB1 IRGB2 IRGB3 IRGB4 sz Regs RegsF;
                               clear RegsF_marker Regs_marker Itriangle_marker Regs RegsF Itriangle;
                           end
                       end
                       clear szImg szTemp;
                       clear Regs RegsF IRGB Itriangle;
                       close all     
                    end    
                    close all; clear fns;
                end
            end 
            %% TERMINATA LA REGISTRAZIONE CON PROCUSTE!!
        else; disp(['No automatic registration of shapes']); end
        if (manualLandmarks) %#ok<ALIGN>
            %% USO I TRIANGOLI MANUALI ORA!!!
            numFactorRed=numel(stReg);
            fRedRegister=stReg{numFactorRed}.factorRed;
            disp(['Hierarchical registration based on Manual Landmarks at detail level=' num2str(fRedRegister)]);
            templates=templates(randperm(numel(templates),numel(templates)));
            disp(['lista templates:'; templates]);
            %% COPY ALL THE IMAGES TO CHANGE PREEXTENSION 
            %% ("O" into "P" if MH registration has not been performed)
            %% ("" into "P" if MH registration has been performed)
            oldstrAdd=strAdd; strAdd='P';
            for numI=1:numel(fnsAll)
                fName=fnsAll(numI,1).name;
                info=parseName(fName);
                baseName=[info.patName '_' info.markerName '_' info.markerColor];                
                copyfile([dirSave '\' baseName '_' oldstrAdd 'IRGB1.mat'],...
                    [dirSave '\' baseName  '_' strAdd 'IRGB1.mat']);  
                copyfile([dirSave '\' baseName '_' oldstrAdd 'IRGB2.mat'],...
                    [dirSave '\' baseName  '_' strAdd 'IRGB2.mat']);  
                copyfile([dirSave '\' baseName '_' oldstrAdd 'IRGB3.mat'],...
                    [dirSave '\' baseName  '_' strAdd 'IRGB3.mat']);  
                copyfile([dirSave '\' baseName '_' oldstrAdd 'IRGB4.mat'],...
                    [dirSave '\' baseName  '_' strAdd 'IRGB4.mat']);  
                copyfile([dirSave '\' baseName '_' oldstrAdd 'Regs.mat'],...
                    [dirSave '\' baseName  '_' strAdd 'Regs.mat']);  
                copyfile([dirSave '\' baseName '_' oldstrAdd 'RegsF.mat'],...
                    [dirSave '\' baseName  '_' strAdd 'RegsF.mat']);  
                copyfile([dirSave '\' baseName '_' oldstrAdd 'Itriangle.mat'],...
                    [dirSave '\' baseName  '_' strAdd 'Itriangle.mat']);            
            end
            val=255; valcheck=val;
            for numTemp=startM: numel(templates)
                tempMarker=templates{numTemp};
                for numI=1:numel(fnsAll) 
                    fName=fnsAll(numI,1).name;
                    info=parseName(fName);
                    baseName=[info.patName '_' info.markerName '_' info.markerColor];
                    if (~strcmp(info.markerName,tempMarker))     
                       strBef=[info.patName];
                       strAfter=[info.markerColor];
                       StrRegs_marker=load([dirSave '\'  strBef '_' tempMarker '_' strAfter '_' strAdd 'Regs.mat']);
                       Regs_marker=logical(StrRegs_marker.Regs);  
                       StrRegsF_marker=load([dirSave '\'  strBef '_' tempMarker '_' strAfter '_' strAdd 'RegsF.mat']);
                       RegsF_marker=logical(StrRegsF_marker.RegsF); 
                       clear StrRegs_marker StrRegsF_marker; 
                       StrTr_marker=load([dirSave '\'  strBef '_' tempMarker '_' strAfter '_' strAdd 'Itriangle.mat']);
                       Itriangle_marker=logical(StrTr_marker.Itriangle); 
                       clear StrRegs_marker StrRegsF_marker StrTr_marker; 
                       Itriangle_marker(~RegsF_marker)=false;
                       % carico le var della img da analizzare
                       load([dirSave '\' baseName '_'  strAdd 'Regs.mat']); 
                       load([dirSave '\' baseName '_'  strAdd 'RegsF.mat']);  
                       load([dirSave '\' baseName '_'  strAdd 'Itriangle.mat']);  
                       load([dirSave '\' baseName '_'  strAdd 'IRGB1.mat']);
                       load([dirSave '\' baseName '_'  strAdd 'IRGB2.mat']);
                       load([dirSave '\' baseName '_'  strAdd 'IRGB3.mat']);
                       load([dirSave '\' baseName '_'  strAdd 'IRGB4.mat']);
                       IRGB=[IRGB1 IRGB2; IRGB3 IRGB4];
                       clear IRGB1 IRGB2 IRGB3 IRGB4;
                       Regs=logical(Regs); 
                       RegsF=logical(RegsF);
                       Itriangle=logical(Itriangle);
                       Itriangle(~RegsF)=false;

                       szTemp=size(Regs_marker);
                       szImg=size(Regs);
                       if ((szTemp(1)~=size(Regs,1)) || (szTemp(2)~=size(Regs,2)))
                            disp('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
                           disp('!!!TEMPLATE DIMENSIONS DIFFER FROM IMAGE DIMENSION!!!');
                           disp('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
                           dbstop; end
                       ROut=imref2d(szTemp);              
                       imgtemp=uint8(Itriangle_marker)*val;
                       imgmove=uint8(Itriangle)*val;
                       if isfinite(valcheck) %#ok<ALIGN>
                           imove=imresize(imgmove,fRedRegister,'Method',methodRed);
                           itemp=imresize(imgtemp,fRedRegister,'Method',methodRed);
                           resStruct=kappa(confusionmat(imove(:)>0,itemp(:)>0));             
                           kappaBOld=resStruct.k; clear resStruct;
                           corrOld=corr2(imove,itemp);
                       else; kappaBOld=0; corrOld=0; end
                       for nReg=1:numel(regMethod)
                           strMethod=regMethod{nReg};
                           RegStruct=registrazioneSingola(imgtemp,imgmove,...
                               strMethod,fRedRegister,methodRed,val);
                           if isfinite(valcheck) %#ok<ALIGN> 
                               kappaB=RegStruct.kappa; corr=RegStruct.corr;
                               flagKappa=(kappaB>=kappaBOld+stReg{numFactorRed}.step);
                               flagCorr=(corr>=corrOld+stReg{numFactorRed}.step);
                           else; flagKappa=true; flagCorr=true; end;
                           moving=double(RegStruct.moved);
                           flagStd=(std(moving(:))>0.1);
                           if ((flagKappa || flagCorr) && flagStd) 
%                                disp(['TRASFORMATION CON ' upper(strMethod)]);
                               if isfinite(valcheck); kappaBOld=kappaB; corrOld=corr; end;
                               tform=RegStruct.tform;
                               RIn=imref2d(szImg);
                               Regs=logical(imwarp(Regs,RIn,tform,methodRed,...
                                   'OutputView',ROut));
                               Regs=logical(bwareaopen(Regs,threshSmallAreas));
                               RegsF=logical(imwarp(RegsF,RIn,tform,methodRed,...
                               'OutputView',ROut));               
                               RegsF=logical(bwareaopen(RegsF,threshSmallAreas));
                               Itriangle=logical(imwarp(Itriangle,RIn,tform,methodRed,...
                               'OutputView',ROut));               
                               Itriangle=logical(bwareaopen(Itriangle,threshSmallAreas));
                               for ch=1:3  %#ok<ALIGN>
                                   img(:,:,ch)=uint8(imwarp(IRGB(:,:,ch),RIn,...
                                       tform,methodRed,'OutputView',ROut)); end;
                                    clear IRGB; IRGB=img; clear img; 
                                    clear RIn tform kappaB moving RegStruct;
                               clear imgmove;
                               % imgtemp rimane uguale ma imgmove cambia!!
                               imgmove=uint8(Itriangle)*val;
                           else
                           end 
                           clear szImg; szImg=size(Regs);
                           clear RegStruct moving flagKappa flagCorr flagStd;
                       end

                       if ((szTemp(1)~=size(Regs,1)) || (szTemp(2)~=size(Regs,2)))
                           disp('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
                           disp('!!!TEMPLATE DIMENSIONS DIFFER FROM IMAGE DIMENSION!!!');
                           disp('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');            
                       else
                           save([dirSave '\' baseName '_' strAdd 'Regs.mat'],'Regs'); 
                           save([dirSave '\' baseName '_' strAdd 'RegsF.mat'],'RegsF'); 
                           save([dirSave '\' baseName '_' strAdd 'Itriangle.mat'],'Itriangle'); 
                           sz=size(Regs);
                           IRGB1=IRGB(1:round(sz(1)/2),1:round(sz(2)/2),:);
                           IRGB2=IRGB(1:round(sz(1)/2),round(sz(2)/2)+1:end,:);
                           IRGB3=IRGB(round(sz(1)/2)+1:end,1:round(sz(2)/2),:);
                           IRGB4=IRGB(round(sz(1)/2)+1:end,round(sz(2)/2)+1:end,:);
                           save([dirSave '\' baseName  '_' strAdd 'IRGB1.mat'], 'IRGB1');
                           save([dirSave '\' baseName  '_' strAdd 'IRGB2.mat'], 'IRGB2');
                           save([dirSave '\' baseName  '_' strAdd 'IRGB3.mat'], 'IRGB3');
                           save([dirSave '\' baseName  '_' strAdd 'IRGB4.mat'], 'IRGB4');  
                           clear IRGB1 IRGB2 IRGB3 IRGB4 sz Regs RegsF;
                           clear RegsF_marker Regs_marker Itriangle_marker Regs RegsF Itriangle;
                       end
                   end
                   clear szImg szTemp;
                   clear Regs RegsF IRGB Itriangle;
                   close all     
                end    
                close all; 
            end 
            %% END MANUAL LANDMARKS REGISTRATION
           clear fns;
        else; disp('No Registration with manual landmarks'); strAdd=''; end
    
        %% NEW MARKER SEGMENTATION AND DENSITY ESTIMATION 
        %% AFTER ANY REGISTRATION
        disp('Marker Segmentation and Density Estimation after registration');
        disp(strTitle);
        for numI=1:numel(fnsAll)
            fName=fnsAll(numI,1).name;
            info=parseName(fName);
            markerName=info.markerName;
            baseName=[info.patName '_' info.markerName '_' info.markerColor];
            disp([num2str(numI) '->' baseName '<-']);
            load([dirSave '\' baseName '_' strAdd 'RegsF.mat']); 
            load([dirSave '\' baseName '_' strAdd 'IRGB1.mat']);
            load([dirSave '\' baseName '_' strAdd 'IRGB2.mat']);
            load([dirSave '\' baseName '_' strAdd 'IRGB3.mat']);
            load([dirSave '\' baseName '_' strAdd 'IRGB4.mat']);
            IRGB=[IRGB1 IRGB2; IRGB3 IRGB4];
            clear IRGB1 IRGB2 IRGB3 IRGB4; 

            if exist('RegsF','var') && exist('IRGB','var')
                if strcmpi(info.markerColor,'R') %#ok<ALIGN>
                    markers=logical(redMarkers(IRGB,RegsF,MdlKNN8Str,stepFR,stepFC,thrArea));
                else; if strcmpi(info.markerColor,'M')
                    markers=logical(brownMarkers(IRGB,RegsF,stepFR,stepFC,thrArea)); end; end
                markersConc=logical(imdilate(markers,stBig));
                markersConc=bwareaopen(markersConc,thrAreaConc);       
                areaReg=double(sum(uint8(RegsF(:))));
                areaMarkers=double(sum(uint8(markers(:))));
                percArea=areaMarkers/areaReg;            
                areaMarkersConc=double(sum(uint8(markersConc(:))));
                percAreaConc=areaMarkersConc/areaReg;            
                str=[baseName sprintf('\t') num2str(areaReg) sprintf('\t')...
                    num2str(areaMarkers) sprintf('\t') num2str(percArea) sprintf('\t')...
                    num2str(areaMarkersConc) sprintf('\t') num2str(percAreaConc)];
                disp(str);
                fprintf(fidDensity, '%s\n',str);
                clear areaReg areaMarkers percArea areaMarkersConc perAreaConc str;
                imgMarkers=cat(3,uint8(markers),uint8(markers),uint8(markers));
                imgMarkers=imgMarkers.*IRGB;
                imgMarkersConc=cat(3,uint8(markersConc),uint8(markersConc),uint8(markersConc));
                imgMarkersConc=imgMarkersConc.*IRGB;
                sz=size(RegsF);
                if (sz(2)>dimLimit); stepFC=uint32(round(sz(2)/dimLimit)); end
                if (sz(1)>dimLimit); stepFR=uint32(round(sz(1)/dimLimit)); end
                taglioC=sz(2)/uint32(stepFC);
                taglioR=sz(1)/uint32(stepFR);               
                BBR=(1:taglioR:sz(1));
                BBC=(1:taglioC:sz(2));
                if (BBR(end)~=sz(1)) && ((sz(1)-BBR(end))<2); BBR(end)=sz(1);
                else; if (BBR(end)~=sz(1)); BBR=[BBR sz(1)]; end; end
                if (BBC(end)~=sz(2)) && ((sz(2)-BBC(end))<2); BBC(end)=sz(2);    
                else; if (BBC(end)~=sz(2)); BBC=[BBC sz(2)]; end; end
                strCut='';
                for i=1: length(BBC)-1
                    for j=1:length(BBR)-1
                        if (stepFR>1 || stepFC>1); strCut=['_' num2str(i) '_' num2str(j)];end
                        imwrite(IRGB(BBR(j):BBR(j+1),BBC(i):BBC(i+1),:),...
                              [dirSaveMarker '\' baseName '_IRGB' strCut '.jpg']);
                        regs=RegsF(BBR(j):BBR(j+1),BBC(i):BBC(i+1));
                        mark=markers(BBR(j):BBR(j+1),BBC(i):BBC(i+1));
                        markConc=markersConc(BBR(j):BBR(j+1),BBC(i):BBC(i+1));
                        regs(mark)=false;
                        r=cat(3,regs,regs,regs);
                        imark=imgMarkers(BBR(j):BBR(j+1),BBC(i):BBC(i+1),:);
                        imark(r)=uint8(round(max(imark(:))/10)); 
                        imwrite(imark,[dirSaveMarker '\' baseName '_RGBmarkers' strCut '.jpg']); 
                        clear imark;
                        imark=imgMarkersConc(BBR(j):BBR(j+1),BBC(i):BBC(i+1),:);
                        imark(r)=uint8(round(max(imark(:))/10)); clear r;
                        imwrite(imark,[dirSaveMarker '\' baseName '_RGBmarkersConc' strCut '.jpg']); 
                        clear imark;
                        imwrite(mark,[dirSaveMarker '\' baseName '_marker' strCut '.jpg']);
                        imwrite(markConc,[dirSaveMarker '\' baseName '_markerConc' strCut '.jpg']);
                        clear mark markConc; 
                    end
                end
                clear imgMarkers markers markersConc;
            end
        end
        clear fnsAll
    else
        if numel(templates)==1 disp('No registration with only one template!'); end
    end
    if numel(templates)>1
        if numel(templates)>3 %#ok<ALIGN>
            j=1;
            temp=templates(2:end,1);
            while numel(temp)>0 
                tempTriplets{1,j}=templates{1};
                tempTriplets{2,j}=temp{1};
                indaux=randi([2,numel(templates)],1,1);
                if numel(temp)>1; tempTriplets{3,j}=temp{2}; 
                else; tempTriplets{3,j}=templates{indaux}; end
                temp=temp(3:end,1); j=j+1;
            end    
        else; tempTriplets=templates; end
        SaveOverlaps(dirImgs,dirSave,tempTriplets, ...
            [true,automaticRegister,manualLandmarks],thrArea,dimLimit); 
        
    end
    fclose(fidDensity);        
end

