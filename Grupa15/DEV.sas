/* ==========================================================================
   ZINTEGROWANY SYSTEM: SCORING + SYMULACJA ZYSKU (MASTER VERSION)
   ========================================================================== */
options mprint symbolgen;
libname inlib "/workspaces/workspace/ASBSAS/inlib";
libname out "/workspaces/workspace/Grupa15";

/* --- CZĘŚĆ 1: ŁADOWANIE DANYCH I URUCHOMIENIE MODELI --- */

data out.abt_app;
    set inlib.abt_app;
run;

/* Uruchomienie modeli scoringowych (Nadzorowane przez %include) */
/* Te skrypty powinny wygenerować zmienną SCORECARD_POINTS oraz PD_css_scorecard (dla CSS) */
%include "/workspaces/workspace/Grupa15/model_pd_css/scoring_code.sas";
%include "/workspaces/workspace/Grupa15/model_pd_ins/scoring_code.sas";
%include "/workspaces/workspace/Grupa15/model_pd_css_cross/scoring_code.sas";

/* Uruchomienie modelu Response */
data out.abt_scored_raw;
    set out.abt_app;
    %include "/workspaces/workspace/Grupa15/model_pr_css_cross/scoring_code.sas";
run;


/* --- CZĘŚĆ 2: PARAMETRY SYMULACJI --- */

/* 2a. Parametry Finansowe */
%let apr_ins=0.01;
%let apr_css=0.18;
%let lgd_ins=0.45;
%let lgd_css=0.55;

/* 2b. Parametry Decyzyjne (Strategia) */
%let pd_css_cutoff  = 0.30;   /* CSS: Akceptujemy do 30% ryzyka */
%let pd_ins_hard    = 0.02;   /* INS: Twarde odcięcie 9% */
%let pd_ins_soft    = 0.02;   /* INS: Wymuszenie cross-sell powyżej 2% */
%let pr_req         = 0.02;   /* INS: Minimalna szansa na sprzedaż cross */


/* --- CZĘŚĆ 3: PRZELICZENIE I SYMULACJA ZYSKU --- */


data out.final_simulation;
    set out.abt_scored_raw;
    
    /* Filtr okresu */
    where '197501'<=period<='198712';
    
    /* Naprawa braków w statusach spłat */
    if default12 in (0,.i,.d) then default12=0;
    if default_cross12 in (0,.i,.d) then default_cross12=0;

    /* --- A. ROZPOZNANIE PRODUKTU (METODA PANCERNA) --- */
    /* Używamy AID, bo zmienna product bywa uszkodzona */
    length _prod_fixed $3;
    if upcase(substr(aid, 1, 3)) = 'CSS' then _prod_fixed = 'css';
    else if upcase(substr(aid, 1, 3)) = 'INS' then _prod_fixed = 'ins';
    else _prod_fixed = lowcase(strip(product));


    /* --- B. PRZYPISANIE PRAWDOPODOBIEŃSTWA (PD) --- */
    risk_score = SCORECARD_POINTS;
    
    /* 1. PD dla CSS */
    if _prod_fixed = 'css' then do;
        /* Dla CSS ufamy zmiennej wyliczonej przez Fixed Model */
        /* Jeśli jest pusta, doliczamy w locie z kalibracji Fixed (25 - 0.05*Score) */
        if not missing(PD_css_scorecard) then pd_css = PD_css_scorecard;
        else pd_css = 1 / (1 + exp( - (25 + (-0.05 * risk_score)) ));
    end;

    /* 2. PD dla INS */
    if _prod_fixed = 'ins' then do;
        /* Dla INS nie mamy zmiennej w pliku, więc liczymy ze wzoru */
        /* Wzór dopasowany do skali punktowej INS (~380 pkt) */
        pd_ins = 1 / (1 + exp( - (-0.032205144 * risk_score + 9.4025558419) ));
    end;
    
    /* 3. Cross-Sell */
    pd_cross_css = prob_default_css_cross;
    pr = prob_response_css;


    /* --- C. OBLICZENIA FINANSOWE --- */
    /* Przypisanie parametrów wg produktu */
    if _prod_fixed='ins' then do;
        lgd=&lgd_ins; apr=&apr_ins/12;
    end;
    else if _prod_fixed='css' then do;
        lgd=&lgd_css; apr=&apr_css/12;
    end;
    
    /* Zysk z Głównego Produktu */
    EL = 0;
    if default12=1 then EL = app_loan_amount * lgd;
    
    installment = 0;
    if app_n_installments > 0 then
        installment = app_loan_amount*apr*((1+apr)**app_n_installments)/(((1+apr)**app_n_installments)-1);
    
    Income = 0;
    if default12=0 then Income = app_n_installments*installment - app_loan_amount; 
    
    Profit = Income - EL;

    /* Zysk z Cross-Sell */
    lgd_cross = &lgd_css; 
    apr_cross = &apr_css/12;
    
    EL_cross = 0;
    if default_cross12=1 then EL_cross = cross_app_loan_amount * lgd_cross;
    
    installment_cross = 0;
    if cross_app_n_installments > 0 then
        installment_cross = cross_app_loan_amount*apr_cross*((1+apr_cross)**cross_app_n_installments)/(((1+apr_cross)**cross_app_n_installments)-1);
        
    Income_cross = 0;
    if default_cross12=0 then Income_cross = cross_app_n_installments*installment_cross - cross_app_loan_amount;
    
    Profit_cross = Income_cross - EL_cross;


    /* --- D. SILNIK DECYZYJNY --- */
    simulated_decision = 'A';
    rejection_reason = 'N/A';
    
    /* Zabezpieczenie przed brakami PD */
    if _prod_fixed='css' and missing(pd_css) then simulated_decision='D';
    if _prod_fixed='ins' and missing(pd_ins) then simulated_decision='D';

    /* Strategia dla CSS */
    if _prod_fixed='css' then do;
        if pd_css > &pd_css_cutoff then do;
            simulated_decision='D';
            rejection_reason='Risk: High PD CSS';
        end;
    end;

    /* Strategia dla INS */
    if _prod_fixed='ins' then do;
        if pd_ins > &pd_ins_hard then do;
            simulated_decision='D';
            rejection_reason='Risk: Hard Cutoff INS';
        end;
        else if (pd_ins > &pd_ins_soft) and (pr < &pr_req or pd_cross_css > &pd_css_cutoff) then do;
            simulated_decision='D';
            rejection_reason='Risk: Soft INS / Bad Cross';
        end;
    end;
    
    /* Reset zysku dla odrzuconych */
    if simulated_decision = 'D' then do;
        Profit = 0;
        Profit_cross = 0;
    end;

    Total_Profit = Profit + Profit_cross;
run;

/* ==========================================================================
   4. RAPORT WYNIKÓW I ANALIZA ODRZUCEŃ
   ========================================================================== */


/* RAPORT 1: FINANSE (Tylko dla zaakceptowanych 'A') */
title " OSTATECZNY WYNIK FINANSOWY";
title2 "Zysk wygenerowany przez zaakceptowanych klientów";
proc tabulate data=out.final_simulation;
    class _prod_fixed simulated_decision;
    var Total_Profit;
    
    where simulated_decision = 'A';
    
    table _prod_fixed all, 
          simulated_decision * (
              N='Liczba Umów'*f=comma12. 
              Total_Profit * Sum='ZYSK (PLN)' * f=comma20.0 
          ) / box='Produkt';
run;

