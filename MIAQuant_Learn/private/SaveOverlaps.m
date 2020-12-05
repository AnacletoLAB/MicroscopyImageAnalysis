function SaveOverlaps(dirImgs,dirSaved,markerTriplets, flags,flagROI,slash)
% Last Update 15 October 2017
   warning off;
   
    flagPrima=flags(1); flagDopoMHReg =flags(2); flagDopoPoly=flags(3);
    disp(['DIRECTORY PATHNAME: ' dirImgs]);
    dirSaveImgs=[dirSaved slash 'ResBeforeAfterReg'];
    if ~exist(dirSaveImgs,'dir'); mkdir(dirSaveImgs); end
    if ~exist(dirSaved,'dir'); mkdir(dirSaved); end
    if exist([dirSaveImgs slash 'OverlappingFactors.txt'],'file') %#ok<*ALIGN>
        fidOverlap = fopen([dirSaveImgs slash 'OverlappingFactors.txt'],'a');
    else; fidOverlap = fopen([dirSaveImgs slash 'OverlappingFactors.txt'],'w'); end
    for nT=1:size(markerTriplets,2)
        templates=markerTriplets(:,nT);
        str='____________________________________________________________';
        str=[str newline]; %#ok<*AGROW>
        for i=1: numel(templates)-1;  str=[str templates{i} ' - ']; end
        str=[str templates{numel(templates)} newline];
        if flagPrima
           strAdd='B';
           disp('Marker Density Before Any Registration');
           str=[str newline '---------------------------------------------------------------------' newline newline];
           str=[str 'Marker Density Before Any Registration'  newline];
           fns=dir([dirSaved slash '*' templates{1} '_*' strAdd 'RegsF.mat']);
           info=overlapImages(fns,dirSaved,dirSaveImgs,templates, strAdd,flagROI,slash);
           fsAfter=info.fsAfter; strSave=info.strSave;
           str=[str 'Overlap at the beginning= ' num2str(fsAfter') newline];
           str=[str 'Mean Overlap at the beginning= ' num2str(mean(fsAfter)) newline];
           str=[str 'Mean Global Overlap at the beginning= ' num2str(mean(info.fsMean)) newline newline];
           disp(str);
           fprintf(fidOverlap, '%s', str);
           save([dirSaveImgs slash strSave '_' strAdd 'fsAfter.mat'],'info');
           clear fns info fsAfter str;
        end
                   
        if (flagDopoMHReg) && ~(flagDopoPoly)
            strAdd='D';
            str=[newline '---------------------------------------------------------------------' newline newline];
            str=[ str 'Marker Density After Multiscale-Hierarchical Registration' newline];
            fns=dir([dirSaved slash '*' templates{1} '_*' strAdd 'RegsF.mat']);
            info=overlapImages(fns,dirSaved,dirSaveImgs,templates, strAdd,flagROI,slash);
            fsAfter=info.fsAfter; strSave=info.strSave;
            str=[str 'Overlap After registration= ' num2str(fsAfter') newline];
            str=[str 'Mean Overlap after registration= ' num2str(mean(fsAfter)) newline];
            str=[str 'Mean Global Overlap after registration= ' num2str(mean(info.fsMean)) newline newline];
            disp(str);
            fprintf(fidOverlap, '%s', str);
            save([dirSaveImgs slash strSave '_' strAdd 'fsAfter.mat'],'info');
            clear fns info fsAfter str;
        end

        if (flagDopoPoly) && ~(flagDopoMHReg)
            strAdd='E';
            str=[newline '---------------------------------------------------------------------' newline];
            str=[str 'Marker Density after Registration with only user selected landmarks' newline];
            fns=dir([dirSaved slash '*' templates{1} '_*' strAdd 'RegsF.mat']);
            info=overlapImages(fns,dirSaved,dirSaveImgs,templates, strAdd,flagROI,slash);
            fsAfter=info.fsAfter; strSave=info.strSave;
            str=[ str 'Overlap After registration with landmarks= ' num2str(fsAfter') newline];
            str=[ str 'Mean Overlap after registration with landmarks= ' num2str(mean(fsAfter)) newline];
            str=[ str 'Mean Global Overlap after registration with landmarks= ' num2str(mean(info.fsMean)) newline newline];
            disp(str);
            fprintf(fidOverlap, '%s', str);
            save([dirSaveImgs slash strSave '_' strAdd 'fsAfter.mat'],'info');
            clear info fsAfter;
        end
        
        if (flagDopoPoly) && (flagDopoMHReg)
            strAdd='F';
            str=['---------------------------------------------------------------------' newline];
            str=[ str 'Marker Density after Multiscale-Hierarchical Registration and' ...
                newline '                    Registration with user selected landmarks' newline newline];
            fns=dir([dirSaved slash '*' templates{1} '_*' strAdd 'RegsF.mat']);
            info=overlapImages(fns,dirSaved,dirSaveImgs,templates, strAdd,flagROI,slash);
            fsAfter=info.fsAfter; strSave=info.strSave;
            str=[ str 'Overlap After registration with landmarks= ' num2str(fsAfter') newline];
            str=[ str 'Mean Overlap after registration with landmarks= ' num2str(mean(fsAfter)) newline];
            str=[ str 'Mean Global Overlap after registration with landmarks= ' num2str(mean(info.fsMean)) newline newline];
            disp(str);
            fprintf(fidOverlap, '%s', str);
            save([dirSaveImgs slash strSave '_' strAdd 'fsAfter.mat'],'info');
            clear info fsAfter str;
        end
    end
    fclose(fidOverlap);
end

