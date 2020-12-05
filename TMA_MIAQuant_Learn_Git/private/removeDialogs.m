function removeDialogs()
    global handles
    for i=1:numel(handles); delete(handles{i}); end
    handles={};
end

