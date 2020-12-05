function OUT = whitePatch(I)
    disp(['white Patch'])
    Kr = 255/max(max(double(I(:,:,1))));
    Kg = 255/max(max(double(I(:,:,2))));
    Kb = 255/max(max(double(I(:,:,3))));
    OUT(:,:,1) = Kr*double(I(:,:,1));
    OUT(:,:,2) = Kg*double(I(:,:,2));
    OUT(:,:,3) = Kb*double(I(:,:,3));
    OUT = uint8(OUT);
end