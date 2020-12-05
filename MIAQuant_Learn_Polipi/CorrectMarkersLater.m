function numCheked = CorrectMarkersLater(dirImgs)
    %Stampa l'immagine dei markers e permette di correggerla
    global FigPosition magFactor scrsz
    scrsz = get(groot,'ScreenSize'); 
    FigPosition=[1 1 scrsz(3)*4/5 scrsz(4)*4/5];
    magFactor = 100;
    slash = filesep;
    if nargin<1; dirImgs=uigetdir(...
            ['C:' slash 'DATI' slash 'Elab_Imgs_Mediche' slash 'MIA' slash 'immagini_MIA'],...
        'Select the img folder');  end
    
    dirMarkers = [dirImgs slash 'Markers'];
    dirRegs = [dirImgs slash 'Masks'];  
    % file con dati corretti
    nameDensity=[dirMarkers slash 'NewMarkerDensityData.txt'];
    if ~exist(nameDensity,'file'); fidDensity = fopen(nameDensity,'w');
    else; fidDensity = fopen(nameDensity,'a'); end
    fprintf(fidDensity,'directory pathname: %s\n',dirImgs); 
    
    strTitle=['--------------marker Density per Img----------------' newline ...
              '-----------------------------------------------' newline...
        'Img Name' sprintf('\t') 'All Tissue Area' sprintf('\t') 'Marker Density w.r.t. All Tissue' ...
        'Marker Area - Red Tissue' sprintf('\t') 'Red Tissue Area'  sprintf('\t') 'Marker Density w.r.t Red tissue' sprintf('\t') ...
        'Marker Area - Yellow Tissue' sprintf('\t') 'Yellow Tissue Area' sprintf('\t') 'Marker Density w.r.t Yellow tissue' sprintf('\t') ...
        'Marker Area - Green Tissue' sprintf('\t') 'Green Tissue Area' sprintf('\t') 'Marker Density w.r.t Green tissue'];
    disp(strTitle);
    fprintf(fidDensity, '%s\n',strTitle); clear strTitle;
    
    fnsAll = [dir([dirImgs slash '*.tif']); dir([dirImgs slash '*.jpg'])];   
    for numI=1:numel(fnsAll)
        fName=fnsAll(numI,1).name;
        info=parseName(fName); 
        baseName=[info.patName '_' info.markerName '_' info.markerColor];
        regsName = [info.patName '_' info.markerName '_Regs.mat'];                    
        markerName = [baseName '_markers.mat'];
        
        % in caso di riscalatura leggo l'immagine che ha la stessa
        % dimensione dei marker - la avevo salvata apposta!
        I = imread([dirMarkers slash baseName '_Rescaled.tif']); 
        if exist([dirMarkers slash markerName],'file')
            load([dirMarkers slash markerName],'markers');
            I = imresize(I, size(markers));
            % se c'era una riscalatura la trovo ridimensionando tutto alla
            % immagine del marker
        else; disp(['no marker found for img: ' fName]); continue; end
        if exist([dirRegs slash regsName],'file')
            load([dirRegs slash regsName],'Regs');
            Regs = imresize(Regs,size(markers),'nearest');
        else; Regs = ones(size(markers)); end
        
        newMarkers = correctMarkersNow(I,markers,Regs);
        markers = newMarkers.markers;
        imgMarkers = newMarkers.imgMarkers;
        
        areaReg=double(sum(uint8(Regs(:)>0)));
        areaMarkers=double(sum(markers(:)));
        percArea=areaMarkers/areaReg;     
        
        RegsR = Regs==1;
        RegsY = Regs==2;
        RegsG = Regs==3;
        markersR = markers & RegsR;
        markersY = markers & RegsY;
        markersG = markers & RegsG;
        
        areaRegRed=double(sum(uint8(RegsR(:))));
        areaMarkersRed=double(sum(markersR(:)));
        percAreaRed=areaMarkersRed/areaRegRed;     

        areaRegY=double(sum(uint8(RegsY(:))));
        areaMarkersY=double(sum(markersY(:)));
        percAreaY=areaMarkersY/areaRegY;  

        areaRegG=double(sum(uint8(RegsG(:))));
        areaMarkersG=double(sum(markersG(:)));
        percAreaG=areaMarkersG/areaRegG; 

        str=[baseName sprintf('\t') num2str(areaReg) sprintf('\t')...
            num2str(areaMarkers) sprintf('\t') num2str(percArea) sprintf('\t')...
            num2str(areaMarkersRed) sprintf('\t') num2str(areaRegRed)...
            sprintf('\t') num2str(percAreaRed)  sprintf('\t') ...
            num2str(areaMarkersY) sprintf('\t') num2str(areaRegY)...
            sprintf('\t') num2str(percAreaY)  sprintf('\t') ...
            num2str(areaMarkersG) sprintf('\t') num2str(areaRegG)...
            sprintf('\t') num2str(percAreaG)];
        fprintf(fidDensity, '%s\n',str); clear str;
        clear areaReg areaMarkers percArea areaMarkersG areaMarkersY areaMarkersRed str;
        clear areaRegRed areaRegY areaRegG percAreaRed percAreaG percAreaY;
        
        save([dirMarkers slash markerName],'markers');
        imwrite(imgMarkers,[dirMarkers slash baseName '_RGBMarkers.tif']);
        imwrite(uint8(markers)*255,[dirMarkers slash baseName '_BINmarkers.tif']);
        
        clear I imgMarkers markers newMarkers
    end
end

