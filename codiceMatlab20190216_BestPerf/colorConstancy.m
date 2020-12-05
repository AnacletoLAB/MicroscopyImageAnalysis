% Juan Manuel Perez Rua

% I =input image
% algorithm =name of the algorithm
% varargin, threshold list, if needed. AN error message error appears
% if incorrect inputs are used.

%Example of usage: J = colorConstancy(I, 'modified white patch', 200);
function  colorConstancy( dirImg, nameImg) 
    gaussDev=0.5;
    I = imread(fullfile(dirImg,nameImg));
    I=I(:,:,1:3);
    IFilt = uint8(zeros(size(I)));
    for ch = 1: size(IFilt,3); IFilt(:,:,ch) = imgaussfilt(medfilt2(I(:,:,ch)), gaussDev); end
    for ratio = 4 
        dirS = ['progressive_' num2str(ratio)]; 
        if  ~exist(fullfile(dirImg,dirS), 'dir'); mkdir(fullfile(dirImg,dirS)); end
        imwrite(progressive(IFilt, ratio), fullfile(dirImg,dirS,nameImg));
    end
    for rFunc = ['G','L','S']
        for scaling = ['L', 'G']
            if strcmpi(rFunc, 'S')
                for slope = [1.5,3,6]
                    dirS=[ 'ace_' rFunc '_' num2str(slope) '_' scaling ];
                    if  ~exist(fullfile(dirImg,dirS), 'dir'); mkdir(fullfile(dirImg,dirS)); end
                    imwrite(ace(IFilt,Inf,'E',[],rFunc,slope, scaling ), fullfile(dirImg,dirS,nameImg));
                end
            else
                dirS=[ 'ace_' rFunc '_' scaling];
                if  ~exist(fullfile(dirImg,dirS), 'dir'); mkdir(fullfile(dirImg,dirS)); end
                imwrite(ace(IFilt,Inf,'E',[],rFunc,[], scaling ), fullfile(dirImg,dirS,nameImg));
            end
        end
    end
    for w=5
        dirS = ['SingleScaleRetinex_' num2str(w)];
        if  ~exist(fullfile(dirImg,dirS), 'dir'); mkdir(fullfile(dirImg,dirS)); end
        imwrite(SSR(IFilt,w), fullfile(dirImg,dirS,nameImg));
    end
    for alpha=60
        for beta=1
            for gain=2
                dirS =['MSRCC_' num2str(alpha) '_' num2str(beta) '_' num2str(gain)];
                if  ~exist(fullfile(dirImg,dirS), 'dir'); mkdir(fullfile(dirImg,dirS)); end
                imwrite(MSRCC(IFilt,alpha,beta,gain), fullfile(dirImg,dirS,nameImg));
            end
        end
    end
    dirS='whitePatch';
    if  ~exist(fullfile(dirImg,dirS), 'dir'); mkdir(fullfile(dirImg,dirS)); end
    imwrite(whitePatch(IFilt), fullfile(dirImg,dirS,nameImg));
    for th=[150,200]
        dirS=['modifiedWhitePatch_' num2str(th)];
        if  ~exist(fullfile(dirImg,dirS), 'dir'); mkdir(fullfile(dirImg,dirS)); end
        imwrite(modifiedWhitePatch(IFilt,200), fullfile(dirImg,dirS,nameImg))
    end
    dirS='greyWorld';
    if  ~exist(fullfile(dirImg,dirS), 'dir'); mkdir(fullfile(dirImg,dirS)); end
    imwrite(greyWorld(IFilt),fullfile(dirImg,dirS,nameImg));
end



    

