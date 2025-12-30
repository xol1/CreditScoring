/* =========================================================
   MODEL: PR Css Cross (SCORING)
   OUTPUT: prob_response_css (0-1)
   Uwaga: Ten plik jest %include'owany WEWNĄTRZ DATA STEP
   (decision_engine.sas), więc nie używamy PROC LOGISTIC.
   ========================================================= */

length _prod_norm $10;
_prod_norm = strip(lowcase(product));

if missing(_prod_norm) or missing(act_age) or missing(app_income) or missing(act_cc) or missing(app_loan_amount) then do;
    prob_response_css = .;
end;
else do;
    _logit = 3.7072
           + 0.0338    * act_age
           + (-0.00005)* app_income
           + (-0.6371) * act_cc
           + 0.00001   * app_loan_amount;

    if _prod_norm = 'css' then _logit + 2.2422;
    else if _prod_norm = 'ins' then _logit + 0;
    else do;
        prob_response_css = .;
        _logit = .;
    end;

    if not missing(_logit) then prob_response_css = 1/(1+exp(-_logit));
end;

drop _logit _prod_norm;
