function strReport=computeBorderDistanceMap(currentMark,markDil,Regs,...
                                    imgName,dirSave,usaMarkDil)
    if (nargin<6); usaMarkDil=false; end;
    stBorder=strel('disk',2);
    dirSave=[dirSave 'PrbBorderDist']; 
    disp('Computing Probability estimate of (not normalized) Border Distances');   
    disp(['saving dir=' dirSave])
    if ~exist(dirSave,'dir'); mkdir(dirSave); end;                                
    fRound=double(100);
    if usaMarkDil; [r,c]=find(markDil & currentMark); 
        currentVasiDil=logical(bwselect(markDil,c,r)); clear r c;
    else currentVasiDil=currentMark; end;
    areaMark=double(sum(uint8(currentMark(:))));
    areaReg=double(sum(uint8(Regs(:))));
    percMark=areaMark/areaReg;
    strReport.Densita=[imgName,sprintf('\t'),sprintf('\t%g%%\t',percMark*100),...
                sprintf('\t%g\t',areaMark),sprintf('\t%g\n',areaReg)];
    if (areaMark>0)
       if (usaMarkDil); cMarkDil=bwlabel(currentVasiDil);
       else cMarkDil=uint8(currentVasiDil>0); end;
           %%% tengo il bordo reale!
           %%% non il bordo indotto dalla regione ammissibile
       BorderReg=logical(uint8(Regs)-...
               uint8(imerode(Regs,stBorder)));
       imgDistBorder=max(round(bwdist(BorderReg)),1);
       currentMark(~Regs)=false; 
       numMarkRimasti=double(sum(uint8(currentMark(:))));
       cMarkDil(~Regs)=0;     
       RegsMeasures=zeros(max(cMarkDil(:)),9);
       for nSubReg=1:max(cMarkDil(:))
            disp(['analizing Area: (' num2str(nSubReg) ')']);
            cV=currentMark & (cMarkDil==nSubReg);
            bDists=round(imgDistBorder(cV(:))*fRound)/fRound; 
            meanvBorder=round(mean(bDists(:))*fRound)/fRound; 
            stdvBorder=round(std(bDists(:))*fRound)/fRound;
            minvBorder=round(min(bDists(:))*fRound)/fRound;
            maxvBorderReg=round(max(bDists(:))*fRound)/fRound;
            save([dirSave '\' imgName '_' ...
                    num2str(nSubReg) '_bDists.mat'],'bDists', 'maxvBorder');            
            clear bDists currentCenter cV;
            RegsMeasures(nSubReg,:)=[double(nSubReg),double(maxvBorderReg), double(maxvBorderReg),...
                double(areaMark),double(numMarkRimasti),...
                meanvBorder,stdvBorder, minvBorder,maxvBorderReg];
            clear numVasiRimasti totVasi;
            clear maxvBorderReg meanvBorder stdvBorder minvBorder maxvBorder;
            clear NumVasiOutliers NumVasiRimasti;
       end
       for nl=1:max(cMarkDil(:))
            arrMeas=RegsMeasures(nl,:);
            strReport.ValDist=[strReport.ValDist, ...
                    sprintf('%s\t%d\t%g\t%g\t%%g\t%g\t%g\t%g\t%g\t%g\n', ...
                    imgName,arrMeas(1), ...
                    arrMeas(2),arrMeas(3), ...
                    arrMeas(4),arrMeas(5),...
                    arrMeas(6), arrMeas(7),arrMeas(8), arrMeas(9))];
        end
        clear RegsMeasures areaReg areaMark percMark;
    end
end
        
        


        