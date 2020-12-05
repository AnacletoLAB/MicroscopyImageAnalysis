function [img_filtrata_stress,img_filtrata_stressAllRange,img_filtrata_r]=rsr_stress(img_letta, Nit, Ns, fattore_dist)
% esegue sia STRESS che RSR, con gli stessi parametri
% dato che stress è quasi identico, sfruttiamo i calcoli per filtrare
% con entrambi i metodi

    % calcolo le dimensioni
    [r,c,p]=size(img_letta);

    % min_lato sarebbe la distanza entro la quale lancio gli spray
    if fattore_dist<1; min_lato = sqrt(r^2+c^2)*fattore_dist;
    else; min_lato = fattore_dist; end

    % riempiamo questa matrice che sarà poi l'img filtrata
    img_filtrata_stress=zeros(r,c,p);
    img_filtrata_r=zeros(r,c,p);

    % ciclo su tutta l'img
    for j1=1:r
        for j2=1:c
            % ciclo per il num di iterazioni (N dell'articolo)
            b_v=[]; b_r=[];
            for j3=1:Nit
                % ciclo per il num di campioni (M dell'articolo)
                for j4=1:Ns
                    % campionamento radiale, serie di controlli
                    %[j1 j2 j3 j4]
                    % devo scegliere i pixel a caso: riga e colonna
                    % scelgo la distanza, tra 0 e R/2, e l'angolo tra o e 2
                    % pigreco
                    dist=rand()*min_lato;
                    theta=rand()*360;
                    % quindi con le trasformazioni di coordinate polari calcolo
                    %   l'incremento su x e su y
                    inc_x=dist*cos((theta*pi/180));
                    inc_y=dist*sin((theta*pi/180));
                    % la riga sara data dalla posizione attuale piu
                    % l'incremento. Faccio l'arrotondamento a intero e anche il
                    % valore assoluto, cioe nel caso esco dall'immagine mi
                    % riporto dentro
                    riga=round(abs(j1+inc_x));
                    colonna=round(abs(j2+inc_y));               
                    % se ho preso un punto che non è nell'img, quel punto
                    % lo sostituisco con un punto a caso nell'img
                    if (riga<1 | riga>r | colonna<1 | colonna>c)
                        % devo scegliere i pixel a caso: riga e colonna
                        %disp('entrato')
                        riga=ceil(rand()*r);
                        colonna=ceil(rand()*c);
                    end % end IF
                    % metto in un vettore i campioni
                    samples_vector(j4,1)=img_letta(riga,colonna,1);
                    samples_vector(j4,2)=img_letta(riga,colonna,2);
                    samples_vector(j4,3)=img_letta(riga,colonna,3);                
                 end % end j4 = Ns = numero campioni = M dell'articolo
                 %samples_vector
                 % il sample vector deve contenere anche il pixel che sto
                 % considerando
                 samples_vector(Ns+1,1)=img_letta(j1,j2,1);
                 samples_vector(Ns+1,2)=img_letta(j1,j2,2); 
                 samples_vector(Ns+1,3)=img_letta(j1,j2,3);             

                 s_max(1)=max(samples_vector(:,1));
                 s_min(1)=min(samples_vector(:,1));
                 r_value(1)=s_max(1)-s_min(1);  

                 if (r_value(1)==0)
                      b_v(j3,1)=0.5;
                   else
                      b_v(j3,1)=(img_letta(j1,j2,1)-s_min(1))/r_value(1);
                 end

                 s_max(2)=max(samples_vector(:,2));
                 s_min(2)=min(samples_vector(:,2));
                 r_value(2)=s_max(2)-s_min(2);

                 if (r_value(2)==0)
                      b_v(j3,2)=0.5;
                   else
                      b_v(j3,2)=(img_letta(j1,j2,2)-s_min(2))/r_value(2);
                 end

                 s_max(3)=max(samples_vector(:,3));
                 s_min(3)=min(samples_vector(:,3));
                 r_value(3)=s_max(3)-s_min(3);

                 if (r_value(3)==0)
                      b_v(j3,3)=0.5;
                   else
                      b_v(j3,3)=(img_letta(j1,j2,3)-s_min(3))/r_value(3);
                 end
                 
                    % memorizzo anche i range (ri nell'articolo)
                 b_r(j3,1)=r_value(1);
                 b_r(j3,2)=r_value(2);
                 b_r(j3,3)=r_value(3);

            end % end j3 = N dell'articolo
            % faccio la media delle iterazioni, per i tre canali separatmante
            img_filtrata_stress(j1,j2,1)=mean(b_v(:,1));
            img_filtrata_stress(j1,j2,2)=mean(b_v(:,2));
            img_filtrata_stress(j1,j2,3)=mean(b_v(:,3));

            % aggiorno la immagine che tiene la media degli ri
            img_filtrata_r(j1,j2,1)=mean(b_r(:,1));
            img_filtrata_r(j1,j2,2)=mean(b_r(:,2));
            img_filtrata_r(j1,j2,3)=mean(b_r(:,3));
        end % end j2

    end % end j1

    % faccio il mapping delle img
    %img_filtrata_stress=img_mapping(img_filtrata_stress);
    %img_filtrata_rsr=img_mapping(img_filtrata_rsr);
    
    img_filtrata_stressAllRange = img_filtrata_stress-min(img_filtrata_stress(:));
    img_filtrata_stressAllRange = uint8(255* (img_filtrata_stressAllRange/max(img_filtrata_stressAllRange(:))));
    
    img_filtrata_stress=min(img_filtrata_stress,1);
    img_filtrata_stress=max(img_filtrata_stress,0);
    img_filtrata_stress=uint8(255*img_filtrata_stress);
    
    img_filtrata_r=min(img_filtrata_r,1);
    img_filtrata_r=max(img_filtrata_r,0);

    % visualizzo l'img
    figure()
    imshow(img_filtrata_stress)
    title('stress RGB')
    figure()
    imshow(img_filtrata_r)
    title('rsr RGB')
    close all
    disp('***')
end


