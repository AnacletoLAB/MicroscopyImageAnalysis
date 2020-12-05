function structLearn=learnDT(ptsOn,ptsOff,factorUnbalancedTree, testD, testL)   
    Npos=size(ptsOn,1); Nneg=size(ptsOff,1);
    if nargin<3; factorUnbalancedTree=10; end
   
    indOn=randperm(Npos);
    indOff=randperm(Nneg);
    ptsOn=ptsOn(indOn,:);
    ptsOff=ptsOff(indOff,:);
    ptsOn=double(ptsOn);
    ptsOff=double(ptsOff);
    N=min(Npos,Nneg);

    ptsOnRules=ptsOn(1:min(N*factorUnbalancedTree,Npos),:);
    ptsOffRules=ptsOff(1:min(N*factorUnbalancedTree,Nneg),:);
    npos=size(ptsOnRules,1);
    nneg=size(ptsOffRules,1);
    respTree=[true(npos,1);false(nneg,1)];
    
    if nneg>5*npos %#ok<ALIGN>
        costTree= [0 1.0-(double(nneg)/double(npos+nneg)); ...
                1.0-(double(npos)/double(npos+nneg)) 0]; 
    else; costTree= [0 1; ...
                    1 0]; end
    
    dataTree=[ptsOnRules; ptsOffRules];
    Mdltree=fitctree(dataTree, respTree,'Cost',costTree,'OptimizeHyperparameters','all', ...
        'HyperparameterOptimizationOptions',struct('MaxObjectiveEvaluations',100));
    clear dataTree;
    
    dataTree=testD;
    labels=testL;
    structLearn.Mdltree=Mdltree;
    if numel(testD)>0
        Npos=sum(labels==1);
        Nneg=sum(labels==0);
        predicted=predict(Mdltree,dataTree);
        tp=double(sum(predicted==1 & labels==1));
        fp=double(sum(predicted==1 & labels==0));
        tn=double(sum(predicted==0 & labels==0));
        fn=double(sum(predicted==0 & labels==1));
        sens=tp/double(Npos);
        spec=tn/double(Nneg); 
        acc=(tp+tn)/double(Npos+Nneg);
        structLearn.tp=tp;
        structLearn.tn=tn;
        structLearn.fp=fp;
        structLearn.fn=fn;
        structLearn.sens=sens;
        structLearn.spec=spec;
        structLearn.acc=acc;
    end
end