function OUT = ace(I,W, distFunc, alpha, rFunc, slope, scalingMethod)
   % I =input Img, W = neighborhood size
    % distFunc = 'E' (Euclidean), 'I' (inverse Exponential), 'M' (Manhattan), 'X' (Max), I 
    % (Inverse Ecuclidean =exp(alpha*Euclidean))
    % rFunc = 'G' (Sign), 'L' (linear), 'S' (sloping con slope = alpha)
    % slope = 'L' (Linear), 'G' (GrayWorld\white Patches)
    disp('ace');
    [m,n,~]=size(I);
    MR = zeros(m,n);
    MG = zeros(m,n);
    MB = zeros(m,n);
    RC = zeros(m,n,3);
    [Y,X]=meshgrid(1:n,1:m);
    for i=1:m
       for j=1:n
           if strcmpi(distFunc,'E') % Euclidean
               MD = sqrt(((X-X(i,j)).^2)+((Y-Y(i,j)).^2));
           elseif strcmpi(distFunc,'I') %InverseExponential
               MD = exp(alpha*(sqrt(((X-X(i,j)).^2)+((Y-Y(i,j)).^2))));
           elseif strcmpi(distFunc,'M') %'Manhattan'
               MD = sqrt(X-X(i,j))+(Y-Y(i,j));
           elseif strcmpi(distFunc,'X') % Max distance
               MD = max(X-X(i,j),Y-Y(i,j));
           end
           if strcmpi(rFunc,'G') %sign
               MR(MD<=W & MD~=0)=sign(double(I(i,j,1))-double(I(MD<=W & MD~=0)));
               MG(MD<=W & MD~=0)=sign(double(I(i,j,2))-double(I(MD<=W & MD~=0)));
               MB(MD<=W & MD~=0)=sign(double(I(i,j,3))-double(I(MD<=W & MD~=0)));
           elseif strcmpi(rFunc,'L') % Linear
               MR(MD<=W & MD~=0)=double(I(i,j,1))-double(I(MD<=W & MD~=0));
               MG(MD<=W & MD~=0)=double(I(i,j,2))-double(I(MD<=W & MD~=0));
               MB(MD<=W & MD~=0)=double(I(i,j,3))-double(I(MD<=W & MD~=0));
           elseif strcmpi(rFunc,'S') % sloping
               MR(MD<=W & MD~=0)=slope*(double(I(i,j,1))-double(I(MD<=W & MD~=0)));
               MG(MD<=W & MD~=0)=slope*(double(I(i,j,2))-double(I(MD<=W & MD~=0)));
               MB(MD<=W & MD~=0)=slope*(double(I(i,j,3))-double(I(MD<=W & MD~=0)));    
           end
           T = zeros(size(m,n));
           T(MD<=W & MD~=0)= MR(MD<=W & MD~=0)./MD(MD<=W & MD~=0);
           RC(i,j,1)=sum(sum(T));

           T = zeros(size(m,n));
           T(MD<=W & MD~=0)= MG(MD<=W & MD~=0)./MD(MD<=W & MD~=0);
           RC(i,j,2)=sum(sum(T));

           T = zeros(size(m,n));
           T(MD<=W & MD~=0)= MB(MD<=W & MD~=0)./MD(MD<=W & MD~=0);
           RC(i,j,3)=sum(sum(T));                   
       end
    end
    %STEP 2
    mc = min(min(min(RC)));
    Mc = max(max(max(RC)));
    s = (255-Mc)/(-mc);
    if strcmpi(scalingMethod,'L') % linear
        OUT = uint8((RC-mc)*255/(Mc-mc));
    elseif strcmpi(scalingMethod,'G') % GrayWorld
        OUT = uint8(round(127.5+RC*(127.5/Mc)));
    end

end
