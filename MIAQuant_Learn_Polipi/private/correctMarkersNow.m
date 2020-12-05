function newMarkers = correctMarkersNow(I,markers,Regs)
    %Stampa l'immagine dei markers e permette di correggerla
    global FigPosition magFactor scrsz fScreen
    fScreen=2; scrsz = get(groot,'ScreenSize'); 
    imgMarkers=drawMarkers(I,markers,Regs);
    res = [Inf Inf Inf Inf];
    fig=figure('Name', 'Click on wrong markers', ...
                'OuterPosition', FigPosition);
    fig.WindowState='maximized';     
    hold on; imshow(imgMarkers, ...
                        'InitialMagnification', magFactor);
    [Xareas , Yareas]= getpts; Xareas=uint32(Xareas);Yareas=uint32(Yareas);
    for i=1: size(Xareas,1)
        xc=Xareas(i); yc=Yareas(i);
        xmin=max(xc-(scrsz(3)/fScreen),1); xmax=min(xc+(scrsz(3)/fScreen)-1,size(imgMarkers,2));
        ymin=max(yc-(scrsz(4)/fScreen),1); ymax=min(yc+(scrsz(4)/fScreen-1),size(imgMarkers,1));
        figTitle = 'Draw areas touching wrong markers'; msg='';
        resPoly = pointsInPoly(imgMarkers(ymin:ymax,xmin:xmax,:), figTitle, msg);
        [yy,xx] = find(resPoly.allShapes);
        markDel = bwselect(markers,round(xx)+double(xmin)-1, round(yy)+double(ymin)-1);
        if any(markDel(:)); markers(markDel)=false; end
        clear imgMarkers; imgMarkers=drawMarkers(I,markers,Regs);
        imshow(imgMarkers, 'InitialMagnification', magFactor);
    end

    fig=figure('Name', 'Click on MISSING markers', ...
                'OuterPosition', FigPosition);
    fig.WindowState='maximized';     
    hold on; imshow(imgMarkers, ...
                        'InitialMagnification', magFactor);
    [Xareas , Yareas]= getpts; Xareas=uint32(Xareas);Yareas=uint32(Yareas);
    for i=1: size(Xareas,1)
        xc=Xareas(i); yc=Yareas(i);
        xmin=max(xc-(scrsz(3)/fScreen),1); xmax=min(xc+(scrsz(3)/fScreen)-1,size(imgMarkers,2));
        ymin=max(yc-(scrsz(4)/fScreen),1); ymax=min(yc+(scrsz(4)/fScreen-1),size(imgMarkers,1));
        
        figTitle = 'Draw perimeter of missing markers'; msg='';
        resPoly = pointsInPoly(imgMarkers(ymin:ymax,xmin:xmax,:), figTitle, msg);
        piece = markers(ymin:ymax,xmin:xmax) | resPoly.allShapes;
        markers(ymin:ymax,xmin:xmax) = piece;
        clear imgMarkers; imgMarkers=drawMarkers(I,markers,Regs);
        imshow(imgMarkers, 'InitialMagnification', magFactor);
    end
    
    newMarkers.markers = markers;
    newMarkers.imgMarkers = imgMarkers;
    
end

