dirSource=cd();
imgDir=uigetdir('D:\MIA\immagini_MIA\TUMORI\IMMAGINI_LICIA\SampleImages','Select working dir');
cd(imgDir);
list=dir(['.\*_pts.mat']);
for i=1:size(list,1)
    imgName=list(i,1).name;
    pos=strfind(imgName,'_pts.mat');
    baseName=imgName(1:pos-1);
    load([baseName '_pts.mat']);
    
    ...
        ...
    save([baseName '_pts.mat'],'ptsOn','ptsOff','ptsCriticalOff');
    delete([baseName '_ptsNuclei.mat']);
    clear ptsNuclei ptsOn ptsOff ptsCritical;
end
cd(dirSource);
    