function OUT=MSRCC(I, alpha, gain, offset)
    disp('MSRCC')

    if nargin<3; offset=1; end
    if nargin<2; gain=2; end
    if nargin<1; alpha=60; end
    
    [m, n, dim]=size(I);

    if (m*n<25)
        error('invalid image size');        %not operating for the area of image less than 25
    end

    OUT=zeros(double(size(I)));
    cw=[25,35,45,100;0.1,0.25,0.5,0.7]';
    RGB_MSR=zeros(m,n,dim);
    
    I=double(I);
    RGB_test=I<1;
    I=RGB_test+I;
    for k=1:4
        RGB_SSR=SSR(I,cw(k,1));
        RGB_MSR=RGB_MSR+cw(k,2).*double(RGB_SSR);
    end
    subplot(337),imshow(mat2gray(RGB_MSR)),title('MSR','BackgroundColor',[.7 .9 .7]),impixelinfo;

    C_I1=zeros(size(RGB_MSR));
    C_I2=zeros(size(RGB_MSR));
    C_I2=zeros(size(RGB_MSR));

    sum_RGB_In=I(:,:,1)+I(:,:,2)+I(:,:,3);

    C_I1=log(alpha.*double(I(:,:,1))./double(sum_RGB_In));
    C_I2=log(alpha.*double(I(:,:,2))./double(sum_RGB_In));
    C_I3=log(alpha.*double(I(:,:,3))./double(sum_RGB_In));

    
    for i=1:1:m
        for j=1:1:n
            OUT(i,j,1)=gain*((C_I1(i,j)*RGB_MSR(i,j,1))+offset);
            OUT(i,j,2)=gain*((C_I2(i,j)*RGB_MSR(i,j,2))+offset);
            OUT(i,j,2)=gain*((C_I3(i,j)*RGB_MSR(i,j,3))+offset);
        end
    end
    OUT=mat2gray(OUT);

end
