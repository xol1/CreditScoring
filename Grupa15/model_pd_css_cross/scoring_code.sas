/* =====================================================
   PD CSS CROSS – MODEL RYZYKA DLA PRODUKTU KRZYŻOWEGO
   Wersja: BEZKOLIZYJNA (Używa zmiennej SCORE_CROSS)
   ===================================================== */
data &zbior._score;
    set &zbior;
    
    /* ZMIANA 1: Używamy unikalnej nazwy dla punktów cross-sell, 
       aby nie kasować punktów głównego modelu */
    SCORE_CROSS = 0; 

    /* ACT12_N_GOOD_DAYS */
    select;
        when ( missing(ACT12_N_GOOD_DAYS) ) do;
            SCORE_CROSS=sum(SCORE_CROSS,54);
            PSC_ACT12_N_GOOD_DAYS=54;
        end;
        when ( not missing(ACT12_N_GOOD_DAYS) and ACT12_N_GOOD_DAYS <= 2 ) do;
            SCORE_CROSS=sum(SCORE_CROSS,45);
            PSC_ACT12_N_GOOD_DAYS=45;
        end;
        when ( 2 < ACT12_N_GOOD_DAYS <= 3 ) do;
            SCORE_CROSS=sum(SCORE_CROSS,37);
            PSC_ACT12_N_GOOD_DAYS=37;
        end;
        when ( 8 < ACT12_N_GOOD_DAYS ) do;
            SCORE_CROSS=sum(SCORE_CROSS,34);
            PSC_ACT12_N_GOOD_DAYS=34;
        end;
        when ( 3 < ACT12_N_GOOD_DAYS <= 4 ) do;
            SCORE_CROSS=sum(SCORE_CROSS,34);
            PSC_ACT12_N_GOOD_DAYS=34;
        end;
        when ( 4 < ACT12_N_GOOD_DAYS <= 8 ) do;
            SCORE_CROSS=sum(SCORE_CROSS,29);
            PSC_ACT12_N_GOOD_DAYS=29;
        end;
        otherwise do;
            SCORE_CROSS=sum(SCORE_CROSS,29);
            PSC_ACT12_N_GOOD_DAYS=29;
        end;
    end;

    /* ACT_CCSS_MAXDUE */
    select;
        when ( missing(ACT_CCSS_MAXDUE) ) do;
            SCORE_CROSS=sum(SCORE_CROSS,71);
            PSC_ACT_CCSS_MAXDUE=71;
        end;
        when ( not missing(ACT_CCSS_MAXDUE) and ACT_CCSS_MAXDUE <= 0 ) do;
            SCORE_CROSS=sum(SCORE_CROSS,59);
            PSC_ACT_CCSS_MAXDUE=59;
        end;
        when ( 0 < ACT_CCSS_MAXDUE <= 1 ) do;
            SCORE_CROSS=sum(SCORE_CROSS,45);
            PSC_ACT_CCSS_MAXDUE=45;
        end;
        when ( 4 < ACT_CCSS_MAXDUE ) do;
            SCORE_CROSS=sum(SCORE_CROSS,37);
            PSC_ACT_CCSS_MAXDUE=37;
        end;
        when ( 1 < ACT_CCSS_MAXDUE <= 4 ) do;
            SCORE_CROSS=sum(SCORE_CROSS,29);
            PSC_ACT_CCSS_MAXDUE=29;
        end;
        otherwise do;
            SCORE_CROSS=sum(SCORE_CROSS,29);
            PSC_ACT_CCSS_MAXDUE=29;
        end;
    end;

    /* ACT_CCSS_N_STATC */
    select;
        when ( 26 < ACT_CCSS_N_STATC ) do;
            SCORE_CROSS=sum(SCORE_CROSS,125);
            PSC_ACT_CCSS_N_STATC=125;
        end;
        when ( 15 < ACT_CCSS_N_STATC <= 26 ) do;
            SCORE_CROSS=sum(SCORE_CROSS,85);
            PSC_ACT_CCSS_N_STATC=85;
        end;
        when ( missing(ACT_CCSS_N_STATC) ) do;
            SCORE_CROSS=sum(SCORE_CROSS,79);
            PSC_ACT_CCSS_N_STATC=79;
        end;
        when ( 6 < ACT_CCSS_N_STATC <= 15 ) do;
            SCORE_CROSS=sum(SCORE_CROSS,54);
            PSC_ACT_CCSS_N_STATC=54;
        end;
        when ( 4 < ACT_CCSS_N_STATC <= 6 ) do;
            SCORE_CROSS=sum(SCORE_CROSS,40);
            PSC_ACT_CCSS_N_STATC=40;
        end;
        when ( not missing(ACT_CCSS_N_STATC) and ACT_CCSS_N_STATC <= 4 ) do;
            SCORE_CROSS=sum(SCORE_CROSS,29);
            PSC_ACT_CCSS_N_STATC=29;
        end;
        otherwise do;
            SCORE_CROSS=sum(SCORE_CROSS,29);
            PSC_ACT_CCSS_N_STATC=29;
        end;
    end;

    /* ACT_CCSS_UTL */
    select;
        when ( 0.5347222222 < ACT_CCSS_UTL ) do;
            SCORE_CROSS=sum(SCORE_CROSS,58);
            PSC_ACT_CCSS_UTL=58;
        end;
        when ( missing(ACT_CCSS_UTL) ) do;
            SCORE_CROSS=sum(SCORE_CROSS,57);
            PSC_ACT_CCSS_UTL=57;
        end;
        when ( 0.5208333333 < ACT_CCSS_UTL <= 0.5347222222 ) do;
            SCORE_CROSS=sum(SCORE_CROSS,44);
            PSC_ACT_CCSS_UTL=44;
        end;
        when ( 0.4895833333 < ACT_CCSS_UTL <= 0.5208333333 ) do;
            SCORE_CROSS=sum(SCORE_CROSS,40);
            PSC_ACT_CCSS_UTL=40;
        end;
        when ( 0.4479166667 < ACT_CCSS_UTL <= 0.4895833333 ) do;
            SCORE_CROSS=sum(SCORE_CROSS,36);
            PSC_ACT_CCSS_UTL=36;
        end;
        when ( 0.4083333333 < ACT_CCSS_UTL <= 0.4479166667 ) do;
            SCORE_CROSS=sum(SCORE_CROSS,32);
            PSC_ACT_CCSS_UTL=32;
        end;
        when ( not missing(ACT_CCSS_UTL) and ACT_CCSS_UTL <= 0.4083333333 ) do;
            SCORE_CROSS=sum(SCORE_CROSS,29);
            PSC_ACT_CCSS_UTL=29;
        end;
        otherwise do;
            SCORE_CROSS=sum(SCORE_CROSS,29);
            PSC_ACT_CCSS_UTL=29;
        end;
    end;

    /* AGS3_MEAN_CMAXA_DUE */
    select;
        when ( missing(AGS3_MEAN_CMAXA_DUE) ) do;
            SCORE_CROSS=sum(SCORE_CROSS,60);
            PSC_AGS3_MEAN_CMAXA_DUE=60;
        end;
        when ( not missing(AGS3_MEAN_CMAXA_DUE) and AGS3_MEAN_CMAXA_DUE <= 0.6666666667 ) do;
            SCORE_CROSS=sum(SCORE_CROSS,49);
            PSC_AGS3_MEAN_CMAXA_DUE=49;
        end;
        when ( 0.6666666667 < AGS3_MEAN_CMAXA_DUE <= 1 ) do;
            SCORE_CROSS=sum(SCORE_CROSS,39);
            PSC_AGS3_MEAN_CMAXA_DUE=39;
        end;
        when ( 3 < AGS3_MEAN_CMAXA_DUE ) do;
            SCORE_CROSS=sum(SCORE_CROSS,33);
            PSC_AGS3_MEAN_CMAXA_DUE=33;
        end;
        when ( 1 < AGS3_MEAN_CMAXA_DUE <= 3 ) do;
            SCORE_CROSS=sum(SCORE_CROSS,29);
            PSC_AGS3_MEAN_CMAXA_DUE=29;
        end;
        otherwise do;
            SCORE_CROSS=sum(SCORE_CROSS,29);
            PSC_AGS3_MEAN_CMAXA_DUE=29;
        end;
    end;

    /* APP_INCOME */
    select;
        when ( 1049 < APP_INCOME <= 3872 ) do;
            SCORE_CROSS=sum(SCORE_CROSS,77);
            PSC_APP_INCOME=77;
        end;
        when ( 573 < APP_INCOME <= 1049 ) do;
            SCORE_CROSS=sum(SCORE_CROSS,60);
            PSC_APP_INCOME=60;
        end;
        when ( 3872 < APP_INCOME ) do;
            SCORE_CROSS=sum(SCORE_CROSS,52);
            PSC_APP_INCOME=52;
        end;
        when ( 411 < APP_INCOME <= 573 ) do;
            SCORE_CROSS=sum(SCORE_CROSS,42);
            PSC_APP_INCOME=42;
        end;
        when ( not missing(APP_INCOME) and APP_INCOME <= 411 ) do;
            SCORE_CROSS=sum(SCORE_CROSS,29);
            PSC_APP_INCOME=29;
        end;
        otherwise do;
            SCORE_CROSS=sum(SCORE_CROSS,29);
            PSC_APP_INCOME=29;
        end;
    end;
run;

