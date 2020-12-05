function MIAQuant_Learn_TMANoRheinard(dirImgs)
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


   
    disp(['DIRECTORY PATHNAME: ' dirImgs]);
    dirClassifiers=['.' filesep 'TrainedClassifiers'];
    dimLimitOut=8000; dimLimitIn=8000;  
    factorRed=input([newline '-------------------' newline 'If wanted insert the reduction factor'...
        newline 'e.g: 0.1 for reduction at 10% image size, 0.5 to halve the image size,... ' newline]);
    if numel(factorRed)==0; factorRed=1; end
    
    dirMasks=[dirImgs filesep 'Masks']; 
    
    methodRed='nearest';    
    offset=11; 
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
    TMAs_no = cell(numel(fnsAll),1);
    subImgIndex = cell(numel(fnsAll),1);
    regAreas = NaN(numel(fnsAll),1);
    markerAreas = NaN(numel(fnsAll),1);
    densities = NaN(numel(fnsAll),1);
    for numI= 1:numel(fnsAll)
        fName=fnsAll(numI,1).name;
        info=parseName(fName);
        disp(['imgName=' info.patName ...
              ' - Color=' info.markerColor]);
        baseName=[info.patName  '_' info.markerColor];
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

        extRegsName = [info.patName '_Regs.mat'];
        disp([num2str(numI) '->' baseName '<-']);
        
        if exist([dirMasks filesep extRegsName],'file')
            load([dirMasks filesep extRegsName],'Regs', 'binHoles', 'deposito');
            Regs = imresize(Regs, [size(IRGB,1), size(IRGB,2)], 'nearest');
            binHoles = imresize(binHoles, [size(IRGB,1), size(IRGB,2)], 'nearest');
            if exist('deposito','var');  deposito = imresize(deposito, [size(IRGB,1), size(IRGB,2)], 'nearest');
            else; deposito = false(size(Regs)); end
            if sum(Regs(:))==0 ; areaReg =0; percArea = 0; areaMarkers =0; 
            else; newR = Regs;
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
                    presetmarkerColor=info.markerColor; 
                    thrArea = 30;



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
                                mark = par_trees_svm_knn24(img,reg,dimLimitIn,dirClassifiers, presetmarkerColor, thrArea);
        %                         mark=par_trees_svm_knn24(img,reg,dimLimitIn,...
        %                                 dirClassifiers, presetmarkerColor,basemarkerColor,thrArea,strClassMarkers);
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


                markers(deposito) = false;
                markers(~Regs) = false;
                imgMarkers = drawMarkers(I, markers, newR);
                if any(markers(:)>0); figure; imshow(imgMarkers);

             %   imwrite(I,[markersDir filesep baseName '_Rescaled.tif']);
                 imwrite(imgMarkers,[markersDir filesep baseName '_RGBMarkers.tif']);
                 imwrite(uint8(markers)*255,[markersDir filesep baseName '_BINmarkers.tif']);
                end

                areaReg=double(sum(uint8(newR(:)>0)));
                areaMarkers=double(sum(markers(:))); percArea=areaMarkers/areaReg;
            end
        else; Regs = zeros(size(IRGB,1), size(IRGB,2)); 
            binHoles = true(size(Regs)); 
            deposito = true(size(Regs));   
            areaReg = 0;
            percArea = 0;
            areaMarkers= 0;
        end
       % binHolesinImg = bwareaopen(mean(IRGB,3)<5,1000);
        newR = Regs;
        newR(binHoles) = 0;

        disp(num2str(percArea)); 
        
        
%        RegsR = newR==1;
%         RegsY = newR==2;
%         RegsG = newR==3;
%         
%        markersR = markers & RegsR;
%         markersY = markers & RegsY;
%         markersG = markers & RegsG;
%         
%         areaRegRed=double(sum(uint8(RegsR(:))));
%         areaMarkersRed=double(sum(markersR(:)));
%         percAreaRed=areaMarkersRed/areaRegRed;     
% 
%         areaRegY=double(sum(uint8(RegsY(:))));
%         areaMarkersY=double(sum(markersY(:)));
%         percAreaY=areaMarkersY/areaRegY;  
% 
%         areaRegG=double(sum(uint8(RegsG(:))));
%         areaMarkersG=double(sum(markersG(:)));
%         percAreaG=areaMarkersG/areaRegG; 
% 
%         str=[baseName sprintf('\t') num2str(areaReg) sprintf('\t')...
%             num2str(areaMarkers) sprintf('\t') num2str(percArea) sprintf('\t')...
%             num2str(areaMarkersRed) sprintf('\t') num2str(areaRegRed)...
%             sprintf('\t') num2str(percAreaRed)  sprintf('\t') ...
%             num2str(areaMarkersY) sprintf('\t') num2str(areaRegY)...
%             sprintf('\t') num2str(percAreaY)  sprintf('\t') ...
%             num2str(areaMarkersG) sprintf('\t') num2str(areaRegG)...
%             sprintf('\t') num2str(percAreaG)];
        
            str=[baseName sprintf('\t') num2str(areaReg) sprintf('\t')...
            num2str(areaMarkers) sprintf('\t') num2str(percArea)];
        fprintf(fidDensity, '%s\n',str); clear str;
        postma = strfind(baseName, 'TMA');
        pospiu = strfind(baseName, '+');
        baseNames{numI,1} =  baseName;
        if (postma(1) >0) && (pospiu(1)>0); tma_no = baseName(postma:pospiu-1); else; tma_no = ''; end
        TMAs_no{numI,1} = tma_no;
        if (pospiu>0); idx_meno = strfind(baseName((pospiu+1):end), '-' );
            if numel(idx_meno)>=2;  subimgindex = baseName(pospiu+1: pospiu+idx_meno(2)-1); 
            else; subimgindex = baseName(pospiu+1: end); end
        else; subimgindex = ''; end
        
        subImgIndex{numI,1} = subimgindex;
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

