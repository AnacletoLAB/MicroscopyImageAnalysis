function imgMarkers = drawMarkers(img, markBIN, R, LineWidthM, LineWidthR)
    
    if nargin<5; LineWidthR = 3; end
    if nargin<4; LineWidthM = 3; end
    stR = strel('disk', LineWidthR);
    stM = strel('disk', LineWidthM);
    
    RegsR = R==1;
    RegsY = R==2;
    RegsG = R==3;
    
    imgMarkers = img;

    markersR = markBIN & RegsR;
    markersY = markBIN & RegsY;
    markersG = markBIN & RegsG;
    mark = markersR;
    markersBorder = logical(mark-imerode(mark>0,stM));
    regBorder = logical(imdilate(RegsR, stR)-RegsR);
    imgMarkers(cat(3,regBorder,regBorder,regBorder)) = 0;
    imgMarkers(cat(3,markersBorder,markersBorder,markersBorder))=0;
    imgMarkers(cat(3,markersBorder, ...
            false(size(markersBorder)),false(size(markersBorder))))= ...
                100+(155/3)* mark(markersBorder);
    clear markersBorder regBorder
    
    mark = markersY;
    markersBorder = logical(mark-imerode(mark>0,stM));
    regBorder = logical(imdilate(RegsY, stR)-RegsY);
    imgMarkers(cat(3,regBorder,regBorder,regBorder)) = 0;
    imgMarkers(cat(3,markersBorder,markersBorder,markersBorder))=0;
    imgMarkers(cat(3,false(size(markersBorder)), ...
        markersBorder,false(size(markersBorder))))= ...
            100+(155/3)* mark(markersBorder);
    imgMarkers(cat(3, markersBorder,false(size(markersBorder)),...
        false(size(markersBorder))))= ...
            100+(155/3)* mark(markersBorder);
    clear markersBorder regBorder
    
    mark = markersG;
    markersBorder = logical(mark-imerode(mark>0,stM));
    regBorder = logical(imdilate(RegsG, stR)-RegsG);
    imgMarkers(cat(3,regBorder,regBorder,regBorder)) = 0;
    imgMarkers(cat(3,markersBorder,markersBorder,markersBorder))=0;
    imgMarkers(cat(3,false(size(markersBorder)), ...
        markersBorder,false(size(markersBorder))))= ...
        100+(155/3)* mark(markersBorder);

end

