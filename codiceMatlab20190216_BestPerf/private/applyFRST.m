function I=applyFRST(IColor, stdDev,alpha, N)
    resFRST=zeros(size(IColor,1), size(IColor,2));
    I=zeros(size(IColor));
    N=double(N);
    for nC=1:size(IColor,3)
       iG=IColor(:,:,nC);
       for r=1:+N/5:N
           res=abs(frst2d( iG, r, alpha, stdDev, 'dark' ));
           resFRST=resFRST+...
               res/max(res(:)).*double(max(iG(:))-iG); 
       end
       I(:,:,nC)=resFRST;
    end
    figure; imshow(uint8(I));
end