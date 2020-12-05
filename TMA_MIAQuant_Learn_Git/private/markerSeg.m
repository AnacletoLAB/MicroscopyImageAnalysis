function markersBin=markerSeg(IRGB,RegsF,markerColor, AllColors, thrArea)
    strop='OR';
    stepCut=[1 1];
    stepCut(1)=max(stepCut(1), uint8(floor(size(RegsF)./10000))); 
    markersBin=logical(par_trees_svm(double(IRGB),RegsF,stepCut,...
            markerColor,strop,thrArea)); 
    for numCol=1:numel(AllColors)
        strCol=AllColors{numCol,:};
        if ~(strCol(1)==markerColor(1))
            markersBin(logical(trees_svm(double(IRGB),RegsF,stepCut,strCol,thrArea)))=false;
        elseif ~strcmp(strCol,markerColor)
            markersBin= markersBin & ...
                logical(trees_svm(double(IRGB),RegsF,stepCut,strCol,thrArea));
        end
    end
    markers=bwareaopen(markers,thrArea);
            
end