function img_filtrata_stress= ...
    masked_stress2(img_letta, Nit, Ns, fattore_dist, maskIn, maskSamples)
% esegue STRESS in una maschera di Input e prendendo campioni da maschera
% di Output
    disp('Bimasked Stress');
    % calcolo le dimensioni
    [r,c,p]=size(img_letta);
    
    % min_lato sarebbe la distanza entro la quale lancio gli spray
    if fattore_dist<1; min_lato = sqrt(r^2+c^2)*fattore_dist;
    else; min_lato = fattore_dist; end

    % riempiamo questa matrice che sarà poi l'img filtrata
    img_filtrata_stress=zeros(r,c,p);
    indSamples = find(maskSamples);
    indIn = find(maskIn);
    % ciclo su tutta l'img
    for i = 1:numel(indIn)
        indP = indIn(i);
        [yy, xx]= ind2sub(size(maskIn), indP);
            % ciclo per il num di iterazioni
        b=[];
        for j3=1:Nit
            % campionamento radiale, serie di controlli
            %[j1 j2 j3 j4]
            % devo scegliere i pixel a caso: riga e colonna
            % scelgo la distanza, tra 0 e R/2, e l'angolo tra o e 2
            % pigreco
            indS= randi(numel(indSamples),numel(indSamples),1);
            [yS,xS] = ind2sub(size(maskSamples),indS);
%                         dist=rand()*min_lato;
%                         theta=rand()*360;
            % quindi con le trasformazioni di coordinate polari calcolo
            %   l'incremento su x e su y
            indConsidera = find((((yS-yy).^2+(xS-xx).^2).^(1/2))<min_lato);
            % la riga sara data dalla posizione attuale piu
            % l'incremento. Faccio l'arrotondamento a intero e anche il
            % valore assoluto, cioe nel caso esco dall'immagine mi
            % riporto dentro
            if numel(indConsidera)<Ns % se indConsidera non contiene abbastanza campioni
                nvolte = ceil(double(Ns)/double(numel(indConsidera)));
                indConsidera = repmat(indConsidera,nvolte,1);
            end
            
            %samples_vector
            % il sample vector deve contenere anche il pixel che sto
            % considerando
            riga = [yS(indConsidera(1:Ns)); yy];
            colonna = [xS(indConsidera(1:Ns)); xx];      
            % metto in un vettore i campioni
            samples_vector= computePtsVals([colonna riga],img_letta);

            s_max=max(samples_vector);
            s_min=min(samples_vector);
            r_value = s_max-s_min;  
            
            b(j3,r_value==0) = 0.5;
            b(j3,r_value~=0)=((computePtsVals([xx,yy],img_letta)'-s_min(:))./r_value(:))';
            clear r_value s_max s_min riga colonna samples_vector;
        end    
        % faccio la media delle iterazioni, per i tre canali separatmante
        img_filtrata_stress(yy,xx,:)=mean(b);
        clear b;
    end % end indP

    img_filtrata_stress=min(img_filtrata_stress,1);
    img_filtrata_stress=max(img_filtrata_stress,0);
    img_filtrata_stress=uint8(255*img_filtrata_stress);
    
    disp('End Bimasked Stress');
end


