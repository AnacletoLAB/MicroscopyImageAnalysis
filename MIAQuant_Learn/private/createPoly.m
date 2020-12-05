function Ip=createPoly(Ip0,redFactor)
    st=strel('disk',1);
    if any(Ip0(:))
        if (nargin==2) 
            szOrig=size(Ip0);
            Ip0=imresize(Ip0,redFactor,'method','nearest');
        end
        cent=regionprops(logical(Ip0),'Centroid');
        Ip=Ip0;
        for nC1=1:numel(cent)-1
            p1=round(cent(nC1,1).Centroid); 
            for nC2=nC1+1:numel(cent)
                p2=round(cent(nC2,1).Centroid);
                Ip=Ip | imdilate(drawLine(Ip,p1(1),p1(2),p2(1),p2(2)),st); 
                clear p2;
            end
            clear p1;
        end   
        clear cent;
        Ip=imerode(imfill(Ip,'holes'),st); 
        areas=regionprops(Ip,'Area');
        Ip=bwareaopen(Ip,max([areas.Area])-1);
        clear areas;
        if (nargin==2); Ip=imresize(Ip,szOrig,'method','nearest'); end
    else; Ip=false(size(Ip0)); end
end