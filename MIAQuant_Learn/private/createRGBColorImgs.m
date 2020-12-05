function createRGBColorImgs()
    startV=5; Offset=25; endV=255;
    offset=0;
    lar=10;
    R=uint8(ones(255*lar+offset*2,255*lar+offset*2))*255;
    for i=1:255;  R(offset+1:end-offset,offset+(i-1)*lar+1:offset+(i*lar))=i; end
    G=uint8(ones(255*lar+offset*2,255*lar+offset*2))*255; 
    for i=1:255;  G(offset+(i-1)*lar+1:offset+(i*lar),offset+1:end-offset)=i; end
    for i=startV:Offset:endV 
        B=uint8(ones(255*lar+offset*2,255*lar+offset*2))*255;
        B(offset+1:end-offset,offset+1:end-offset)=i;
        I=cat(3, R,G,B); 
        imwrite(I,['Colors_B' num2str(i) '.tif']); end
    clear B; B=G; clear G;
%     for i=startV:Offset:endV 
%         G=uint8(ones(255*lar+offset*2,255*lar+offset*2))*255;
%         G(offset+1:end-offset,offset+1:end-offset)=i;
%         I=cat(3, R,G,B); 
%         imwrite(I,['Colors_G' num2str(i) '.tif']); end
%     clear G; G=R; clear R;
%     for i=startV:Offset:endV 
%         R=uint8(ones(255*lar+offset*2,255*lar+offset*2))*255;
%         R(offset+1:end-offset,offset+1:end-offset)=i;
%         I=cat(3, R,G,B); 
%         imwrite(I,['Colors_R' num2str(i) '.tif']); end
    
end