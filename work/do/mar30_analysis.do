* Created March 30, 2023 by Madison Perry

cd "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data\cpsmonthly"

***** sort and visually explore the panel data
use cpsmonths_ctc_linked, clear
sort hrhhid hrhhid2 pulineno hrmis yearmth
order hrhhid hrhhid2 pulineno prtage hrmis yearmth prpertyp

* note: PRPERTYP is a "type of person recode" that gives 1 if child household member.

drop if prtage>64

* make a simplified race variable

** make indicator for living in a household with a child 0-17
* assume child age is static as of first observation. 
g kid = (prtage<18)
g youngkid = (prtage<7)

* count kids
bys hrhhid hrhhid2 yearmth: egen numkid = sum(kid)
bys hrhhid hrhhid2 yearmth: egen numyoungkid = sum(youngkid)

* living in a household with a kid
gen haskid = (kid>=1)
* living in a household with a young child 0-6
gen hasyoungkid = (numyoungkid>=1)

order hrhhid hrhhid2 pulineno prtage hrmis yearmth prpertyp haskid hasyoungkid


* drop the observations of the kids themselves
drop if prtage<17

***** Add labor force status indicators ******
drop if pemlr == 0

gen E = (pemlr<=2) 
gen U = (pemlr>=3 & pemlr<=4)
gen N = (pemlr>=5)
gen pop = (E==1 | U == 1 | N == 1)
gen  LF = (E==1 | U == 1)

***** Looking at LFPRs


** all people with kids vs. no kids
table (yearmth) (haskid) [fweight=pwsswgt], statistic(mean LF) nformat(%5.2fc)

table (yearmth) (hasyoungkid) [fweight=pwsswgt], statistic(mean LF) nformat(%5.2fc)

** women only
table (yearmth) (haskid) [fweight=pwsswgt] if pesex==2, statistic(mean LF) nformat(%5.2fc)

table (yearmth) (hasyoungkid) [fweight=pwsswgt] if pesex==2, statistic(mean LF) nformat(%5.2fc)


*** regression on panel 

* make additional indicators for treatment
g postctc = (yearmth>202106 & yearmth<202201) // checks came out mid-July

g woman = (pesex==2)


* make panel variable 
egen panelid = group(hrhhid hrhhid2 pulineno)

*xtreg depvar [indepvars] [if] [in] [weight] , fe [FE_options]
xtset panelid yearmth, monthly


xtreg LF postctc##haskid, fe 

xtreg LF postctc##hasyoungkid, fe 

xtreg LF postctc##haskid##woman, fe 

xtreg LF postctc##hasyoungkid##woman, fe 




**** regression on not panel 
use cpsm_ctc, clear
* this is copy paste of the chunk above.
sort hrhhid hrhhid2 pulineno hrmis yearmth
order hrhhid hrhhid2 pulineno prtage hrmis yearmth prpertyp

* note: PRPERTYP is a "type of person recode" that gives 1 if child household member.

drop if prtage>64

** make indicator for living in a household with a child 0-17
* assume child age is static as of first observation. 
g kid = (prtage<18)
g youngkid = (prtage<7)

* count kids
bys hrhhid hrhhid2 yearmth: egen numkid = sum(kid)
bys hrhhid hrhhid2 yearmth: egen numyoungkid = sum(youngkid)

* living in a household with a kid
gen haskid = (kid>=1)
* living in a household with a young child 0-6
gen hasyoungkid = (numyoungkid>=1)

order hrhhid hrhhid2 pulineno prtage hrmis yearmth prpertyp haskid hasyoungkid

* drop the observations of the kids themselves
drop if prtage<17

***** Add labor force status indicators ******
drop if pemlr == 0

gen E = (pemlr<=2) 
gen U = (pemlr>=3 & pemlr<=4)
gen N = (pemlr>=5)
gen pop = (E==1 | U == 1 | N == 1)
gen  LF = (E==1 | U == 1)

***** make treatment indicators

g advCTC = (yearmth>202107 & yearmth<202201) // checks came out mid-July

g woman = (pesex==2)

*keep if prtage<50 // try keeping only younger people bc they are the ones likely to be the actual parents of the kid in their HH. 


reghdfe LF advCTC##haskid woman prtage peeduca, absorb(yearmth gestfips)

reghdfe LF advCTC##hasyoungkid woman prtage peeduca, absorb(yearmth gestfips)

reghdfe LF advCTC##haskid##woman prtage peeduca, absorb(yearmth gestfips)

reghdfe LF advCTC##hasyoungkid##woman prtage peeduca, absorb(yearmth gestfips)

** how do I make the output look nice?


** Intensive margin 
* PEHRUSL1 - how many hours per week do you usually work at your main job
* PEHRFTPT - are you usually working fulltime 
* PEHRACT1 - how many hours last week did you actually work at your job?

reghdfe pehrusl1 advCTC##haskid woman prtage peeduca, absorb(yearmth gestfips) // am I actually doing this right?

reghdfe pehract1 advCTC##haskid woman prtage peeduca, absorb(yearmth gestfips)

reghdfe pehrusl1 advCTC##hasyoungkid woman prtage peeduca, absorb(yearmth gestfips) 

reghdfe pehract1 advCTC##hasyoungkid woman prtage peeduca, absorb(yearmth gestfips)

