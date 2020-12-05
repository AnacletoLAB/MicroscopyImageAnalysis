function EstraiRegFede()
% Gli dai in input la dir che contiene tutto: la dir subimages
% e la dir che ha nome come l'immagine e in cui ci sono gli overaly!
% le sottoimmagini create con lo script di
% imagemagick in quella dir devi copiare gli overlay!!
%la directory deve chiamarsi come la immagine
    
nameBigDir = uigetdir('C:\DATI\Elab_Imgs_Mediche\MIA\immagini_MIA', 'Select image directory');

res = dir(nameBigDir);
subimagesDir = [nameBigDir filesep 'subimages'];

maskDir = [subimagesDir filesep 'Masks'];

if ~exist(maskDir,'dir'); error('Mask Dir Not Existent'); end

st1= strel('disk',1);  st3= strel('disk',3); st11 = strel('disk',11);
    thrArea = 10000;
    f = 0.3; fsz = 3; gaussDev = 0.5;
    nIter =100;
    
% for nDir =  numel(res):-1:1
%  if res(nDir).isdir==1 && ~strcmpi(res(nDir).name, 'subimages')
%     nomeImg = res(nDir).name;
%     nameDir = [res(nDir).folder filesep nomeImg];  
%    info = parseName(nomeImg);
    nomifiles = [dir([subimagesDir filesep  '*.tif']); ...
        dir([subimagesDir filesep '*.jpg'])];
    
    for nf=1:numel(nomifiles)
       
       imgName = nomifiles(nf).name;
       info = parseName(imgName);
       posPiu = strfind(info.patName,'+');
       disp([num2str(nf) ')' imgName]);
       imgIndex = info.patName(posPiu+1:end);
       overlayName = [imgIndex '-overlay'];
       
       nameDir = [nameBigDir filesep info.patName(1:posPiu-1) '_' info.markerName];
       trovataCaxxoOverlay = dir([nameDir '*' filesep overlayName '.jpg']);
       if numel(trovataCaxxoOverlay)==1
           imgOverlay = imread([trovataCaxxoOverlay(1).folder filesep overlayName '.jpg']);
       elseif numel(trovataCaxxoOverlay)>1; dbstop at 49;
           disp('TROPPE IMG OVERLAY!');
       else; dbstop at 49;
           disp('NON JHO IMG OVERLAY!');
       end
           
           pos = strfind(imgName,'-overlay.jpg');
           if numel(pos)==0; ext = 'tif'; 
               pos = strfind(imgName,'-overlay.tif'); 
           else; ext = 'jpg'; end

           resName = [info.patName '_' info.markerName '_Regs'];
           maskFedeName = [info.patName  '_' info.markerName '_*.tif_binarized'];
           trovataCaxxoReg = dir([maskDir filesep maskFedeName '.mat']);
           if numel(trovataCaxxoReg)==1
                if ~exist([maskDir filesep resName '.mat'],'file')
                    load([trovataCaxxoReg.folder filesep trovataCaxxoReg.name], 'BinImage');
                    img = imread([subimagesDir filesep imgName]);
                    imgSmall = imresize(img,f);
                    for i = 1:3; imgSmall(:,:,i) = imgaussfilt(medfilt2(imgSmall(:,:,i),[fsz fsz]),gaussDev); end
                    greyImg = rgb2gray(imgSmall);
                    
                    % tutte della stessa dimensione!
                    greyImg = imadjust(greyImg,stretchlim(greyImg),[]); % PICCOLA!!!
                    imgGrayfilt=imgaussfilt(medfilt2(greyImg,[fsz fsz]),gaussDev);
                    imgOverlay = imresize(imgOverlay, size(imgGrayfilt), 'nearest');
                    
                    binHolesInit = imfill(imgOverlay(:,:,1)<10 & imgOverlay(:,:,2)<10 & imgOverlay(:,:,3)<10, 'holes');
                    
                    RegDaClinici = imfill(imdilate(imgOverlay(:,:,1)>230 & imgOverlay(:,:,2)<10 & imgOverlay(:,:,3)<10, st3),'holes');
                    if any(RegDaClinici(:));  Regs = RegDaClinici; 
                        Regs = imresize(Regs,  size(imgGrayfilt),  'nearest');
                    else; Regs = imresize(BinImage, size(imgGrayfilt), 'nearest'); end
                        if any(any(Regs(binHolesInit)))
                            disp('buchi!');
                        
%                         binHoles = binHoles | activecontour(imgGrayfilt, ...
%                            imfill(binHoles,'holes'),nIter,'edge');
%                         
                            binHoles = binHolesInit | (imgGrayfilt > median(imgGrayfilt(~Regs))- std(double(imgGrayfilt(~Regs))*1.5));
                            binHoles(logical(Regs-imerode(Regs,st11)) | (~Regs)) = false;
                            [r,c] = find(binHolesInit);
                            binHoles = imfill(imclose(bwselect(binHoles, c,r),st11),'holes');
                     %   binHoles = imresize(binHoles, [size(img,1), size(img,2)]);
                        else; binHoles = false(size(img,1), size(img,2)); end
                   
                    
                    Regs(binHoles) = false; 
                    NewR = imopen(imclose(Regs, st11), st11); 
                    Regs = Regs | NewR;
                    Regs(binHoles) = false; 
                    Regs(binHolesInit) = false; 
                    
                    
                    Regs =   imresize(Regs, [size(img,1), size(img,2)], 'nearest');      
                    deposito = imresize(imgOverlay(:,:,1)>253 & imgOverlay(:,:,2)>253 & imgOverlay(:,:,3)>253, [size(img,1), size(img,2)], 'nearest');
                    binHoles = false(size(Regs)); 

                   if any(Regs(:)>0)

                       iShow = img;
                       binRbord = logical(binHoles - imerode(binHoles,st11)); 
                       iShow(cat(3,binRbord, binRbord,binRbord)) = 0;
                       binRbord = logical(Regs - imerode(Regs,st11)); 
                       iShow(cat(3, binRbord, binRbord, binRbord)) = 0;
                       iShow(cat(3, binRbord, false(size(binRbord)),false(size(binRbord)))) = 255;
                       
%                       binRbord = logical(NewR - imerode(NewR,st11)); 
%                       iShow(cat(3, binRbord, binRbord, binRbord)) = 0;
%                       iShow(cat(3, false(size(binRbord)), binRbord,false(size(binRbord)))) = 255;
%                        
                       figure; imshow(iShow);
                       save([maskDir filesep resName '.mat'], 'Regs','binHoles', 'deposito');
                       resName = ['View' info.patName '_' info.markerName];
                       imwrite(iShow, [maskDir filesep resName '.tif']);

        %               iShow(cat(3, 
        %                binYbord = imerode(binY,st11); 
        %                iShowY(cat(3,binYbord, binYbord,binYbord)) = 0;
        %                iShowY(cat(3,binYbord,binYbord,false(size(binYbord)))) = 255;
        % 
        %                iShowG=imgOverlay;
        %                binGbord = imerode(binG,st11); 
        %                iShowG(cat(3,binGbord, binGbord,binGbord)) = 0;
        %                iShowG(cat(3,false(size(binGbord)),binGbord,false(size(binGbord)))) = 255;



                  %      figure; imshow(cat(2,img,iShowR,iShowY,iShowG));

                        close all
                   else
                       
                   end
                end
           else; disp('perchè non ci sta nulla ??'); 
               dbstop at 139;
           end
       
    end
 end
% end
% end