function [ Norm ] = NormReinhardMasked( Source, Target,  maskSource, maskTarget )

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NormRienhard: Normalise a Source image with respect to a Target image
% using Reinhard's method.
% 
% This routine takes a Source and Target image as input and uses Reinhard's 
% method (Reference below) to normalise the stain of Source image
% 
%
% Input:
% Source         - RGB Source image.
% Target         - RGB Reference image.
% verbose        - (optional) Display results.
%                  (default 0)
%
%
% Output:
% Norm           - Normalised RGB Source image.
%
%
% References:
% [1] E Reinhard, M Adhikhmin, B Gooch, P Shirley. "Color transfer between 
%     images". IEEE Computer Graphics and Applications, vol.21 no.5, pp.
%     34-41, 2001.
%
% Copyright (c) 2013, Adnan Khan
% Department of Computer Science,
% University of Warwick, UK.
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    disp('masked Reinhard');

    % RGB to LAB colour space conversion for Source/Ref Image
    SourceLab = applycform(im2double(Source), makecform('srgb2lab'));

    % Means of Source image channels in Lab Colourspace
    ms = mean(reshape(SourceLab(cat(3, maskSource, maskSource, maskSource)), [], 3));

    % Standard deviations of Source image channels in Lab Colourspace
    stds = std(reshape(SourceLab(cat(3, maskSource, maskSource, maskSource)), [], 3));


    % RGB to LAB colour space conversion for Target Image
    TargetLab = applycform(im2double(Target), makecform('srgb2lab'));

    % Means of Target image channels in Lab Colourspace
    mt = mean(reshape(TargetLab(cat(3, maskTarget, maskTarget, maskTarget)), [], 3));

    % Standard deviations of Target image channels in Lab Colourspace
    stdt = std(reshape(TargetLab(cat(3, maskTarget, maskTarget, maskTarget)), [], 3));


    % Normalise each channel based on statistics of source and target images
    NormLab(:,:,1) = ((SourceLab(:,:,1)-ms(1))*(stdt(1)/stds(1)))+mt(1);
    NormLab(:,:,2) = ((SourceLab(:,:,2)-ms(2))*(stdt(2)/stds(2)))+mt(2);
    NormLab(:,:,3) = ((SourceLab(:,:,3)-ms(3))*(stdt(3)/stds(3)))+mt(3);

    % LAB to RGB conversion
    Norm = applycform(NormLab, makecform('lab2srgb'));

    % Display results if verbose mode is true
    
    disp('End masked Reinhard');

end

        

    


