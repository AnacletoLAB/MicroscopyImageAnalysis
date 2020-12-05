function RegTumori(I,Itriangle, baseName, tempDir,Crop)
    if nargin<5; Crop=true; end;
    if ~exist(tempDir,'dir'); mkdir(tempDir); end 
 
     origsize=size(I);
     factor=max(origsize)/5000;
     fsz=20;
     h=fspecial('gaussian',[fsz fsz]);        
     IRGBS=imresize(I,'scale', 1/factor, 'method', 'lanczos3');
     imgGray=rgb2gray(IRGBS);
     imgGray=imfilter(medfilt2(imgGray,[fsz fsz]),h);
     Regs=~im2bw(imgGray,graythresh(imgGray)) | (imgGray<235);
     Regs=imclose(Regs, strel('disk',2));
     Regs=bwareaopen(Regs,round(numel(Regs)*1e-03));
     Regs(1:5,:)=false; Regs(:,1:5)=false;
     Regs(:,end-4:end)=false; Regs(end-4:end,:)=false;

%       areas=regionprops(Regs,'Area');
%       Regs=bwareaopen(Regs,max([areas.Area])); areas=[];
      Regs=imresize(Regs,[origsize(1),origsize(2)],'nearest'); 
      if Crop; [indY,indX]=find(Regs>0); %#ok<ALIGN>
        BB=[min(indY),max(indY), min(indX),max(indX)];
        indX=[]; indY=[];
      else BB=[1,size(Regs,1),1,size(Regs,2)]; end;
      Regs=Regs(BB(1):BB(2),BB(3):BB(4)); 
      if isfinite(sum(Itriangle(:))); Itriangle=Itriangle(BB(1):BB(2),BB(3):BB(4));
      else Itriangle=Regs; end
      IRGB=I(BB(1):BB(2),BB(3):BB(4),:).*uint8(cat(3,Regs,Regs,Regs)); 
      clear sz; sz=size(Regs);
      IRGB1=IRGB(1:round(sz(1)/2),1:round(sz(2)/2),:); %#ok<NASGU>
      IRGB2=IRGB(1:round(sz(1)/2),round(sz(2)/2)+1:end,:); %#ok<NASGU>
      IRGB3=IRGB(round(sz(1)/2)+1:end,1:round(sz(2)/2),:); %#ok<NASGU>
      IRGB4=IRGB(round(sz(1)/2)+1:end,round(sz(2)/2)+1:end,:); %#ok<NASGU>
      save([tempDir '\' baseName  '_OIRGB1.mat'], 'IRGB1');
      save([tempDir '\' baseName  '_OIRGB2.mat'], 'IRGB2');
      save([tempDir '\' baseName  '_OIRGB3.mat'], 'IRGB3');
      save([tempDir '\' baseName  '_OIRGB4.mat'], 'IRGB4');
      clear IRGB1 IRGB2 IRGB3 IRGB4 IRGB;

      save([tempDir '\' baseName  '_ORegs.mat'], 'Regs');
      save([tempDir '\' baseName  '_OItriangle.mat'], 'Itriangle');
      RegsF=imfill(Regs,'holes');
      save([tempDir '\' baseName  '_ORegsF.mat'], 'RegsF');
      imwrite(imresize((uint8(RegsF)+uint8(Regs)+uint8(Itriangle))*85,1/factor),...
          [tempDir '\' baseName  '_RegsF.jpg']);
      clear Regs RegsF Itriangle;       
end
