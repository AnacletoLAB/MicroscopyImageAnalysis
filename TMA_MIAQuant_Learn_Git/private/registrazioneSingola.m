function RegStruct=registrazioneSingola(imgFixed,imgMoving,strMethod,factorRed, methodRed,val)
    if nargin<5; methodRed='nearest'; end
    if nargin<4; factorRed=1; end
    if nargin<3; strMethod='rigid'; end
    if isfinite(factorRed) && (factorRed ~=1) %#ok<ALIGN>
        imgT=imresize(imgFixed,factorRed,'Method',methodRed);   
        imgMove=imresize(imgMoving,factorRed,'Method',methodRed); 
    else imgT=imgFixed; imgMove=imgMoving; end
        
  
    optimizer = registration.optimizer.RegularStepGradientDescent;
    metric = registration.metric.MeanSquares;
    optimizer.MaximumIterations=300;   
    
    [moving,~,tform]= ...
             imregisterEle(uint8(imgMove),uint8(imgT),...
                        strMethod, optimizer,metric);
    if isfinite(factorRed) && (factorRed ~=1)
         T=tform.T;
         T(3,1:2)=T(3,1:2)*1/factorRed;
         tform.T=T;
    end
    RegStruct.moved=moving;
    RegStruct.tform=tform;
    RegStruct.RTemp=imref2d(size(imgFixed));
    RegStruct.RMove=imref2d(size(imgMoving));
    if isfinite(val)
         resStruct=kappa(confusionmat(moving(:)>0,imgT(:)>0));  
         resStruct2=kappa(confusionmat(moving(:)==val,imgT(:)==val)); 
%        resStruct.k=0; resStruct2.k=0;
        RegStruct.kappa=mean([resStruct.k;resStruct2.k]); clear resStruct resStruct2;
        RegStruct.corr=mean([corr2(moving,imgT);corr2(moving==val,imgT==val)]);
    end
end