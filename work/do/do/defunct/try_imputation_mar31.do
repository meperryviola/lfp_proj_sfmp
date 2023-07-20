* trying to predict HH income category using observables 

* made on March 31, 2023 by Madison Perry


clear all
set more off

cd "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data" // Madison path
use asec_19to22.dta, clear // Madison dta name

cd "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data\cpsmonthly" // grab the panel dataset and append it with this one
append using cpsmonths_ctc_linked

drop if hhstatus == 0
*make a variable to grab just the householder's age
g hhead_age = a_age if hhdfmx==1
bys year ph_seq: egen hh_age = max(hhead_age)

bys year ph_seq: egen heip = sum(eip_crd)

* make household-level variable for Advance ctc amount
bys year ph_seq: egen h_adv = sum(adv_ctc) 

* make HH-level variable for estimated total CTC amount
bys year ph_seq: egen h_actc = sum(actc_crd)

* make variable for number of children in household 
g addkids = spm_numkids if spm_head==1
bys year ph_seq: egen h_numkids = sum(addkids)


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

* unified age variable
replace a_age = prtage if a_age==.

replace a_sex = pesex if a_sex==.

*************** add LF status **********************
drop if pemlr == 0

gen E = (pemlr<=2) 
gen U = (pemlr>=3 & pemlr<=4)
gen N = (pemlr>=5)
gen pop = (E==1 | U == 1 | N == 1)
gen LF = (E==1 | U == 1)

****************************************************

* Household accounting: (this is asec only)

gen h_main_income  = hfrval  + hseval + hwsval 
gen h_other_income = hannval + hcspval + hdisval + hdivval + hdstval + hedval + hfinval + hintval + hpenval + hoival  + hssival + hssval + hsurval + hvetval + hwcval + hrntval
gen h_ben = hpawval + hucval  + hengval + hfdval + heip + h_adv

replace h_main_income = 0  if  h_main_income<0 
replace h_other_income = 0 if  h_other_income<0 
gen h_tot_income_calc = h_main_income +  h_other_income + h_ben

gen h_ben_indicator = (h_ben>0)

recode h_tot_income_calc (0/24999 = 1) (25000/49999 = 2) (50000/99999 = 3) (100000/149999 = 4) (150000/. = 5), generate(income_cat)
label variable income_cat "Household income category"
label define income_cat_labels 1 "up to $24,999" 2 "$25,000-$49,000" 3 "$50,000-$99,999" 4 "$100,000-$149,999" 5 "$150,000+"
label values income_cat income_cat_labels

** Try to use observables to predict income_cat 
*mlogit income_cat i.a_sex i.race a_age i.educ i.gestfips

mi set mlong
mi impute mlogit income_cat i.a_sex i.race a_age i.educ i.gestfips, add(1)














