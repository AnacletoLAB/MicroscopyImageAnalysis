function MIAQuant_Learn_Polipi(dirImgs)
% Last Update 09 May 2019
% % Copyright: Elena Casiraghi

    global fScreen scrsz FigPosition msgPosition magFactor
    global optMsg
    warning off;
    clc;
    close all;
    optMsg.Interpreter = 'tex';
    optMsg.WindowStyle = 'normal';
    magFactor = 200;
    fScreen=10; scrsz = get(groot,'ScreenSize'); 
    FigPosition=[0 0  1 1];
    msgPosition=[100 scrsz(4)/2];
    
    warning off;
    strClassMarkers='Markers'; 
    
    if (nargin==0); dirImgs=uigetdir(...
            ['C:' filesep 'DATI' filesep 'Elab_Imgs_Mediche' filesep 'MIA' filesep 'immagini_MIA'],...
        'Select the img folder'); end %#ok<ALIGN>


    %% CREA LA LISTA DEI MARKERS (cell array templates)
%     if (nargin<2)
%         lineMarkers=input([newline '-------------------' newline 'Insert the '...
%             '(space separated) marker Names (e.g. CD3 CD68 CD163) ' newline],'s');
%         pos=strfind(lineMarkers,' ');
%         templates={};
%         oldPos=0;
%         for i=1:numel(pos); templates{i,1}=lineMarkers(oldPos+1:pos(i)-1); oldPos=pos(i); end
%         templates{end+1,1}=lineMarkers(oldPos+1:end);
%     end
    disp(['DIRECTORY PATHNAME: ' dirImgs]);
    dirClassifiers=['.' filesep 'TrainedClassifiers'];
    dimLimitOut=8000; dimLimitIn=8000;  
%     factorRed=input([newline '-------------------' newline 'If wanted insert the reduction factor'...
%         newline 'e.g: 0.1 for reduction at 10% image size, 0.5 to halve the image size,... ' newline]);
%     if numel(factorRed)==0; factorRed=1; end
    
    factorRed=1;
    dirMasks=[dirImgs filesep 'Masks']; 
    dirAspecifico = [dirImgs filesep 'Aspecifico']; 
    methodRed='nearest';    
    thrArea=3;
    offset=11; 
    st11 = strel('disk',11); st3 = strel('disk',3);
    if ~exist(dirMasks,'dir'); mkdir(dirMasks); end
    disp(dirMasks);
    
    markersDir=[dirImgs filesep strClassMarkers];
    if ~exist(markersDir,'dir'); mkdir(markersDir); end
    
    nameDensity=[markersDir filesep 'MarkerDensityData.txt'];
    fidDensity = fopen(nameDensity,'w');
    
   
    %% FILE CONTENENTE DATI MARKER SEGMENTATION AND DENSITY ESTIMATION 
    %delete(gcp('nocreate')); parpool;
%     strTitle=['Img Name' sprintf('\t') 'TissueArea' sprintf('\t') 'MarkerArea' sprintf('\t') 'MarkerDensity' sprintf('\t')...
%         'Marker Area - Red Tissue' sprintf('\t') 'Red Tissue Area'  sprintf('\t') 'Marker Density w.r.t Red tissue' sprintf('\t') ...
%         'Marker Area - Yellow Tissue' sprintf('\t') 'Yellow Tissue Area' sprintf('\t') 'Marker Density w.r.t Yellow tissue' sprintf('\t') ...
%         'Marker Area - Green Tissue' sprintf('\t') 'Green Tissue Area' sprintf('\t') 'Marker Density w.r.t Green tissue'];
    
    strTitle=['Img Name' sprintf('\t') 'TissueArea' sprintf('\t') 'MarkerArea' sprintf('\t') 'MarkerDensity'];
   

    disp(strTitle);
    
    fprintf(fidDensity, '%s\n',strTitle); clear strTitle;
    
    %% SEGMENTO TUTTE LE TISSUE REGIONS e i manual landmarks
    %inputCorrect = input('Correct Marker later?','s');
    inputCorrect = 'N';
    interactive = false;
    fnsAll = dir([dirImgs filesep '*.tif']);

    baseNames = cell(numel(fnsAll),1);
    regAreas = NaN(numel(fnsAll),1);
    markerAreas = NaN(numel(fnsAll),1);
    densities = NaN(numel(fnsAll),1);
    for numI= 1:numel(fnsAll)
        fName=fnsAll(numI,1).name
        info=parseName(fName);
        disp(['imgName=' info.patName ...
             ' - Color=' info.markerColor]);
        if ~(contains(info.patName, 'RED') || contains(info.patName, 'BLACK'))
            disp('Immagine Originale: la salto!'); continue;
        end
