/* =====================================================
   PD CSS – MODEL RYZYKA KREDYTU GOTÓWKOWEGO
   Punkt startowy: abt_app
   Target: default12
   Okres: 1975–1987
   ===================================================== */

/* =====================================================
   1. LIBNAME – lokalizacja danych
   ===================================================== */

libname data "F:\SGH\credit scoring\software\software\ASB_SAS\inlib";

/* =====================================================
   2. Wczytanie pe³nej populacji ABT
   ===================================================== */

data abt_all;
    set data.abt_app;
run;

/* Kontrola struktury */
proc contents data=abt_all;
run;
/* =====================================================
   3. Filtrowanie okresu 1975–1987
   ===================================================== */

data abt_time;
    set abt_all;
    if '197501' <= period <= '198712';
run;

/* Kontrola okresu */
proc freq data=abt_time;
    tables period / nocum nopercent;
run;
/* =====================================================
   4. Wybór produktu CSS
   ===================================================== */

data abt_css;
    set abt_time;
    if act_ccss_n_loan > 0;
run;

/* Kontrola liczebnoœci */
proc sql;
    select 
        count(*) as n_obs,
        mean(default12) format=percent8.2 as default_rate
    from abt_css;
quit;
/* =====================================================
   5. Kontrola zmiennej celu
   ===================================================== */

proc freq data=abt_css;
    tables default12 / missing;
run;
/* =====================================================
   6. LOSOWY PODZIA£ NA TRAIN / VALID (POD PROFIT)
   ===================================================== */

data abt_css;
    set abt_css;
    if default12 in (0,1);
run;
data train valid;
    set abt_css_rnd;
    if u <= 0.7 then output train;
    else output valid;
run;
proc sql;
    select 
        'TRAIN' as sample,
        count(*) as n_obs,
        sum(default12) as n_default,
        mean(default12) format=percent8.2 as default_rate
    from train
    union all
    select 
        'VALID' as sample,
        count(*) as n_obs,
        sum(default12) as n_default,
        mean(default12) format=percent8.2 as default_rate
    from valid;
quit;
/* =====================================================
   7.1 Lista zmiennych wykluczonych
   ===================================================== */

data exclude;
    length name $32;
    input name $;
    datalines;
CID
AID
PERIOD
DEFAULT3
DEFAULT6
DEFAULT9
DEFAULT_CROSS3
DEFAULT_CROSS6
DEFAULT_CROSS9
DEFAULT_CROSS12
OUTSTANDING
;
run;

;
/* =====================================================
   7.2 Automatyczne wybranie zmiennych kandydackich
   ===================================================== */

proc contents data=train out=varlist(keep=name type) noprint;
run;

proc sql;
    create table model_vars as
    select a.name
    from varlist as a
    left join exclude as b
        on upcase(a.name) = b.name
    where a.type = 1
      and b.name is null;
quit;

/* =====================================================
   7.3 Univariate screening – logistic 1D
   ===================================================== */

/* =====================================================
   Univariate screening – C-statistic (ROC)
   ===================================================== */

data uni_cstat;
    length variable $32 c_stat 8.;
    stop;
run;

%macro univariate_cstat;
    %local i var;

    proc sql noprint;
        select name into :var1-:var999
        from model_vars;
        %let nvars=&sqlobs;
    quit;

    %do i = 1 %to &nvars;
        %let var = &&var&i;

        ods output Association=assoc_tmp;

        proc logistic data=train descending;
            model default12 = &var;
        run;

        ods output close;

        /* jeœli tabela Association istnieje */
        %if %sysfunc(exist(assoc_tmp)) %then %do;

            data assoc_tmp;
                set assoc_tmp;
                where upcase(label2) = 'C';
                length variable $32;
                variable = "&var";
                c_stat = nvalue2;
                keep variable c_stat;
            run;

            proc append base=uni_cstat data=assoc_tmp force;
            run;

            proc datasets lib=work nolist;
                delete assoc_tmp;
            quit;

        %end;

    %end;
%mend;

%univariate_cstat;

proc sort data=uni_cstat;
    by descending c_stat;
run;

proc print data=uni_cstat(obs=50) label noobs;
    var variable c_stat;
    label
        variable = "Zmienna"
        c_stat   = "C-statistic";
run;

%let model_vars_final =
    act_ccss_dueutl
    act_ccss_maxdue
    act_ccss_utl
    act_ccss_n_statC
    act3_n_arrears
    act6_n_arrears
    act9_n_arrears
    act12_n_arrears
    agr6_Mean_CMaxC_Due
    agr12_Mean_CMaxA_Due
;
/* =====================================================
   8. MODEL PD CSS – REGRESJA LOGISTYCZNA
   ===================================================== */

proc logistic data=train descending;
    model default12 =
        &model_vars_final
        / selection=none
          lackfit;
    output out=score_train p=PD;
run;
proc logistic data=train descending;
    model default12 =
        &model_vars_final;
    score data=valid out=score_valid fitstat;
run;
ods output ParameterEstimates = pd_css_params;

proc logistic data=train descending;
    model default12 =
        &model_vars_final;
run;

ods output close;
data pd_css_table;
    set pd_css_params;
    where variable ne 'Intercept';

    /* Iloraz szans */
    odds_ratio = exp(estimate);

    /* Kierunek wp³ywu */
    if estimate > 0 then impact = '+';
    else if estimate < 0 then impact = '-';
    else impact = '0';

    keep variable estimate odds_ratio impact probchisq;
run;
data pd_css_table_sort;
    set pd_css_table;
    abs_estimate = abs(estimate);
run;
proc sort data=pd_css_table_sort;
    by descending abs_estimate;
run;
ods html file="PD_CSS_Model_Report.html" style=htmlblue;


proc print data=pd_css_table label noobs;
    var variable estimate odds_ratio impact probchisq;
    label
        variable   = "Zmienna"
        estimate   = "Wspó³czynnik"
        odds_ratio = "Iloraz szans (OR)"
        impact     = "Kierunek wp³ywu"
        probchisq  = "P-value";
run;
ods pdf close;
