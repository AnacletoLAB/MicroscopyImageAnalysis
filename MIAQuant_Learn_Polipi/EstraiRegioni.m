function EstraiRegioni(nameBigDir)
% Gli dai in input la dir che contiene tutto: la dir subimages
% e la dir che ha nome come l'immagine e in cui ci sono gli overaly!
% le sottoimmagini create con lo script di
% imagemagick in quella dir devi copiare gli overlay!!
%la directory deve chiamarsi come la immagine
    
if nargin<1; nameBigDir = uigetdir('C:\DATI\Elab_Imgs_Mediche\MIA\immagini_MIA', 'Select image directory'); end
dirSubImgs = [nameBigDir filesep 'subimages'];
dirMasks =  [dirSubImgs filesep 'Masks'];
if ~exist(dirMasks,'dir'); mkdir(dirMasks); end

strDispImg = '_RegsShow';
thrArea =100;
offset = 7;
res = dir([nameBigDir filesep '*.tif']);
for nI =  numel(res):-1:1
 
    nomeImg = res(nI).name(1:end-4);
    nameDir = [res(nI).folder filesep nomeImg];  
    nomifiles = [dir([nameDir '\*-overlay.jpg']); ...
        dir([nameDir '\*-overlay.tif'])];
    st1= strel('disk',1);  st7= strel('disk',7); st11 = strel('disk',11);
   
    for nf=numel(nomifiles):-1:1
       
       imgName = nomifiles(nf).name;
       disp([num2str(nf) ')' imgName]);
       img = imread(fullfile(nameDir,imgName));
       pos = strfind(imgName,'-overlay.jpg');
       if numel(pos)==0; ext = 'tif'; 
           pos = strfind(imgName,'-overlay.tif'); 
       else; ext = 'jpg'; end
       imgIndex = imgName(1:pos-1);
      
       
       info = parseName(nomeImg);
       
       resName = [info.patName '+' imgIndex '_' info.markerColor ];
       bigImgName = [resName '.tif'];
       
       if ~exist([dirMasks filesep resName strDispImg '.tif'], 'file')
           imgBig = imread([dirSubImgs filesep bigImgName]);
           sz = size(imgBig);
           sz1 = sz(1); sz2 = sz(2);
           fact = 500.0/double(max(sz(1:2)));


            bin = img(:,:,1)<75 & img(:,:,2)<75 & img(:,:,3)<75;
            bin = logical(imfill(imdilate(bin,st11),'holes'));
            bin = imopen(imerode(bin, st11),st11);       
            if any(bin(:))
                props = regionprops(bin,'Area');
                binB = bwareaopen(bin,floor(max([props.Area])/5));
            else; binB = bin; end
            clear bin;

            bin = img(:,:,1)>100 & img(:,:,2)<75 & img(:,:,3)<75;
            bin = logical(imfill(imdilate(bin,st11),'holes'));
            bin = imopen(imerode(bin, st11),st11); 
            if any(bin(:))
                props = regionprops(bin,'Area');
                binR = bwareaopen(bin,floor(max([props.Area])/5));
            else; binR = bin; end
            clear bin; 


            if any(binB(:) & binR(:))
                delR = binB & binR;
                binB(delR) = false;
                binR(delR) = false;
            end

            iShowR = img;
            if any(binB(:))
                rr = binB;
                binRbord = logical(rr-imerode(rr,st7)); 
                iShowR(cat(3,binRbord, binRbord,binRbord)) = 0;
            end
            if any(binR(:))
                rr = binR;
                binRbord = logical(rr-imerode(rr,st7)); 
                iShowR(cat(3,binRbord, binRbord,binRbord)) = 0;
                iShowR(cat(3,binRbord, false(size(binRbord)),false(size(binRbord)))) = 255;
            end
            figure('units','normalized', 'OuterPosition', [0 0 1 1]); 
            subplot(1,2,1);imshow(img); subplot(1,2,2);imshow(iShowR);
            answ = input('stop or continue? (S/null)','s');

            if numel(answ) == 0
                
                imwrite(iShowR, [dirMasks filesep resName strDispImg '.tif']);
            strAppend = 'BLACK';
                if any(binB(:)); bin = imresize(binB, [size(imgBig,1) size(imgBig,2)]);
                    props = regionprops(bin,'BoundingBox');
                    for nR = 1: numel(props)
                        bbbox = round(props(nR).BoundingBox);
                        sy = max([bbbox(2)-offset,1]); ey = min([bbbox(2)+bbbox(4)+offset,sz1]);
                        sx = max([bbbox(1)-offset,1]); ex = min([bbbox(1)+bbbox(3)+offset,sz2]);

                        Regs = bin(sy:ey,sx:ex);
                        imgCut = imgBig(sy:ey,sx:ex,:);
                        if numel(props)>1; imgIndex = [imgIndex '-' num2str(nR)]; end
                        resName = [info.patName '+' imgIndex '-' strAppend '_' info.markerColor];
                        disp(resName)
                        save([dirMasks filesep resName '_Regs.mat'], 'Regs');
                        imwrite(imgCut, [dirSubImgs filesep resName '.tif']);


                        clear Regs imgCut iShowR;
                    end

                 else; disp( 'non ho black') ; end  


            strAppend = 'RED';
                  if any(binR(:)); bin = imresize(binR, [size(imgBig,1) size(imgBig,2)]);
                      props = regionprops(bin,'BoundingBox');
                        for nR = 1: numel(props)
                            bbbox = round(props(nR).BoundingBox);
                            sy = max([bbbox(2)-offset,1]); ey = min([bbbox(2)+bbbox(4)+offset,sz1]);
                            sx = max([bbbox(1)-offset,1]); ex = min([bbbox(1)+bbbox(3)+offset,sz2]);

                            Regs = bin(sy:ey,sx:ex);
                            imgCut = imgBig(sy:ey,sx:ex,:);
                            if numel(props)>1; imgIndex = [imgIndex '-' num2str(nR)]; end
                            resName = [info.patName '+' imgIndex '-' strAppend '_' info.markerColor];
                            disp(resName)
                            save([dirMasks filesep resName '_Regs.mat'], 'Regs');
                            imwrite(imgCut, [dirSubImgs filesep resName '.tif']);


                            clear Regs imgCut iShowR;
                        end


                        clear Regs imgCut iShowR;
                else; disp( 'non ho red') ; end     
                close all;
                clear resName;
            else; dbstop at 83; 
                disp('qualcosa non va');
            end
            clear bin bbbox strAppend;
            
       else; disp('Che GIOIA!!! Immagine già processata'); end
 end
end
