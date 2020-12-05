function imcircles = analizeCircles(bw,radiusRange)
    st3 = strel('disk',3);
    [centers,radii,metric] = imfindcircles(bw,radiusRange);
    imcircles=double(zeros(size(bw)));
    imtemp=imcircles;
    for i=1:numel(metric)
        [y,x]=drawCircles(centers(i,:), radii(i));
        y = int64(round(y)); x = int64(round(x));
        inddel=isnan(y) | y<=0 | x<=0 | y>=size(bw,1) | x>=size(bw,2);
        y(inddel)=[]; x(inddel)=[];
        ind=sub2ind(size(bw),y,x);
        imtemp(ind)=1; imtemp=imfill(imtemp,'holes');
        % riempio a mano cerchi attaccati ai bordi che non vengono riempiti
        % con la imfill
        % riempio i cerchi attaccati alla riga sopra e sotto
        res = bwselect(imdilate(imtemp,st3), 1:size(imtemp,2), ones(1,size(imtemp,2)) ) | ...
                bwselect(imdilate(imtemp,st3), 1:size(imtemp,2),repmat(size(imtemp,1),1,size(imtemp,2)));
        if any(res(:))
            res(1,1:size(imtemp,2)) = true; res(size(imtemp,1),1:size(imtemp,2)) = true;
            res=imfill(res,'holes'); 
            res(1,1:size(imtemp,2)) = false; res(size(imtemp,1),1:size(imtemp,2)) = false;
            res = imdilate(res,st3); imtemp = imtemp | res; clear res; 
        end
        
        % riempio i cerchi attaccati alla clonna a sx e dx
        res = bwselect(imdilate(imtemp,st3), ones(1,size(imtemp,1)),1:size(imtemp,1)) | ...
                    bwselect(imdilate(imtemp,st3), repmat(size(imtemp,2),1,size(imtemp,1)),1:size(imtemp,1));
        if any(res(:))
            res(1:size(imtemp,1),1) = true; res(1:size(imtemp,1), size(imtemp,2)) = true;
            res=imfill(res,'holes'); 
            res(1:size(imtemp,1),1) = false; res(1:size(imtemp,1), size(imtemp,2)) = false;
            res = imdilate(res,st3); imtemp = imtemp | res; clear res; 
        end
        imtemp = double(imtemp);
        if sum(sum(uint8(imcircles>0 & imtemp>0))) < pi*radii(i)*radii(i)*0.75
            if max(imcircles(:))==0; imcircles = imtemp;
            else; imcircles(imtemp>0) = max(imcircles(:))+ 1; end
        else
%             disp(['circle num=' num2str(i) ' discarded']); 
%             disp(['center = ' num2str(centers(i,:)) ', radii = ' num2str(radii(i))]);
        end
        imtemp(:)=0;    
    end
end

