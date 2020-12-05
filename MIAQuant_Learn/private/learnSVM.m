function structLearn=learnSVM(ptsOn,ptsOff,factorUnbalanced, testD, testL)   
    Npos=size(ptsOn,1); Nneg=size(ptsOff,1);
    if nargin<3; factorUnbalanced=50; end
    paramOpti='auto' ;
    ptsOn(ptsOn==0)=1;
    ptsOff(ptsOff==0)=1;
    indOn=randperm(Npos);
    indOff=randperm(Nneg);
    ptsOn=ptsOn(indOn,:);
    ptsOff=ptsOff(indOff,:);
    ptsOn=double(ptsOn);
    ptsOff=double(ptsOff);
    N=min(Npos,Nneg);

    ptsOnSVM=ptsOn(1:min(N*factorUnbalanced,Npos),:);
    ptsOffSVM=ptsOff(1:min(N*factorUnbalanced,Nneg),:);
    npos=size(ptsOnSVM,1);
    nneg=size(ptsOffSVM,1);
    respSVM=[true(npos,1);false(nneg,1)];
%    costSVM= [0 1; 1 0]; 
     costSVM= [0 1.0-(double(nneg)/double(npos+nneg)); ...
             1.0-(double(npos)/double(npos+nneg)) 0]; 
     
    dataSVM=[ptsOnSVM; ptsOffSVM];
    
    Mdlsvm=fitcsvm(dataSVM,respSVM,'KernelFunction','rbf',...
        'cost', costSVM,'Standardize',true,'OptimizeHyperparameters',paramOpti);
    
    %disp(Mdlsvm)
    clear dataSVM;
    
    dataSVM=testD;
    labels=testL; 
    Npos=sum(labels==1);
    Nneg=sum(labels==0);
    predicted=predict(Mdlsvm,dataSVM);
    tp=double(sum(predicted==1 & labels==1));
    fp=double(sum(predicted==1 & labels==0));
    tn=double(sum(predicted==0 & labels==0));
    fn=double(sum(predicted==0 & labels==1));
    sens=tp/double(Npos);
    spec=tn/double(Nneg); 
    acc=(tp+tn)/double(Npos+Nneg);
    structLearn.Mdlsvm=Mdlsvm;
    structLearn.tp=tp;
    structLearn.tn=tn;
    structLearn.fp=fp;
    structLearn.fn=fn;
    structLearn.sens=sens;
    structLearn.spec=spec;
    structLearn.acc=acc;
end