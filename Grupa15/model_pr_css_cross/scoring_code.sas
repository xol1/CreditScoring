data &zbior._score;
    set &zbior;

    /* Inicjalizacja bazowej liczby punktów (Intercept modelu: 3.7072) */
    SCORECARD_POINTS = 3.7072;

    /* 1. Normalizacja produktu dla logiki warunkowej */
    length _prod_norm_pr $10;
    _prod_norm_pr = strip(lowcase(product));

    /* ===================== ACT_AGE (Współczynnik: 0.0338) ===================== */
    select;
        when (not missing(ACT_AGE)) do;
            PSC_ACT_AGE = 0.0338 * ACT_AGE;
            SCORECARD_POINTS = sum(SCORECARD_POINTS, PSC_ACT_AGE);
        end;
        otherwise PSC_ACT_AGE = .;
    end;

    /* ===================== APP_INCOME (Współczynnik: -0.00005) ===================== */
    select;
        when (not missing(APP_INCOME)) do;
            PSC_APP_INCOME = -0.00005 * APP_INCOME;
            SCORECARD_POINTS = sum(SCORECARD_POINTS, PSC_APP_INCOME);
        end;
        otherwise PSC_APP_INCOME = .;
    end;

    /* ===================== ACT_CC (Współczynnik: -0.6371) ===================== */
    select;
        when (not missing(ACT_CC)) do;
            PSC_ACT_CC = -0.6371 * ACT_CC;
            SCORECARD_POINTS = sum(SCORECARD_POINTS, PSC_ACT_CC);
        end;
        otherwise PSC_ACT_CC = .;
    end;

    /* ===================== APP_LOAN_AMOUNT (Współczynnik: 0.00001) ===================== */
    select;
        when (not missing(APP_LOAN_AMOUNT)) do;
            PSC_APP_LOAN_AMOUNT = 0.00001 * APP_LOAN_AMOUNT;
            SCORECARD_POINTS = sum(SCORECARD_POINTS, PSC_APP_LOAN_AMOUNT);
        end;
        otherwise PSC_APP_LOAN_AMOUNT = .;
    end;

    /* ===================== PRODUCT LOGIC (Współczynnik CSS: 2.2422) ===================== */
    select;
        when (_prod_norm_pr = 'css') do;
            PSC_PRODUCT = 2.2422;
            SCORECARD_POINTS = sum(SCORECARD_POINTS, PSC_PRODUCT);
        end;
        when (_prod_norm_pr = 'ins') do;
            PSC_PRODUCT = 0;
            SCORECARD_POINTS = sum(SCORECARD_POINTS, PSC_PRODUCT);
        end;
        otherwise do;
            PSC_PRODUCT = .;
            SCORECARD_POINTS = .; /* Brak możliwości wyliczenia dla innego produktu */
        end;
    end;

    /* Wyliczenie finalnego prawdopodobieństwa na podstawie uzyskanych punktów (logit) */
    if not missing(SCORECARD_POINTS) then 
        prob_response_css = 1/(1+exp(-SCORECARD_POINTS));
    else 
        prob_response_css = .;

    /* Sprzątanie zmiennych technicznych */
    drop _prod_norm_pr;
run;