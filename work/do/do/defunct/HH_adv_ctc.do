* Advance CTC 
* created March 28, 2023

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


gen h_main_income  = hfrval  + hseval + hwsval 
gen h_other_income = hannval + hcspval + hdisval + hdivval + hdstval + hedval + hfinval + hintval + hpenval + hoival  + hssival + hssval + hsurval + hvetval + hwcval + hrntval
gen h_ben = hpawval + hucval  + hengval + hfdval + heip + h_adv

*Confirm (1) above by computing what I think are included in HTOTVAL
 
gen h_tot_income_ASEC_calc = hfrval  + hseval + hwsval+hannval + hcspval + hdisval + hdivval + hdstval + hedval + hfinval + hintval + hpenval + hoival  + hssival + hssval + hsurval + hvetval + hwcval + hrntval + hpawval + hucval

gen check_hh_income =  h_tot_income_ASEC_calc/htotval

tab check_hh_income 


replace h_main_income = 0  if  h_main_income<0 
replace h_other_income = 0 if  h_other_income<0 
gen h_tot_income_calc = h_main_income +  h_other_income + h_ben


***** Flag Household benefit receipt **************************
gen h_ben_indicator = (h_ben>0)

gen h_adv_indicator = (h_adv>0 & h_adv!=.)

gen h_uc_indicator = (hucval>0 & hucval!=.)

gen h_fs_indicator = (hfdval>0 & hfdval!=.)
*************************************************

recode h_tot_income_calc (0/24999 = 1) (25000/49999 = 2) (50000/99999 = 3) (100000/149999 = 4) (150000/. = 5), generate(income_cat)
label variable income_cat "Household income category"
label define income_cat_labels 1 "up to $24,999" 2 "$25,000-$49,000" 3 "$50,000-$99,999" 4 "$100,000-$149,999" 5 "$150,000+"
label values income_cat income_cat_labels

**** collapse to the Household level

collapse  (mean) h_main_income h_ben h_other_income h_tot_income_calc hucval h_ben_indicator h_adv_indicator h_uc_indicator h_fs_indicator heip h_adv h_actc hwcval  hfdval hsup_wgt income_cat h_numkids ctc_elig hectc_yn, by(ph_seq year)

replace hsup_wgt = int(hsup_wgt/100)

label variable income_cat "Household income category"
label values income_cat income_cat_labels


collect create benefit_ind
table income_cat year [fweight=hsup_wgt], statistic(mean h_ben_indicator)  nformat(%5.3fc) 
collect export benefit_ind.tex, tableonly replace

collect create ctc_ind
table income_cat [fweight = hsup_wgt] if year==2022, statistic(mean h_adv_indicator) nformat(%5.3fc)
collect export ctc_ind.tex, tableonly replace

collect create uc_ind
table income_cat year [fweight=hsup_wgt], stat(mean h_uc_indicator) nformat(%5.3fc)
collect export uc_ind.tex, tableonly replace

* what % of all HHs self-declare getting advance?
replace hectc_yn=0 if hectc_yn==2
table income_cat [fweight = hsup_wgt] if year==2022, statistic(mean hectc_yn) nformat(%5.3fc)
collect export ctc_yesno.tex, tableonly replace


* What % of HHs are eligible for CTC? 
collect create ctc_eligible
table income_cat [fweight = hsup_wgt] if year==2022, statistic(mean ctc_elig) nformat(%5.3fc)
collect export ctc_eligible.tex, tableonly replace

* What % of eligible HHs have a positive advance CTC?
collect create adv_eligible
table income_cat [fweight = hsup_wgt] if ctc_elig>0 & year==2022, statistic(mean h_adv_indicator) nformat(%5.3fc)
collect export adv_eligible.tex, tableonly replace

* Among those that are eligible but reported no advance, what income categories do they fall into? what kind of filers are they?
* ID group, then tab income_cat
g answerno = (ctc_elig>0 & h_adv_indicator==0)

table income_cat if answerno==1 & year==2022, stat(percent) nformat(%5.1fc)


******* Average amounts *******************
label variable h_ben "Total benefits"
label variable hucval "Unemployment compensation"
label variable heip "Economic Impact Payment"
label variable h_adv "Expanded Child Tax Credit"

collect create benefit_amt_breakdown
table income_cat year [fweight=hsup_wgt], statistic(mean h_ben hucval heip h_adv) nformat(%6.0fc)
collect export benefit_amt.tex, tableonly replace

************* ratios to household income ******************
gen ben_ratio = h_ben/h_tot_income_calc if h_ben>0
replace ben_ratio = 0 if h_ben==0 


g ctc_ratio = h_adv/h_tot_income_calc if h_adv>0
replace ctc_ratio = 0 if h_adv==0


collect create benefit_ratio
table income_cat year [fweight=hsup_wgt], statistic(mean ben_ratio) nformat(%5.3fc) 
collect export benefit_ratio.tex, tableonly replace


collect create childtaxcredit_ratio
table income_cat [fweight=hsup_wgt], statistic(mean ctc_ratio) nformat(%5.3fc)
collect export childtaxcredit_ratio.tex, tableonly replace


****************** compute ctc avg amt and ratio conditional on having a child in the house *************************

g kids_indicator = (h_numkids>0)

* proportion of HHs that have kids
collect create haskids
table income_cat year [fweight = hsup_wgt], stat(mean kids_indicator) nformat(%5.2fc) 
collect export haskids.tex, tableonly replace

* proportion getting adv_ctc among HHs with kids 
preserve
replace h_adv_indicator = h_adv_indicator*100
collect create adv_uptake_kids
table income_cat [fweight = hsup_wgt] if kids_indicator>0 & year==2022, stat(mean h_adv_indicator) nformat(%5.1fc)
collect export adv_uptake_kids.tex, tableonly replace


* proportion getting adv_ctc among HHs deemed CTC-eligible
collect create adv_uptake_elig
table income_cat [fweight = hsup_wgt] if ctc_elig>0 & year==2022, stat(mean h_adv_indicator) nformat(%5.1fc)
collect export adv_uptake_elig.tex, tableonly replace
restore


* average amount of adv ctc, conditional on getting adv ctc
collect create cond_avg_ctc
table income_cat [fweight = hsup_wgt] if h_adv_indicator>0 & year==2022, stat(mean h_adv) nformat(%5.0fc)
collect export cond_avg_ctc.tex, tableonly replace


* ratio 
collect create recip_ctc_ratio
table income_cat [fweight = hsup_wgt] if h_adv_indicator>0 & year==2022, stat(mean ctc_ratio) nformat(%5.3fc) nototals
collect export recip_ctc_ratio.tex, tableonly replace





