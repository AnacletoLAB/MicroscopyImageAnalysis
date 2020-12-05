function rOk = divideOnDist(rOk, distImg)
    flag = true;
    baseLab = bwlabel(rOk>0);
    st1 = strel('disk',1);
    bw = (rOk>0) | distImg>0;
    % regioni iniziali: in bw sono tutte attaccate.
    % vado avanti finchè ogni regione in rOk è staccata in bw
    while flag && max(distImg(:))>0 && max(max(bwlabel(bw)))<max(baseLab(:))
        flag = false;
        delR = imdilate(distImg==max(distImg(:)),st1);
        bw(delR) = false;
        distImg(delR) = min(distImg(:));
        % labello bw
        bwlab = labelmatrix(bwconncomp(bw));
        stats = regionprops(bwconncomp(bw), 'PixelList');
        for i = 1: max(baseLab(:))
            % per ogni regione in rOk
            R = baseLab==i;
            
            % vado a vedere che label ha questa regione in bw
            lab = max(bwlab(R));
            
            % vado a prendere le regioni in rOk che hanno label lab in bw
            res = bwselect(rOk>0, stats(lab).PixelList(:,1), stats(lab).PixelList(:,2));
            
            % se ho preso più di una regione procedo perchè 
            % la regione che ho creato ha ancora regioni attaccate in rOk
            labRes = bwlabel(res);
            if max(max(labRes))>1; flag = true;
            else; break; end
            clear labRes;
        end
    end
    regs = bwlabel(bw);
    for nR=1: max(regs(:)) 
        rOk(regs==nR) = max(max(rOk(regs==nR)));
    end
    
end