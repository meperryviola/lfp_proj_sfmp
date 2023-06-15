* Linearly predicting values for the imputed vars. using the variables that I think are better for doing that.

*global dopath "C:\Users\c1mep01\OneDrive - FR Banks\childtaxcredit_proj_sfmp\work\do"
*global datapath "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data"
*global texpath "C:\Users\c1mep01\OneDrive - FR Banks\childtaxcredit_proj_sfmp\documentation\tex"

global datapath "/home/c1mep01/Work/madison_cps/data" // cluster
global texpath "/home/c1mep01/Work/childtaxcredit_proj_sfmp/documentation/tex"

cd "$datapath"

** check the Multiple Imputuation ones. 
forvalues x = 2019/2021 {
use impute`x', clear
keep if is_asec==1

order hrhhid hrhhid2 pulineno prtage hrmis yearmth hefaminc prpertyp

* make a unified age variable
g age = prtage if is_basic==1
replace age = a_age if is_asec==1

* make a unified sex variable
g sex = pesex if is_basic==1
replace sex = a_sex if is_asec==1


g kid = (age<18)
g adult = (age>=18)
g elderly = (age>64)

* make marital status variables
g marital = (a_maritl<4) if is_asec==1
replace marital = 0 if marital!=1

* make count kids variable - note this is number of kids in the same household as the person.
bys year ph_seq: egen numkid = sum(kid) if is_asec==1
bys year ph_seq: egen numadult = sum(adult) if is_asec==1

* make number of kids bins
g numkid_bin = 0 if numkid==0
replace numkid_bin = 1 if numkid==1
replace numkid_bin = 2 if numkid==2 | numkid==3
replace numkid_bin = 4 if numkid>=4

g numadult_bin = 1 if numadult==1
replace numadult_bin=2 if numadult==2
replace numadult_bin=3 if numadult==3
replace numadult_bin=4 if numadult>=4

** simplified race variable
g race = prdtrace if is_asec==1
replace race = ptdtrace if is_basic==1
replace race = 1 if race==1
replace race = 2 if race==2
replace race = 3 if race>2 & race<.

** simplified educational attainment variable
g educ = a_hga if is_asec==1
replace educ = peeduca if is_basic==1
replace educ = 1 if educ<39
replace educ = 2 if educ==39
replace educ = 3 if educ>=40 & educ<43
replace educ = 4 if educ==43 
replace educ = 5 if educ>43 & educ<.

* make variables that capture spousal characteristics
* we are ignoring subfamilies right now. 

* first, mark primary and secondary person in the monthly.
g refperson = (prfamrel==1)
replace refperson = 2 if (prfamrel==2)
* do the same thing for the ASEC records
bys ph_seq yearmth: replace refperson = 1 if p_seq==fheadidx & is_asec==1
bys ph_seq yearmth: replace refperson = 2 if p_seq==fspouidx & is_asec==1


g emp_prim = ((pemlr==1 | pemlr==2) & refperson==1)
bys hrhhid hrhhid2 yearmth: egen emp_prim1 = max(emp_prim) if is_basic==1
bys ph_seq yearmth: egen emp_prim2 = max(emp_prim) if is_asec==1

g emp_sec = ((pemlr==1 | pemlr==2) & refperson==2) 
bys hrhhid hrhhid2 yearmth: egen emp_sec1 = max(emp_sec) if is_basic==1
bys ph_seq yearmth: egen emp_sec2 = max(emp_sec) if is_asec==1

g spousemp = .
replace spousemp = emp_prim1 if refperson==2 & is_basic==1 // put the primary person's employment status in the secondary person's row.
replace spousemp = emp_prim2 if refperson==2 & is_asec==1
replace spousemp = emp_sec1 if refperson==1 & is_basic==1 // vice versa
replace spousemp = emp_sec2 if refperson==1 & is_asec==1
replace spousemp=0 if marital==0
* but, as we see later, inclusion of this variable in the regressions weakens the fit, even though it's significant.


* carry AGI across the family - initially the only people with agi values were the reference people for each family
bys ph_seq: egen fam_agi = max(agi)

* drop the observations of kids.
drop if age<18


** duplicate the variables into the ones we're gonna delete actual values from
g p_ftotval = ftotval
g p_fam_agi = fam_agi
g p_fearnval = fearnval


set seed 4409
* pull a random sample (half) of the asec and delete the actual values for the variables we will be imputing
splitsample, generate(svar) values(0 1)
replace p_ftotval = . if svar==1
replace p_fam_agi= . if svar==1
replace p_fearnval= . if svar==1



* Here I'm messing with the model specifications and seeing what the fit looks like:
regress ftotval i.race i.educ i.sex i.hefaminc c.numadult_bin c.numkid_bin##i.marital [weight=marsupwt]
predict phat_ftotval

regress fam_agi i.race i.educ i.sex i.hefaminc c.numadult_bin c.numkid_bin##i.marital [weight=marsupwt]
predict phat_fam_agi 

regress fearnval i.race i.educ i.sex i.hefaminc c.numkid_bin##i.marital [weight=marsupwt]
predict phat_fearnval



/*
bys marital: regress ftotval fam_agi fearnval i.race i.educ i.sex i.hefaminc c.numadult_bin c.numkid_bin i.spousemp
bys marital: regress fam_agi fearnval ftotval i.race i.educ i.sex i.hefaminc c.numkid_bin i.spousemp
by marital: regress fearnval ftotval agi i.race i.educ i.sex i.hefaminc c.numkid_bin i.spousemp

reg p_fam_agi marital numkid_bin elderly hefaminc 

reg p_fearnval marital numkid_bin elderly hefaminc [weight=marsupwt]
*/

cd "$datapath"

save test_linear2_`x', replace
}

cd "$datapath"
use test_linear2_2019, clear
append using test_linear2_2020, force
append using test_linear2_2021, force


* make differences
g r_ftot = ftotval-phat_ftotval
g r_fam_agi = fam_agi - phat_fam_agi
g r_fearn = fearnval - phat_fearnval

* make log differences
*g r_ftot = ln(ftotval)-ln(phat_ftotval)
*g r_fam_agi = ln(fam_agi) - ln(phat_fam_agi)
*g r_fearn = ln(fearnval) - ln(phat_fearnval)

g r_ftot2 = r_ftot^2
g r_fam_agi2 = r_fam_agi^2
g r_fearn2 = r_fearn^2

* count the number of imputed obs for each year - this is the denominator
bys year: egen count_preds = sum(svar==1)
 
* sum the squared log differences
bys year: g sum_rftot2 = sum(r_ftot2) if svar==1 
bys year: g sum_rfam_agi2 = sum(r_fam_agi2) if svar==1 
bys year: g sum_rfearn2 = sum(r_fearn2) if svar==1

*divide 
g error_ftot = (sum_rftot2/count_preds)
g error_fam_agi = (sum_rfam_agi2/count_preds)
g error_fearn = (sum_rfearn2/count_preds)

* square root
g sqe_ftot = sqrt(error_ftot)
g sqe_fam_agi = sqrt(error_fam_agi)
g sqe_fearn = sqrt(error_fearn)




local resids = "sqe_ftot sqe_fam_agi sqe_fearn"

bys year: sum `resids' if svar==1

label variable sqe_ftot "Total family income"
label variable sqe_fam_agi "Family AGI"
label variable sqe_fearn "Total family earnings"

cd "$texpath"

table () year if svar==1, stat(mean `resids') nototals nformat(%6.0fc)
collect export "linear2_rmse.tex", replace

