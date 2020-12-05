function markBIN = correctMarkersLater(img,markBIN,R)
    %Stampa l'immagine dei markers e permette di correggerla
    global FigPosition magFactor
    
    dirImgs=uigetdir(...
            ['C:' slash 'DATI' slash 'Elab_Imgs_Mediche' slash 'MIA' slash 'immagini_MIA'],...
        'Select the img folder'); end %#ok<ALIGN>
    
    fnsAll=[dir([dirImgs slash '*.tif']);
                dir([dirImgs slash '*.jpg']);
                dir([dirImgs slash '*.png']);];

    imgMarkers=drawMarkers(img,markBIN,R);

    while res(3)+res(4)>10
        fig=figure('Name', 'Draw rectangle containing wrong markers', ...
                'OuterPosition', FigPosition); hold on; imshow(imgMarkers, ...
                        'InitialMagnification', magFactor);
        res = getrect(fig);
        ymin = res(2); ymax = ymin + res(4); xmin=res(1)+res(3); 
        figTitle = 'Draw areas with wrong markers'; msg='';
        resPoly = pointsInPoly(imgMarkers(ymin:ymax,xmin:xmax,:), figTitle, msg);
        [Yareas,Xareas] = find(resPoly.allShapes);
        markBIN(bwselect(markBIN,Xareas+xmin-1, Yareas+ymin-1))=false;
        imgMarkers=drawMarkers(img,markBIN,R);
    end

    while res(3)+res(4)>10
        fig=figure('Name', 'Draw rectangle containing missing markers', ...
                'OuterPosition', FigPosition); hold on; imshow(imgMarkers, ...
                        'InitialMagnification', magFactor);
        res = getrect(fig);
        ymin = res(2); ymax = ymin + res(4); xmin=res(1)+res(3); 
        figTitle = 'Draw missing markers'; msg='';
        resPoly = pointsInPoly(imgMarkers(ymin:ymax,xmin:xmax,:), figTitle, msg);
        piece = markBIN(ymin:ymax,xmin:xmax) || resPoly.allShapes;
        markBIN(ymin:ymax,xmin:xmax) = piece;
    end
end

