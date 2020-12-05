function dataAnalisys24Feat(ptsOnVals,ptsOffVals, markerColor,dirSave)
    global slash
    numFeat=size(ptsOnVals,2);
    ptsOnCoded=ptsOnVals;
    ptsOffCoded=ptsOffVals;
    
    %% KNN che lavora sui colori nello spazio l*a*b*
%     disp([newline ...
%           '----------------------------------------' newline ...
%           'TRAINING KNN on all Training Data' newline ...
%           '----------------------------------------' newline]);
%     ptsOffKNN=ptsOffCoded(:,1:3);
%     ptsOnKNN=ptsOnCoded(:,1:3);    
%     npos=size(ptsOnKNN,1);
%     nneg=size(ptsOffKNN,1);
%     respKNN=[true(npos,1);false(nneg,1)];
%     MdlKNN=fitcknn([ptsOnKNN;ptsOffKNN],respKNN,'NumNeighbors',8);
%     save([dirSave slash 'MdlKNN_' markerColor '.mat'],'MdlKNN');
%     clear ptsOnKNN ptsOffKNN;

    %% albero di decisione che lavora con tutte le features
    testD=[ptsOnCoded; ptsOffCoded];
    testLab=[true(size(ptsOnCoded,1),1); 
                false( size(ptsOffCoded,1),1)];
    maxAcc=-1.0;
    On=ptsOnCoded;
    Off=ptsOffCoded;
    fUnbalanced=50;
    disp([newline ...
          '-------------------------------------------------------------' newline ...
          'TRAINING FIRST TREE on ptsOn + ptsOff for color ' markerColor newline ...
          '-------------------------------------------------------------' newline]);
    disp('Number of features')
    disp(size(ptsOnCoded,2));
    numIter=min(ceil(...
        double(max(size(Off,1)/size(ptsOnCoded,1), ...
        size(ptsOnCoded,1)/size(Off,1)))/double(fUnbalanced)),10);
    for i=1:numIter
        structLearn=learnDT(On,Off,fUnbalanced, testD, testLab, 7);
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
    save([dirSave slash 'Mdltree_' markerColor '.mat'],'Mdltree');
    view(Mdltree,'Mode','graph');
    clear On Off;
    
    
   %% classifico con l'albero di decisione i punti Off
   %% e tengo solo quelli che vengono giudicati sbagliati
%     ptsOffInit=ptsOffCoded;
%     predicted=predict(Mdltree,ptsOffInit); 
%     ptsOffSel= ptsOffInit(predicted,:);
%     ptsOnSel=ptsOnCoded;
%     if size(ptsOnSel,1)>size(ptsOffSel,1)
%         ptsOffAdd=ptsOffInit(~predicted,:); clear ptsOffInit;
%         ptsOffAdd=ptsOffAdd(randperm(size(ptsOffAdd,1)),:);
%         ptsOffSel=[ptsOffSel; ptsOffAdd(1:min(size(ptsOffAdd,1),...
%             size(ptsOnSel,1)-size(ptsOffSel,1)),:)];
%         clear ptsOffAdd;
%     end
%     clear predicted;  
%     

%     ptsOnSel=ptsOnCoded;
%     ptsOffSel=ptsOffCoded;
%     
%     startF=1; endF=12;
%     ptsOnSVM=ptsOnSel(:,startF:endF );
%     ptsOffSVM=ptsOffSel(:,startF:endF);
%     %% faccio il training delle SVM prendendo i punti ON e quelli giudicati 
%     %% male dall'albero di decisione
%     disp([newline ...
%       '----------------------------------------' newline ...
%       'TRAINING SVM on ptsOn + not-discarded ptsOff' newline ...
%       '----------------------------------------' newline]);
%     structLearn=learnSVM(ptsOnSVM,ptsOffSVM,100, testD(:,startF:endF), testLab);
%     close all;
%     Mdlsvm=structLearn.Mdlsvm;
%     disp(['Perf - sens=' num2str(structLearn.sens) ', spec=' num2str(structLearn.spec)...
%                 ', acc=' num2str(structLearn.acc) newline ...
%         '----------------------------------------------------------' newline]);
%     clear structLearn;    
%     save([dirSave slash 'Mdlsvm_' markerColor '.mat'],'Mdlsvm');
%     clear ptsOnSVM ptsOffSVM Mdlsvm;
        
        
end
    
