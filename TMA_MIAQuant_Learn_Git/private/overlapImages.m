function info=overlapImages(fnList,dirSave,dirSImgs, templates, strAdd,flagROI,slash)
    stBig=strel('disk',10);
    st=strel('disk',3);
    stBig2=strel('disk',30);
    fac=uint8(255/6);
    radDil=200;
    stDil=strel('disk',radDil);
    for numI=1:numel(fnList)
        fName=fnList(numI,1).name;
        infoImg=parseName(fName);
        baseName=[infoImg.patName '_' infoImg.markerName '_' infoImg.markerColor];
        disp(['Img Being Processed=' infoImg.patName]);
        load([dirSave slash baseName '_' strAdd 'RegsF.mat']);
        load([dirSave slash baseName '_' strAdd 'Regs.mat']);
        load([dirSave slash baseName '_' strAdd 'Ipoly.mat']);
        load([dirSave slash baseName '_' strAdd 'markersConc.mat']);
        load([dirSave slash baseName '_' strAdd 'markers.mat']);
        RegsF=imclose(imfill(RegsF,'holes'),stBig2);
        if sum(uint8(Ipoly(:)))==0; Ipoly=RegsF; flagIpoly=0;
        else; flagIpoly=1; Ipoly=imdilate(Ipoly,stDil);
            save([dirSave slash baseName '_' strAdd 'IpolyDil.mat'],'Ipoly');
        end
        BS=uint8(RegsF)-uint8(imerode(RegsF,stBig));
        IpolyB=uint8(Ipoly)-uint8(imerode(Ipoly,stBig));
        imS=BS*fac*2+...
            fac*uint8(RegsF)+fac*uint8(Regs)+fac*uint8(IpolyB);
        It(:,:,1)=uint8(Ipoly);
        clear Ipoly;
        imwrite(BS*255+uint8(markers)*255,[dirSImgs slash baseName '_' strAdd 'BINmarkers.tif']);
        imwrite(uint8(Regs)*128+uint8(RegsF)*128,[dirSImgs slash baseName '_' strAdd 'Regs_RegsF.tif']);
        imwrite(BS*255+uint8(markersConc)*255,[dirSImgs slash baseName '_' strAdd 'BINmarkersConc.tif']);
        imSMark=(uint8(RegsF)-uint8(imerode(RegsF,stBig)))*fac*6+uint8(markers)*fac*6;
        imSMarkConc=(uint8(RegsF)-uint8(imerode(RegsF,stBig)))*fac*6+uint8(markersConc)*fac*6;
        clear Regs RegsF markers BS markersConc;
        strSave=[infoImg.patName '_' infoImg.markerName ];
        for numTemp=2: numel(templates)
            tempMarker=templates{numTemp};
            strBef=[infoImg.patName];
            fnsImg=dir([dirSave slash strBef '_' tempMarker '_*_' strAdd 'RegsF.mat']);
            if numel(fnsImg)>0
                infImg=parseName(fnsImg(1,1).name);
                strAfter=[infImg.markerColor]; clear fnsImg infImg;
                baseName=[strBef '_' tempMarker '_' strAfter];
                load([dirSave slash baseName '_' strAdd 'RegsF.mat']);
                load([dirSave slash baseName '_' strAdd 'Regs.mat']);
                load([dirSave slash baseName '_' strAdd 'Ipoly.mat']); 
                load([dirSave slash baseName '_' strAdd 'markers.mat']); 
                load([dirSave slash baseName '_' strAdd 'markersConc.mat']); 
                RegsF=imclose(imfill(RegsF,'holes'),stBig2);
                if sum(uint8(Ipoly(:)))==0; Ipoly=RegsF;
                else; flagIpoly=flagIpoly+1; Ipoly=imdilate(Ipoly,stDil);
                    save([dirSave slash baseName '_' strAdd 'IpolyDil.mat'],'Ipoly');
                end
                BS=uint8(RegsF)-uint8(imerode(RegsF,stBig));
                IpolyB=uint8(Ipoly)-uint8(imerode(Ipoly,stBig));
                im=(BS)*fac*2+...
                    fac*uint8(RegsF)+fac*uint8(Regs)+fac*uint8(IpolyB);
                It(:,:,numTemp)=uint8(Ipoly);
                clear Ipoly;
                imS=cat(3,imS,im); clear im;
                imwrite(BS*255+uint8(markers)*255,[dirSImgs slash baseName '_' strAdd 'BINmarkers.tif']);
                imwrite(BS*255+uint8(markersConc)*255,[dirSImgs slash baseName '_' strAdd 'BINmarkersConc.tif']);
                imwrite(uint8(Regs)*128+uint8(RegsF)*128,[dirSImgs slash baseName '_' strAdd 'Regs_RegsF.tif']);
                imM=(uint8(RegsF)-uint8(imerode(RegsF,stBig)))*fac*6+...
                        uint8(markers)*fac*6;
                imSMark=cat(3,imSMark,imM);  clear imM Regs markers;
                imM=(uint8(RegsF)-uint8(imerode(RegsF,stBig)))*fac*6+...
                        uint8(markersConc)*fac*6; clear RegsF;
                imSMarkConc=cat(3,imSMarkConc,imM);  clear imM markersConc;
            end
            strSave=[strSave '_' tempMarker]; %#ok<AGROW>
        end
        if size(imS,3)<3
            for i=size(imS,3)+1:3
                imS=cat(3,imS,uint8(zeros(size(imS,1),size(imS,2))));
                imSMark=cat(3,imSMark,uint8(zeros(size(imSMark,1),size(imSMark,2))));
            end; end
        if flagROI 
           if flagIpoly>0; answ=input('Use manual landmark to define the ROI? (Y/N)','s'); 
           else; answ=false; end
           if strcmpi(answ,'Y')
               imgROI=sum(uint8(It),3)>0;
           else
               fig=figure('Name','Draw ROI where to compute co-existence measures'); imshow(imSMark);
               [x, y] = getline(fig,'closed'); close(fig);
               x=round(x); y=round(y);
               imgROI=false(size(imSMark,1),size(imSMark,2));
               for j=1:size(x,1)-1
                   imgROI=imgROI | drawLine(imgROI,x(j,1),y(j,1),x(j+1,1),y(j+1,1));
               end
               imgROI=imgROI | drawLine(imgROI,x(1,1),y(1,1),x(end,1),y(end,1));
               imgROI=imdilate(imgROI,st);
           end
           imgROI=imerode(imfill(imdilate(imgROI, st),'holes'), st);
           imgROIB=logical(uint8(imgROI)-uint8(imerode(imgROI,stBig)));
           R=cat(3,imgROIB,imgROIB,imgROIB);
           imSMarkConc(R)=255;
           imSMark(R)=255;
           imS(R)=255;
           save([dirSave slash infoImg.patName '_' strAdd 'ROI.mat'],'imgROI');
        end
        imwrite(imS,[dirSImgs slash strSave '_' strAdd 'AllRegs' '.tif']);
        imwrite(imSMark,[dirSImgs slash strSave '_' strAdd 'AllMarkers' '.tif']);
        imwrite(imSMarkConc,[dirSImgs slash strSave '_' strAdd 'AllMarkersConc' '.tif']);
        clear imS imSMark;
        ItSum=double(sum(sum(uint8(sum(It,3)==size(It,3)))));
        fsAfter=zeros(size(It,3),1);
        for numTemp=1:size(It,3); fsAfter(numTemp,1)=ItSum/double(sum(sum(It(:,:,numTemp)))); end
        info.fsAfter=fsAfter;
        info.fsMean=ItSum/double(sum(sum(uint8(sum(It,3)>1))));
        info.strSave=strSave;
        clear It;
    end
end