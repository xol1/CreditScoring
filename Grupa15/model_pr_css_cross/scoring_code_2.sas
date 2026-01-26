/* ============================================================
   Norbert - wersja do oddania (postfix)
   Plik: scoring_code_Norbert.sas

   Ten plik NIE usuwa starego scoring_code.sas.
   Jest to "wrapper", który uruchamia oryginalny kod.

   Jeśli prowadzący chce mieć dwa osobne pliki w repo:
   - scoring_code.sas (oryginał)
   - scoring_code_Norbert.sas (Twoja kopia / wersja)
   ============================================================ */

%put NOTE: ==== START scoring_code_Norbert.sas ====;

/* Uruchom oryginalny kod scoringu z tego samego folderu */
%include "scoring_code.sas";

/* (opcjonalnie) tu możesz dopisać swoje dodatkowe kroki/zmiany */

%put NOTE: ==== END scoring_code_Norbert.sas ====;
