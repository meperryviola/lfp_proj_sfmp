** Data preparation - monthly

** this technique comes from Enriquez replication file. smart way of narrowing what variables I keep.
global cpsvars 			"hryear4 year month prpertyp pesex"
global agevars 			"prtage prtage"
global racevars			"ptdtrace pehspnon penatvty"
global educvars			"peeduca"
global cpssvysetvars		"gtcbsasz gestfips"
	
use $cpsvars $agevars $educvars $racevars $cpssvysetvars gestfips /// 
	yearmth prchld peafever pesex pemlr hrhhid hrhhid2 perrp ///
	pemaritl pulineno prpertyp prnmchld ///
	hefaminc pwlgwgt pwcmpwgt pwsswgt pehractt pehruslt gediv ///
	using basics_raw_19to22, clear


g famunit = 1 if perrp<53
replace famunit=2 if perrp>=54 & perrp<.

g is_basic=1
*** variable creation and wrangling prior to imputation

* make a unified age variable - want age of householder
g age = prtage

drop if age==.

g kid = (age<18)
g adult = (age>=18)
g elderly = (age>64)

bys yearmth hrhhid hrhhid2 famunit: egen numkid = sum(kid)
bys yearmth hrhhid hrhhid2 famunit: egen numadult = sum(adult)

* make number of kids bins
g numkid_bin = 0 if numkid==0
replace numkid_bin = 1 if numkid==1
replace numkid_bin = 2 if numkid==2 | numkid==3
replace numkid_bin = 4 if numkid>=4

g numadult_bin = 1 if numadult==1
replace numadult_bin=2 if numadult==2
replace numadult_bin=3 if numadult==3
replace numadult_bin=4 if numadult>=4


* indicate if age of youngest child is less than 6
g under6 = (age<6)

* count number of retired people in household
g retired = (pemlr==5)

bys hrhhid hrhhid2 yearmth famunit: egen sumretired = sum(retired)

** simplified educational attainment variable
g educ = peeduca if is_basic==1
replace educ = 1 if educ<39
replace educ = 2 if educ==39
replace educ = 3 if educ>=40 & educ<43
replace educ = 4 if educ==43 
replace educ = 5 if educ>43 & educ<.
label define edlabel 1 "LTHS" 2 "HS grad" 3 "some coll" 4 "Bachelors" 5 "Adv deg"
label values educ edlabel

bys yearmth hrhhid hrhhid2 famunit: egen max_educ = max(educ)

label values max_educ edlabel

bys yearmth hrhhid hrhhid2 famunit: egen min_educ = min(educ)
label values min_educ edlabel

********

* make a reference person for each family.
bys yearmth hrhhid hrhhid2 famunit: egen min_lineno = min(pulineno)
g famhead = (pulineno==min_lineno) // the family head is the person with the first roster line number in the family. 

** age of family head
g age_fh = age if famhead==1


* make a unified sex variable
g sex = pesex if is_basic==1

* want sex of family head
g sex_fh = sex if famhead==1


* make marital status variables - want marital status of householder 
g marital = (pemaritl<4) 
replace marital = 0 if marital!=1
g marital_fh = marital if famhead==1 

** simplified race variable - want race of householder
g race = ptdtrace
replace race = 1 if race==1
replace race = 2 if race==2
replace race = 3 if race>2 & race<.
g race_fh = race if famhead==1

g hisp = (pehspnon==1)
g hisp_fh = hisp if famhead==1


** indicator for famhead military service
g vetstat_fh = (peafever==1)

*trying to tweak model to improve predictive 
g age_fh2 = age_fh*age_fh

collapse (mean) numkid numadult under6 sumretired max_educ min_educ race_fh age_fh sex_fh marital_fh hisp_fh vetstat_fh age_fh2 (max) hefaminc, by(yearmth hrhhid hrhhid2 famunit)

