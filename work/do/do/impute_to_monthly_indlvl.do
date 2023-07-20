*  put together the ASEC and monthly

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

** Regressions and predictions - individual-level
forvalues x = 2019/2022 {
regress lnftotval age age2 i.elderly i.hefaminc i.race##i.max_educ i.min_educ i.vetstat i.hrhtype c.numadult i.sex##i.marital c.numkid##i.under6 if is_asec==1 & year==`x'
predict phat_lnftotval_`x' if year==`x'

regress lnfam_agi age age2 i.elderly i.hefaminc i.race##i.max_educ i.min_educ i.vetstat i.hrhtype c.numadult i.sex##i.marital c.numkid##i.under6 if is_asec==1 & year==`x'
predict phat_lnfam_agi_`x' if year==`x'


regress lnfearnval age age2 i.elderly i.hefaminc i.race##i.max_educ i.min_educ i.vetstat i.hrhtype c.numadult i.sex##i.marital c.numkid##i.under6 if is_asec==1 & year==`x'
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

** This portion is from "tabulate_LFPR".
******* check the labor force participation by income quintile 
 
gen E = (pemlr<=2) 
gen U = (pemlr>=3 & pemlr<=4)
gen N = (pemlr>=5)
gen pop = (E==1 | U == 1 | N == 1)
gen LF = (E==1 | U == 1)


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


** Fixed categories 
table (fixed1_cat) (year) [fweight==marsupwt] if is_asec==1 & unlog_phat_ftotval!=., stat(mean LF) nformat(%5.1fc) // (A)

table (fixed2_cat) (year) [fweight==marsupwt] if is_asec==1 & unlog_phat_ftotval!=., stat(mean LF) nformat(%5.1fc) // (B)



