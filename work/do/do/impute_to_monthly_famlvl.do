**  put together the ASEC and monthly
* sort by year


global datapath "/home/c1mep01/Work/madison_cps/data"
global dopath "/home/c1mep01/Work/lfp_proj_sfmp_local/work/do"

*cd "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data"
cd "$datapath"

* append together the two files, not collapsed
use basics_inc_19to22, clear
append using asec_20to22_inc, force

* impute 
local varlist = "ftotval fam_agi fearnval htotval"

foreach varname in `varlist'{
	g ln`varname' = ln(`varname')
	replace ln`varname'=0 if `varname'<=0 //  EDIT as of 6/26: Replace the natural log of the variable with 1 if variable<=0
}

** Regressions and predictions
forvalues x = 2019/2022 {
regress lnftotval c.mean_age##i.max_educ c.mean_age2##i.min_educ c.share_elderly c.numadult##i.hefaminc i.hrhtype##c.share_married c.share_black##i.gestfips c.share_hisp c.share_immg c.kid_ratio c.share_under6  if is_asec==1 & year==`x'

predict phat_lnftotval_`x' if year==`x'

regress lnfam_agi c.mean_age##i.max_educ c.mean_age2##i.min_educ c.share_elderly c.numadult##i.hefaminc i.hrhtype##c.share_married c.share_black##i.gestfips c.share_hisp c.share_immg c.kid_ratio c.share_under6  if is_asec==1 & year==`x'
predict phat_lnfam_agi_`x' if year==`x'


regress lnfearnval c.mean_age##i.max_educ c.mean_age2##i.min_educ c.share_elderly c.numadult##i.hefaminc i.hrhtype##c.share_married c.share_black##i.gestfips c.share_hisp c.share_immg c.kid_ratio c.share_under6  if is_asec==1 & year==`x'
predict phat_lnfearnval_`x' if year==`x'

}

** consolidate into single variables 
local varlist = "ftotval fam_agi fearnval"
foreach varname in `varlist' {
	g phat_ln`varname' =.
	forvalues x = 2019/2022 {
		replace phat_ln`varname' = phat_ln`varname'_`x' if year==`x'
	}
}

** exponentiate the variables
local varlist = "ftotval fam_agi fearnval"
foreach varname in `varlist'{
	clonevar clone_`varname' = `varname'
	clonevar clone_ln`varname' = ln`varname' // Made a copy that I can mess with, preserving original.
	
	replace clone_ln`varname' = phat_ln`varname' if ln`varname'==. // THIS fills in the original with the imputed values for the ones previously missing, letting the nonmissing ASEC ppl keep their actual values.
	
	g unlog_`varname' = exp(ln`varname') // this preserves the missingness for certain asec ppl.
	g unlog_fill`varname' = exp(clone_ln`varname') // keeps originals, fills for the missing
	g unlog_phat_`varname' = exp(phat_ln`varname') // This holds the predicted values for everybody, even ASEC.
}

replace unlog_ftotval=25000.00 if ftotval==25000.00 // this is the only time when the logging and exponentiation causes a rounding error that falls on a consequential boundary

** Fixed categories
recode unlog_phat_ftotval (0/24999.999 = 1) (25000.00/49999.99 = 2) (50000/99999.99 = 3) (100000/149999.99 = 4) (150000/. = 5), generate(fixed2_cat)

recode unlog_ftotval (0/24999.999 = 1) (25000.00/49999.99 = 2) (50000/99999.99 = 3) (100000/149999.99 = 4) (150000/. = 5), generate(fixed1_cat)

xtile p_qtile = unlog_phat_ftotval, nquantiles(5)
xtile actual_qtile = unlog_ftotval, nquantiles(5)
/*
* re-attribute the imputed values to individuals by merging on the raw files using the identifying info 1:m merge.
preserve
keep if is_basic==1
merge 1:m yearmth hrhhid hrhhid2 famunit using basics_inc_19to22
drop _merge
save basics_imp_19to22, replace
restore

keep if is_asec==1
merge 1:m year ph_seq pf_seq using asec_20to22_inc
drop _merge
save asec_imp_20to22, replace 

append using basics_imp_19to22, force // This holds the asec and basic individual observations and everyone has their predicted family income values attributed to them.
*/
*********** 


** check how well the predicted values approximate the actual ones for the ASEC observations


* count the number of imputed obs for each year - this is the denominator
bys year: egen count_preds = sum(is_asec==1)

local varlist = "ftotval fam_agi fearnval"

* compute Root mean square errors
foreach varname in `varlist'{
* make differences
g r_`varname' = unlog_`varname'- unlog_phat_`varname'

g r_`varname'2 = r_`varname'^2
 
* sum the squared log differences
bys year: g sum_r`varname'2 = sum(r_`varname'2) if is_asec==1 

*divide 
g error_`varname' = (sum_r`varname'2/count_preds)

* square root
g sqe_`varname' = sqrt(error_`varname')

}

local resids = "sqe_ftotval sqe_fam_agi sqe_fearnval"

bys year: sum `resids' if is_asec==1

table () year if is_asec==1, stat(mean `resids') nototals nformat(%6.0fc)


******* check the labor force participation by income quintile 

*drop the observations of kids.
drop if age<15
drop if pemlr==0

** make household level labor force participation rate. 
gen E = (pemlr<=2) 
gen U = (pemlr>=3 & pemlr<=4)
gen N = (pemlr>=5)
gen pop = (E==1 | U == 1 | N == 1)
gen LF = (E==1 | U == 1)

replace LF = LF*100

table (fixed1_cat) (year) [fweight=marsupwt] if is_asec==1 & unlog_phat_ftotval!=., stat(mean LF) nformat(%5.1fc) // (A)

table (fixed2_cat) (year) [fweight=marsupwt] if is_asec==1 & unlog_phat_ftotval!=., stat(mean LF) nformat(%5.1fc) // (B)

*** Quintiles ***
table (actual_qtile) (year) [fweight=marsupwt] if is_asec==1 & unlog_phat_ftotval!=., stat(mean LF) nformat(%5.1fc)

table (p_qtile) (year) [fweight=marsupwt] if is_asec==1 & unlog_phat_ftotval!=., stat(mean LF) nformat(%5.1fc) // predicted qtile
