function modifica()
cd('E:\TMA11-PDL1_Marroni\subimages\Masks')
nomifiles = dir('*.tif')
for i = 1:numel(nomifiles)
   imgname = nomifiles(i).name;
   img = imread(imgname);
   if ((size(img,1)==100) && (size(img,2)==100) && sum(img(:))==0)
       imwrite(uint8(zeros(10,10,3)), nomifiles(i).name);
       
   end
    
end