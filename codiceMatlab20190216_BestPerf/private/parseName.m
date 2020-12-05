function info=parseName(strName)
    posPunto=strfind(strName,'.');
    info.ext=strName(posPunto:end);
    strName=strName(1:posPunto-1);
    info.imgname=strName;
    info.patName='';
    info.markerNames='';
    info.markerName{1}='';
    info.markerColors='';
    info.markerColor{1}.Color='';
    info.markerColor{1}.BaseColor='';
    info.numFetta='';    
    resSplit=split(strName,'_');
    if numel(resSplit)>=4; info.NumFetta=resSplit{4}; end
    if numel(resSplit)>=3
        info.markerColors=resSplit{3}; 
        resCol=split(info.markerColors,'+');
        for i=1:numel(resCol)
            splitCol=split(resCol{i},'-');
            info.markerColor{i}.Color=splitCol{1};
            if numel(splitCol)==2; info.markerColor{i}.BaseColor=splitCol{2};
            else; info.markerColor{i}.BaseColor=''; end
        end
    end
    if numel(resSplit)>=2        
        info.markerNames=resSplit{2}; 
        info.markerName=split(info.markerNames,'+');
    end
    if numel(resSplit)>=1;  info.patName=resSplit{1}; end
end

% % function cellArr=split(moreNames,sep)
% %     ind=strfind(moreNames,sep);
% %     for i=1:numel(ind)
% %         if i==1; cellArr{i}=moreNames(1:ind(1)-1);
% %         else
% %             cellArr{i}=moreNames(ind(i-1)+1:ind(i)-1);                   
% %         end
% %         if i==numel(ind); cellArr{i+1}=moreNames(ind(numel(ind))+1:end); end      
% %     end
% % end