function [Regs, RegsF]=regTissue(I,regFill, thrArea)
    
    I(I==0)=1;
    
    origsize=size(I); 
    
    if (size(I,1)<100 && size(I,2)<100); Regs=true(origsize(1),origsize(2));
    else
         imgGray = rgb2gray(I); 
         thresh = multithresh(imgGray,10);
         Regs = imgGray<max(thresh);
         Regs = bwareaopen(Regs, thrArea);
     end
    
   
    if regFill
        RegsF=imfill(Regs,'holes');
        holes=RegsF & (~Regs);
        areaReg=sum(Regs(:));
        Bigholes=bwareaopen(holes, round(areaReg*1e-03));
        RegsF=bwareaopen(RegsF,thrArea) & (~Bigholes);
        Regs(~RegsF)=false;
    else; RegsF=Regs; end   
    
end
