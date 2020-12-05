function dist=KLDiv(P,Q)
%  dist = KLDiv(P,Q) Kullback-Leibler divergence of two discrete probability
%  distributions
    Paux=P(:); Qaux=Q(:);
    minV=min([min(Paux(Paux>0)),min(Qaux(Qaux>0)),10^(-20)]);
    Q(Q==0)=minV;
    P(P==0)=minV; clear Paux Qaux minV;
    
    Q = Q /sum(Q(:));
    P = P /sum(P(:));
    temp =  P.*log(P./Q);
    temp(isnan(temp))=0; % resolving the case when P(i)==0
    temp(isinf(temp))=max(temp(:));
    dist = sum(temp(:));
end


