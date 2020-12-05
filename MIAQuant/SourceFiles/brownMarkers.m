function markersBIN=brownMarkers(I, maskReg,stepCutR,stepCutC,thrArea)
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
               maskIRGB=(irgb(:,:,1)>=1.15*(irgb(:,:,2))) & ...
                    (irgb(:,:,1)>=(irgb(:,:,3))) & regs;
               clear imgComb;
               clear maskComb maskIRGB;
            end
            markersBIN(BBR(j):BBR(j+1),BBC(i):BBC(i+1))=bwareaopen(macrof_irgb,thrArea);
            clear macrof_irgb;
        end
    end
    markersBIN=bwareaopen(markersBIN,thrArea);
end