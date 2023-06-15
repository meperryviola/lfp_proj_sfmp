********* Initial investigation of variable ***************

cd "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data\cpsmonthly"

use cpsmonths_ctc_linked, clear

sort hrhhid hrhhid2 pulineno hrmis yearmth
order hrhhid hrhhid2 pulineno prtage hrmis yearmth hefaminc prpertyp

* should I hold hefaminc fixed from May onward?
* grab just hefaminc for May
g may_hefaminc = hefaminc if yearmth==202105
bys hrhhid hrhhid2: egen const_faminc = mean(may_hefaminc)

order hrhhid hrhhid2 pulineno prtage hrmis yearmth hefaminc const_faminc prpertyp

* check that HEFAMINC is actually a household-level variable
g head_faminc = hefaminc if perrp==40 | perrp==41
bys hrhhid hrhhid2 yearmth: egen hh_faminc = sum(head_faminc)
*assert hefaminc==hh_faminc
browse if hefaminc!=hh_faminc // only cases are those with hefaminc==-1

order hrhhid hrhhid2 pulineno prtage hrmis yearmth hefaminc hh_faminc head_faminc

** What is HEFAMINC relationship to HTOTVAL? 
cd "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data" // Madison path
use asec_19to22.dta, clear // Madison dta name

*browse hefaminc htotval // there is some disagreement, both understating and overstating.
* HEFAMINC is Family income from basic CPS income screener question.
*  per documentation "NOTE: If a nonfamily household, income includes only that of householder."

****************** end *********************************



