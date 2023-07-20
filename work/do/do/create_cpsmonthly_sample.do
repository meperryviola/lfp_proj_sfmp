* create cross sectional file of all CPS months August 19 - March 23
** This is the sample needed for replicating Enriquez, Jones, Tedeschi (2023)

* then separately create linked sample of people in cps months May 21 - August 21
** This is a smaller panel that Shigeru wanted.

clear 
set more off

global monthlypath "/home/c1mep01/Work/madison_cps/data/cpsmonthly"
global datapath "/home/c1mep01/Work/madison_cps/data"


cd "$monthlypath"
*cd "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data\cpsmonthly"

/*
* read in the monthly CSVs and save as dta 
local x=202001

while `x' <= 202303{
clear

import delimited "/home/c1mep01/Work/madison_cps/data/cpsmonthly/cpsm`x'.csv"

gen yearmth = `x'
local year=round(`x'/100)
local month=round((`x'-`year'*100))

gen year = `year'
g month = `month'

save cpsm`x', replace


local x = `x' + 1
if (`x'-13)/100 == int((`x'-13)/100) {
    local x = `x' + 88
    }

}

* Note that the DTA files for 2019 monthly basic were pulled from the inherited "Reasons for Nonparticipation" folder.
* this is because those had to be read in from RAW format and the code to do that was in that folder.

forvalues x = 201901/201912 {
use cpsm`x', clear
*gen yearmth = `x'
local year=round(`x'/100)
local month=round((`x'-`year'*100))
gen year = `year'
g month = `month'

destring hrhhid, replace // the 2019 ones had been read in differently so these identifiers were strings but i need them to match the others.
destring hrhhid2, replace

save cpsm`x', replace 
}


* Combine all basics
cd "$monthlypath"
use cpsm201901, clear
local x=201902
while `x' <= 202212{
append using cpsm`x', force

local x = `x' + 1
if (`x'-13)/100 == int((`x'-13)/100) {
    local x = `x' + 88
    }
}
cd "$datapath"
g is_basic=1

g famunit = 1 if perrp<=53
replace famunit=2 if perrp>=54 & perrp<.

save basics_raw_19to22, replace
*/

** Data preparation - monthly
cd "$datapath"
** this technique comes from Enriquez replication file. smart way of narrowing what variables I keep.
global cpsvars 			"hryear4 year month prpertyp pesex"
global agevars 			"prtage prtage"
global racevars			"ptdtrace pehspnon penatvty"
global educvars			"peeduca"
global cpssvysetvars		"gtcbsasz gestfips"
	
use $cpsvars $agevars $educvars $racevars $cpssvysetvars gestfips /// 
	yearmth prchld peafever pesex pemlr hrhhid hrhhid2 perrp prcitshp ///
	pemaritl pulineno prpertyp prnmchld hrhtype year is_basic famunit ///
	hefaminc pwlgwgt pwcmpwgt pwsswgt pehractt pehruslt gediv ///
	using basics_raw_19to22, clear


*** variable creation and wrangling prior to imputation

* make a unified age variable 
g age = prtage

drop if age==.

g kid = (age<18)
g adult = (age>=18)
g elderly = (age>64)

bys yearmth hrhhid hrhhid2 famunit: egen numkid = sum(kid)  // number of children in family
bys yearmth hrhhid hrhhid2 famunit: egen numadult = sum(adult) // number of adults in family 
gen famsize = numadult +numkid

g adult_age = age if adult==1
bys yearmth hrhhid hrhhid2 famunit: egen mean_age = mean(adult_age)
g mean_age2 = mean_age*mean_age

* indicate if age of youngest child is less than 6
g under6 = (age<6)
bys yearmth hrhhid hrhhid2 famunit: g sum_under6 = sum(under6)
g share_under6 = sum_under6/numkid // Share of children in the family under age 6
replace share_under6 = 0 if numkid==0

* count number of elderly people in household
bys hrhhid hrhhid2 yearmth famunit: egen sum_elderly = sum(elderly)
g share_elderly = sum_elderly/numadult // Share of adults in the family above 65


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

* grab education level from people who are adults only
g educ_adult = educ if adult==1
bys yearmth hrhhid hrhhid2 famunit: egen min_educ = min(educ_adult)
label values min_educ edlabel


** share of adults that are married:
g marital = (pemaritl<4) 
replace marital = 0 if marital!=1
bys yearmth hrhhid hrhhid2 famunit: egen count_married = sum(marital)
g share_married = count_married/numadult // share of adults in family that are married


* share of family that is Black
g black = (ptdtrace==2)
bys yearmth hrhhid hrhhid2 famunit: egen sum_black = sum(black)
g share_black = sum_black/famsize

* share of family that is Hispanic
g hisp = (pehspnon==1)
bys yearmth hrhhid hrhhid2 famunit: egen sum_hisp = sum(hisp)
g share_hisp = sum_hisp/famsize

* share of family that is immigrant
g immg = (prcitshp>=4 & prcitshp<=5)
bys yearmth hrhhid hrhhid2 famunit: egen sum_immg = sum(immg)
g share_immg = sum_immg/famsize

* ratio of children to adults 
g kid_ratio = numkid/numadult


********

//* make a reference person for each family. *//
/*bys yearmth hrhhid hrhhid2 famunit: egen min_lineno = min(pulineno)
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
g vetstat = (peafever==1)
g vetstat_fh = vetstat if famhead==1

*trying to tweak model to improve predictive
g age2 = age*age 
g age_fh2 = age_fh*age_fh

g elderly_fh = elderly if famhead==1

*/


save basics_inc_19to22, replace



/*
** Collapse to the family level.
collapse (mean) numkid numadult  sumretired elderly_fh hrhtype max_educ min_educ race_fh age_fh sex_fh marital_fh hisp_fh vetstat_fh age_fh2 is_basic year (max) under6 hefaminc, by(yearmth hrhhid hrhhid2 famunit)

save basics_collapsed_19to22, replace


** THESE ARE SCRAPS **
/* make big cross sectional file of all months August19 - March22
use cpsm201908, clear
save ctc_crosssection, replace
local x=201909
while `x' <= 202303{
append using cpsm`x', force

local x = `x' + 1
if (`x'-13)/100 == int((`x'-13)/100) {
    local x = `x' + 88
    }
}

save ctc_crosssection, replace

** end


* create linked sample of people in May 21 - August 21
use cpsm202105, clear
keep if hrmis == 1 | hrmis == 5
save cpsmonths_ctc_linked, replace

use cpsm202106, clear
keep if hrmis == 2 | hrmis == 6
append using cpsmonths_ctc_linked
save cpsmonths_ctc_linked, replace

use cpsm202107, clear
keep if hrmis == 3 | hrmis == 7
append using cpsmonths_ctc_linked 
save cpsmonths_ctc_linked, replace

use cpsm202108
keep if hrmis == 4 | hrmis==8
append using cpsmonths_ctc_linked 
save cpsmonths_ctc_linked, replace


