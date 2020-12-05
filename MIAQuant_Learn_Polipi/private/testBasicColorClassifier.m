function testBasicColorClassifier(Mdltree,testTree,labels)
    testTree=double(testTree);
    if size(testTree,1)>0
        testTree=[testTree testTree(:,1)./testTree(:,2) testTree(:,1)./testTree(:,3) testTree(:,2)./testTree(:,3)];
        Npos=sum(labels==1);
        Nneg=sum(labels==0);
        predicted=predict(Mdltree,testTree);
        tp=double(sum(predicted==1 & labels==1));
        fp=double(sum(predicted==1 & labels==0));
        tn=double(sum(predicted==0 & labels==0));
        fn=double(sum(predicted==0 & labels==1));
        sens=tp/double(Npos);
        spec=tn/double(Nneg); 
        acc=(tp+tn)/double(tp+fp+tn+fn);
        clear mdl tp fp tn fn predicted;
        disp([...
        '______________________________________________' newline ...
        'evaluation of basic color classifier on training data' newline ...
        'estimated sensitivity on training data=' num2str(sens) newline... 
        'estimated specificity on training data=' num2str(spec) newline ...
        'estimated accuracy on training data=' num2str(acc) newline ...
        '______________________________________________' newline ]);
    end

end