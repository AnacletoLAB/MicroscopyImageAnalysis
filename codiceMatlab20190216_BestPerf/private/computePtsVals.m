function ptsVal=computePtsVals(pts,im)
   % pts=matrix con le posizioni dei punti (ogni riga = [X Y] del punto)
   imR=reshape(im,size(im,1)*size(im,2),size(im,3));
   if size(pts,2)==2;  ptsInd=sub2ind([size(im,1),size(im,2)],pts(:,2),pts(:,1)); 
   else ptsInd=pts; end
   ptsVal=imR(ptsInd,:);
  
end