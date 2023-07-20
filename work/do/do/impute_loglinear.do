* This file takes the log-linear regression imputation model I developed in "try_improve_model_fit" and applies it to the combined ASEC-and-monthly data, using the "in-sample" ASEC values to predict for the "out of sample" basic.

// Last updated: 6/30/23

** apply the model to the data that needs imputing:

global datapath "/home/c1mep01/Work/madison_cps/data"
global dopath "/home/c1mep01/Work/lfp_proj_sfmp_local/work/do"

*cd "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data"
cd "$datapath"


forvalues x = 2019/2021 {
use impute`x', clear

cd "$dopath"
do data_prep
cd "$datapath"

local varlist = "ftotval fam_agi fearnval htotval"

foreach varname in `varlist'{
	g ln`varname' = ln(`varname')
	replace ln`varname'=0 if `varname'<=0 //  EDIT as of 6/26: Replace the natural log of the variable with 1 if variable<=0
}

** Regressions

regress lnftotval age age2 i.elderly i.hefaminc i.race##i.max_educ i.min_educ i.spousemp i.peafever i.hrhtype c.numadult i.sex##i.marital c.numkid##i.under6 if is_asec==1
predict phat_lnftotval

regress lnfam_agi age age2 i.elderly i.hefaminc i.race##i.max_educ i.min_educ i.spousemp i.peafever i.hrhtype c.numadult i.sex##i.marital c.numkid##i.under6 if is_asec==1
predict phat_lnfam_agi 

regress lnfearnval age age2 i.elderly i.hefaminc i.race##i.max_educ i.min_educ i.spousemp i.peafever i.hrhtype c.numadult i.sex##i.marital c.numkid##i.under6 if is_asec==1
predict phat_lnfearnval

local varlist = "ftotval fam_agi fearnval"
foreach varname in `varlist'{
	clonevar clone_`varname' = `varname'
	clonevar clone_ln`varname' = ln`varname' // Made a copy that I can mess with, preserving original.
	
	replace clone_ln`varname' = phat_ln`varname' if ln`varname'==. // THIS this fills in the original with the imputed values for the ones previously missing, letting the nonmissing ASEC ppl keep their actual values.
	
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

save loglinear_imputed_`x', replace
}


