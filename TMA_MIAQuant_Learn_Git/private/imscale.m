function imgt=imscale(img, oldrange,range)
% IMSCALE  Scale an image to fit the range
%
%  This function scales the values of an image to fit the range.
%
%  Params:
%
% img   = The image.
% oldrange = values to be scaled
% range  = The output target value. (def=[0,1])
%
% imgt  = The image scaled.

%disp('imscaling from MIA\CODICE_MATLAB\Usage');
    % Check params:    
    if (nargin<3); range=[0.0 1.0]; end;
    if (nargin<2); oldrange=[min(img(:)) max(img(:))]; end;
    % Transform the image type:
    imgt=single(img); 
    oldrange=single(oldrange); range=single(range);
    imgt(imgt>oldrange(2))=oldrange(2);
    imgt(imgt<oldrange(1))=oldrange(1);    
    % Obtain and appling the offset:
    imgt = imgt-oldrange(1);
    % Obtain and appling the scale:
    imgt = imgt/(oldrange(2)-oldrange(1));
    
    % Generate the required image:
    if not(abs(range(2)-range(1))==1)
        imgt = imgt*abs(range(2)-range(1));
    end
    if not(range(1)==0)
        imgt = imgt+range(1);
    end
    clear img;
end

