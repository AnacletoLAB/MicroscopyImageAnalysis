function info=parseName(strName)
    pos=strfind(strName,'_');
    info.patName=strName(1:pos(1)-1);
    info.markerName=strName(pos(1)+1:pos(2)-1);
    if (numel(pos)==3) %#ok<ALIGN>
        info.markerColor=strName(pos(2)+1:pos(3)-1);
        info.numFetta=strName(pos(3)+1:end-4); 
    else; info.markerColor=strName(pos(2)+1:end-4); end    
end