function img=drawLine(img, x0,y0,x1,y1,st)
    
    if ((x0==x1) && (y0==y1)); disp('points equal');
    elseif (x0==x1); disp('vertical line');
        for y=uint32(min(y0,y1)):uint32(max(y0,y1)); img(y,uint32(x0))=true; end;
    elseif (y0==y1); disp('horizontal line');
        for x=uint32(min(x0,x1)):uint32(max(x0,x1)); img(uint32(y0),x)=true; end;
    else m=double(y0-y1)/double(x0-x1); q=y0-m*double(x0); 
        for x=uint32(min(x0,x1)):uint32(max(x0,x1)); 
            y=uint32(round(m*double(x)+q)); img(y,x)=true; end;
        for y=uint32(min(y0,y1)):uint32(max(y0,y1)); 
            x=uint32(round((double(y)-q)/m)); img(y,x)=true; end;
    end
    img=imdilate(img,st);
end
            

