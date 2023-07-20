* create linked sample of people in March 22 - June 22. Use only those who we have asec info for. 
cd "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data\cpsmonthly"
** make set of basic months
use cpsm202203, clear
keep if hrmis == 1 | hrmis == 5
save cpsmonths_ctc_linked, replace

use cpsm202204, clear
keep if hrmis == 2 | hrmis == 6
append using cpsmonths_ctc_linked
save cpsmonths_ctc_linked, replace

use cpsm202205, clear
keep if hrmis == 3 | hrmis == 7
append using cpsmonths_ctc_linked 
save cpsmonths_ctc_linked, replace

use cpsm202206, clear
keep if hrmis == 4 | hrmis==8
append using cpsmonths_ctc_linked 
save cpsmonths_ctc_linked, replace





cd "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data"

* link March basic to ASEC
* open the ipums files to merge in variables necessary for linking
use "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data\ipums\mar_jan_hrhhids\hrhhids_merge.dta", clear

* merge linking vars with ASEC
rename (hseq pernum lineno) (ph_seq p_seq a_lineno)
keep if year==2022 // just keep the asec 2022

merge 1:1 ph_seq p_seq a_lineno using asec2022
gen mish_march = mish
keep if _merge==3
drop _merge

* Merge ASEC with basic 
g pulineno = a_lineno
cd "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data\cpsmonthly"
merge 1:1 hrhhid hrhhid2 pulineno using cpsm202203
keep if _merge==3
keep if hrmis == 1 | hrmis == 5
drop _merge 
save asec_basic_matches, replace 



* merge the asec-matchable onto the basic months
merge m:1 hrhhid hrhhid2 pulineno month using cpsmonths_ctc_linked
g match = (_merge==3)
bys year hrhhid hrhhid2 pulineno: egen matches = max(match)
keep if matches>=1


tab mish if month==3
tab month

sort hrhhid hrhhid2 pulineno month
order hrhhid hrhhid2 pulineno month hrmis

save spring22_panel, replace