
use loglinear_imputed_2019, clear
append using loglinear_imputed_2020, force
append using loglinear_imputed_2021, force
 keep if is_asec==1

 
drop if year==2019

drop if a_age<16

replace LF = LF*100

***********
** identify multifamily households
* question: am I counting families correctly with the family identifier?

bys year ph_seq pf_seq: egen minfamln = min(a_lineno) if is_asec==1
g famhead = (a_lineno==minfamln) if is_asec==1

bys year ph_seq: egen numfams = sum(famhead) if is_asec==1
g multifam = (numfams>1)


** check that htotval is actually the sum of ftotval
g fam_totval = ftotval if famhead==1
bys year ph_seq: egen hfam_totval = sum(fam_totval) if is_asec==1
assert htotval == hfam_totval if is_asec==1
* there's only 41 contradictions out of 367,781 obs, so I'm calling that good enough.


** how many people have zero or negative ftotval?
table () (year) if ftotval==0 & is_asec==1, stat(frequency) nformat(%6.0fc)

table () (year) if ftotval<0 & is_asec==1, stat(frequency) nformat(%6.0fc)

** compare exclusion vs inclusion 
table () (year) [fweight=marsupwt] if ftotval<25000.00 & ftotval>0, stat(mean LF) nformat(%6.1fc)

table () (year) [fweight=marsupwt] if unlog_ftotval<25000.00 & is_asec==1, stat(mean LF) nformat(%6.1fc)

*** these make table 1 information ***
table (multifam) (year)  if ftotval<25000.00 & htotval<25000.00 & is_asec==1, stat(frequency) nformat(%6.0fc)

table (multifam) (year) if ftotval<25000.00 & htotval>24999.99 & is_asec==1, stat(frequency) nformat(%6.0fc)

** tabulate the people that have ftotval>htotval
table (multifam) (year)  if ftotval>24999.99 & htotval<25000.00 & is_asec==1, stat(frequency) nformat(%6.0fc)

table (multifam) (year)  if htotval>24999.99 & ftotval<25000.00 & is_asec==1, stat(frequency) nformat(%6.0fc)

** Labor force participation rates

table (multifam) (year) if ftotval<25000.00 & htotval<25000 & is_asec==1 [fweight=marsupwt], stat(mean LF) nformat(%6.1fc) // cases 1 and 3
table (multifam) (year) if ftotval<25000.00 & htotval>=25000.00 & is_asec==1 [fweight=marsupwt], stat(mean LF) nformat(%6.1fc) // cases 2 and 4

table () (year) [fweight=marsupwt] if ftotval<25000.00, stat(mean LF) nformat(%6.1fc) // Gives madison grand average

table () (year) if ftotval<25000.00 & ftotval>0 & is_asec==1 [fweight=marsupwt], stat(mean LF) nformat(%6.1fc) // OLD for comparison to before unlog_ftotval fix.


**** Make Shigeru changes
* re-load the data 
use asec_19to22, clear
** make household level labor force participation rate. 
gen E = (pemlr<=2) 
gen U = (pemlr>=3 & pemlr<=4)
gen N = (pemlr>=5)
gen pop = (E==1 | U == 1 | N == 1)
gen LF = (E==1 | U == 1)

drop if a_age<15

drop if pemlr==0


bys year ph_seq: egen heip = sum(eip_crd)
*bys year ph_seq: egen h_ectc = sum(adv_ctc) 

gen h_main_income  = hfrval  + hseval + hwsval 
gen h_other_income = hannval + hcspval + hdisval + hdivval + hdstval + hedval + hfinval + hintval + hpenval + hoival  + hssival + hssval + hsurval + hvetval + hwcval + hrntval


gen h_ben = hpawval + hucval  + hengval + hfdval + heip // + h_ectc, but removed for now bc I'm trying to replicate Shigeru march numbers and we didn't include CTC in this sum in March.

* see HHBenefitAnalysis for more regarding HH accounting. 

replace h_main_income = 0  if  h_main_income<0 
replace h_other_income = 0 if  h_other_income<0 
gen h_tot_income_calc = h_main_income +  h_other_income + h_ben

gen h_ben_indicator = (h_ben>0)


recode h_tot_income_calc (0/24999.99 = 1) (25000/49999.99 = 2) (50000/99999.99 = 3) (100000/149999.99 = 4) (150000/. = 5), generate(income_cat)
label variable income_cat "Household income category"
label define income_cat_labels 1 "up to $24,999" 2 "$25,000-$49,000" 3 "$50,000-$99,999" 4 "$100,000-$149,999" 5 "$150,000+"
label values income_cat income_cat_labels

** try again the tabulation 
table () (year) if income_cat==1 [fweight=marsupwt], stat(frequency)

table () (year) if income_cat==1 [fweight=marsupwt], stat(mean LF) nformat(%6.3fc) // this is Shigeru's numbers
