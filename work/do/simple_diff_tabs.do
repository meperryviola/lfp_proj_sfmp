* makes cross tabulations of mean LF participation by income qtiles

// Last edited 5/15/23

global datapath "/home/c1mep01/Work/madison_cps/data"
global logpath "/home/c1mep01/Work/childtaxcredit_proj_sfmp/work/logs"

*cd "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data"
cd "$datapath"


use loglinear_imputed_2019, clear
append using loglinear_imputed_2020, force
append using loglinear_imputed_2021, force

*save linear2_imputed.dta, replace


**** Basic comparison of LFP by income, pre- and post-July, with and without kids

keep if is_basic==1
keep if year==2021


* make income category variable
g income_cat=.
local x = 202101
while `x' <= 202112{
	xtile income_cat_`x' = unlog_ftotval if yearmth==`x', nquantiles(5) // assign quintiles monthly
	replace income_cat = income_cat_`x' if yearmth==`x' // put quintile markers in a unified variable
	local x = `x' + 1
if (`x'-13)/100 == int((`x'-13)/100) {
    local x = `x' + 88
    }

}

tab income_cat

table income_cat (), statistic(min unlog_ftotval) statistic(mean unlog_ftotval)


g advCTC = (yearmth>=202107)

table income_cat (yearmth), statistic(mean LF) nformat(%5.2fc)

table income_cat advCTC, stat(mean LF) nformat(%5.2fc) // overall

table income_cat advCTC if numkid>=1, stat(mean LF) nformat(%5.2fc) // parents

table income_cat advCTC if numkid>=1 & marital==1, stat(mean LF) nformat(%5.2fc) // married parents

table income_cat advCTC if numkid>=1 & marital==0, stat(mean LF) nformat(%5.2fc) // unmarried parents

table income_cat advCTC if numkid>=1 & sex==2, stat(mean LF) nformat(%5.2fc) // women with kids

** cross tabulations
label define numkid_label 0 "None" 1 "1" 2 "2-3" 4 "4+"
label values numkid_bin numkid_label
label variable numkid_bin "Number of kids"

label define ctclab 0 "Pre-July" 1 "Post-July"
label values advCTC ctclab 
label variable advCTC "2021"

table (numkid_bin) (advCTC) (income_cat), stat(mean LF) nformat(%5.2fc) nototals
cd "$logpath"
collect export "simpledif_byinccat.tex", tableonly replace

* limit to prime age 
table (numkid_bin) (advCTC) (income_cat) if age>=25 & age<=54, stat(mean LF) nformat(%5.2fc) nototals

* what if prime age and married
table (numkid_bin) (advCTC) (income_cat) if age>=25 & age<=54 & marital==1, stat(mean LF) nformat(%5.2fc) nototals

* what if prime age and married and a woman
table (numkid_bin) (advCTC) (income_cat) if age>=25 & age<=54 & marital==1 & sex==2, stat(mean LF) nformat(%5.2fc) nototals


** explore intensive margin labor supply 
table (numkid_bin) (advCTC) (income_cat) if age>=25 & age<=54 & marital==1 & sex==2, stat(mean ) nformat(%5.2fc) nototals



