function H=myHist(dists, xAxis)
    h=histogram(dists, xAxis);
    H.Values=[h.Values h.Values(end)];
    numCampioni=double(sum(H.Values));
    H.NormValues=H.Values/numCampioni;  
end
