* benchmark the hotdeck RMSLEs by doing what you'd do if you were just linearly predicting values for the imputed vars.

*global dopath "C:\Users\c1mep01\OneDrive - FR Banks\childtaxcredit_proj_sfmp\work\do"
*global datapath "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data"
*global texpath "C:\Users\c1mep01\OneDrive - FR Banks\childtaxcredit_proj_sfmp\documentation\tex"

global datapath "/home/c1mep01/Work/madison_cps/data" // cluster
global texpath "/home/c1mep01/Work/childtaxcredit_proj_sfmp/documentation/tex"

cd "$datapath"
 
forvalues x = 2019/2021 {
use impute`x', clear
keep if is_asec==1


* use Enriquez et al's hotdeck imputation method to fill in values
order hrhhid hrhhid2 pulineno prtage hrmis yearmth hefaminc prpertyp

* make a unified age variable
g age = prtage if is_basic==1
replace age = a_age if is_asec==1

* make a unified sex variable
g sex = pesex if is_basic==1
replace sex = a_sex if is_asec==1


g kid = (age<18)
*g adult = (age>=18)
g elderly = (age>64)

* make marital status variables
g marital = (a_maritl<4) if is_asec==1
replace marital = 0 if marital!=1

* make count kids variable - note this is number of kids in the same household as the person.
bys year ph_seq: egen numkid = sum(kid) if is_asec==1
*bys year ph_seq: egen numadult = sum(adult) if is_asec==1

* make number of kids bins
g numkid_bin = 0 if numkid==0
replace numkid_bin = 1 if numkid==1
replace numkid_bin = 2 if numkid==2 | numkid==3
replace numkid_bin = 4 if numkid>=4

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

reg p_ftotval marital numkid_bin elderly hefaminc [weight=marsupwt]
predict phat_ftotval

reg p_fam_agi marital numkid_bin elderly hefaminc [weight=marsupwt]
predict phat_fam_agi 

reg p_fearnval marital numkid_bin elderly hefaminc [weight=marsupwt]
predict phat_fearnval

cd "$datapath"

save test_linear_`x', replace
}


use test_linear_2019, clear
append using test_linear_2020, force
append using test_linear_2021, force


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
collect export "linear_rmse.tex", replace


