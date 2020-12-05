function RenameFilesBasic(dirImgs)
    % Last Update 03 July 2017
   
    if (nargin<1); dirImgs=uigetdir('C:\DATI\Elab_Imgs_Mediche\MIA\immagini_MIA'); end
    disp(['DIRECTORY PATHNAME: ' dirImgs]);
    fnsAll= dir(dirImgs); 
    
    for numI=1:numel(fnsAll)
        fName=fnsAll(numI,1).name;
        pos=strfind(fName,'CD163');
        if numel(pos)>0
            name = fName(1:pos+numel('CD163')-1);
            name = strrep(name,' ','-');
            if isfolder([dirImgs filesep fName])
                fName2= [name '_MPolipi']; 
            else; posPunto = strfind(fName, '.');
                ext = fName(posPunto(end)+1:end);
                if strcmpi(ext,'qptma'); ext = 'txt'; end
                fName2= [name '_MPolipi.' ext]; end

            disp(fName);
            disp(fName2);
            if ~strcmpi(fName, fName2) 
                answer=input('change name?? Y/N','s');
                if strcmpi(answer,'Y') || (numel(answer)==0)
                    str1=[dirImgs filesep fName];
                    str2=[dirImgs filesep fName2];
                    movefile(str1,str2); end
            end
        end
    end
end

