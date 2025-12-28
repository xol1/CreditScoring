libname inlib "/workspaces/workspace/ASBSAS/inlib";

data work.abt_scored_final;
    set inlib.abt_app;

    /* --- SEKKCJA 1: Wyliczanie Score'ów (Modele) --- */
    
    %include "/workspaces/workspace/Grupa15/model_pd_css/scoring_code.sas";
    %include "/workspaces/workspace/Grupa15/model_pd_ins/scoring_code.sas";
    %include "/workspaces/workspace/Grupa15/model_pd_css_cross/scoring_code.sas";
    %include "/workspaces/workspace/Grupa15/model_pr_css_cross/scoring_code.sas";

    /* --- SEKCJA 2: Inicjalizacja zmiennych decyzyjnych --- */
    length decision $10 rejection_reason $100;
    
    decision = 'ACCEPT'; 
    rejection_reason = '';
    
    cross_sell_offer = 1; 

    _prod_norm = strip(lowcase(product));


    /* --- SEKCJA 3: Logika Biznesowa --- */

    if active_customer_flag = 0 then do;
        decision = 'DECLINE';
        rejection_reason = '998: Not active customer';
        cross_sell_offer = 0; 
    end;
    
    else do; 

        /* --- Scenariusz: Produkt INS --- */
        if _prod_norm = 'ins' then do;
            if missing(prob_default_ins) then do;
                decision = 'MANUAL'; 
                rejection_reason = 'ERR: Missing Score INS';
            end;
            else if prob_default_ins > 0.08 then do;
                decision = 'DECLINE';
                rejection_reason = 'Risk: High PD INS';
            end;
        end;

        /* --- Scenariusz: Produkt CSS --- */
        else if _prod_norm = 'css' then do;
            if missing(prob_default_css) then do;
                decision = 'MANUAL';
                rejection_reason = 'ERR: Missing Score CSS';
            end;
            else if prob_default_css > 0.05 then do;
                decision = 'DECLINE';
                rejection_reason = 'Risk: High PD CSS';
            end;
        end;
        
        else do;
            decision = 'ERROR';
            rejection_reason = cat('Unknown Product Type: ', product);
        end;


        /* --- SEKCJA 4: Logika Cross-Sell (Dla wszystkich aktywnych) --- */
           
        if cross_sell_offer = 1 then do;
            if prob_default_css_cross > 0.12 then cross_sell_offer = 0;
            
            if prob_response_css < 0.02 then cross_sell_offer = 0;
            
            if missing(prob_default_css_cross) or missing(prob_response_css) then cross_sell_offer = 0;
        end;

    end;

    drop _prod_norm;

run;

title "Podsumowanie decyzji kredytowych";
proc freq data=work.abt_scored_final;
    tables decision rejection_reason cross_sell_offer product*decision / list missing;
run;