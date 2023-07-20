** Grab the wage info from the outgoing group in August 2020 and link to the people in the May-Aug 2021 panel.
* Made by Madison Perry on April 3, 2023.


* open August 2020 file. 
cd "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data\cpsmonthly"
use cpsm202008, clear
keep if hrmis==4

append using cpsmonths_ctc_linked

merge m:1 hrhhid hrhhid2 pulineno using august2020_wage_matches
keep if _merge==3

sort hrhhid hrhhid2 pulineno hrmis yearmth
order hrhhid hrhhid2 pulineno prtage hrmis yearmth prpertyp

* aggregate wage info to the household-level v
g grswk = pternwa/100 // rescaled back into dollars.
replace grswk = 0 if pternwa<0 | pternwa==.
bys hrhhid hrhhid2: egen hternwa = sum(grswk) // household level top-coded earnings from wages.

g ann_ernwa = hternwa*52

recode ann_ernwa (0/24999.99 = 1) (25000/49999.99 = 2) (50000/99999.99 = 3) (100000/149999.99 = 4) (150000/. = 5), generate(income_cat)
label variable income_cat "Household income category"
label define income_cat_labels 1 "up to $24,999" 2 "$25,000-$49,000" 3 "$50,000-$99,999" 4 "$100,000-$149,999" 5 "$150,000+"
label values income_cat income_cat_labels

drop if prtage>64
drop if yearmth==202008

tab income_cat // looks a little weird. why the clustering in the lowest and highest groups?


* make a simplified race variable

** make indicator for living in a household with a child 0-17
* assume child age is static as of first observation. 
g kid = (prtage<18)
g youngkid = (prtage<7)

* count kids
bys hrhhid hrhhid2 yearmth: egen numkid = sum(kid)
bys hrhhid hrhhid2 yearmth: egen numyoungkid = sum(youngkid)

* living in a household with a kid
gen haskid = (numkid>=1)
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
table (income_cat haskid) (yearmth) [fweight=pwsswgt], statistic(mean LF) stat(frequency) nformat(%5.2fc) nototals

table (income_cat hasyoungkid) (yearmth) [fweight=pwsswgt], statistic(mean LF) stat(frequency) nformat(%5.2fc) nototals

** women only
table (income_cat haskid) (yearmth) [fweight=pwsswgt] if pesex==2, statistic(mean LF) stat(frequency) nformat(%5.2fc) nototals

table (income_cat hasyoungkid) (yearmth) [fweight=pwsswgt] if pesex==2, statistic(mean LF) stat(frequency) nformat(%5.2fc) nototals


*** regression on panel 

* make additional indicators for treatment
g postctc = (yearmth>202106 & yearmth<202201) // checks came out mid-July

g woman = (pesex==2)


* make panel variable 
egen panelid = group(hrhhid hrhhid2 pulineno)

*xtreg depvar [indepvars] [if] [in] [weight] , fe [FE_options]
xtset panelid yearmth, monthly


xtreg LF (postctc##haskid)#i.income_cat, fe 

xtreg LF (postctc##hasyoungkid)#i.income_cat, fe 


xtreg LF postctc##haskid##woman if income_cat==1, fe 
xtreg LF postctc##haskid##woman if income_cat==2, fe 
xtreg LF postctc##haskid##woman if income_cat==3, fe 
xtreg LF postctc##haskid##woman if income_cat==4, fe 
xtreg LF postctc##haskid##woman if income_cat==5, fe 


xtreg LF postctc##hasyoungkid##woman if income_cat==1, fe 
xtreg LF postctc##hasyoungkid##woman if income_cat==2, fe 
xtreg LF postctc##hasyoungkid##woman if income_cat==3, fe 
xtreg LF postctc##hasyoungkid##woman if income_cat==4, fe 
xtreg LF postctc##hasyoungkid##woman if income_cat==5, fe 

