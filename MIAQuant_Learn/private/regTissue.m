function sz=regTissue(I,InfoImgColor, baseName, tempDir,strAdd, ...
                        Crop,regFill, fsz, gaussDev, threshSmallAreas,slash)
   
    if ~exist(tempDir,'dir'); mkdir(tempDir); end 
    I(I==0)=1;
    
    origsize=size(I); 
    factor=5000/max(origsize(1:2));
    if (size(I,1)<2000 && size(I,2)<2000); Regs=true(origsize(1),origsize(2));
    else
         IRGBS=imresize(I,'scale', factor, 'method', 'nearest');
         imgGray=rgb2gray(IRGBS); clear IRGBS;
         imgGrayfilt=imgaussfilt(medfilt2(imgGray,[fsz fsz]),gaussDev);
         thresh=multithresh(imgGrayfilt,10);
         Regs=imgGrayfilt<max(thresh);
         Regs=imclose(Regs, strel('disk',3)); clear imgGrayfilt;
         Regs=bwareaopen(Regs,round(sum(Regs(:))*1e-03));
         Regs(1:5,:)=false; Regs(:,1:5)=false;
         Regs(:,end-4:end)=false; Regs(end-4:end,:)=false;
     % per evitare errori dovuti al ridimensionamento
     % elimino da regs quei pixel per cui ldg + 5 > media degli ldg dei
     % pixels non nella regione!
         meanVOut=mean(imgGray(~Regs(:)));
         stdVOut=std(double(imgGray(~Regs(:)))); clear imgGray;
         Regs=imresize(Regs,[origsize(1),origsize(2)],'nearest'); 
         ig=double(rgb2gray(I));
         Regs(ig>(meanVOut-0.25*stdVOut))=false; clear ig;
     end
    
     if any(isfinite(InfoImgColor(:))) && numel(InfoImgColor(:))>0
        Ip=logical(InfoImgColor(:,:,1)<10 & InfoImgColor(:,:,2)>250 & InfoImgColor(:,:,3)<10);
        noHolesArea=imresize(...
            logical(InfoImgColor(:,:,1)>250 & InfoImgColor(:,:,2)>250 & InfoImgColor(:,:,3)<10),...
            [origsize(1),origsize(2)],'nearest'); 
        bordersOI=imresize(logical(...
            imfill(logical(InfoImgColor(:,:,1)>250 & InfoImgColor(:,:,2)<10 & InfoImgColor(:,:,3)>250),'holes')),...
            [origsize(1),origsize(2)],'nearest'); 
    else; noHolesArea=false(size(Regs,1),size(Regs,2));
        bordersOI=false(size(Regs,1),size(Regs,2)); 
        Ip=false(size(Regs,1),size(Regs,2)); 
    end    
    Regs=Regs | bordersOI;
    if Crop; [indY,indX]=find(Regs>0); %#ok<ALIGN>
        BB=[min(indY),max(indY), min(indX),max(indX)];
        indX=[]; indY=[];
    else BB=[1,size(Regs,1),1,size(Regs,2)]; end
    Regs=Regs(BB(1):BB(2),BB(3):BB(4)); 
    Ipoly=Ip(BB(1):BB(2),BB(3):BB(4));
    
    Ipoly=createPoly(Ipoly,factor);
    noHolesArea=noHolesArea(BB(1):BB(2),BB(3):BB(4));
    bordersOI=bordersOI(BB(1):BB(2),BB(3):BB(4));
    save([tempDir slash baseName  '_' strAdd 'Ipoly.mat'], 'Ipoly');
    save([tempDir slash baseName  '_' strAdd 'bordersOI.mat'], 'bordersOI');
    
    if regFill
        RegsF=imfill(Regs,'holes');
        holes=RegsF & (~Regs);
        areaReg=sum(Regs(:));
        holes=bwareaopen(holes, round(areaReg*1e-05));
        [r,c]=find(logical(uint8(RegsF)-uint8(Regs)) & noHolesArea);
        clear noHolesArea;
        if numel(r)>0; RegsF(bwselect(logical(uint8(RegsF)-uint8(Regs)),c(1),r(1)))=false; end
        RegsF=bwareaopen(RegsF,threshSmallAreas) & (~holes);
        Regs(~RegsF)=false;
    else; RegsF=Regs; end
    save([tempDir slash baseName  '_' strAdd 'Regs.mat'], 'Regs');
    save([tempDir slash baseName  '_' strAdd 'RegsF.mat'], 'RegsF');
    
    sz=size(RegsF);
    save([tempDir slash baseName  '_' strAdd 'Size.mat'], 'sz');
    clear Ipoly deleteMarkerAreas;
    IRGB=I(BB(1):BB(2),BB(3):BB(4),:).*uint8(cat(3,RegsF,RegsF,RegsF));

    clear sz; sz=size(Regs); clear RegsF;
    IRGB1=IRGB(1:round(sz(1)/2),1:round(sz(2)/2),:); %#ok<NASGU>
    IRGB2=IRGB(1:round(sz(1)/2),round(sz(2)/2)+1:end,:); %#ok<NASGU>
    IRGB3=IRGB(round(sz(1)/2)+1:end,1:round(sz(2)/2),:); %#ok<NASGU>
    IRGB4=IRGB(round(sz(1)/2)+1:end,round(sz(2)/2)+1:end,:); %#ok<NASGU>
    save([tempDir slash baseName  '_' strAdd 'IRGB1.mat'], 'IRGB1');
    save([tempDir slash baseName  '_' strAdd 'IRGB2.mat'], 'IRGB2');
    save([tempDir slash baseName  '_' strAdd 'IRGB3.mat'], 'IRGB3'),
    save([tempDir slash baseName  '_' strAdd 'IRGB4.mat'], 'IRGB4');
    clear IRGB1 IRGB2 IRGB3 IRGB4 IRGB;
    clear Regs;        
end
