clear matrix
clear mata
clear
set maxvar 120000

cd "/home/c1mep01/Work/madison_cps/data" // cluster path
*cd "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data"

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

* make count kids variable using - note this is number of kids in the same household as the person.
bys year ph_seq: egen numkid = sum(kid) if is_asec==1
bys year ph_seq: egen numadult = sum(adult) if is_asec==1

bys hrhhid hrhhid2 yearmth: replace numkid = sum(kid) if is_basic==1
bys hrhhid hrhhid2 yearmth: replace numadult = sum(adult) if is_basic==1

/* make number of kids bins
g numkid_bin = 0 if numkid==0
replace numkid_bin = 1 if numkid==1
replace numkid_bin = 2 if numkid==2 | numkid==3
replace numkid_bin = 4 if numkid>=4
*/

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


* carry AGI across the family
bys ph_seq: egen fam_agi = max(agi)



/* pull out the observations of the kids themselves*
preserve 
keep if age<18
save kids_obs_preimpute, replace
restore
*/
drop if age<18


mi set wide
mi register imputed ftotval fam_agi fearnval

* Here I'm messing with the model specifications and seeing what the fit looks like:
regress ftotval agi fearnval i.race i.educ i.sex i.hefaminc c.numkid##i.marital
regress fam_agi fearnval ftotval i.race i.educ i.sex i.hefaminc c.numkid##i.marital
regress fearnval ftotval agi i.race i.educ i.sex i.hefaminc c.numkid##i.marital

bys marital: regress ftotval agi fearnval i.race i.educ i.sex i.hefaminc c.numkid i.spousemp
bys marital: regress fam_agi fearnval ftotval i.race i.educ i.sex i.hefaminc c.numkid i.spousemp
by marital: regress fearnval ftotval agi i.race i.educ i.sex i.hefaminc c.numkid i.spousemp



*might have to do Monotone bc my pattern of missingess is monotone, but rn I'm trying chained:
mi impute chained (pmm, knn(3)) fearnval ftotval fam_agi  = i.race i.educ i.sex i.hefaminc c.numkid i.spousemp, add(5) rseed(4409) by(marital) force

save mult_imputed_`x', replace
}







/*
spikeplot fearnval if is_asec==1 & fearnval<400000 & fearnval>0
spikeplot fearnval if  fearnval<400000 & fearnval>0


* this is MICE
*mi impute chained (pmm, knn(3)) fearnval = i.race i.educ i.sex i.hefaminc c.numkid i.spousemp i.marital, add(5) rseed(4409) force
* mi impute chained (pmm) ftotval agi fearnval = i.race i.educ i.sex i.hefaminc c.numkid i.spousemp, by(marital) add(5) rseed(4409) 




/*
mlogit race i.sex i.hefaminc i.educ i.sex numkid i.marital i.spousemp
logit sex i.race i.hefaminc i.educ numkid i.marital i.spousemp
ologit hefaminc i.sex i.race i.educ numkid i.marital i.spousemp
regress numkid sex i.race i.hefaminc i.educ i.marital i.spousemp
logit marital numkid sex i.race i.hefaminc i.educ i.spousemp
ologit educ i.race i.sex i.hefaminc numkid i.marital i.spousemp
ologit spousemp i.educ i.race i.sex i.hefaminc numkid i.marital







