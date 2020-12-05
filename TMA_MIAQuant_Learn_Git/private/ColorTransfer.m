function imgRGBNew=ColorTransfer(imgRGB,imgRGBRef)
    imgRef=RGB2LAlphaBeta(imgRGBRef);
    imgIn=RGB2LAlphaBeta(imgRGB);
    for ch=1: size(imgIn,3)
       img=double(imgIn(:,:,ch));
       img=img-mean(img(:));
       img=img/std(img(:));
       img=img*std(std(imgRef(:,:,ch)));
       img=img+mean(mean(imgRef(:,:,ch)));
       imgIn(:,:,ch)=img; clear img;
    end
    imgRGBNew=uint8(round(LAlphaBeta2RGB(imgIn)));
end