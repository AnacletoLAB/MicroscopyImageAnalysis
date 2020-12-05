function RGB_SSR=SSR(RGB_In,c)

    disp('Single Scale Retinex')
    if nargin<2; c=5; end

    [m n dim]=size(RGB_In);

    if (m*n<25)
        error('invalid image size');        %not operating for the area of image less than 25
    end

    RGB_Out=zeros(size(RGB_In));
    RGB_In=double(RGB_In);

    RGB_In_test=RGB_In<1;
    RGB_In=RGB_In_test + RGB_In;

    RGB_Out_R=zeros(m,n);
    RGB_Out_G=zeros(m,n);
    RGB_Out_B=zeros(m,n);

    RGB_R=zeros(m,n);
    RGB_G=zeros(m,n);
    RGB_B=zeros(m,n);

    RGB_R=RGB_In(:,:,1);
    RGB_G=RGB_In(:,:,2);
    RGB_B=RGB_In(:,:,3);

    F=zeros(m,n);
    RGB_conv=zeros(size(RGB_In));
    %using the standart deviation to calculate the Filtered image
    F=fspecial('gaussian',[m n],c);

    RGB_conv1=zeros(m,n);
    RGB_conv2=zeros(m,n);
    RGB_conv3=zeros(m,n);

    RGB_Out_R=zeros(m,n);
    RGB_Out_G=zeros(m,n);
    RGB_Out_B=zeros(m,n);

    %Applying the Convolution to get the 

    RGB_conv1=conv2(F,RGB_R,'same');
    RGB_conv2=conv2(F,RGB_G,'same');
    RGB_conv3=conv2(F,RGB_B,'same');

    RGB_Out_R=log(double(RGB_R)./(RGB_conv1));
    RGB_Out_G=log(double(RGB_G)./(RGB_conv2));
    RGB_Out_B=log(double(RGB_B)./(RGB_conv3));

    RGB_Out(:,:,1)=RGB_Out_R;
    RGB_Out(:,:,2)=RGB_Out_G;
    RGB_Out(:,:,3)=RGB_Out_B;
    RGB_SSR=mat2gray(RGB_Out);

end