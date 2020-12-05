function hists = calcolaDistHist(markers, reg,ROI, threshDist, ...
            fStep,fRound,baseName, dirSaveHists,slash)
    st=strel('disk',2);
    xAxisReg=1:fStep:threshDist(1);
    if xAxisReg(end)<threshDist(1); xAxisReg(end+1)=threshDist(1); end
    xAxisROI=1:fStep:threshDist(2);
    if xAxisROI(end)<threshDist(2); xAxisROI(end+1)=threshDist(2); end
    reg=imfill(reg, 'holes');
    borderReg=logical(uint8(imdilate(reg, st))-uint8(reg));
    imgDistBorder=max(bwdist(borderReg),1);
    imgSave=uint8(markers)*128+uint8(borderReg)*128+...
        128*uint8((imgDistBorder<=xAxisReg(end)) & reg);
    imwrite(imgSave,[dirSaveHists slash baseName '_DistBorder.tif']);
    clear imgSave;
    borderDists=round(imgDistBorder(markers(:))*fRound)/fRound; 
    borderDistsCut=borderDists;
    borderDistsCut(borderDistsCut>xAxisReg(end))=[];
    hists.histBorder=myHist(borderDistsCut,xAxisReg);
    hists.xAxisBorder=xAxisReg;
    clear BorderDistsCut;
    
    if any(ROI(:)) 
        borderROI=logical(uint8(imdilate(ROI, st))-uint8(ROI));
        imgDistROI=max(bwdist(borderROI),1); 
        imgSave=uint8(markers)*128+uint8(borderROI)*128+...
            128*uint8((imgDistROI<=xAxisROI(end)) & reg & ~ROI);
        imwrite(imgSave,[dirSaveHists slash baseName '_DistROI.tif']);
        clear imgSave;
        ROIDists=round(imgDistROI(markers(:) & (~ROI(:)))*fRound)/fRound;
        ROIDistsCut= ROIDists;
        ROIDistsCut(ROIDistsCut>xAxisROI(end))=[];
        hists.histROI=myHist( ROIDistsCut,xAxisROI);
        hists.xAxisROI=xAxisROI;
    else
        hists.histROI=NaN;
        hists.xAxisROI=NaN;
    end
    
    
    %% struttura restituita:
%     hists.histBorder = istogramma della distanza dal bordo del tessuto
%     hists.histPOI    = istogramma della distanza dal centroide del tessuto
%     hists.histROI    = istogramma della distanza dal bordo della regione
%     di interesse segnata manualmente (NaN se non c'è regione segnata)
%     hists.histBorderROI= istogramma 2D della distanza dal bordo del 
%                           tessuto e dal bordo della regione
%                           di interesse segnata manualmente 
%                            (NaN se non c'è regione segnata)
end


