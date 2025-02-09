function structR=kappa(varargin)
% KAPPA: This function computes the Cohen's kappa coefficient.
% Cohen's kappa coefficient is a statistical measure of inter-rater
% reliability. It is generally thought to be a more robust measure than
% simple percent agreement calculation since k takes into account the
% agreement occurring by chance.
% Kappa provides a measure of the degree to which two judges, A and B,
% concur in their respective sortings of N items into k mutually exclusive
% categories. A 'judge' in this context can be an individual human being, a
% set of individuals who sort the N items collectively, or some non-human
% agency, such as a computer program or diagnostic test, that performs a
% sorting on the basis of specified criteria.
% The original and simplest version of kappa is the unweighted kappa
% coefficient introduced by J. Cohen in 1960. When the categories are
% merely nominal, Cohen's simple unweighted coefficient is the only form of
% kappa that can meaningfully be used. If the categories are ordinal and if
% it is the case that category 2 represents more of something than category
% 1, that category 3 represents more of that same something than category
% 2, and so on, then it is potentially meaningful to take this into
% account, weighting each cell of the matrix in accordance with how near it
% is to the cell in that row that includes the absolutely concordant items.
% This function can compute a linear weights or a quadratic weights.
%
% Syntax: 	kappa(X,W,ALPHA)
%      
%     Inputs:
%           X - square data matrix
%           W - Weight (0 = unweighted; 1 = linear weighted; 2 = quadratic
%           weighted; -1 = display all. Default=0)
%           ALPHA - default=0.05.
%
%     Outputs:
%           - Observed agreement percentage
%           - Random agreement percentage
%           - Agreement percentage due to true concordance
%           - Residual not random agreement percentage
%           - Cohen's kappa 
%           - kappa error
%           - kappa confidence interval
%           - Maximum possible kappa
%           - k observed as proportion of maximum possible
%           - k benchmarks by Landis and Koch 
%           - z test results
%
%      Example: 
%
%           x=[88 14 18; 10 40 10; 2 6 12];
%
%           Calling on Matlab the function: kappa(x)
%
%           Answer is:
%
% UNWEIGHTED COHEN'S KAPPA
% --------------------------------------------------------------------------------
% Observed agreement (po) = 0.7000
% Random agreement (pe) = 0.4100
% Agreement due to true concordance (po-pe) = 0.2900
% Residual not random agreement (1-pe) = 0.5900
% Cohen's kappa = 0.4915
% kappa error = 0.0549
% kappa C.I. (alpha = 0.0500) = 0.3839     0.5992
% Maximum possible kappa, given the observed marginal frequencies = 0.8305
% k observed as proportion of maximum possible = 0.5918
% Moderate agreement
% Variance = 0.0031     z (k/sqrt(var)) = 8.8347    p = 0.0000
% Reject null hypotesis: observed agreement is not accidental
%
%           Created by Giuseppe Cardillo
%           giuseppe.cardillo-edta@poste.it
%
% To cite this file, this would be an appropriate format:
% Cardillo G. (2007) Cohens kappa: compute the Cohen's kappa ratio on a 2x2 matrix.   
% http://www.mathworks.com/matlabcentral/fileexchange/15365



%Input Error handling
global m f x w alpha

args=cell(varargin);
nu=numel(args);
if isempty(nu)
    error('Warning: Matrix of data is missed...')
elseif nu>4
    error('Warning: Max three input data are required')
end
default.values = {[],0,0.05};
if (nu==1); default.values(1) = args; display=1;
else default.values(1:nu-1) = args(1:nu-1); display=args{nu}; end

[x w alpha] = deal(default.values{:});

if isempty(x)
    error('Warning: X matrix is empty...')
end
if isvector(x)
    error('Warning: X must be a matrix not a vector')
end
if ~all(isfinite(x(:))) || ~all(isnumeric(x(:)))
    error('Warning: all X values must be numeric and finite')
end   
if ~isequal(x(:),round(x(:)))
    error('Warning: X data matrix values must be whole numbers')
end

m=size(x);
if ~isequal(m(1),m(2))
    error('Input matrix must be a square matrix')
end
if nu>1 %eventually check weight
    if ~isscalar(w) || ~isfinite(w) || ~isnumeric(w) || isempty(w)
        error('Warning: it is required a scalar, numeric and finite Weight value.')
    end
    a=-1:1:2;
    if isempty(a(a==w))%check if w is -1 0 1 or 2
        error('Warning: Weight must be -1 0 1 or 2.')
    end
