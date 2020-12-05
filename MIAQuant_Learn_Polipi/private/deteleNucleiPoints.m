dirSource=cd();
imgDir=uigetdir('E:\','Select working dir');
cd(imgDir);
list=dir(['.\*_pts.mat']);
for i=1:size(list,1)
    imgName=list(i,1).name;
    pos=strfind(imgName,'_pts.mat');
    baseName=imgName(1:pos-1);
    load([baseName '_pts.mat']);
    load([baseName '_ptsNuclei.mat']);
    
    ptsOn=[ptsOn;ptsNucleiOn];
    ptsNucleiOn=[];
    ptsOff=[ptsOff; ptsNucleiOff];
    ptsCriticalOff=ptsNucleiOff;
    save([baseName '_pts.mat'],'ptsOn','ptsOff','ptsCriticalOff');
    delete([baseName '_ptsNuclei.mat']);
    clear ptsNuclei ptsOn ptsOff ptsCritical;
end
cd(dirSource);
    