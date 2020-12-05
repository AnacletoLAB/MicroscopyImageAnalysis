function RenameFiles(dirImgs)
    % Last Update 03 July 2017
    curDir=cd;
    slash='\';
    k = strfind(curDir, slash);
    if numel(k)==0; slash='/'; end
    if (nargin<1) || numel(dirImgs)==0  %#ok<ALIGN>
        dirImgs=uigetdir( curDir); end
    disp(['DIRECTORY PATHNAME: ' dirImgs]);
    fnsAll=[dir([dirImgs slash '*.tif']);  dir([dirImgs slash '*.jpg']);  dir([dirImgs slash '*.png'])]; 
    
    for numI=1:numel(fnsAll)
        fName=fnsAll(numI,1).name;
        
        info=parseName(fName);
        fName2=[info.patName '_' info.markerName{1} '+cells_Red+Blu' '_' info.markerColor{1}.Color info.numFetta(3:end) info.ext]; 
       
        disp(fName);
        disp(fName2);
        answer=input('change name?? Y/N','s');
        if strcmpi(answer,'Y') || (numel(answer)==0)
            str1=[dirImgs slash fName];
            str2=[dirImgs slash fName2];
            movefile(str1,str2); end
    end
end

