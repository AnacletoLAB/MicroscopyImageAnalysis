function [cells, ok] = analizeAttachedRegs(cells, ok, areaDet, factorComp, thrEcc, ...
                                thrEquivDiam,factorMinArea,factorMaxArea, conn)
    
    
    if nargin< 10; conn = 4; end
    if nargin< 8; factorMaxArea = 0.75; end
    if nargin< 7; factorMinArea = 1; end
    if nargin< 6; thrEquivDiam = 0.2; end
    if nargin< 5; thrEcc = 0.9; end
    if nargin< 4; factorComp = 2; end
    
    st1 = strel('disk',1);
    okDil = imdilate(ok>0,st1);
    % prendo le regioni in cells che toccano quelle in ok
    [Y, X] = find(okDil);
    cTouch = bwselect(cells,X,Y);
    cellsTouch = bwareaopen(imopen(cTouch,st1), round(areaDet.minArea/2)); 
    cells(cTouch) = false;
    if any(cellsTouch(:))
        cells = cells | cellsTouch;
        %Seleziono le regioni belle circolari 
        [cellsTouch, ok] =  analizeRegs(cellsTouch, ok, areaDet, factorComp, thrEcc, ...
                                        thrEquivDiam, factorMinArea, factorMaxArea); 
        if any(cellsTouch(:))
            cc = bwconncomp(cellsTouch,conn); 
            labs = labelmatrix(cc);
            stats = regionprops(cc,'Area','Perimeter','ConvexArea','PixelList',...
                                    'MinorAxisLength', 'MajorAxisLength','Image');

            for nR = 1: numel(stats)
               % disp(nR)
                Rtouch = (labs == nR);
                distR = bwdist(bwskel(stats(nR).Image));
                maxR = max(distR(bwperim(stats(nR).Image)));
                minR = min(distR(bwperim(stats(nR).Image)));

                if ((stats(nR).Area<areaDet.maxArea*factorMaxArea && ...
                        (stats(nR).Area/stats(nR).ConvexArea<0.7)) || ...
                        ((stats(nR).Area<areaDet.medianArea && maxR < areaDet.minRad)) || ...
                        stats(nR).Area<areaDet.minArea*factorMinArea) 
                    % se è minore dell'area massima ed è molto concava
                    % o se è minore della medianArea e è molto stretta
                    % o se è più piccola di minArea*factorMinArea la
                    % considero
                    rOk = imerode(bwselect(okDil>0, stats(nR).PixelList(:,1), stats(nR).PixelList(:,2)),st1);
                    rOk = double(rOk).*ok; % prendo quelle non dilatate!
                    if ((max(max(rOk(rOk>0)))-min(min(rOk(rOk>0)))) == 0) 
                        % se è attaccata a una sola regione devo capire
                        % cosa fare: se attaccarla o no. Lo faccio in base
                        % a quanto interseca e quanto è concava
                        valInter = sum(sum(double(Rtouch & okDil)))/double(stats(nR).Perimeter);    
                        newArea = sum(sum(double(rOk>0 | Rtouch)));
                        if  (newArea<areaDet.maxArea*factorMaxArea) && ...
                             (minR/maxR<0.5) && ...
                                stats(nR).MinorAxisLength/stats(nR).MajorAxisLength<0.5 && ...
                                sum(sum(uint8(rOk>0 | Rtouch)))<areaDet.maxArea && ...
                            (stats(nR).Area < (areaDet.minArea*factorMinArea) || valInter>0.35)
                        % se la regione bella concava è attaccata a una sola
                        % regione, la includo in quella se la loro somma non da
                        % un'area troppo grossa allora la attacco
                            ok(rOk>0 | Rtouch) = max(max(ok(rOk>0)));
                            cells(rOk>0 | Rtouch) = false;
                        else
                            ok(Rtouch) = max(ok(:)) + 1;
                            cells(Rtouch) = false;
                        end
                    else
                        % se si attacca a più regioni ed è molto concava 
                        % allora la splitto in base alla
                        % distanza
                        if (stats(nR).Area/stats(nR).ConvexArea<0.6) || (minR/maxR<0.2)
                            rOk = divideOnDist(rOk, bwdist(rOk>0).*double(Rtouch));
                            cells(rOk>0 | Rtouch) = false;
                            ok(rOk>0 | Rtouch) = rOk(rOk>0 | Rtouch);
                        else
                            ok(Rtouch) = max(ok(:)) + 1;
                            cells(Rtouch) = false;
                        end
        %                 isRound = [];  valsRound = [];
        %                 isIntersect = [];  valsIntersect = [];
        %                 for i = 1:max(labsInter(:))
        %                     areaIntersect = double(sum(sum(uint8((labsInter==i) & Rtouch))));
        %                     reg = (labsInter==i | Rtouch);
        %                     if sum(uint8(reg(:)))< areaDet.maxArea
        %                         if ((double(stats(nR).Perimeter)/areaIntersect)<0.5 && ...
        %                                 (stats(nR).Area/stats(nR).ConvexArea)<0.4 && ...
        %                                 (stats(nR).Perimeter/stats(nR).Area)<factorComp && ...
        %                                         stats(nR).Area< thrArea)
        %                             isIntersect = [isIntersect i];
        %                             valsIntersect =[valsIntersect (double(stats(nR).Perimeter)/areaIntersect)];
        %                         end 
        % 
        %                         [~,okNew] = analizeRegs(reg, false(size(reg)), factorComp, thrEcc, ...
        %                                     thrEquivDiam, areaDet, conn, false);
        %                         if sum(uint8(okNew(:)>0)) >0
        %                             flagRound = true;
        %                             stR = regionprops(okNew>0, 'Area', 'Perimeter');
        %                             isRound = [isRound i];
        %                             valsRound = [valsRound double(stR.Perimeter)/double(stR.Area)];
        %         %                         cells(labsInter==i | Rtouch) = false;
        %         %                         ok(okNew(:)>0) = max(ok(labsInter==i));
        %         %                         break;
        %                         end
        %                     end
        %                 end
        %                 if numel(isRound)>0
        %                     [~, indMin] = min(valsRound);
        %                     reg = (labsInter==isRound(indMin) | Rtouch);
        %                     ok(reg) = max(ok(labsInter==isRound(indMin)));
        %                     cells(reg) = false;
        %                 elseif numel(isIntersect)>0
        %                     [~, indMin] = min(valsIntersect);
        %                     reg = (labsInter==isIntersect(indMin) | Rtouch);
        %                     ok(reg) = max(ok(labsInter==isRound(indMin)));
        %                     cells(reg) = false;
        %                 end
        %                 clear isIntersect valsIntersect isRound valsRound;
                    end
                elseif (stats(nR).Area<areaDet.medianArea && stats(nR).Area/stats(nR).ConvexArea>0.7) || ...
                    (stats(nR).Area<areaDet.medianArea && minR/maxR>=0.45)    
                    % se è una regione molto compatta la considero come nuova
                    % regione
                    ok(Rtouch) = max(ok(:)) + 1;
                    cells(Rtouch) = false;
                end
            end
            clear cc labs stats idx
        end
    end
end
    
    