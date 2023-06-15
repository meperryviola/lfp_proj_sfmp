// Last edited 6/14/23

global datapath "/home/c1mep01/Work/madison_cps/data"
global logpath "/home/c1mep01/Work/childtaxcredit_proj_sfmp/work/logs"
global texpath "/home/c1mep01/Work/childtaxcredit_proj_sfmp/work/tex"
*cd "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data"
cd "$datapath"


use loglinear_imputed_2019, clear
append using loglinear_imputed_2020, force
append using loglinear_imputed_2021, force


*keep if is_basic==1
*keep if is_asec==1

* fix the yearmth variable for ASEC observations:
forvalues x = 2020/2022 {
	replace yearmth = `x'03 if is_asec==1 & year==`x'
}


* fix the year and month components into a time variable

replace year = 2019 if yearmth<202001 // somehow year got messed up for 2019. I don't know where.

g time = ym(year, month)
format time %tm

replace LF = LF*100


***** For ASEC *********

*** fixed categories ***
** current objective is to bring (B) closer to (A).
cd "$texpath"
table (fixed1_cat) (year) [fweight==marsupwt] if is_asec==1 & unlog_phat_ftotval!=., stat(mean LF) nformat(%5.1fc) // (A)
collect export "prime_LFP_actual_ftot.tex", tableonly replace

table (fixed2_cat) (year) [fweight==marsupwt] if is_asec==1 & unlog_phat_ftotval!=., stat(mean LF) nformat(%5.1fc) // (B)
collect export "prime_LFP_predicted_ftot.tex", tableonly replace


** tabulate proportional split by fixed category:
table () (year) [fweight==marsupwt] if is_asec==1, stat(fvpercent fixed1_cat) nformat(%12.1fc) 
collect export "actual_fixcat_share.tex", tableonly replace

table () (year) [fweight==marsupwt] if is_asec==1, stat(fvpercent fixed2_cat) nformat(%12.1fc)
collect export "p_fixcat_share.tex", tableonly replace


***********************

*** Quintiles ***
** LFPR 
table (actual_qtile) (year) [fweight==marsupwt] if is_asec==1 & unlog_phat_ftotval!=., stat(mean LF) nformat(%5.1fc) // actual qtile
collect export "prime_LFP_actualqtile_ftot.tex", tableonly replace

table (p_qtile) (year) [fweight==marsupwt] if is_asec==1 & unlog_phat_ftotval!=., stat(mean LF) nformat(%5.1fc) // predicted qtile
collect export "prime_LFP_predictedqtile_ftot.tex", tableonly replace


** minimum incomes by quintile 
table (actual_qtile) (year) [fweight==marsupwt] if is_asec==1, stat(min unlog_ftotval) nformat(%12.0fc) nototals
collect export "actualqtile_min.tex", tableonly replace

table (p_qtile) (year) [fweight==marsupwt] if is_asec==1, stat(min unlog_phat_ftotval) nformat(%12.0fc) nototals
collect export "predictedqtile_min.tex", tableonly replace
******************



** Investigating why the ASEC actual and ASEC with predicted values yield such different LFPRs.
** This plots the distribution of actual and predicted
twoway (hist unlog_ftotval if unlog_ftotval<200000, bcolor(blue%20) width(10000)) (hist unlog_phat_ftotval if unlog_phat_ftotval<200000, bcolor(red%20) width(10000))


*********** For Basic *****************

table (fixed2_cat) (year) [fweight==pwcmpwgt] if month==3 & is_basic==1, stat(mean LF) nformat(%5.1fc) // show for march only
collect export "LFP_basic_march.tex", tableonly replace


table (p_qtile) (year) [fweight==pwcmpwgt] if month==3 & is_basic==1 & unlog_phat_ftotval!=., stat(mean LF) nformat(%5.1fc) 
collect export "LFP_basicqtile_march.tex", tableonly replace


table (fixed2_cat) (year) [fweight==pwcmpwgt], stat(mean LF) nformat(%5.1fc) // annual average over all months

* grab the mean LFPR monthly for each income category
forvalues x = 1/5 {
	bys time: egen cat`x' = mean(LF) if fixed2_cat==`x' & is_basic==1 & unlog_phat_ftotval!=.
	bys time: egen qtile`x' = mean(LF) if p_qtile==`x' & is_basic==1 & unlog_phat_ftotval!=.
	
}
twoway (line cat1 time if time<%tm(2023m1)) (line cat2 time) (line cat3 time) (line cat4 time) (line cat5 time)

twoway (line qtile1 time if time<tm(2023m1)) (line qtile2 time if time<tm(2023m1)) (line qtile3 time if time<tm(2023m1)) (line qtile4 time if time<tm(2023m1)) (line qtile5 time if time<tm(2023m1)) 


cd "$texpath"
table (year month) (p_qtile) [fweight==pwcmpwgt], stat(mean LF) nformat(%5.1fc) nototals
collect export "LFP_monthly.tex", tableonly replace

**
