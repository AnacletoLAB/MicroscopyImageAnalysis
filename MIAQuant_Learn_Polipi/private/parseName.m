function info=parseName(strName)
    pos=strfind(strName,'_');
    posP=strfind(strName,'.');
    if numel(pos)>1; info.patName=strName(1:(pos(1)-1)); 
        info.markerColor=strName(pos(1)+1:pos(2)-1); 
    elseif numel(pos)==1; info.patName=strName(1:pos(1)-1);
        info.markerColor=strName(pos(1)+1:posP(1)-1); 
    else; info.patName=strName(1:posP(1)-1); end  
    if numel(posP)>0; info.ext=strName(posP+1:end);
    else; info.ext= ''; end
end