* Expanded CTC, looking at the refund amount of CTC and CDC.
* created April 12, 2023

clear all
set more off

cd "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data\cpsmonthly" // Madison path
use spring22_panel.dta, clear // Madison dta name


order ph_seq hhdfmx

*make a variable to grab just the householder's age
g hhead_age = a_age if hhdfmx==1
bys month ph_seq: egen hh_age = max(hhead_age)

* Make indicator for HH head older than 64.
g elderly = (hh_age>64)

* make counter of kids
g numkids = (a_age<18)
bys year ph_seq: egen h_numkids = sum(numkids)

* household-level variable for EIP
bys year ph_seq: egen heip = sum(eip_crd)

* make household-level variable for Advance ctc amount
bys year ph_seq: egen h_adv = sum(adv_ctc) 

* make HH-level variable for estimated total CTC amount
bys year ph_seq: egen h_ctc = sum(actc_crd)

* refund amount variable
g h_ctcref = h_ctc - h_adv 

* Child and dependent care credit
bys year ph_seq: egen h_cdc = sum(cdc_crd)


* Child refund amount
g h_refund = h_ctcref + h_cdc

order ph_seq a_age hhdfmx actc_crd adv_ctc h_ctc h_ctcref cdc_crd h_cdc h_refund



* if ctc_crd>0 then the CPS tax model determined that person belongs to a tax unit that is likely eligible for CTC.
g ctc_elig = (h_ctc>0)
g cdc_elig = (h_cdc>0)


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


recode h_tot_income_calc (0/24999 = 1) (25000/49999 = 2) (50000/99999 = 3) (100000/149999 = 4) (150000/. = 5), generate(income_cat)
label variable income_cat "Household income category"
label define income_cat_labels 1 "up to $24,999" 2 "$25,000-$49,000" 3 "$50,000-$99,999" 4 "$100,000-$149,999" 5 "$150,000+"
label values income_cat income_cat_labels


* drop kids observations

drop if a_age<15
drop if pemlr == 0

gen E = (pemlr<=2) 
gen U = (pemlr>=3 & pemlr<=4)
gen N = (pemlr>=5)
gen pop = (E==1 | U == 1 | N == 1)
gen LF = (E==1 | U == 1)


g refund_ratio = h_refund/h_tot_income_calc if h_refund>0
replace refund_ratio = 0 if h_refund==0


table (income_cat) () if month==3 [fweight = marsupwt], stat(mean refund_ratio) nformat(%5.3fc)

preserve

collapse  (mean) h_main_income h_ben h_other_income h_tot_income_calc hucval heip h_adv hsup_wgt income_cat ctc_elig  h_numkids hectc_yn refund_ratio h_refund, by(ph_seq year)
table (income_cat) () if h_numkids>=1 [fweight = hsup_wgt], stat(mean h_refund) nformat(%5.0fc)
table (income_cat) () if h_numkids>=1 [fweight = hsup_wgt], stat(mean refund_ratio) nformat(%5.2fc)
restore 
