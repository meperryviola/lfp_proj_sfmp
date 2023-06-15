** Try imputing family income using a family-level regression 

* set paths
global datapath "/home/c1mep01/Work/madison_cps/data"
global logpath "/home/c1mep01/Work/childtaxcredit_proj_sfmp/work/logs"

cd "$datapath"

* collapse dataset to the family level

forvalues x = 2019/2021 {
use impute`x', clear


* make a unified age variable
g age = prtage if is_basic==1
replace age = a_age if is_asec==1
drop if age==.

* make a unified sex variable
g sex = pesex if is_basic==1
replace sex = a_sex if is_asec==1


g kid = (age<18)
g adult = (age>=18)
g elderly = (age>64)

* make marital status variables
g marital = (a_maritl<4) if is_asec==1
replace marital = (pemaritl<4) if is_basic==1
replace marital = 0 if marital!=1

* make count kids variable - note this is number of kids in the same household as the person.
bys year ph_seq: egen numkid = sum(kid) if is_asec==1
bys year ph_seq: egen numadult = sum(adult) if is_asec==1

bys yearmth hrhhid hrhhid2: replace numkid = sum(kid) if is_basic==1
bys yearmth hrhhid hrhhid2: replace numadult = sum(adult) if is_basic==1

* make number of kids bins
g numkid_bin = 0 if numkid==0
replace numkid_bin = 1 if numkid==1
replace numkid_bin = 2 if numkid==2 | numkid==3
replace numkid_bin = 4 if numkid>=4

g numadult_bin = 1 if numadult==1
replace numadult_bin=2 if numadult==2
replace numadult_bin=3 if numadult==3
replace numadult_bin=4 if numadult>=4

* age of youngest child
bys year ph_seq: egen min_kage = min(age) if is_asec==1
bys yearmth hrhhid hrhhid2: replace min_kage = min(age) if is_basic==1
replace min_kage = 0 if numkid==0

* age of oldest child
bys year ph_seq: egen max_kage1 = max(age) if is_asec==1 
bys yearmth hrhhid hrhhid2: egen max_kage2 = max(age) if is_basic==1
g max_kage = max_kage1 if is_asec==1 //THis is a dumb thing I have to do bc bysort won't cooperate with "replace" and max()
replace max_kage = max_kage2 if is_basic==1
replace max_kage = 0 if numkid==0


* mean age of adults in the family
g adult_age = age if age>=18

bys year ph_seq: egen mean_aage = mean(adult_age) if is_asec==1
bys yearmth hrhhid hrhhid2: replace mean_aage = mean(adult_age) if is_basic==1

** simplified educational attainment variable
g educ = a_hga if is_asec==1
replace educ = peeduca if is_basic==1
replace educ = 1 if educ<39
replace educ = 2 if educ==39
replace educ = 3 if educ>=40 & educ<43
replace educ = 4 if educ==43 
replace educ = 5 if educ>43 & educ<.
label define edlabel 1 "LTHS" 2 "HS grad" 3 "some coll" 4 "Bachelors" 5 "Adv deg"
label values educ edlabel

* make var to capture the maximum level of education attained by any member of the family.
bys ph_seq: egen max_educ1 = max(educ) if is_asec==1
bys yearmth hrhhid hrhhid2: egen max_educ2 = max(educ) if is_basic==1
g max_educ = max_educ1
replace max_educ = max_educ2 if is_basic==1 // THis is a dumb thing I have to do bc bysort won't cooperate with "replace" and max().

label values max_educ edlabel

* repeat to make a minimum education level var.
bys ph_seq: egen min_educ1 = min(educ) if is_asec==1
bys yearmth hrhhid hrhhid2: egen min_educ2 = min(educ) if is_basic==1
g min_educ = min_educ1
replace min_educ = min_educ2 if is_basic==1 
label values min_educ edlabel


*household type - hrhtype


* carry AGI across the family - initially the only people with agi values were the reference people for each family
bys ph_seq: egen fam_agi = max(agi)


** simplified race variable
g race = prdtrace if is_asec==1
replace race = ptdtrace if is_basic==1
replace race = 1 if race==1
replace race = 2 if race==2
replace race = 3 if race>2 & race<.


**** This part may be omitted if race is not super important predictor:

* in order to use race to impute at the family level, I have to use the race of just the reference person - I am not making family-composite race variables.

* first, mark primary and secondary person in the monthly.
g refperson = (prfamrel==1)
replace refperson = 2 if (prfamrel==2)
* do the same thing for the ASEC records
bys ph_seq yearmth: replace refperson = 1 if p_seq==fheadidx & is_asec==1
bys ph_seq yearmth: replace refperson = 2 if p_seq==fspouidx & is_asec==1

replace race=. if refperson!=1

g hisp = (pehspnon==1)
replace hisp = . if refperson!=1
***********************************************************************


** use the log of ftotval
g lnftotval = ln(ftotval)
g lnfearnval = ln(fearnval)
g lnfam_agi = ln(fam_agi)

preserve
keep if is_asec==1

* collapse command
collapse (mean) mean_aage min_kage max_kage max_educ min_educ i.hefaminc i.hrhtype c.numadult c.numkid##i.under6 i.h_tenure fam_agi ftotval fearnval htotval by(year ph_seq)

save fam_impute_asec`x', replace
restore 

preserve 
keep if is_basic==1
collapse (mean) mean_aage min_kage max_kage max_educ min_educ i.hefaminc i.hrhtype c.numadult c.numkid##i.under6 i.h_tenure fam_agi ftotval fearnval htotval by(hrhhid hrhhid2 yearmth)

save fam_impute_basic`x', replace
restore 



