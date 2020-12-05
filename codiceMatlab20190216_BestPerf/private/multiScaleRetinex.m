function OUT = multiScaleRetinex(I, scales)
    %scales=50,150,200
    disp(['multi scale (equally weighted retinex) scales =' num2str(scales)]);
    OUT=zeros(size(I));
    for c=scales
       OUT=OUT+(1/double(numel(scales)))*double(singleScaleRetinex(I,c));
    end
    OUT = uint8(OUT);
end
