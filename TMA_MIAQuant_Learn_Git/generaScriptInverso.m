function generaScriptInverso()
% % Richiede che ci sia una cartella contenente:
% % - file dell'immagine con nome dal formato: ID_markerName_color.tif
% % - file dele coordinate dei rettangoli estratto da QuPath con nome: ID_markerName_color.txt
% %QUINDI IL FILE DELLE COORDINATE è lo stesso della img ma ha estensione .txt
% %Lo script prende tutte le img e per ogni img prende il file delle coordinate e genera il file : ID_markerName_color-script.txt

    start = cd ;
    first= [start '\bin\convert ']; 
    second=' -crop ';
    third='x'; fourth='+'; fifth=fourth;
    nameDir=uigetdir('D:\immagini_MIA','Select image directory');
    nomifilesTIF=[dir([nameDir filesep '*.tif']); 
                dir([nameDir filesep '*.jpg']);];
    factor = input(['insert reduction factor' newline]);
    if numel(factor)==0; factor =1; end
    disp(['reduction factor: ' num2str(factor)]);
    nameSubImgDir = 'subimages';
    if ~exist([nameDir filesep nameSubImgDir], 'dir')
        mkdir([nameDir filesep nameSubImgDir]); end
    maskDir = [nameDir filesep nameSubImgDir filesep 'Masks'];
    if ~exist(maskDir,'dir'); mkdir(maskDir); end
    dim_nothing = 10;
    diary fidDiary.txt
    fidW = fopen([nomifilesTIF(1).folder filesep 'CreateSubImages-script.bat'],'w');    
    
    for nf = numel(nomifilesTIF):-1:1
       
        imgfile=nomifilesTIF(nf).name;
        info=parseName(imgfile);
        nomefile=imgfile(1:end-4);
        if exist(fullfile(nomifilesTIF(nf).folder,[nomefile '.txt']), 'file')
            fidR = fopen(fullfile(nomifilesTIF(nf).folder,[nomefile '.txt']),'r');
            %% primo ciclo per leggere 5 righe inutili
            for i=1:6; res=fgetl(fidR); end
            while feof(fidR)==0
                res=split(fgetl(fidR));
                newName = [info.patName '+' res{1} '_' ... 
                                    info.markerColor '.' info.ext];
                if strcmpi(res{6}, 'true') 
                    % if (~exist([nameDir filesep 'subimages' filesep newName],'file') || ... 
                      %   ~exist([maskDir filesep info.patName '+' res{1} '_Regs.mat'],'file'))
                         
                        
                        if EstraiRegioni_on_img(nameDir, nomefile, res{1}, maskDir, false)>0
                            if exist([nameDir filesep 'subimages' filesep newName],'file')
                                subimg = imread([nameDir filesep 'subimages' filesep newName]);
                                disp('controllo sotto-immagine!');
                                if ((size(subimg,1)==dim_nothing && size(subimg,2)==dim_nothing) && ...
                                         (sum(subimg(:))==0)); flag_recreate = 1;
                                    disp('ricreao immagine!')
                                else; disp('immagine già creata!'); 
                                    flag_recreate =0; 
                                end
                            else; flag_recreate=1; 
                                disp('Creo sotto-immagine!')
                            end
                            if flag_recreate > 0
                                str = [first imgfile second ... 
                                                num2str(round(str2num(res{4})*factor)) third ...
                                                num2str(round(str2num(res{5})*factor)) fourth ...
                                                num2str(round(str2num(res{2})*factor)) fifth ...
                                                num2str(round(str2num(res{3})*factor)) ' ' ...
                                                    '.' filesep 'subimages' filesep ...
                                                        newName newline];
                                
                                 str_exec = [first nameDir filesep imgfile second ... 
                                                num2str(round(str2num(res{4})*factor)) third ...
                                                num2str(round(str2num(res{5})*factor)) fourth ...
                                                num2str(round(str2num(res{2})*factor)) fifth ...
                                                num2str(round(str2num(res{3})*factor)) ' ' ...
                                                    nameDir filesep 'subimages' filesep ...
                                                        newName newline];
                                
                                disp(str_exec);
                                system(str_exec);
                                disp('DONE');
                                fprintf(fidW,'%s',str);
                            end
                        else % salvo una img tutta nera se non ho regioni e quindi dovrò mettere nmarker =0
                            imwrite(uint8(zeros(dim_nothing,dim_nothing,3)), [nameDir filesep 'subimages' filesep newName]);
                        end
                    %end
                else 
                    cdName = [nameDir filesep nomefile filesep];
                    fileDelImg = [res{1} '.jpg'];
                    fileDeloverlay = [res{1} '-overlay.jpg'];
                    if exist([cdName fileDelImg],'file')
                        str = ['del ' cdName fileDelImg newline];
                        fprintf(fidW,'%s',str);
                        system(str);
                    end
                    if exist([cdName fileDeloverlay],'file')
                        str = ['del ' cdName fileDeloverlay newline];
                        fprintf(fidW,'%s',str);
                        system(str)
                    end
                end
            end
            fclose(fidR);
        end
    end
    fclose(fidW);
 %   cd(nomifilesTIF(1).folder)
 %   system('CreateSubImages-script.bat');
    
    diary off

end