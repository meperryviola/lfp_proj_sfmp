*** Test imputation of FTOTVAL and HTOTVAL using individual-level characteristics

* keeps only the ASEC observations, takes a subset (half) of them as in-sample and pretends like the rest are out-of-sample
* predicts for the "out-of-sample"
* outputs the predicted values and the actual values for the "out-of-sample"

* Computes a quality of prediction statistic

global datapath "/home/c1mep01/Work/madison_cps/data"
global dopath "/home/c1mep01/Work/lfp_proj_sfmp_local/work/do"
*cd "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data"
cd "$datapath"


forvalues x = 2019/2021 {
use impute`x', clear

keep if is_asec==1

* pull a random sample (half) of the asec 
set seed 4409
splitsample, generate(svar) values(0 1)

cd "$dopath"
do data_prep
cd "$datapath"

** use the log of the income variables
local varlist = "ftotval fam_agi fearnval htotval"

foreach varname in `varlist'{
	g ln`varname' = ln(`varname')
	replace ln`varname'=0 if `varname'<=0 //  EDIT as of 6/26: Replace the natural log of the variable with 1 if variable<=0

* duplicate the variables and delete the actual values for the "out-of-sample" half.
	g s_ln`varname' = ln`varname'
	replace s_ln`varname' = . if svar==1 // now the LHS var will be s_ln`varname'

	regress s_ln`varname' age age2 i.elderly i.hefaminc i.race##i.max_educ i.min_educ i.spousemp i.peafever i.hrhtype c.numadult i.sex##i.marital c.numkid##i.under6 if is_asec==1
	predict phat_s_ln`varname'
	
	g unlog_`varname' = exp(ln`varname') // this preserves the missingness for certain asec ppl.
	
	g unlog_phat_s_`varname' = exp(phat_s_ln`varname') // This holds the predicted values for everybody, even ASEC.

}

save test_indiv_imp_`x', replace
}

use test_indiv_imp_2019, clear
append using test_indiv_imp_2020, force
append using test_indiv_imp_2021, force


* count the number of imputed obs for each year - this is the denominator
bys year: egen count_preds = sum(svar==1)

local varlist = "ftotval fam_agi fearnval htotval"

foreach varname in `varlist'{
* make differences
g r_`varname' = unlog_`varname'- unlog_phat_s_`varname'

* make log differences
*g r_ftot = ln(ftotval)-ln(phat_ftotval)
*g r_fam_agi = ln(fam_agi) - ln(phat_fam_agi)
*g r_fearn = ln(fearnval) - ln(phat_fearnval)

g r_`varname'2 = r_`varname'^2
 
* sum the squared log differences
bys year: g sum_r`varname'2 = sum(r_`varname'2) if svar==1 

*divide 
g error_`varname' = (sum_r`varname'2/count_preds)

* square root
g sqe_`varname' = sqrt(error_`varname')

}

local resids = "sqe_ftotval sqe_fam_agi sqe_fearnval sqe_htotval"

bys year: sum `resids' if svar==1

table () year if svar==1, stat(mean `resids') nototals nformat(%6.0fc)
