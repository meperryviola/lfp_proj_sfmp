* this file is a version of the hotdeck_enriquez file which imputes ftotval, agi, and fearnval at the individual level. 
* This version collapses to the household level and then re-attributes those values to the individuals by 1:m merging an imputed file with the pre-imputation file on hrhhid hrhhid2 

// last updated 4/24/2023 by Madison Perry


cd "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data"


forvalues x = 2019/2021 {
use impute`x', clear

order hrhhid hrhhid2 pulineno prtage hrmis yearmth hefaminc prpertyp

* make a unified age variable
g age = prtage if is_basic==1
replace age = a_age if is_asec==1

g hhead_age = age if perrp==40 | perrp==41 // the assumption is that the reference person is the householder


g kid = (age<18)
*g youngkid = (age<6)
g adult = (age>=18)


g hhead_elderly = (hhead_age>64)

* make marital status variables
g marital = (a_maritl<4) if is_asec==1
replace marital = (pemaritl==1 | pemaritl==2) if is_basic==1
replace marital = 0 if marital!=1

g hhead_marital = marital if perrp==40 | perrp==41 // grab the marital status of the reference person. 

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

* make bins for number of adults
g numadult_bin = 1 if numadult==1
replace numadult_bin=2 if numadult==2
replace numadult_bin = 3 if numadult==3
replace numadult_bin = 4 if numadult>=4


* carry AGI across the family
bys ph_seq: egen fam_agi = max(agi)

* collapse basic to the household level
collapse (max) hhead_marital hhead_elderly (mean) numkid_bin hefaminc marsupwt if is_basic==1, by(hrhhid hrhhid2 yearmth)

* collapse ASEC to the household level 


* make sure the directory is the one where the ado file is.
cd "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\do\ctc_and_lfpr"
* weighted hotdeck imputation: use the person weights for ASEC 
wtd_hotdeck ftotval fam_agi fearnval, cells(marital numkid_bin elderly hefaminc) weight(marsupwt) seed(12345)

cd "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data"

save hotdeck_imputed_`x', replace
}