end
if nu>2 %eventually check alpha
    if ~isscalar(alpha) || ~isnumeric(alpha) || ~isfinite(alpha) || isempty(alpha)
        error('Warning: it is required a numeric, finite and scalar ALPHA value.');
    end
    if alpha <= 0 || alpha >= 1 %check if alpha is between 0 and 1
        error('Warning: ALPHA must be comprised between 0 and 1.')
    end
end
clear args default nu

m(2)=[]; 
tr=repmat('-',1,80);
if w==0 || w==-1
    f=diag(ones(1,m)); %unweighted
    %disp('UNWEIGHTED COHEN''S KAPPA')
    %disp(tr)
    structR=kcomp(display);
    %disp(' ')
end
if w==1 || w==-1
    J=repmat((1:1:m),m,1);
    I=flipud(rot90(J));
    f=1-abs(I-J)./(m-1); %linear weight
    %disp('LINEAR WEIGHTED COHEN''S KAPPA')
    %disp(tr)
    structR=kcomp(display);
    %disp(' ')
end
if w==2 || w==-1
    J=repmat((1:1:m),m,1);
    I=flipud(rot90(J));
    f=1-((I-J)./(m-1)).^2; %quadratic weight
    %disp('QUADRATIC WEIGHTED COHEN''S KAPPA')
    %disp(tr)
    structR=kcomp(display);
end
return
end

function structRes=kcomp(display)
global m f x alpha
n=sum(x(:)); %Sum of Matrix elements
x=x./n; %proportion
r=sum(x,2); %rows sum
s=sum(x); %columns sum
Ex=r*s; %expected proportion for random agree
pom=sum(min([r';s]));
po=sum(sum(x.*f));
pe=sum(sum(Ex.*f));
k=(po-pe)/(1-pe);
km=(pom-pe)/(1-pe); %maximum possible kappa, given the observed marginal frequencies
ratio=k/km; %observed as proportion of maximum possible
sek=sqrt((po*(1-po))/(n*(1-pe)^2)); %kappa standard error for confidence interval
ci=k+([-1 1].*(abs(-realsqrt(2)*erfcinv(alpha))*sek)); %k confidence interval
wbari=r'*f;
wbarj=s*f;
wbar=repmat(wbari',1,m)+repmat(wbarj,m,1);
a=Ex.*((f-wbar).^2);
var=(sum(a(:))-pe^2)/(n*((1-pe)^2)); %variance
z=k/sqrt(var); %normalized kappa
p=(1-0.5*erfc(-abs(z)/realsqrt(2)))*2;
%display results
% ARROTONDAMENTO ALLA SECONDA CIFRA DECIMALE!!!
k=(round(k*100))/100;
ci=(round(ci*100))/100;
strAgreement='';
if(display==1)
%        fprintf('k =%0.4f (error=%0.4f)\n',k,sek)
%    fprintf('k = Agreement for true concordance(po-pe)/Residual not random agreement(1-pe) = %0.4f (error=%0.4f)\n',k,sek)
%     fprintf('Observed agreement (po) = %0.4f\n',po)
%     fprintf('Random agreement (pe) = %0.4f\n',pe)
%    fprintf('Agreement due to true concordance (po-pe) = %0.4f\n',po-pe)
%    fprintf('Residual not random agreement (1-pe) = %0.4f\n',1-pe)
 %   fprintf('kappa error = %0.4f\n',sek)
%     fprintf('kappa C.I. (alpha = %0.4f) = %0.4f     %0.4f\n',alpha,ci)
%     fprintf('km = Maximum possible kappa, given the observed marginal frequencies = %0.4f\n',km)
%     fprintf('k/km = k observed as proportion of maximum possible = %0.4f\n',ratio)
    
    if k<=0
        strAgreement='Poor ag.';
    elseif k>0 && k<=0.2
        strAgreement='Slight ag.';
    elseif k>0.2 && k<=0.4
        strAgreement='Fair ag.';
    elseif k>0.4 && k<=0.6
        strAgreement='Moderate ag.';
    elseif k>0.6 && k<=0.8
        strAgreement='Substantial ag.';
    elseif k>0.8 && k<=1
        strAgreement='Perfect ag.';
    end
%    fprintf('Variance = %0.4f     z (k/sqrt(var)) = %0.4f    p = %0.4f\n',var,z,p)
    if p<0.05
        strAgreement=[strAgreement ' NOT ACC.'];
        %disp('Reject null hypotesis: observed agreement is not accidental')
    else
        strAgreement=[strAgreement ' ACC.'];
        %disp('Accept null hypotesis: observed agreement is accidental')
    end
   % disp(strAgreement);
end
structRes.k=k;
structRes.ci=ci;
structRes.km=km;
structRes.p=p;
structRes.description=strAgreement;

return
end