function res = DoG(img, sigma1, sigma2)
    img = double(img);
    h1 = fspecial('gaussian', sigma1*3+1, sigma1);
    h2 = fspecial('gaussian', sigma2*3+1, sigma2);
    res = imfilter(img,h1) - imfilter(img,h2);  
end