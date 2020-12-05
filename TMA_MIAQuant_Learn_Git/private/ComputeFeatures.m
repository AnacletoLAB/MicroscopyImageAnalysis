function Ifeats = ComputeFeatures(IRGB)
    n0 = 3; n1=5; n2=7; n3=11;
    ones0=ones(n0);  ones1=ones(n1);  ones2=ones(n2);  ones3=ones(n3);
    IRGB=double(IRGB);
    IRGB(IRGB==0)=1;
    IRGBDiv=cat(3,IRGB(:,:,1)./IRGB(:,:,2),IRGB(:,:,1)./IRGB(:,:,3),IRGB(:,:,2)./IRGB(:,:,3));
    
    IRGBMean0=imboxfilt(IRGB,[n0 n0]);
    IRGBMean1=imboxfilt(IRGB,[n1 n1]);
    IRGBMean2=imboxfilt(IRGB,[n2 n2]);
    IRGBMean3=imboxfilt(IRGB,[n3 n3]);

    IRGBStd0=stdfilt(IRGB,ones1);
    IRGBStd1=stdfilt(IRGB,ones1);
    IRGBStd2=stdfilt(IRGB,ones2);
    IRGBStd3=stdfilt(IRGB,ones3);

    IRGBrange0=rangefilt(IRGB,ones0);
    IRGBrange1=rangefilt(IRGB,ones1);
    IRGBrange2=rangefilt(IRGB,ones2);
    IRGBrange3=rangefilt(IRGB,ones3);

    
    Ifeats=cat(3,IRGB,IRGBDiv, ...
                IRGBMean0,IRGBMean1,IRGBMean2,IRGBMean3, ...
                IRGBStd0,IRGBStd1,IRGBStd2,IRGBStd3,...
                IRGBrange0,IRGBrange1,IRGBrange2,IRGBrange3); 
    clear IRGBMean0 IRGBMean1 IRGBMean2 IRGBMean3 ...
            IRGBrange0 IRGBrange1 IRGBrange2 IRGBrange3 ...
            IRGBStd0 IRGBStd1 IRGBStd2 IRGBStd3 IRGBentropy1 IRGBentropy2 IRGBentropy3 ...
            IRGBDiv;

end