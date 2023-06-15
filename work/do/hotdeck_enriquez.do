* From the 2019-2022 ASECs, make bins representing Marriage status, # children, and elderly status. 
* Impute ftotval agi and fearnval conditional on those demographic categories and HEFAMINC category.
* This is the weighted hotdeck method used in Enriquez etc. It does not preserve spousal pairs or incorporate spousal characteristics. 

// last updated 5/9/2023 by Madison Perry

global datapath "/home/c1mep01/Work/madison_cps/data"
global dopath "/home/c1mep01/Work/childtaxcredit_proj_sfmp/work/do"

*cd "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data"
cd "$datapath"

forvalues x = 2019/2021 {
use impute`x', clear

order hrhhid hrhhid2 pulineno prtage hrmis yearmth hefaminc prpertyp

* make a unified age variable
g age = prtage if is_basic==1
replace age = a_age if is_asec==1

* make a unified sex variable
g sex = pesex if is_basic==1
replace sex = a_sex if is_asec==1


g kid = (age<18)
*g youngkid = (age<6)
g adult = (age>=18)
g elderly = (age>64)

* make marital status variables
g marital = (a_maritl<4) if is_asec==1
replace marital = (pemaritl==1 | pemaritl==2) if is_basic==1
replace marital = 0 if marital!=1

* make count kids variable - note this is number of kids in the same household as the person.
bys year ph_seq: egen numkid = sum(kid) if is_asec==1
bys year ph_seq: egen numadult = sum(adult) if is_asec==1

bys hrhhid hrhhid2 yearmth: replace numkid = sum(kid) if is_basic==1
bys hrhhid hrhhid2 yearmth: replace numadult = sum(adult) if is_basic==1

* make number of kids bins
g numkid_bin = 0 if numkid==0
replace numkid_bin = 1 if numkid==1
replace numkid_bin = 2 if numkid==2 | numkid==3
replace numkid_bin = 4 if numkid>=4

* carry AGI across the family
bys ph_seq: egen fam_agi = max(agi)

* pull out the observations of the kids themselves*
preserve 
keep if age<18
save kids_obs_preimpute`x', replace
restore
drop if age<18


local varlist = "ftotval fam_agi fearnval"

foreach varname in `varlist'{
	clonevar clone_`varname' = `varname'
}


* make sure the directory is the one where the ado file is.
*cd "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\do\ctc_and_lfpr"
cd "$dopath"
* weighted hotdeck imputation: use the person weights for ASEC 
wtd_hotdeck ftotval fam_agi fearnval, cells(marital numkid_bin elderly hefaminc) weight(marsupwt) seed(12345)

cd "$datapath"


save hotdeck_imputed_`x', replace
}

/*
use hotdeck_imputed_2019, clear
append using hotdeck_imputed_2020, force
append using hotdeck_imputed_2021, force


drop if is_asec==1
sort hrhhid hrhhid2 yearmth
save EJT_replication, replace
