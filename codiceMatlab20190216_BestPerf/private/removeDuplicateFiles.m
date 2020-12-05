function fnsAll=removeDuplicateFiles(fns)
    fnsAll=[];
    for i=1:numel(fns)
        flagAdd=true;
        for j=1:numel(fnsAll)
            if strcmp(fns(i).name,fnsAll(j).name)
                flagAdd=false;
                break;
            end
        end
        if flagAdd; fnsAll=[fnsAll; fns(i)]; end
    end
end
