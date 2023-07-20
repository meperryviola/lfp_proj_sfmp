** what is and isn't in ftotval

*Computing what I think are included in FTOTVAL:
 
gen f_tot_income_ASEC_calc = ffrval  + fseval + fwsval + fannval + fcspval + fdisval + fdivval + fdstval + fedval + ffinval + fintval + foival + fpenval + fssival + fssval + fsurval + fvetval + fwcval + frntval + fpawval + fucval

hfrval  + hseval + hwsval+hannval + hcspval + hdisval + hdivval + hdstval + hedval + hfinval + hintval + hpenval + hoival  + hssival + hssval + hsurval + hvetval + hwcval + hrntval + hpawval + hucval

gen check_f_income =  f_tot_income_ASEC_calc/ftotval // I'm correct.
tab check_f_income

** 
