 
function OUT=progressive(I, ratio)
     % h1 = LowThreshold
     % h2 = highThreshold
    ratio = double(ratio);
    if ratio < 1; ratio = 1/ratio; end
    h1 = double(max(I(:))/ratio);
    h2 = double(max(I(:))*3/ratio);
    disp(['Progressive with thresholds:', num2str(h1), num2str(h2)]);

    imap = (double(I(:,:,1))+double(I(:,:,2))+double(I(:,:,3)))/3;
    R=I(:,:,1); G=I(:,:,2); B=I(:,:,3);

    Kr = zeros(size(imap));
    Kg = zeros(size(imap));
    Kb = zeros(size(imap));

    Kr( imap>=h1 )=255/mean(R(R>=h1));
    Kg( imap>=h1 )=255/mean(G(G>=h1));
    Kb( imap>=h1 )=255/mean(B(B>=h1));

    [m,n,~]=size(I);
    Rmean = sum(sum(R))/(m*n);
    Gmean = sum(sum(G))/(m*n);
    Bmean = sum(sum(B))/(m*n);
    Avg = mean([Rmean Gmean Bmean]);

    Kr( imap<=h2 ) = Avg/Rmean;
    Kg( imap<=h2 ) = Avg/Gmean;
    Kb( imap<=h2 ) = Avg/Bmean;

    deltha = imap/(h1-h2)-h2/(h1-h2);
    Kr( imap>=h2 & imap<=h1 ) = (1-deltha(imap>=h2 & imap<=h1))*...
        255/mean(R(R>=h1)) + deltha(imap>=h2 & imap<=h1)*255/mean(R(R>=h1));
    Kg( imap>=h2 & imap<=h1 ) = (1-deltha(imap>=h2 & imap<=h1))*...
        255/mean(G(G>=h1)) + deltha(imap>=h2 & imap<=h1)*255/mean(G(G>=h1));
    Kb( imap>=h2 & imap<=h1 ) = (1-deltha(imap>=h2 & imap<=h1))*...
        255/mean(B(B>=h1)) + deltha(imap>=h2 & imap<=h1)*255/mean(B(B>=h1));
    OUT(:,:,1) = Kr.*double(I(:,:,1));
    OUT(:,:,2) = Kg.*double(I(:,:,2));
    OUT(:,:,3) = Kb.*double(I(:,:,3));
    OUT = uint8(OUT);              
end
