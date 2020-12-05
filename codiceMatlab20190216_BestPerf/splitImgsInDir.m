function resPath = splitImgsInDir(dirImgs, dims)

    if nargin < 1
        dirImgs=uigetdir(...
            fullfile('C:', 'DATI' , 'Elab_Imgs_Mediche' , 'MIA' , 'immagini_MIA'),...
        'Select the img folder');
    end
    if nargin< 2 || numel(dims)<4
        prompt = {'Enter the width of subImages:', 'Enter the offset along lines:', ...
            'Enter the height of subImages:',  'Enter the offset along heights:'  };
        title = 'Input';
        definput = {'256', '32', '256', '32'};
        dims = [1 35];
        answer = inputdlg(prompt,title,dims,definput);

        sx=uint64(str2double(answer{1})); sy=uint64(str2double(answer{3}));
        % i tagli si sovrappongono di offset pixel
        offx = uint64(str2double(answer{2})); offy = uint64(str2double(answer{4}));
    else
        sx = dims(1); sy = dims(2); offx = dims(3); offy = dims(4);
    end
    fnsAll=[dir(fullfile(dirImgs, '*.tif'));
                dir(fullfile(dirImgs, '*.tiff'));
                dir(fullfile(dirImgs, '*.jpg'));
                dir(fullfile(dirImgs, '*.png'));
                dir(fullfile(dirImgs, '*.svs'))];
   
    nameSub = 'subImages';
    resPath = fullfile(dirImgs, nameSub);
    if ~exist( resPath, 'dir'); mkdir(resPath); end 
    
    for numI=1:numel(fnsAll)
        fName=fnsAll(numI,1).name;
        I = imread(fullfile(dirImgs, fName));
        I = I(:,:,1:3);
        splitImage(fName, resPath, I, sx, sy, offx, offy)
    end    
    
end


function splitImage(imgN, resPath, I, sx, sy, offx, offy)
    szy = size(I,1); szx = size(I,2);
    if offx >= sx; offx = uint64(sx)/2; end
    if offy >= sy; offy = uint64(sy)/2; end
    pos = strfind(imgN, '.');
    imgName = imgN(1:pos-1);
    ext = imgN(pos:end);
    n = 0;
    for xx = 1 : sx : szx-sx 
        for yy = 1 : sy : szy-sy
            starty = max(yy - offy, 1); startx = max(xx - offx, 1);
            endy = min(starty+sy-1,szy); endx = min(startx+sx-1,szx);
            imwrite(I(starty:endy,startx:endx,:), ...
                fullfile(resPath,  [imgName '_' num2str(n) ext]));
            n = n+1;
        end
    end
    for yy = szy : -sy+offy : sy
        endy = yy; starty = max(yy-sy+1,1); 
            imwrite(I(starty: endy,szx-sx:szx-1,:), ...
            fullfile(resPath,  [imgName '_' num2str(n) ext]));
        n = n+1;
    end
    for xx = szx-sx : -sx+offx : sx
        startx = max(xx - sx+1, 1); endx = xx; 
            imwrite(I(szy-sy:szy-1,startx:endx,:), ...
            fullfile(resPath,  [imgName '_' num2str(n) ext]));
        n = n+1;
    end
end