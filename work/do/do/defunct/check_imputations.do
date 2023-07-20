* This code checks certain things about the hotdeck imputations.
* First it attempts to verify that all three imputed values come from the same donor during the hotdeck procedure.
* Then, it computes Root Mean Squared Log Error (RMSLE) for each year. 
 
// last updated 5/8/2023 by Madison Perry

*global dopath "C:\Users\c1mep01\OneDrive - FR Banks\childtaxcredit_proj_sfmp\work\do"
*global datapath "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data"
*global texpath "C:\Users\c1mep01\OneDrive - FR Banks\childtaxcredit_proj_sfmp\documentation\tex"

global datapath "/home/c1mep01/Work/madison_cps/data" // cluster
global texpath "/home/c1mep01/Work/childtaxcredit_proj_sfmp/documentation/tex"

cd "$datapath"

* Check the plausibility of combinaitons of imputed values:
/* in the Hotdeck method, do all three values come from the same donor?
use hotdeck_imputed_2019
order ph_seq p_seq a_lineno yearmth hrhhid hrhhid2 ftotval fam_agi fearnval 
sort ph_seq yearmth hrhhid hrhhid2


browse if ftotval==53200 & fearnval==53200  // should yield at least two observations, one of which being from the ASEC and it does.

* yes I believe that all three values come from the same donor. they are being pulled at the same time. 
*/


* Now, randomly delete the imputed variable values for a sample of the ASEC people for whom we have actual values.
* Run the hotdecking procedure for those people
* compute log squared error measure overall and for each cell. 

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

* make sure the directory is the one where the hotdeck program ado file is.
cd "$dopath"
* weighted hotdeck imputation: use the person weights for ASEC 
wtd_hotdeck p_ftotval p_fam_agi p_fearnval, cells(marital numkid_bin elderly hefaminc) weight(marsupwt) seed(12345)

cd "$datapath"

save test_hotdeck_`x', replace
}

use test_hotdeck_2019, clear
append using test_hotdeck_2020, force
append using test_hotdeck_2021, force


* make differences
g r_ftot = ftotval-p_ftotval
g r_fam_agi = fam_agi - p_fam_agi
g r_fearn = fearnval - p_fearnval

* make log differences
*g r_ftot = ln(ftotval+1)-ln(p_ftotval+1)
*g r_fam_agi = ln(fam_agi+1) - ln(p_fam_agi+1)
*g r_fearn = ln(fearnval+1) - ln(p_fearnval+1)

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

label variable sqe_ftot "Total family income"
label variable sqe_fam_agi "Family AGI"
label variable sqe_fearn "Total family earnings"

local resids = "sqe_ftot sqe_fam_agi sqe_fearn"

cd "$texpath"
table () year if svar==1, stat(mean `resids') nototals nformat(%6.0fc mean)
collect export "hotdeck_rmse.tex", replace


/*cd "$texpath"
collect export rmslerrors.tex

*bys year: sum `resids' if svar==1 & marital==1 & numkid_bin==1 & elderly==0


