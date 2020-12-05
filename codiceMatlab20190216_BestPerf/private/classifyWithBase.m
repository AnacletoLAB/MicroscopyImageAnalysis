function labels= classifyWithBase(I, mdlTree)
    global indFeatBaseTree
    img=I;
    X=repmat(1:size(img,2), size(img,1),1); X=X(:);
    Y=repmat((1:size(img,1))',size(img,2),1);
    ind=[X Y];
    feats = double(computePtsVals(ind, img));
    featsGray = double(computePtsVals(ind, rgb2gray(img)));
    feats=[...
      feats ...
      feats(:,1)./feats(:,2) feats(:,1)./feats(:,3) feats(:,2)./feats(:,3)...
      featsGray];
    labels=predict(mdlTree,feats(:,indFeatBaseTree));              
    labels=bwareaopen(reshape(labels,size(img,1),size(img,2)),5);
end

