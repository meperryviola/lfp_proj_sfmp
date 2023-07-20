** tabulate and plot LFPR for various groups
global datapath "/home/c1mep01/Work/madison_cps/data"
global logpath "/home/c1mep01/Work/childtaxcredit_proj_sfmp/work/logs"
global texpath "/home/c1mep01/Work/childtaxcredit_proj_sfmp/work/tex"
*cd "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data"
cd "$datapath"


/*
** this needs to be run after impute_loglinear.do

use loglinear_imputed_2019, clear
append using loglinear_imputed_2020, force
append using loglinear_imputed_2021, force
*/


* fix the yearmth variable for ASEC observations:
forvalues x = 2020/2022 {
	replace yearmth = `x'03 if is_asec==1 & year==`x'
}

* fix the year and month components into a time variable

replace year = 2019 if yearmth<202001 // somehow year got messed up for 2019. I don't know where.

g time = ym(year, month)
format time %tm

replace LF = LF*100


drop if age<15
drop if pemlr==0

**************** tabulate for full sample ************************************

** This takes the ASEC people we have actual values for and tabulates the LFPRs when people are sorted by actual income and compares to the LFPRs when people are sorted by predicted incomes 

*** fixed categories ***
cd "$texpath"
table (fixed1_cat) (year) [fweight==marsupwt] if is_asec==1 & unlog_phat_ftotval!=., stat(mean LF) nformat(%5.1fc) // (A)
collect export "LFP_actual_ftot.tex", tableonly replace

table (fixed2_cat) (year) [fweight==marsupwt] if is_asec==1 & unlog_phat_ftotval!=., stat(mean LF) nformat(%5.1fc) // (B)
collect export "LFP_predicted_ftot.tex", tableonly replace

*** Quintiles ***
table (actual_qtile) (year) [fweight==marsupwt] if is_asec==1 & unlog_phat_ftotval!=., stat(mean LF) nformat(%5.1fc) // actual qtile
collect export "LFP_actualqtile_ftot.tex", tableonly replace

table (p_qtile) (year) [fweight==marsupwt] if is_asec==1 & unlog_phat_ftotval!=., stat(mean LF) nformat(%5.1fc) // predicted qtile
collect export "LFP_predictedqtile_ftot.tex", tableonly replace
*******************************************************************************


********************* tabulate for people aged 25-64 only ****************************
preserve
keep if age>24 & age<64

*** fixed categories ***
table (fixed1_cat) (year) [fweight==marsupwt] if is_asec==1 & unlog_phat_ftotval!=., stat(mean LF) nformat(%5.1fc) // (A)
collect export "LFP_actual_ftot.tex", tableonly replace

table (fixed2_cat) (year) [fweight==marsupwt] if is_asec==1 & unlog_phat_ftotval!=., stat(mean LF) nformat(%5.1fc) // (B)
collect export "LFP_predicted_ftot.tex", tableonly replace

*** Quintiles ***
table (actual_qtile) (year) [fweight==marsupwt] if is_asec==1 & unlog_phat_ftotval!=., stat(mean LF) nformat(%5.1fc) // actual qtile
collect export "LFP_actualqtile_ftot.tex", tableonly replace

table (p_qtile) (year) [fweight==marsupwt] if is_asec==1 & unlog_phat_ftotval!=., stat(mean LF) nformat(%5.1fc) // predicted qtile
collect export "LFP_predictedqtile_ftot.tex", tableonly replace

restore
**************************************************************************************


******** tabulate, excluding cases where all persons in HH are retirees *******************
preserve
drop if h_numper==2 & sumretired==2 & is_asec==1 
drop if hrnumhou==sumretired & is_basic==1 

*** fixed categories ***
table (fixed1_cat) (year) [fweight==marsupwt] if is_asec==1 & unlog_phat_ftotval!=., stat(mean LF) nformat(%5.1fc) // (A)
collect export "excl_LFP_actual_ftot.tex", tableonly replace

table (fixed2_cat) (year) [fweight==marsupwt] if is_asec==1 & unlog_phat_ftotval!=., stat(mean LF) nformat(%5.1fc) // (B)
collect export "excl_LFP_predicted_ftot.tex", tableonly replace

*** Quintiles ***
table (actual_qtile) (year) [fweight==marsupwt] if is_asec==1 & unlog_phat_ftotval!=., stat(mean LF) nformat(%5.1fc) // actual qtile
collect export "excl_LFP_actualqtile_ftot.tex", tableonly replace

table (p_qtile) (year) [fweight==marsupwt] if is_asec==1 & unlog_phat_ftotval!=., stat(mean LF) nformat(%5.1fc) // predicted qtile
collect export "excl_LFP_predictedqtile_ftot.tex", tableonly replace

restore
**************************************************************************************










*********** For Basic *****************
** for March using monthly data only - Fixed category
table (fixed2_cat) (year) [fweight==pwcmpwgt] if month==3 & is_basic==1, stat(mean LF) nformat(%5.1fc) // show for march only
collect export "LFP_basic_march.tex", tableonly replace

* same, but quintiles
table (p_qtile) (year) [fweight==pwcmpwgt] if month==3 & is_basic==1 & unlog_phat_ftotval!=., stat(mean LF) nformat(%5.1fc) 
collect export "LFP_basicqtile_march.tex", tableonly replace

