function img=drawLine(imgIn, x0,y0,x1,y1)    
    sz1 = size(imgIn,1); sz2 = size(imgIn,2);
    img = false(sz1,sz2); 
    st1 = strel('disk',1);
    if (y0>=1 && y0<=sz1 && x0>=1 && x0<=sz2); img(y0,x0) = true; end
    if (y1>=1 && y1<=sz1 && x1>=1 && x1<=sz2); img(y1,x1) = true; end
    if ((x0==x1) && (y0==y1)) % disp('points equal');
    elseif (x0==x1) %disp('vertical line');
        for y=uint32(min(y0,y1)):uint32(max(y0,y1)) 
            if (y>=1 && y<=sz1 && x0>=1 && x0<=sz2) 
                img(y,uint32(x0)) = true; end 
        end
    elseif (y0==y1) %disp('horizontal line');
        for x=uint32(min(x0,x1)):uint32(max(x0,x1)) 
            if (y0>=1 && y0<=sz1 && x>=1 && x<=sz2)
                img(uint32(y0),x) = true; end; end
    else; m=double(y0-y1)/double(x0-x1); q=y0-m*double(x0); 
        for x=uint32(min(x0,x1)):uint32(max(x0,x1)) %#ok<*ALIGN>
            y=uint32(round(m*double(x)+q)); 
            if (y>=1 && y<=sz1 && x>=1 && x<=sz2); img(y,x) = true; end; end
        for y=uint32(min(y0,y1)):uint32(max(y0,y1)) 
            x=uint32(round((double(y)-q)/m)); 
            if (y>=1 && y<=sz1 && x>=1 && x<=sz2); img(y,x) = true; end; end
    end
    while max(max(bwlabel(img,8)))>1; img = imdilate(img,st1); end
end
            

