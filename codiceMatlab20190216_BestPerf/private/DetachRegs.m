function Regs = DetachRegs(R)
    szY = size(R,1); szY = size(R,2); off = 2;
    RSkel = bwskel(R);
    distImg = bwdist(RSkel); 
    distSkel = distImg(bwperim(regLab));
    [Y,X] = find(RSkel);
    M = []; Q =[]; len = [];
    for i=off+1:numel(Y)-(off+1)
        yy = Y(i); xx = X(i);
        [yyN, xxN] = find(RSkel(max(yy-off,1):min(yy+off,szY), max(xx-off,1):min(xx+off,szX)));
        if numel(yyN) == off*2+1
            lineVert = false(szY,szX);
            if yyN(1) == yyN(2)
                lineVert(sub2ind([szY,szX],(1:szY)',repmat(xx,szY,1))) = true;
            elseif xxN(1)==xxN(2)
                lineVert(sub2ind([szY,szX],repmat(yy,szX,1),(1:szX)')) = true;
            else
                cs = polyfit(xxN,yyN,1);
                mVert = -1/cs(1);
                qVert = yy - mVert*xx;
                lineVert(sub2ind([szY,szX],((1:szX)'*mVert)+repmat(qVert,szX,1),(1:szX)')) = true;
            end
            len = [len; sum(sum(uint8(lineVert & R)))];
            M = [M; mVert]; Q = [Q; qVert];
        end
    end
    pos=findpeaks(smooth(max(len)-len));
    
end

