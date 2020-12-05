function OUT = greyWorld(I)
    disp(['grey World'])
    
    [m,n,~]=size(I);
    Rmean      = sum(sum(I(:,:,1)))/(m*n);
    Gmean      = sum(sum(I(:,:,2)))/(m*n);
    Bmean      = sum(sum(I(:,:,3)))/(m*n);
    Avg        = mean([Rmean Gmean Bmean]);
    Kr         = Avg/Rmean;
    Kg         = Avg/Gmean;
    Kb         = Avg/Bmean;
    OUT(:,:,1) = Kr*double(I(:,:,1));
    OUT(:,:,2) = Kg*double(I(:,:,2));
    OUT(:,:,3) = Kb*double(I(:,:,3));
    OUT = uint8(OUT);
end