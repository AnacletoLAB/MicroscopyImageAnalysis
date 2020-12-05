function strPoly= pointsInPoly(imgS, figTitle,msg)
    global handles
    global FigPosition magFactor optMsg msgPosition
    
    X=[]; Y=[]; areas=[];
    st=strel('disk', 5);
    fig=figure('units','normalized','outerposition', FigPosition);
    
    fig.Name = figTitle;
    
    hold on; imshow(imgS,'InitialMagnification',magFactor);
    if numel(msg)>0
        handles{end+1}=msgbox(msg, 'Title','none',optMsg);
        h=handles{end}; h.Position(1:2)=msgPosition;
    end
    removeDialogs();
    szY = size(imgS,1);
    szX = size(imgS,2);
    imgShape=false(szY,szX);
    allShapes=false(szY,szX);
    
    while true
       [XX,YY]=getline(fig, 'closed'); 
       if (numel(XX)<2) 
           strPoly.points=[X,Y];
           strPoly.areas=areas;
           strPoly.allShapes=allShapes;
           clear imgShape; 
           close all;
           return; 
       else
           imgShape(:)=false;
           if numel(X)==2
               [Xn,Yn]=getpts(fig); close(fig);
           else
               XX=round(XX); YY=round(YY);
               
               for j=1:size(XX,1)-1
                   imgShape=imgShape | drawLine(imgShape,XX(j,1),YY(j,1),XX(j+1,1),YY(j+1,1));
               end
               imgShape=imgShape | drawLine(imgShape,XX(1,1),YY(1,1),XX(end,1),YY(end,1));
               
               if any(XX<1 | YY<1 | XX>size(imgS,2) | YY>size(imgS,1))
                    XX(XX<1)=1; YY(YY<1)=1; 
                    XX(XX>size(imgS,2))=size(imgS,2); 
                    YY(YY>size(imgS,1))=size(imgS,1); 
                    for j=1:size(XX,1)-1
                        imgShape=imgShape | drawLine(imgShape,XX(j,1),YY(j,1),XX(j+1,1),YY(j+1,1));
                    end
                    imgShape=imgShape | drawLine(imgShape,XX(1,1),YY(1,1),XX(end,1),YY(end,1));
               end
               
               imgShape=imclose(imgShape,st);
               for nC=1:size(imgS,3) 
                   ii=imgS(:,:,nC);
                   ii(imgShape)=255;
                   imgS(:,:,nC)=ii; clear ii;
               end
               fig.WindowState='maximize';  
               imshow(imgS,'InitialMagnification',magFactor);
               imgShape=imfill(imgShape,'holes');
               [Yn, Xn]= find(imgShape);
               areas=[areas; numel(Xn)]; %#ok<AGROW>
               allShapes = allShapes | imgShape;
           end
           Y=[Y;Yn]; X=[X;Xn]; clear Xn Yn;
           
       end 
    end    
    
end