function neighs=ptsNeighs(pts,Nhood)
% pts=matrix con le posizioni dei punti (ogni riga = [X Y] del punto)
% ATTENZIONE che poi Matlab vuole prima la coord Y che la X!
    
% restituisce una matrice contenente 
% Nhood (4 o 8) coppie di coord X,Y per riga.
% Sono gli nHood vicini del punto che corrisponde a quella riga in pts
    if ~isempty(pts) %#ok<ALIGN>
        numPts=size(pts,1);
        if (Nhood==8)
            N=repmat(pts,1,Nhood);
            offset=repmat([[0,-1],[-1, -1],[-1, 0],[-1, +1],...
                            [0 1],[1 1],[1 0],[1 -1]],numPts,1); 
        elseif (Nhood==4)
            N=repmat(pts,1,Nhood);
            offset=repmat([[0,-1],[-1, 0],[0 1],[1 0]],numPts,1);
        elseif (Nhood==0)
            N=[];
        end
        N=uint32(int32(N)+int32(offset));
    else N=[]; end;
    neighs=[]; for i=1:+2:size(N,2)-1; neighs=[neighs; N(:,i:i+1)]; end
end
