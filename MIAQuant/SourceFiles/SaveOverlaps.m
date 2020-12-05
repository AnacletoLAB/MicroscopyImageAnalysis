function SaveOverlaps(dirImgs,dirSaved,markerTriplets,flags,thrArea,dimLimit)
% Last Update 28 May 2017
   warning off;
    stepFR=1; stepFC=1;
    flagPrima=flags(1); flagDopoMHReg =flags(2); flagDopoPoly=flags(3);
    disp(['DIRECTORY PATHNAME: ' dirImgs]);
     
    dirSaveImgs=[dirSaved '\ResBeforeAfterReg'];
    if ~exist(dirSaveImgs,'dir'); mkdir(dirSaveImgs); end
    if ~exist(dirSaved,'dir'); mkdir(dirSaved); end
    load('SelectedMdlKNN8');
    stBig=strel('disk',30);
    for nT=1:size(markerTriplets,2)
        templates=markerTriplets(:,nT);
        fac=uint8(255/6);
        fns=dir([dirImgs '\*' templates{1} '*_0001.tif']);
        disp('____________________________________________________________');
        disp(templates');
        if flagPrima
           for numI=1:numel(fns)
                fName=fns(numI,1).name;
                info=parseName(fName);
                baseName=[info.patName '_' info.markerName '_' info.markerColor];
                disp(['Img Being Processed=' info.patName]);
                load([dirSaved '\' baseName '_ORegsF.mat']);
                load([dirSaved '\' baseName '_ORegs.mat']);
                load([dirSaved '\' baseName '_OItriangle.mat']);
                imS=(uint8(RegsF)-uint8(imerode(RegsF,stBig)))*fac*2+...
                    fac*uint8(RegsF)+fac*uint8(Regs)+fac*uint8(Itriangle);
                It(:,:,1)=uint8(Itriangle); clear Itriangle;
                str1=load([dirSaved '\' baseName '_OIRGB1.mat']);
                str2=load([dirSaved '\' baseName '_OIRGB2.mat']);
                str3=load([dirSaved '\' baseName '_OIRGB3.mat']);
                str4=load([dirSaved '\' baseName '_OIRGB4.mat']);
                IRGB=[str1.IRGB1 str2.IRGB2; str3.IRGB3 str4.IRGB4]; 
                clear str1 str2 str3 str4 IRGB1 IRGB2 IRGB3 IRGB4;
                imwrite(IRGB,[dirSaveImgs '\' baseName '_OIRGB.tif']);
                sz=size(RegsF);
                if (sz(2)>dimLimit); stepFC=uint32(round(sz(2)/dimLimit)); end
                if (sz(1)>dimLimit); stepFR=uint32(round(sz(1)/dimLimit)); end
                if strcmpi(info.markerColor,'R') %#ok<ALIGN>
                    markers=logical(redMarkers(IRGB,RegsF,MdlKNN8Str,stepFR,stepFC,thrArea));
                else; if strcmpi(info.markerColor,'M')
                    markers=logical(brownMarkers(IRGB,RegsF,stepFR,stepFC,thrArea)); end; end
                imarkers=IRGB.*uint8(cat(3,markers, markers, markers)); clear IRGB;
                R=cat(3,RegsF & ~markers,RegsF & ~markers,RegsF & ~markers);  
                imarkers(R)=mean(imarkers(:)); clear R;
                imwrite(imarkers,[dirSaveImgs '\' baseName '_OmarkersRGB.tif']);
                clear imarkers IRGB;
                imSMark=(uint8(RegsF)-uint8(imerode(RegsF,stBig)))*fac*2+...
                    fac*uint8(RegsF)+uint8(markers)*fac*4;
                clear Regs RegsF markers;
                strSave=[info.patName '_' info.markerName];
                for numTemp=2: numel(templates)
                    tempMarker=templates{numTemp};
                    strBef=[info.patName];
                    strAfter=[ info.markerColor];
                    baseName=[strBef '_' tempMarker '_' strAfter];
                    load([dirSaved '\' baseName '_ORegsF.mat']);
                    load([dirSaved '\' baseName '_ORegs.mat']);
                    load([dirSaved '\' baseName '_OItriangle.mat']);
                    im=(uint8(RegsF)-uint8(imerode(RegsF,stBig)))*fac*2+...
                        fac*uint8(RegsF)+fac*uint8(Regs)+fac*uint8(Itriangle);
                    It(:,:,numTemp)=uint8(Itriangle); clear Itriangle;
                    imS=cat(3,imS,im); clear im;
                    str1=load([dirSaved '\' baseName '_OIRGB1.mat']);
                    str2=load([dirSaved '\' baseName '_OIRGB2.mat']);
                    str3=load([dirSaved '\' baseName '_OIRGB3.mat']);
                    str4=load([dirSaved '\' baseName '_OIRGB4.mat']);
                    IRGB=[str1.IRGB1 str2.IRGB2; str3.IRGB3 str4.IRGB4]; 
                    clear str1 str2 str3 str4 IRGB1 IRGB2 IRGB3 IRGB4;
                    if strcmpi(info.markerColor,'R') %#ok<ALIGN>
                        markers=logical(redMarkers(IRGB,RegsF,MdlKNN8Str,stepFR,stepFC,thrArea));
                    else; if strcmpi(info.markerColor,'M')
                        markers=logical(brownMarkers(IRGB,RegsF,stepFR,stepFC,thrArea)); end; end
                    imwrite(IRGB,[dirSaveImgs '\' baseName '_OIRGB.tif']);
                    imarkers=IRGB.*uint8(cat(3,markers, markers, markers)); clear IRGB;
                    R=cat(3,RegsF & ~markers,RegsF & ~markers,RegsF & ~markers);
                    imarkers(R)=mean(imarkers(:));  clear R;
                    imwrite(imarkers,[dirSaveImgs '\' baseName '_OmarkersRGB.tif']);
                    clear imarkers IRGB;
                    imM=(uint8(RegsF)-uint8(imerode(RegsF,stBig)))*fac*2+...
                            fac*uint8(RegsF)+uint8(markers)*fac*4;
                    imSMark=cat(3,imSMark,imM);  clear imM Regs RegsF markers;
                    strSave=[strSave '_' tempMarker]; 
                end
                if size(imS,3)<3
                    for i=size(imS,3)+1:3
                        imS=cat(3,imS,uint8(zeros(size(imS,1),size(imS,2))));
                        imSMark=cat(3,imSMark,uint8(zeros(size(imSMark,1),size(imSMark,2))));
                    end; end
                imwrite(imS,[dirSaveImgs '\' strSave '_RegsBeforeReg.tif']);
                imwrite(imSMark,[dirSaveImgs '\' strSave '_MarkersBeforeReg.tif']);
                clear imS imSMark;
                ItSum=double(sum(sum(uint8(sum(It,3)==size(It,3)))));
                fsBefore=zeros(1,size(It,3));
                for numTemp=1:size(It,3); fsBefore(numTemp)=ItSum/double(sum(sum(It(:,:,numTemp)))); end
                disp(['Overlap before registration= ' num2str(fsBefore)]);
                disp(['Mean Overlap before registration= ' num2str(sum(fsBefore)/size(It,3))]);
                save([dirSaveImgs '\' strSave '_fsBefore.mat'],'fsBefore');
                clear It;
            end
        end
        if flagDopoMHReg             
            disp('---------------------------------------------------------------------');
            disp('Marker Density After Multiscale-Hierarchical Registration');
            for numI=1:numel(fns)
                fName=fns(numI,1).name;
                info=parseName(fName);
                baseName=[info.patName '_' info.markerName '_' info.markerColor];
                disp(['Img Being Processed=' info.patName ]);
                load([dirSaved '\' baseName '_RegsF.mat']);
                load([dirSaved '\' baseName '_Regs.mat']);
                load([dirSaved '\' baseName '_Itriangle.mat']);
                imS=(uint8(RegsF)-uint8(imerode(RegsF,stBig)))*fac*2+...
                    fac*uint8(RegsF)+fac*uint8(Regs)+fac*uint8(Itriangle);
                It(:,:,1)=uint8(Itriangle);
                clear Itriangle;
                str1=load([dirSaved '\' baseName '_IRGB1.mat']);
                str2=load([dirSaved '\' baseName '_IRGB2.mat']);
                str3=load([dirSaved '\' baseName '_IRGB3.mat']);
                str4=load([dirSaved '\' baseName '_IRGB4.mat']);
                IRGB=[str1.IRGB1 str2.IRGB2; str3.IRGB3 str4.IRGB4]; 
                clear str1 str2 str3 str4 IRGB1 IRGB2 IRGB3 IRGB4;
                imwrite(IRGB,[dirSaveImgs '\' baseName '_IRGB.tif']);
                sz=size(RegsF);
                if (sz(2)>dimLimit); stepFC=uint32(round(sz(2)/dimLimit)); end
                if (sz(1)>dimLimit); stepFR=uint32(round(sz(1)/dimLimit)); end
                if strcmpi(info.markerColor,'R') %#ok<ALIGN>
                    markers=logical(redMarkers(IRGB,RegsF,MdlKNN8Str,stepFR,stepFC,thrArea));
                else; if strcmpi(info.markerColor,'M')
                    markers=logical(brownMarkers(IRGB,RegsF,stepFR,stepFC,thrArea)); end; end
                imarkers=IRGB.*uint8(cat(3,markers, markers, markers)); clear IRGB;
                R=cat(3,RegsF & ~markers,RegsF & ~markers,RegsF & ~markers);
                imarkers(R)=mean(imarkers(:));  clear R;
                imwrite(imarkers,[dirSaveImgs '\' baseName '_markersRGB.tif']);        
                clear imarkers IRGB;
                imSMark=(uint8(RegsF)-uint8(imerode(RegsF,stBig)))*fac*2+...
                    fac*uint8(RegsF)+uint8(markers)*fac*4;
                clear Regs RegsF markers;
                strSave=[info.patName '_' info.markerName];
                for numTemp=2: numel(templates)
                    tempMarker=templates{numTemp};
                    strBef=[info.patName];
                    strAfter=[ info.markerColor];
                    baseName=[strBef '_' tempMarker '_' strAfter];
                    load([dirSaved '\' baseName '_RegsF.mat']);
                    load([dirSaved '\' baseName '_Regs.mat']);
                    load([dirSaved '\' baseName '_Itriangle.mat']); 
                    im=(uint8(RegsF)-uint8(imerode(RegsF,stBig)))*fac*2+...
                        fac*uint8(RegsF)+fac*uint8(Regs)+fac*uint8(Itriangle);
                    It(:,:,numTemp)=uint8(Itriangle);
                    clear Itriangle;
                    imS=cat(3,imS,im); clear im;
                    str1=load([dirSaved '\' baseName '_IRGB1.mat']);
                    str2=load([dirSaved '\' baseName '_IRGB2.mat']);
                    str3=load([dirSaved '\' baseName '_IRGB3.mat']);
                    str4=load([dirSaved '\' baseName '_IRGB4.mat']);
                    IRGB=[str1.IRGB1 str2.IRGB2; str3.IRGB3 str4.IRGB4]; 
                    clear str1 str2 str3 str4 IRGB1 IRGB2 IRGB3 IRGB4;
                    imwrite(IRGB,[dirSaveImgs '\' baseName  '_IRGB.tif']);
                    if strcmpi(info.markerColor,'R') %#ok<ALIGN>
                        markers=logical(redMarkers(IRGB,RegsF,MdlKNN8Str,stepFR,stepFC,thrArea));
                    else; if strcmpi(info.markerColor,'M')
                        markers=logical(brownMarkers(IRGB,RegsF,stepFR,stepFC,thrArea)); end; end
                    imarkers=IRGB.*uint8(cat(3,markers, markers, markers)); clear IRGB;
                    R=cat(3,RegsF & ~markers,RegsF & ~markers,RegsF & ~markers);
                    imarkers(R)=mean(imarkers(:)); clear R;
                    imwrite(imarkers,[dirSaveImgs '\' baseName '_markersRGB.tif']);
                    clear imarkers IRGB;
                    imM=(uint8(RegsF)-uint8(imerode(RegsF,stBig)))*fac*2+...
                            fac*uint8(RegsF)+uint8(markers)*fac*4;
                    imSMark=cat(3,imSMark,imM);  clear imM Regs RegsF markers;
                    strSave=[strSave '_' tempMarker]; %#ok<AGROW>
                end
                if size(imS,3)<3
                    for i=size(imS,3)+1:3
                        imS=cat(3,imS,uint8(zeros(size(imS,1),size(imS,2))));
                        imSMark=cat(3,imSMark,uint8(zeros(size(imSMark,1),size(imSMark,2))));
                    end; end                
                imwrite(imS,[dirSaveImgs '\' strSave '_RegsAfterReg.tif']);
                imwrite(imSMark,[dirSaveImgs '\' strSave '_MarkersAfterReg.tif']);
                clear imS imSMark;
                ItSum=double(sum(sum(uint8(sum(It,3)==size(It,3)))));
                fsAfter=zeros(1,size(It,3));
                for numTemp=1:size(It,3); fsAfter(numTemp)=ItSum/double(sum(sum(It(:,:,numTemp)))); end
                disp(['Overlap After registration= ' num2str(fsAfter)]);
                disp(['Mean Overlap after registration= ' num2str(sum(fsAfter)/size(It,3))]);
                save([dirSaveImgs '\' strSave '_fsAfter.mat'],'fsAfter');
                clear It;
            end
        end
        if flagDopoPoly 
            disp('---------------------------------------------------------------------');
            disp('Marker Density After MH-Registration+Registration with user selected landmarks');
            for numI=1:numel(fns)
                fName=fns(numI,1).name;
                info=parseName(fName);
                baseName=[info.patName '_' info.markerName '_' info.markerColor];
                disp(['Img Being Processed=' info.patName]);
                load([dirSaved '\' baseName '_PRegsF.mat']);
                load([dirSaved '\' baseName '_PRegs.mat']);
                load([dirSaved '\' baseName '_PItriangle.mat']);
                imS=(uint8(RegsF)-uint8(imerode(RegsF,stBig)))*fac*2+...
                    fac*uint8(RegsF)+fac*uint8(Regs)+fac*uint8(Itriangle);
                It(:,:,1)=uint8(Itriangle);
                clear Itriangle;
                str1=load([dirSaved '\' baseName '_PIRGB1.mat']);
                str2=load([dirSaved '\' baseName '_PIRGB2.mat']);
                str3=load([dirSaved '\' baseName '_PIRGB3.mat']);
                str4=load([dirSaved '\' baseName '_PIRGB4.mat']);
                IRGB=[str1.IRGB1 str2.IRGB2; str3.IRGB3 str4.IRGB4]; 
                clear str1 str2 str3 str4 IRGB1 IRGB2 IRGB3 IRGB4;
                imwrite(IRGB,[dirSaveImgs '\' baseName '_PIRGB.tif']);
                sz=size(RegsF);
                if (sz(2)>dimLimit); stepFC=uint32(round(sz(2)/dimLimit)); end
                if (sz(1)>dimLimit); stepFR=uint32(round(sz(1)/dimLimit)); end
                if strcmpi(info.markerColor,'R') %#ok<ALIGN>
                    markers=logical(redMarkers(IRGB,RegsF,MdlKNN8Str,stepFR,stepFC,thrArea));
                else; if strcmpi(info.markerColor,'M')
                    markers=logical(brownMarkers(IRGB,RegsF,stepFR,stepFC,thrArea)); end; end
                imarkers=IRGB.*uint8(cat(3,markers, markers, markers)); clear IRGB;
                R=cat(3,RegsF & ~markers,RegsF & ~markers,RegsF & ~markers);
                imarkers(R)=mean(imarkers(:));  clear R;
                imwrite(imarkers,[dirSaveImgs '\' baseName '_PmarkersRGB.tif']);        
                clear imarkers IRGB;
                imSMark=(uint8(RegsF)-uint8(imerode(RegsF,stBig)))*fac*2+...
                    fac*uint8(RegsF)+uint8(markers)*fac*4;
                clear Regs RegsF markers;
                strSave=[info.patName '_' info.markerName];
                for numTemp=2: numel(templates)
                    tempMarker=templates{numTemp};
                    strBef=[info.patName];
                    strAfter=[ info.markerColor];
                    baseName=[strBef '_' tempMarker '_' strAfter];
                    load([dirSaved '\' baseName '_PRegsF.mat']);
                    load([dirSaved '\' baseName '_PRegs.mat']);
                    load([dirSaved '\' baseName '_PItriangle.mat']); 
                    im=(uint8(RegsF)-uint8(imerode(RegsF,stBig)))*fac*2+...
                        fac*uint8(RegsF)+fac*uint8(Regs)+fac*uint8(Itriangle);
                    It(:,:,numTemp)=uint8(Itriangle);
                    clear Itriangle;
                    imS=cat(3,imS,im); clear im;
                    str1=load([dirSaved '\' baseName '_PIRGB1.mat']);
                    str2=load([dirSaved '\' baseName '_PIRGB2.mat']);
                    str3=load([dirSaved '\' baseName '_PIRGB3.mat']);
                    str4=load([dirSaved '\' baseName '_PIRGB4.mat']);
                    IRGB=[str1.IRGB1 str2.IRGB2; str3.IRGB3 str4.IRGB4]; 
                    clear str1 str2 str3 str4 IRGB1 IRGB2 IRGB3 IRGB4;
                    imwrite(IRGB,[dirSaveImgs '\' baseName  '_PIRGB.tif']);
                    if strcmpi(info.markerColor,'R') %#ok<ALIGN>
                        markers=logical(redMarkers(IRGB,RegsF,MdlKNN8Str,stepFR,stepFC,thrArea));
                    else; if strcmpi(info.markerColor,'M')
                        markers=logical(brownMarkers(IRGB,RegsF,stepFR,stepFC,thrArea)); end; end
                    imarkers=IRGB.*uint8(cat(3,markers, markers, markers)); clear IRGB;
                    R=cat(3,RegsF & ~markers,RegsF & ~markers,RegsF & ~markers);
                    imarkers(R)=mean(imarkers(:)); clear R;
                    imwrite(imarkers,[dirSaveImgs '\' baseName '_PmarkersRGB.tif']);
                    clear imarkers IRGB;
                    imM=(uint8(RegsF)-uint8(imerode(RegsF,stBig)))*fac*2+...
                            fac*uint8(RegsF)+uint8(markers)*fac*4;
                    imSMark=cat(3,imSMark,imM);  clear imM Regs RegsF markers;
                    strSave=[strSave '_' tempMarker]; %#ok<AGROW>
                end
                if size(imS,3)<3
                    for i=size(imS,3)+1:3
                        imS=cat(3,imS,uint8(zeros(size(imS,1),size(imS,2))));
                        imSMark=cat(3,imSMark,uint8(zeros(size(imSMark,1),size(imSMark,2))));
                    end; end
                imwrite(imS,[dirSaveImgs '\' strSave '_RegsAfterPolyReg.tif']);
                imwrite(imSMark,[dirSaveImgs '\' strSave '_MarkersAfterPolyReg.tif']);
                clear imS imSMark;
                ItSum=double(sum(sum(uint8(sum(It,3)==size(It,3)))));
                fsAfterPoly=zeros(1,size(It,3));
                for numTemp=1:size(It,3); fsAfterPoly(numTemp)=ItSum/double(sum(sum(It(:,:,numTemp)))); end
                disp(['Overlap After registration with manual landmarks= ' num2str(fsAfterPoly)]);
                disp(['Mean Overlap after registration with manual landmarks= ' num2str(sum(fsAfterPoly)/size(It,3))]);
                save([dirSaveImgs '\' strSave '_fsAfterPoly.mat'],'fsAfterPoly');
                clear It;
            end
        end
        clear fns;
    end
    diary([dirSaveImgs '\OverlappingFactors.txt']);
end

