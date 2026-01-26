/* --- Silnik decyzyjny z zaaplikowaną nową logiką biznesową --- */

%macro scoring_engine(wej,wyj);
data cal;
    set &wej;
    _period = put(period, 6.); /* Konwersja na tekst na wszelki wypadek */
    drop period;
    rename _period=period;
run;

/* Etapy scoringowe (pozostają bez zmian, bo generują niezbędne PD i PR) */
%let zbior=cal;
%include "/workspaces/workspace/Grupa15/model_pd_ins/scoring_code.sas";

data cal1;
    set cal_score;
    risk_ins_score=.;
    if product='ins' then risk_ins_score=SCORECARD_POINTS;
    pd_ins=1/(1+exp(-(-0.032205144*risk_ins_score+9.4025558419)));
    drop psc: SCORECARD_POINTS;
run;

%let zbior=cal1;
%include "/workspaces/workspace/Grupa15/model_pd_css/scoring_code.sas";

data cal2;
    set cal1_score;
    risk_css_score=.;
    if product='css' then risk_css_score=SCORECARD_POINTS;
    pd_css=1/(1+exp(-(-0.028682728*risk_css_score+8.1960829753)));
    drop psc: SCORECARD_POINTS;
run;

%let zbior=cal2;
%include "/workspaces/workspace/Grupa15/model_pd_css_cross/scoring_code.sas";

data cal3;
    set cal2_score;
    risk_cross_css_score=SCORECARD_POINTS;
    pd_cross_css=1/(1+exp(-(-0.028954669*risk_cross_css_score+8.2497434934)));
    drop psc: SCORECARD_POINTS;
run;

%let zbior=cal3;
/* Plik pr_css_cross.sas musi być wczytany wewnątrz data stepu lub sam go tworzyć */
data cal3_score;
    set cal3;
    %include "/workspaces/workspace/Grupa15/model_pr_css_cross/scoring_code.sas";
run;
data cal4;
    set cal3_score;
    response_score=SCORECARD_POINTS;
    pr=1/(1+exp(-(-0.035007455*response_score+10.492092793)));
    drop psc: SCORECARD_POINTS;
run;

/* --- SEKCJA FINALNA: IMPLEMENTACJA LOGIKI BIZNESOWEJ --- */
/* Obniżamy próg dla CSS - 18% to wciąż dużo, bezpieczniej celować w 12-15% */
%let pd_css = 0.15; 

/* Zaostrzamy selekcję na produkcie ratalnym (ins) */
%let pd_ins1 = 0.03; 

/* Podnosimy wymagania co do szansy na cross-sell (pr) */
%let pd_ins2 = 0.02; 
%let pr2 = 0.102;

data &wyj;
    length cid $10 aid $16 product $3 period $6 decision $10 decline_reason $40
           app_loan_amount app_n_installments pd cross_pd pr 8;
    
    set cal4;

    /* Inicjalizacja wartości domyślnych */
    decision = 'A';
    decline_reason = '999: OK';
    cross_sell_offer = 1; /* Zakładamy 1, flaga będzie weryfikowana niżej */
    
    /* Mapowanie zmiennych na potrzeby czytelności */
    pd = .;
    if product = 'ins' then pd = pd_ins;
    else if product = 'css' then pd = pd_css;
    cross_pd = pd_cross_css;

/*     if (act_cins_n_statB>0 or act_ccss_n_statB>0) then do; */
/*         decision='D'; */
/*         decline_reason='1 bad customer'; */
/*     end; */


/*     if agr12_Max_CMaxA_Due>3 then do; */
/*         decision='D'; */
/*         decline_reason='1 bad customer'; */
/*     end; */

    if product='css' and pd_css>&pd_css then do;
        decision='D';
        decline_reason="1 PD cut-off on css";
    end;
    if product='ins' and pd_ins>&pd_ins1 then do;
        decision='D';
        decline_reason="2 PD cut-off on ins";
    end;

    if product='ins' and &pd_ins1>=pd_ins>&pd_ins2
        and (pr<&pr2 or pd_cross_css>&pd_css) then do;
        decision='D';
        decline_reason="3 PD,PDCross and PR cut-offs on ins";
    end;

if period<'197501' then do;
	decision='A';
	decline_reason='999ok';
end;

if product='css' and act_cus_active ne 1 then do;
	decision='N';
	decline_reason='998 not active customer';
end;

keep
cid aid product period decision decline_reason app_loan_amount 
app_n_installments pd cross_pd pr;
format pd cross_pd pr nlpct12.2;
run;

%mend;

