function createRGBColorImgs()
    startV=5; Offset=17; endV=255;
    off=0;
    lar=10;
    R=uint8(ones(255*lar+off*2,255*lar+off*2))*255;
    G=uint8(ones(255*lar+off*2,255*lar+off*2))*255; 
    B=uint8(ones(255*lar+off*2,255*lar+off*2))*255;
    for i=1:255;  R(off+1:end-off,off+(i-1)*lar+1:off+(i*lar))=i; end
    for i=1:255;  G(off+(i-1)*lar+1:off+(i*lar),off+1:end-off)=i; end
    for i=startV:Offset:endV 
        B(:)=1;
        B(off+1:end-off,off+1:end-off)=i;
        I=cat(3, R,G,B); 
        if i>99;imwrite(I,['Colors_B' num2str(i) '.tif']); 
        elseif i>10 && i<100; imwrite(I,['Colors_B0' num2str(i) '.tif']);
        else; imwrite(I,['Colors_B00' num2str(i) '.tif']); end
    end
    R(:)=uint8(1);
    G(:)=uint8(1);
    B(:)=uint8(1);
%     startV=14; Offset=42; endV=255;
%     off=0;
%     lar=10;
%     for i=1:255;  G(off+1:end-off,off+(i-1)*lar+1:off+(i*lar))=i; end
%     for i=1:255;  B(off+(i-1)*lar+1:off+(i*lar),off+1:end-off)=i; end
%     for i=startV:Offset:endV 
%         R(:)=1;
%         R(off+1:end-off,off+1:end-off)=i;
%         I=cat(3, R,G,B); 
%         imwrite(I,['Colors_R' num2str(uint8(floor(i/Offset))) '.tif']); 
%     end
%     R(:)=uint8(1);
%     G(:)=uint8(1);
%     B(:)=uint8(1);
%     startV=28; Offset=42; endV=255;
%     off=0;
%     lar=10;
%     for i=1:255;  B(off+1:end-off,off+(i-1)*lar+1:off+(i*lar))=i; end
%     for i=1:255;  R(off+(i-1)*lar+1:off+(i*lar),off+1:end-off)=i; end
%     for i=startV:Offset:endV 
%         G(:)=1;
%         G(off+1:end-off,off+1:end-off)=i;
%         I=cat(3, R,G,B); 
%         imwrite(I,['Colors_G' num2str(uint8(floor(i/Offset))) '.tif']); 
%     end
end