%         if contains(info.patName, '$');    disp('Da saltare'); continue;
%         end
        baseName=[info.patName '_' info.markerColor];
        disp(baseName)
        if ~exist([dirMasks filesep baseName '_IRGB.mat'],'file') 
            if (factorRed~=1); I=imresize(imread([dirImgs filesep fName]),factorRed,methodRed);
            else; I= imread([dirImgs filesep fName]); end
            I = uint8(I(:,:,1:3));
            IRGB = I-I;
            for nc=1:3; IRGB(:,:,nc) = imgaussfilt(medfilt2(I(:,:,nc))); end
        else
            load([dirMasks filesep baseName '_IRGB.mat'],'IRGB'); 
            load([dirMasks filesep baseName '_IOrig.mat'],'I');
        end
        disp('Marker segmentation and density estimation After Region opening');

        extRegsName = [info.patName '_' info.markerColor '_Regs.mat'];
        extRegsName = [info.patName '_' 'MPolipi' '_Regs.mat'];
        disp([num2str(numI) '->' baseName '<-']);
        
        if exist([dirMasks filesep extRegsName],'file')
            load([dirMasks filesep extRegsName],'Regs');
            Regs = imresize(Regs, [size(IRGB,1), size(IRGB,2)], 'nearest');
        else
            Regs = ones(size(IRGB,1), size(IRGB,2)); end
        if exist([dirAspecifico filesep info.patName '_' info.markerColor '.tif'],'file')
            aspecifico = imread([dirAspecifico filesep info.patName '_' info.markerColor '.tif']);
            aspecifico = aspecifico(:,:,1)< 10 & aspecifico(:,:,2)>240 & aspecifico(:,:,3)< 10;
            aspecifico = imresize(aspecifico, [size(IRGB,1), size(IRGB,2)]);
        else; aspecifico = false(size(IRGB,1), size(IRGB,2)); end
        
        binHoles = false(size(Regs)); 
        
       % binHolesinImg = bwareaopen(mean(IRGB,3)<5,1000);
        newR = Regs;
        newR(binHoles) = 0;
        

        if ~exist([markersDir filesep baseName '_markers.mat'],'file') %#ok<ALIGN>
            %% se una immagine ha nome colore= presetCol-addCol
            % presetCol è il colore più selettivo che permette di selezionare 
            % solo porzioni di regioni di marker, 
            % ma tali regioni vengono spesso sottosegmentate
            % addCol è un colore più generico che prende di più ma permette di ottenere
            % zone di marker meglio definite
            % quindi prendo le regioni di marker cercando zone con colore presetCol
            %% e poi uso le forme date dalla ricerca di zone di colore addCol
            sz=size(newR);
           
            markerColor=info.markerColor; 
            disp(['Segment markers with color ' markerColor]);
                
            thrArea = 3;
           
                stepCut(2)=uint32(ceil(double(sz(2))/double(dimLimitOut)));
                stepCut(1)=uint32(ceil(double(sz(1))/double(dimLimitOut)));
                taglioC=uint32(ceil(double(sz(2))/double(stepCut(2))));
                taglioR=uint32(ceil(double(sz(1))/double(stepCut(1))));
                markers= zeros(sz(1),sz(2));
                for i=uint32(1):uint32(stepCut(1))
                    for j=uint32(1):uint32(stepCut(2))
                        miny=max((i-1)*taglioR+1-offset,1);
                        maxy=min(i*taglioR+offset,sz(1));
                        minx=max((j-1)*taglioC+1-offset,1);
                        maxx=min(j*taglioC+offset,sz(2));
                        img=double(IRGB(miny:maxy,minx:maxx,:));  
                        reg=newR(miny:maxy,minx:maxx);
                        mark=par_trees_svm_knn24(img,reg,dimLimitIn,...
                                dirClassifiers, markerColor,thrArea);
                        clear img reg;
                        if (miny>1); miny=miny+offset; mark=mark(1+offset:end,:); end
                        if (maxy<sz(1)); maxy=maxy-offset; mark=mark(1:end-offset,:); end
                        if (minx>1); minx=minx+offset; mark=mark(:,offset+1:end); end
                        if (maxx<sz(2)); maxx=maxx-offset; mark=mark(:,1:end-offset); end
                        markers(miny:maxy,minx:maxx)=mark;
                    end
                end 

                if (interactive && strcmpi(inputCorrect,'N')); markers = correctMarkersNow(I,markers,newR); end
                save([markersDir filesep baseName '_markers.mat'],'markers');
            
        else; load([markersDir filesep  baseName '_markers.mat'],'markers'); end
        
        
        markers(aspecifico) = false;
        markers(~Regs) = false;
       markers = bwareaopen(markers, 35);
        imgMarkers = drawMarkers(I, markers, newR);
        figure; imshow(imgMarkers);
        
        imwrite(I,[markersDir filesep baseName '_Rescaled.tif']);
        imwrite(imgMarkers,[markersDir filesep baseName '_RGBMarkers.tif']);
        imwrite(uint8(markers)*255,[markersDir filesep baseName '_BINmarkers.tif']);
        
        areaReg=double(sum(uint8(newR(:)>0)));
        areaMarkers=double(sum(markers(:)));
        percArea=areaMarkers/areaReg;     

       
        

            str=[baseName sprintf('\t') num2str(areaReg) sprintf('\t')...
            num2str(areaMarkers) sprintf('\t') num2str(percArea)];
        fprintf(fidDensity, '%s\n',str); clear str;
        baseNames(numI,1) =  {baseName};
        regAreas(numI,1) = areaReg;
        markerAreas(numI,1) = areaMarkers;
        densities(numI,1) = percArea;
        
        
        tab = table(baseNames, regAreas, markerAreas, densities, 'VariableNames',{'ImgName','tissueArea','markerArea','markeDensity'});

        clear areaReg areaMarkers percArea areaMarkersG areaMarkersY areaMarkersRed str;
        clear areaRegRed areaRegY areaRegG percAreaRed percAreaG percAreaY;
        
        clear imgMarkers I IRGB Regs;
        close all  
    end
    clear fnsAll;
    fclose(fidDensity);
    writetable(tab, [markersDir filesep 'markerData.xlsx']);
    if strcmpi(inputCorrect,'Y'); CorrectMarkersLater(dirImgs); end
end

