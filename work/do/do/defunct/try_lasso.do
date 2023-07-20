***** Try using Lasso to figure out a good model
// last edited 5/12/23

global datapath "/home/c1mep01/Work/madison_cps/data"

*cd "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data"
cd "$datapath"


use impute2019, clear 
keep if is_asec==1
save samp_asec19, replace

use impute2019, clear 
keep if is_basic==1

unab basicvars : * // make vector of all vars.
append using samp_asec19

keep if is_asec==1
keep `basicvars'

** Perform the set of variable transformations:

* make a unified age variable
g age = prtage if is_basic==1
replace age = a_age if is_asec==1

* make a unified sex variable
g sex = pesex if is_basic==1
replace sex = a_sex if is_asec==1


g kid = (age<18)
g adult = (age>=18)
g elderly = (age>64)

* make marital status variables
g marital = (a_maritl<4) if is_asec==1
replace marital = 0 if marital!=1

* make count kids variable - note this is number of kids in the same household as the person.
bys year ph_seq: egen numkid = sum(kid) if is_asec==1
bys year ph_seq: egen numadult = sum(adult) if is_asec==1

bys yearmth hrhhid hrhhid2: replace numkid = sum(kid) if is_basic==1
bys yearmth hrhhid hrhhid2: replace numadult = sum(adult) if is_basic==1

* make number of kids bins
g numkid_bin = 0 if numkid==0
replace numkid_bin = 1 if numkid==1
replace numkid_bin = 2 if numkid==2 | numkid==3
replace numkid_bin = 4 if numkid>=4

g numadult_bin = 1 if numadult==1
replace numadult_bin=2 if numadult==2
replace numadult_bin=3 if numadult==3
replace numadult_bin=4 if numadult>=4

** simplified race variable
g race = prdtrace if is_asec==1
replace race = ptdtrace if is_basic==1
replace race = 1 if race==1
replace race = 2 if race==2
replace race = 3 if race>2 & race<.

** simplified educational attainment variable
g educ = a_hga if is_asec==1
replace educ = peeduca if is_basic==1
replace educ = 1 if educ<39
replace educ = 2 if educ==39
replace educ = 3 if educ>=40 & educ<43
replace educ = 4 if educ==43 
replace educ = 5 if educ>43 & educ<.

label define edlabel 1 "LTHS" 2 "HS grad" 3 "some coll" 4 "Bachelors" 5 "Adv deg"
label values educ edlabel

* make var to capture the maximum level of education attained by any member of the family.
bys ph_seq: egen max_educ1 = max(educ) if is_asec==1
bys yearmth hrhhid hrhhid2: egen max_educ2 = max(educ) if is_basic==1
g max_educ = max_educ1
replace max_educ = max_educ2 if is_basic==1 // THis is a dumb thing I have to do bc bysort won't cooperate with "replace" and max().

label values max_educ edlabel

* repeat to make a minimum education level var.
bys ph_seq: egen min_educ1 = min(educ) if is_asec==1
bys yearmth hrhhid hrhhid2: egen min_educ2 = min(educ) if is_basic==1
g min_educ = min_educ1
replace min_educ = min_educ2 if is_basic==1 
label values min_educ edlabel

* make variables that capture spousal characteristics
* we are ignoring subfamilies right now. 

* first, mark primary and secondary person in the monthly.
g refperson = (prfamrel==1)
replace refperson = 2 if (prfamrel==2)
* do the same thing for the ASEC records
bys ph_seq yearmth: replace refperson = 1 if p_seq==fheadidx & is_asec==1
bys ph_seq yearmth: replace refperson = 2 if p_seq==fspouidx & is_asec==1


g emp_prim = ((pemlr==1 | pemlr==2) & refperson==1)
bys hrhhid hrhhid2 yearmth: egen emp_prim1 = max(emp_prim) if is_basic==1
bys ph_seq yearmth: egen emp_prim2 = max(emp_prim) if is_asec==1

g emp_sec = ((pemlr==1 | pemlr==2) & refperson==2) 
bys hrhhid hrhhid2 yearmth: egen emp_sec1 = max(emp_sec) if is_basic==1
bys ph_seq yearmth: egen emp_sec2 = max(emp_sec) if is_asec==1

g spousemp = .
replace spousemp = emp_prim1 if refperson==2 & is_basic==1 // put the primary person's employment status in the secondary person's row.
replace spousemp = emp_prim2 if refperson==2 & is_asec==1
replace spousemp = emp_sec1 if refperson==1 & is_basic==1 // vice versa
replace spousemp = emp_sec2 if refperson==1 & is_asec==1
replace spousemp=0 if marital==0


* carry AGI across the family - initially the only people with agi values were the reference people for each family
bys ph_seq: egen fam_agi = max(agi)

* drop the observations of kids.
drop if age<18


* make clones and then mess with variable transformations
local varlist = "ftotval fam_agi fearnval"
foreach varname in `varlist'{
	clonevar clone_`varname' = `varname'
}


** use the log of ftotval as the outcome
g lnftotval = ln(ftotval)


* This is called Post Double selection lasso. This is causal ML code. 


* I first want to just put the variables I want to impute in the y position 

local yd lnftotval ftotval fearnval fam_agi  LF hh_lfp  // Pull out the outcomes. I also may want to pull out the variables that I can't use bc it would be predicting using someting we'd use later as an outcome in the analysis. I know I should take out all income-related variables.

*qstnum occurnum h_idnum2 h_idnum1 peridnum



local X : list basicvars - yd
local numXs : list sizeof X
display "Number of Xs in dictionary: `numXs'"
lasso linear ftotval `X' // Lasso the outcome on X


local Xy `e(basicvars_sel)'
local ky = e(k_nonzero_sel)
display "num covs kept by outcome lasso: `ky'"



/** Below this point is the example code **
local yd ftotval fearnval fam_agi  // Pull out the outcome(s) and main regressor from the vector of all variables. The 'y' and the 'd'. Also pull out the string variables 
local X : list basicvars - yd
local numXs : list sizeof X
display "Number of Xs in dictionary: `numXs'"

** PDS Lasso with CV-chosen penalty

lasso linear lnftotval `X' // Lasso the outcome on X
local Xy `e(basicvars_sel)'
local ky = e(k_nonzero_sel)
display "num covs kept by outcome lasso: `ky'"

* lasso treatment on X
lasso linear black `X' // Lasso the 'treatment' on X 
local Xd `e(allvars_sel)'
local kd = e(k_nonzero_sel)
display "num covs kept by treatment lasso: `kd'"

* regress outcome on treatment and union of controls
reg lnw_2016 black `Xy' `Xd',robust	

** THis is a shortcut that does PDS lasso with "plugin penalty", which I don't know what that is. 









