* created March 29, 2023


clear all
set more off

cd "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data" // Madison path
use asec_19to22.dta, clear // Madison dta name
cd "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\lfpr_and_benefits_tables"

drop if hhstatus == 0
*make a variable to grab just the householder's age
g hhead_age = a_age if hhdfmx==1
bys year ph_seq: egen hh_age = max(hhead_age)

* drop HHs with a head older than 64.
drop if hh_age>64

bys year ph_seq: egen heip = sum(eip_crd)

* make household-level variable for Advance ctc amount
bys year ph_seq: egen h_adv = sum(adv_ctc) 

* make HH-level variable for estimated total CTC amount
bys year ph_seq: egen h_actc = sum(actc_crd)

* make variable for number of children in household 
g addkids = spm_numkids if spm_head==1
bys year ph_seq: egen h_numkids = sum(addkids)


* if actc_crd>0 then the CPS tax model determined that person belongs to a tax unit that is likely eligible for CTC.
g ctc_elig = (h_actc>0)

*************** add LF status **********************
drop if a_age<15
drop if pemlr == 0

gen E = (pemlr<=2) 
gen U = (pemlr>=3 & pemlr<=4)
gen N = (pemlr>=5)
gen pop = (E==1 | U == 1 | N == 1)
gen LF = (E==1 | U == 1)

****************************************************

* Household accounting: 

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


*** Basic Labor Force stats across years for this population
table income_cat year [fweight=marsupwt] if LF==1, statistic(mean E) nformat(%5.2fc)

collect create urate
table income_cat year [fweight=marsupwt] if LF==1, statistic(mean U) nformat(%5.2fc)
collect export urate.tex, replace

table income_cat year [fweight=marsupwt], statistic(mean N) nformat(%5.2fc)


preserve
	replace LF = LF*100
	collect create lfpr
	table income_cat year [fweight=marsupwt], stat(mean LF) nformat(%5.1fc)
	collect export lfpr.tex, tableonly replace 
	****

	***** Individual level indicator of a HH characteristic **************************
	gen h_adv_indicator = (h_adv>0 & h_adv!=.)
	label variable h_adv_indicator "Received advance ACTC"
	label define indicator_labels 0 "No" 1 "Yes"
	label values h_adv_indicator indicator_labels


	***********************************************************************

	collect create lfpr_ACTC
	table (income_cat h_adv_indicator) year [fweight = marsupwt], statistic(mean LF) nformat(%5.1fc mean)
	collect title "compare lfpr among adv ctc recips and everybody else"
	collect export lfpr_ACTC.tex, tableonly replace

	* lfpr conditional 

	g kids_indicator = (h_numkids>0)


	collect create ppl_wkids_in_hh
	table (income_cat) year [fweight = marsupwt], statistic(mean kids_indicator) nformat(%5.2fc)
	collect title "Share of people living in a household with children"
	collect export ppl_wkids_in_hh.tex, tableonly replace


	* compute lfpr among all people with kids in their HH
	collect create lfpr_wkids
	table (income_cat) year [fweight=marsupwt] if kids_indicator>0, statistic(mean LF) nformat(%5.1fc)
	collect title "LFPR among all people with kids in their HH"
	collect export lfpr_wkids.tex, tableonly replace


	* compute lfpr among all people from HHs that tax model thinks are eligible for CTC 
	collect create lfpr_ctc_eligible
	table (income_cat) year [fweight=marsupwt] if ctc_elig>0, statistic(mean LF) nformat(%5.1fc)
	collect title "LFPR among all people from HHs that the CPS tax model thinks are eligible for CTC"
	collect export lfpr_ctc_elig.tex, tableonly replace


	* compute lfpr among all people from households that are receiving actc  - compare to the population that has kids in HH 
	collect create lfpr_wkids_adv
	table (income_cat h_adv_indicator) year [fweight=marsupwt] if kids_indicator>0, statistic(mean LF) nformat(%5.1fc)
	collect title "LFPR among all people from HHs that receive advance CTC, relative to people from HHs that have kids but do not receive advance CTC"
	collect export lfpr_wkids_adv.tex, tableonly replace
restore
