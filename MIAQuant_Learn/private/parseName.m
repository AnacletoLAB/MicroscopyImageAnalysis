function info=parseName(strName)
    pos=strfind(strName,'_');
    if numel(pos)>1; info.patName=strName(1:pos(1)-1); 
    else; info.patName=strName(1:end-4);return;  end    
    if numel(pos)>2; info.markerName=strName(pos(1)+1:pos(2)-1);
    else; info.markerName=strName(pos(2)+1:end-4); return; end       
    if numel(pos)>=3; info.markerColor=strName(pos(2)+1:pos(3)-1);
        info.numFetta=strName(pos(3)+1:end-4);
    else; info.markerColor=strName(pos(2)+1:end-4); return; end  
    pos=strfind(strName,'.');
    info.ext=strName(pos+1:end);
end