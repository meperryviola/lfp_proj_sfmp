* Making income categories using HEFAMINC
* later imputing pre- and post-expansion CTC benefit amounts by matching HHs by # adults # kids and income category.

* created by Madison Perry on 4/5/2023

***** Using hefaminc to make income categories and rerun the panel regressions *****

cd "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data\cpsmonthly"
use cpsmonths_ctc_linked, clear
g is_basic = 1

* make a unified age variable
g age = prtage

* make a unified sex variable
g sex = pesex


** make variable for number of children in household 
g kid = (age<18)
g youngkid = (age<7)


bys hrhhid hrhhid2 yearmth: egen numkid = sum(kid) if is_basic==1

bys hrhhid hrhhid2 yearmth: egen numyoungkid = sum(youngkid) if is_basic==1

** make variable for number of adults in HH.
g adult = (age>=18)

bys hrhhid hrhhid2 yearmth: egen numadult = sum(adult) if is_basic==1

** grab just hefaminc for May and use that for the panel people.
g may_hefaminc = hefaminc if yearmth==202105
bys hrhhid hrhhid2: egen const_faminc = mean(may_hefaminc)

order hrhhid hrhhid2 pulineno prtage hrmis yearmth hefaminc const_faminc prpertyp

* hefaminc is already categorical. 

** making additional indicator variables
gen haskid = (numkid>=1)

gen hasyoungkid = (numyoungkid>=1)

g postctc = (yearmth>202106 & yearmth<202201) // checks came out mid-July

g woman = (pesex==2)

* drop the observations of the kids themselves
drop if age<17
drop if age>64

***** Add labor force status indicators ******
drop if pemlr == 0

gen E = (pemlr<=2) 
gen U = (pemlr>=3 & pemlr<=4)
gen N = (pemlr>=5)
gen pop = (E==1 | U == 1 | N == 1)
gen  LF = (E==1 | U == 1)

**** table ******
table (hefaminc haskid) (yearmth) [fweight=pwsswgt] if woman==1, statistic(mean LF) stat(frequency) nformat(%5.2fc) nototals


*** regression on panel 

* make panel variable 
egen panelid = group(hrhhid hrhhid2 pulineno)
drop if panelid==.
*xtreg depvar [indepvars] [if] [in] [weight] , fe [FE_options]
xtset panelid yearmth, monthly


* consolidate hefaminc into 5 categories
recode hefaminc (1/7 = 1) (8/11 = 2) (12/14 = 3) (15 = 4) (16/. = 5), generate(income_cat)


xtreg LF postctc##haskid##income_cat, fe 

xtreg LF postctc##hasyoungkid##income_cat, fe

xtreg LF postctc##haskid##woman##income_cat, fe 

xtreg LF postctc##hasyoungkid##woman##income_cat, fe