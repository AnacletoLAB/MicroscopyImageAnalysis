function allColors=removeDuplicateColors(colorList)
    allColors={};
    for i=1:numel(colorList)
        flagAdd=true;
        for j=1:numel(allColors)
            if strcmp(colorList{i}.Color,allColors{j}.Color) && ...
                        strcmp(colorList{i}.BaseColor,allColors{j}.BaseColor) 
                flagAdd=false;
                break;
            end
        end
        if flagAdd; allColors{end+1}=colorList{i}; end
    end
end
