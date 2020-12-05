function dataAnalisys24Feat(ptsOnVals,ptsOffVals,ptsCriticalOffVals, markerColor,dirSave, slash)
    
    if nargin<5; dirSave=['.' slash 'TrainedClassifiers']; end
    st=strel('disk',3);
    stBig=strel('disk',7);
    testD=[ptsOnVals; ptsOffVals; ...
                        ptsCriticalOffVals];
    testLab=[true(size(ptsOnVals,1),1); 
                false( size(ptsOffVals,1)+size(ptsCriticalOffVals,1),1)];
    
    strClassDef = 'Markers';
    numFeat=size(ptsOnVals,2);
    ptsOnCoded=ptsOnVals;
    ptsOffCoded=ptsOffVals;
    ptsCriticalOffCoded=ptsCriticalOffVals;
    
    
    %% learn KNN to select Marker against 
    %% Critical Not Markers based on THREE RGB features 
    disp([newline ...
          '----------------------------------------' newline ...
          'TRAINING KNN on all Training Data' newline ...
          '----------------------------------------' newline]);
    ptsOffKNN=[ptsCriticalOffCoded(:,1:3); ptsOffCoded(:,1:3)];
    ptsOnKNN=ptsOnCoded(:,1:3);    
    npos=size(ptsOnKNN,1);
    nneg=size(ptsOffKNN,1);
    respKNN=[true(npos,1);false(nneg,1)];
    MdlKNN=fitcknn([ptsOnKNN;ptsOffKNN],respKNN,'NumNeighbors',8);
    save([dirSave slash 'MdlKNN' num2str(numFeat) '_' strClassDef '_' markerColor '.mat'],'MdlKNN');
    clear ptsOnKNN ptsOffKNN;

    testD=[ptsOnCoded; ptsOffCoded; ...
                        ptsCriticalOffCoded];
    testLab=[true(size(ptsOnCoded,1),1); 
                false( size(ptsOffCoded,1)+size(ptsCriticalOffCoded,1),1)];
            
    maxAcc=-1.0;
    On=ptsOnCoded;
    Off=ptsOffCoded;
    fUnbalanced=50;
    disp([newline ...
          '----------------------------------------' newline ...
          'TRAINING FIRST TREE on ptsOn + ptsOff' newline ...
          '----------------------------------------' newline]);
    numIter=min(ceil(...
        double(max(size(Off,1)/size(ptsOnCoded,1), ...
        size(ptsOnCoded,1)/size(Off,1)))/double(fUnbalanced)),10);
    for i=1:numIter
        structLearn=learnDT(On,Off,fUnbalanced, testD, testLab);
        disp(['estimated sensitivity=' num2str(structLearn.sens) newline... 
            'estimated specificity=' num2str(structLearn.spec) newline ...
            'estimated accuracy=' num2str(structLearn.acc)]);
        close all;
        if (structLearn.acc>maxAcc)
            Mdltree=structLearn.Mdltree;
            maxAcc=structLearn.acc;
            disp(['estimated MAX accuracy=' num2str(structLearn.acc) newline... 
            'estimated specificity with MAX sens=' num2str(structLearn.spec) newline ...
            'estimated sensitivity with MAX acc=' num2str(structLearn.sens) newline ...
            '----------------------------------------------------------------' newline]);
        end
        clear structLearn;
    end
    save([dirSave slash 'Mdltree' num2str(numFeat) '_' strClassDef '_' markerColor '.mat'],'Mdltree');
    view(Mdltree,'Mode','graph');
    clear On Off;
    
    % rivaluto solo gli obvious
    strClassDef = 'CriticalMarkers';
    predicted=predict(Mdltree,ptsOffCoded); 
    clear Mdltree;
    ptsOnCritical=ptsOnCoded;
    % visto che ptsOffcoded contiene anche i critical che voglio tenere
    % scarto solo gli errori tra i primi NNEG
    ptsOffCritical=[ptsOffCoded(predicted,:); ptsCriticalOffCoded];  
    if size(ptsOnCritical,1)>size(ptsOffCritical,1)
        ptsOffAdd=ptsOffCoded(~predicted,:);
        ptsOffAdd=ptsOffAdd(randperm(size(ptsOffAdd,1)),:);
        ptsOffCritical=[ptsOffCritical; ptsOffAdd(1:min(size(ptsOffAdd,1),...
            size(ptsOnCritical,1)-size(ptsOffCritical,1)),:)];
        clear ptsOffAdd;
    end
    clear predicted;
    disp([newline ...
          '----------------------------------------' newline ...
          'TRAINING SECOND TREE on ptsOn + ptsCriticalOff+ not-discarded ptsOff' newline ...
          '----------------------------------------' newline]);
    %% learn Trees to select Marker against wrongly classified not-markers +
    %% Critical Not Markers based on six features 
    maxAcc=-1.0;
    fUnbalanced=50;
    numIter=ceil(...
        double(max(size(ptsOffCritical,1)/size(ptsOnCritical,1), ...
        size(ptsOnCritical,1)/size(ptsOffCritical,1)))/double(fUnbalanced));
    if numIter>1; numIter=round(numIter*1.5); end
    for i=1:numIter
        structLearn=learnDT(ptsOnCritical,ptsOffCritical,fUnbalanced,testD,testLab);
        disp(['estimated sensitivity=' num2str(structLearn.sens) newline... 
            'estimated specificity=' num2str(structLearn.spec) newline ...
            'estimated accuracy=' num2str(structLearn.acc)]);
        close all;
        if (structLearn.acc>maxAcc)
            Mdltree=structLearn.Mdltree;
            maxAcc=structLearn.acc;
            disp(['estimated MAX accuracy=' num2str(structLearn.acc) newline... 
            'estimated specificity with MAX sens=' num2str(structLearn.spec) newline ...
            'estimated sensitivity with MAX acc=' num2str(structLearn.sens)  newline ...
            '----------------------------------------------------------------' newline]);
        end
        clear structLearn;
    end
    save([dirSave slash 'Mdltree' num2str(numFeat) '_' strClassDef '_' markerColor '.mat'],'Mdltree');
    view(Mdltree,'Mode','graph'); 
    clear ptsOnCritical ptsOffCritical;
    
    ptsOffInit=[ptsOffCoded; ptsCriticalOffCoded];
    predicted=predict(Mdltree,ptsOffInit); clear MdltreeColDiv;
    ptsOffSel= ptsOffInit(predicted,:);
    ptsOnSel=ptsOnCoded;
    if size(ptsOnSel,1)>size(ptsOffSel,1)
        ptsOffAdd=ptsOffInit(~predicted,:); clear ptsOffInit;
        ptsOffAdd=ptsOffAdd(randperm(size(ptsOffAdd,1)),:);
        ptsOffSel=[ptsOffSel; ptsOffAdd(1:min(size(ptsOffAdd,1),...
            size(ptsOnSel,1)-size(ptsOffSel,1)),:)];
        clear ptsOffAdd;
    end
    clear predicted;  
    
    startF=1; endF=numFeat;
        ptsOnSVM=ptsOnSel(:,startF:endF);
        ptsOffSVM=ptsOffSel(:,startF:endF);
        %% learn SVM COLOR to select Marker against wrongly classified not-markers +
        %% Critical Not Markers based on THREE RGB features 
       disp([newline ...
          '----------------------------------------' newline ...
          'TRAINING SVM on ptsOn + not-discarded (ptsCriticalOff+ptsOff)' newline ...
          '----------------------------------------' newline]);
        structLearn=learnSVM(ptsOnSVM,ptsOffSVM,100, testD(:,startF:endF), testLab);
        close all;
        Mdlsvm=structLearn.Mdlsvm;
        disp(['Perf - sens=' num2str(structLearn.sens) ', spec=' num2str(structLearn.spec)...
                    ', acc=' num2str(structLearn.acc) newline ...
            '----------------------------------------------------------' newline]);
        clear structLearn;    
        save([dirSave slash 'Mdlsvm' num2str(startF) '-' num2str(endF) '_' strClassDef '_' markerColor '.mat'],'Mdlsvm');
        clear ptsOnSVM ptsOffSVM Mdlsvm;
        
        
end
    
