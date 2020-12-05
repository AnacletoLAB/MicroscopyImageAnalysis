function createSubImages()
    dirImgs = uigetdir('C:\DATI\Elab_Imgs_Mediche\MIA\immagini_MIA', 'Select directory of subimages to split');
    
    dirSub = [dirImgs filesep 'subImgs'];
    dirGTSub = [dirSub filesep 'GT'];
    if ~(exist(dirSub,'dir')); mkdir(dirSub); end
    if ~(exist(dirGTSub,'dir')); mkdir(dirGTSub); end
    
    dimS = input('insert dimension of subimages (es.: [dimx dimy]): ');
    if numel(dimS) ==0; dimS = [256 256]; end
    subfns = dir([dirImgs filesep '*.tif']);
    dirMasks = 'Masks'; nameReg = 'Regs.mat';
    dirGT = 'Markers';  nameGT = 'markers.mat';
    
    for numI = 1:numel(subfns)
       imgName = subfns(numI).name;
       info = parseName(imgName);
       if exist([subfns(numI).folder filesep dirMasks filesep ...
           info.patName '_' info.markerName '_' nameReg], 'file') && ...
          exist([subfns(numI).folder filesep dirGT  filesep ...
           info.patName '_' info.markerName '_' info.markerColor '_' nameGT], 'file') 
           img = imread([subfns(numI).folder filesep imgName]);
           load([subfns(numI).folder filesep dirMasks filesep ...
               info.patName '_' info.markerName '_' nameReg]);
           load([subfns(numI).folder filesep dirGT  filesep ...
               info.patName '_' info.markerName '_' info.markerColor '_' nameGT]);
           Regs = imresize(Regs==1, size(markers),'nearest');
           binHoles = imresize(binHoles, size(markers),'nearest');

           img(cat(3, ~Regs | binHoles==1,~Regs | binHoles==1,~Regs | binHoles==1)) = 0;

           for nC = 1:round(dimS(2)/2):size(img,2)-dimS(2)           
           for nR = 1:round(dimS(1)/2):size(img,1)-dimS(1)
               subR = Regs(nR:nR+dimS(1)-1,nC:nC+dimS(2)-1);
               if sum(uint8(subR(:)))/numel(subR)>0.5
                   subImg = img(nR:nR+dimS(1)-1,nC:nC+dimS(2)-1,:);
                   subGT = uint8(markers(nR:nR+dimS(1)-1,nC:nC+dimS(2)-1))*255;
                   imwrite(subImg,[dirSub filesep info.patName '_' info.markerName '_' num2str(nC) '-' num2str(nR) '.tif']);
                   imwrite(subGT,[dirGTSub filesep info.patName '_' info.markerName '_' num2str(nC) '-' num2str(nR) '.tif']);
               end
           end
           end
       end    
    end
    
end
