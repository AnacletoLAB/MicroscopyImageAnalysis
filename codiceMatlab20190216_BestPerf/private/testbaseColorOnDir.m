function  testbaseColorOnDir(imgList, mdlTreeBase)
    global slash
    for numI=1:size(imgList,1)
        imgName=imgList(numI,1).name;
        info=parseName(imgName);
        if strcmpi(info.ext,'mat')  %#ok<*ALIGN>
            load([imgDir slash imgName]); %#ok<LOAD>
        else; IRGB=imread([imgList(numI,1).folder slash imgName]); end
        labels=reshape(classifyWithBase(IRGB, mdlTreeBase),size(IRGB,1),size(IRGB,2));
        IRGBOff=IRGB;
        for nC=1:size(IRGB,3)
            IRGBOff(:,:,nC)=IRGBOff(:,:,nC).*uint8(labels==0);
            IRGB(:,:,nC)=IRGB(:,:,nC).*uint8(labels==1);
        end
        figure('Name','Pixels discarded by Base Classifier'); imshow(IRGBOff);
        pause;
%         imwrite(IRGBOff,[info.imgname 'Discarded.jpg']);
%         imwrite(IRGBOn,[info.imgname 'KEPT.jpg']);
        figure('Name','Pixels KEPT by Base Classifier'); imshow(IRGB);
        pause;
    end
end

