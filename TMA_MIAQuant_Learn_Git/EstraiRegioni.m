function EstraiRegioni()
% Gli dai in input la dir che contiene tutto: la dir subimages
% e la dir che ha nome come l'immagine e in cui ci sono gli overaly!
% le sottoimmagini create con lo script di
% imagemagick in quella dir devi copiare gli overlay!!
%la directory deve chiamarsi come la immagine
    
nameBigDir = uigetdir('C:\DATI\Elab_Imgs_Mediche\MIA\immagini_MIA', 'Select image directory');

res = dir(nameBigDir);
resDir = [nameBigDir filesep 'subimages' filesep 'Masks'];
if ~exist(resDir,'dir'); mkdir(resDir); end
    
for nDir =  numel(res):-1:1
 if res(nDir).isdir==1
    nomeImg = res(nDir).name
    nameDir = [res(nDir).folder filesep nomeImg];  
    nomifiles = [dir([nameDir '\*-overlay.jpg']); ...
        dir([nameDir '\*-overlay.tif'])];
    st1= strel('disk',1);  st3= strel('disk',3); st11 = strel('disk',11);
    thrArea = 10000;
    for nf=numel(nomifiles):-1:1
       
       imgName = nomifiles(nf).name;
       disp([num2str(nf) ')' imgName]);
       img = imread(fullfile(nameDir,imgName));
       pos = strfind(imgName,'-overlay.jpg');
       if numel(pos)==0; ext = 'tif'; 
           pos = strfind(imgName,'-overlay.tif'); 
       else; ext = 'jpg'; end
       imgIndex = imgName(1:pos-1);
       pos = strfind(nameDir,'\');      
       info = parseName(nomeImg);
       resName = [info.patName '+' imgIndex '_Regs'];
       disp(resName)
       if ~exist([resDir filesep resName '.mat'],'file')
          
           % figure; imshow(img);

            binHoles = img(:,:,1)<10 & img(:,:,2)<10 & img(:,:,3)<10;
            binHoles = logical(imfill(imdilate(binHoles,strel('disk',3)),'holes'));
%            binHoles = imopen(imerode(bin, st11),st11);
         %  binHoles = bwareaopen(bin,thrArea);
           % figure; imshow(uint8(binHoles)*255);
           
           bin = img(:,:,1)>100 & img(:,:,2)<75 & img(:,:,3)<75;
           bin = logical(imfill(imdilate(bin,st3),'holes'));
           bin = imopen(imerode(bin, st3),st3);       
           binR = bwareaopen(bin,thrArea);
           binR(binHoles) = 0;
  %          figure('Position',[1 1 255 255]); imshow(uint8(binR)*255);
%             if strcmpi(input('area rossa,lavoro? (Y/N)', 's'),'y')
%                 dbstop at 56 in EstraiRegioni; 
%             end

           bin = img(:,:,1)>175 & img(:,:,2)>175 & img(:,:,3)<100;
           bin = logical(imfill(imdilate(bin,st11),'holes'));
           bin = imopen(imerode(bin, st11),st11);
           binY = bwareaopen(bin,thrArea);
           binY(binHoles) = 0;
%           figure; imshow(uint8(binY)*255); 
%            if strcmpi(input('area gialla, lavoro? (Y/N)', 's'),'y')
%                dbstop at 56 in EstraiRegioni; 
%                disp('butto giallo'); end

           bin = img(:,:,1)<175 & img(:,:,2)>175 & img(:,:,3)<175;
           bin = logical(imfill(imdilate(bin,st11),'holes'));
           bin = imopen(imerode(bin, st11),st11);
           binG = bwareaopen(bin,thrArea);
           binG(binHoles) = 0;
 %          figure; imshow(uint8(binG)*255);
%            if strcmpi(input('area verde, lavoro?(Y/N)', 's'),'y')
%                dbstop at 56 in EstraiRegioni; 
%                disp('butto verde'); end

          
           Regs = uint8(binR)*1 + uint8(binY)*2 + uint8(binG)*3;
           
           
           if any(Regs(:)>0)
               imwrite(Regs*85, [resDir filesep resName '.tif']);
               save([resDir filesep resName '.mat'], 'Regs', 'binHoles');
               imwrite(uint8(binHoles)*255, [resDir filesep resName '_NORegs.tif']);
               iShowR=img;

               binRbord = imerode(binR,st11); 
               iShowR(cat(3,binRbord, binRbord,binRbord)) = 0;
               iShowR(cat(3,binRbord, false(size(binRbord)),false(size(binRbord)))) = 255;

               iShowY=img;
               binYbord = imerode(binY,st11); 
               iShowY(cat(3,binYbord, binYbord,binYbord)) = 0;
               iShowY(cat(3,binYbord,binYbord,false(size(binYbord)))) = 255;

               iShowG=img;
               binGbord = imerode(binG,st11); 
               iShowG(cat(3,binGbord, binGbord,binGbord)) = 0;
               iShowG(cat(3,false(size(binGbord)),binGbord,false(size(binGbord)))) = 255;

               resName = ['Compare_' info.patName '+' imgIndex ];
               imwrite(cat(2,img,iShowR,iShowY,iShowG), [resDir filesep resName '.tif']);

          %      figure; imshow(cat(2,img,iShowR,iShowY,iShowG));

                close all
           else
               disp('Img senza regioni');
               if delImgNoReg
                   fileDel = fullfile(nameDir, [imgIndex '.' ext]);
                   if exist(fileDel, 'file')
                        delete(fileDel);
                        fileDel = fullfile(nameDir,imgName); 
                        delete(fileDel);
                        resName = [info.patName '+' imgIndex ...
                            '_'  ...
                            info.markerColor '.' ext];
                        fileDel = fullfile(nameDir,'subimages',resName); 

                   else
                       disp('perche non esiste?');
                   end
               else
                   imwrite(Regs*85, [resDir filesep resName '.tif']);
                   save([resDir filesep resName '.mat'], 'Regs', 'binHoles');
                   imwrite(ones(size(binHoles))*255, [resDir filesep resName '_NORegs.tif']);  
               end
               close all
           end
       end
    end
 end
end
end