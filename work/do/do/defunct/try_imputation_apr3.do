* trying to predict HH income category using observables 

* made on March 31, 2023 by Madison Perry


clear all
set more off
set maxvar 120000

cd "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data" // Madison path
use asec_19to22.dta, clear // Madison dta name
g is_asec = 1
cd "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data\cpsmonthly" // grab the panel dataset and append it with this one
append using cpsmonths_ctc_linked

drop if hhstatus == 0

* make a unified age variable
g age = a_age
replace age = prtage if is_asec!=1

* make a unified sex variable
g sex = a_sex
replace sex = pesex if is_asec!=1


* PRNMCHLD counts the number of own children the person has.
** make variable for number of children in household 

g kid = (age<18)
g youngkid = (age<7)

bys year ph_seq: egen numkid = sum(kid) if is_asec==1

bys hrhhid hrhhid2 yearmth: replace numkid = sum(kid)


* make variable that grabs only the age of the youngest child

bys year ph_seq: egen youngestkid = min(age) if is_asec==1

bys hrhhid hrhhid2 yearmth: egen youngestkid_basic = min(age) // I know this is inefficient. "egen replace" was throwing a weird error. THis is a workaround.
replace youngestkid = youngestkid_basic if is_asec!=1

replace youngestkid = . if youngestkid>=18


** simplified race variable
replace prdtrace = ptdtrace if prdtrace==.
g race = .
replace race = 1 if prdtrace==1
replace race = 2 if prdtrace==2
replace race = 3 if prdtrace>2 & prdtrace<.

** simplified educational attainment variable
replace a_hga = peeduca if a_hga==.
g educ = . 
replace educ = 1 if a_hga<39
replace educ = 2 if a_hga==39
replace educ = 3 if a_hga>=40 & a_hga<43
replace educ = 4 if a_hga==43 
replace educ = 5 if a_hga>43 & a_hga<.


*************** add LF status **********************
drop if pemlr == 0

gen E = (pemlr<=2) 
gen U = (pemlr>=3 & pemlr<=4)
gen N = (pemlr>=5)
gen pop = (E==1 | U == 1 | N == 1)
gen LF = (E==1 | U == 1)

****************************************************

* Household accounting: (this is asec only)

bys year ph_seq: egen heip = sum(eip_crd)

* make household-level variable for Advance ctc amount
bys year ph_seq: egen h_adv = sum(adv_ctc) 

* make HH-level variable for estimated total CTC amount
bys year ph_seq: egen h_actc = sum(actc_crd)

gen h_main_income  = hfrval  + hseval + hwsval 
gen h_other_income = hannval + hcspval + hdisval + hdivval + hdstval + hedval + hfinval + hintval + hpenval + hoival  + hssival + hssval + hsurval + hvetval + hwcval + hrntval
gen h_ben = hpawval + hucval  + hengval + hfdval + heip + h_adv

replace h_main_income = 0  if  h_main_income<0 
replace h_other_income = 0 if  h_other_income<0 
gen h_tot_income_calc = h_main_income +  h_other_income + h_ben

g h_income = h_tot_income_calc

recode h_income (0/24999 = 1) (25000/49999 = 2) (50000/99999 = 3) (100000/149999 = 4) (150000/. = 5), generate(income_cat)
replace income_cat = . if h_tot_income_calc==.
label variable income_cat "Household income category"
label define income_cat_labels 1 "up to $24,999" 2 "$25,000-$49,000" 3 "$50,000-$99,999" 4 "$100,000-$149,999" 5 "$150,000+"
label values income_cat income_cat_labels


drop if age<18

* make a variable for married
g marstat = a_maritl
replace marstat = prmarsta if a_maritl==.


** use regressions to try to find a good model for predicting h_income 
logit h_income i.marstat numkid i.sex##youngestkid i.sex##i.race age age#i.sex i.sex#i.educ i.gestfips if is_asec==1



** Try to use observables to predict h_income value. Then use the predicted value to assign income_cat for each iteration

mi set mlong
mi register imputed h_income
mi register passive income_cat 


mi impute reg h_income numkid i.sex##i.race age age#i.sex i.educ i.gestfips, add(3) force




* make additional indicators for treatment
g postctc = (yearmth>202106 & yearmth<202201) // checks came out mid-July

g woman = (pesex==2)


* make panel variable 
egen panelid = group(hrhhid hrhhid2 pulineno)

*xtreg depvar [indepvars] [if] [in] [weight] , fe [FE_options]
xtset panelid yearmth, monthly










