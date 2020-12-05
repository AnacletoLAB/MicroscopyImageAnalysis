function OUT= modifiedWhitePatch(I,th)
    disp(['modified white Patch with threshold: ', num2str(th)]);
    R=I(:,:,1); Kr = 255/mean(R(R>th));
    G=I(:,:,2); Kg = 255/mean(G(G>th));
    B=I(:,:,3); Kb = 255/mean(B(B>th));
    OUT(:,:,1) = Kr*double(I(:,:,1));
    OUT(:,:,2) = Kg*double(I(:,:,2));
    OUT(:,:,3) = Kb*double(I(:,:,3));
    OUT = uint8(OUT);
end