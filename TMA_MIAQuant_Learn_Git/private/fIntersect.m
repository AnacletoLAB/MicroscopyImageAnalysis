function val= fIntersect( hM,hI)
    hI=double(hI); hM=double(hM);
    val=sum(sum(min(hI,hM)))/sum(hM(:));
end

