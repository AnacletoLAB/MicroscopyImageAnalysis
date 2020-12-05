function [regs, ok] =  analizeRegsSimple(regs, ok, areaDet, conn)  
    
    if nargin<4; conn = 4; end
    cc = bwconncomp(regs,conn); 
    labs = labelmatrix(cc);
    stats = regionprops(cc, 'Area', 'MinorAxisLength', ...
                            'MajorAxisLength'); 

    idx = find( [stats.Area]<= areaDet.maxArea & ... % l'area non deve essere troppo grossa
                [stats.Area]>= areaDet.minArea*0.5 & ...                % ne troppo piccola
                [stats.MinorAxisLength]./[stats.MajorAxisLength]>0.6); 
    if numel(idx)>0 % le rimuovo da notOk e le metto in ok!
       rr = ismember(labs, idx);
       clear labs;
       % controllo anche che il raggio minimo e massimo non abbiano un 
       % rapporto troppo scompensato
       cc = bwconncomp(rr,conn); 
       labs = labelmatrix(cc);
       stats = regionprops(cc,'Image','ConvexImage');
       for nR = 1 : max(labs(:))
           distR = bwdist(bwskel(stats(nR).Image));
           maxR = max(distR(bwperim(stats(nR).Image)));
           minR = min(distR(bwperim(stats(nR).Image)));

           distR = bwdist(bwskel(stats(nR).ConvexImage));
           maxRC = max(distR(bwperim(stats(nR).ConvexImage)));
           minRC = min(distR(bwperim(stats(nR).ConvexImage)));
         %  disp(['nR = ' num2str(nR) ', minR/maxR = ' num2str(minR/maxR)...
          %         ', minRC/maxRC = ' num2str(minRC/maxRC)]);
           if minR/maxR<0.1 && minRC/maxRC<0.45                       
               rr(labs == nR) = false;
           end
       end
       rr = imfill(rr,'holes');
       ok(rr) = max(ok(:));
       ok = ok + bwlabel(rr, conn);
       regs(imdilate(rr,strel('disk',1))) = false;
    end
end
