function markersBIN=redMarkers(I,maskReg,MdlKNN,stepCutR,stepCutC,thrArea)
    %for i=1: size(I,3); I(:,:,i)=medfilt2(I(:,:,i)); end
    sz=size(maskReg);
    taglioC=uint32(sz(2))/uint32(stepCutC);
    taglioR=uint32(sz(1))/uint32(stepCutR);
    BBR=(1:taglioR:sz(1));
    BBC=(1:taglioC:sz(2));
    if (BBR(end)~=sz(1)) && ((sz(1)-BBR(end))<2); BBR(end)=sz(1);
    else; if (BBR(end)~=sz(1)); BBR=[BBR sz(1)]; end; end
    if (BBC(end)~=sz(2)) && ((sz(2)-BBC(end))<2); BBC(end)=sz(2);    
    else; if (BBC(end)~=sz(2)); BBC=[BBC sz(2)]; end; end
    for i=1: length(BBC)-1
        for j=1:length(BBR)-1
            regs=maskReg(BBR(j):BBR(j+1),BBC(i):BBC(i+1),:);
            macrof_irgb= false(size(regs));
            if any(regs(:)>0)
               irgb=I(BBR(j):BBR(j+1),BBC(i):BBC(i+1),:);
               ILab=lab2uint8(rgb2lab(irgb));
               imgLab2=int32(ILab(:,:,2));
               imgLab3=int32(ILab(:,:,3));
               clear ILab;
               IYcbcr=rgb2ycbcr(irgb);
               imgYcbcr3=int32(IYcbcr(:,:,3)); clear IYcbcr;
               imgComb=imgLab2 - imgLab3+ imgYcbcr3;
               maskTooClear=regs & (irgb(:,:,1)>200) & ((irgb(:,:,3)>120) | (irgb(:,:,2)>120));
               maskNuclei=regs & (uint8(irgb(:,:,1)<75) + uint8(irgb(:,:,2)<75) + uint8(irgb(:,:,3)<75))>=2;
               bigNuclei=logical(bwareaopen(maskNuclei,thrArea*20));
               maskNuclei(bigNuclei)=false;
               maskMarkers=regs & irgb(:,:,1)>1.1*irgb(:,:,3) & (imgComb>=170);
               macrof_irgb(maskMarkers | maskNuclei & (~maskTooClear))=true;
               ind=find(macrof_irgb);
               img=cat(3,irgb,imgComb); clear imgYcbcr3 imgLab2 imgLab3;
               feats=computePtsVals(ind,img); clear img irgb imgComb;
               KNNClass=uint8(zeros(size(feats,1),1));
               for numCl=1:numel(MdlKNN)
                   KNNClass=KNNClass+predict(MdlKNN(numCl).MdlKNN8,feats);
               end 
               macrof_irgb(ind)=macrof_irgb(ind) & (KNNClass>(numel(MdlKNN)/3));                clear regs ind feats;
            end
            markersBIN(BBR(j):BBR(j+1),BBC(i):BBC(i+1))=bwareaopen(macrof_irgb,thrArea);
            clear macrof_irgb;
        end
    end
end