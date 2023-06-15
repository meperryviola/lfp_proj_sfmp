* This file takes the log-linear regression imputation model I developed in "try_improve_model_fit" and applies it to the combined ASEC-and-monthly data, using the "in-sample" ASEC values to predict for the "out of sample" basic.

// Last updated: 6/14/23

** apply the model to the data that needs imputing:

global datapath "/home/c1mep01/Work/madison_cps/data"
global logpath "/home/c1mep01/Work/childtaxcredit_proj_sfmp/work/logs"

*cd "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data"
cd "$datapath"


forvalues x = 2019/2021 {
use impute`x', clear


*** perform sample selection
* exclude 2 person HHs where both everyone is retired (pemlr==5)
g retired = (pemlr==5)
bys ph_seq: egen sumretired = sum(retired) if is_asec==1
bys hrhhid hrhhid2 yearmth: replace sumretired = sum(retired) if is_basic==1
*drop if h_numper==2 & sumretired==2 & is_asec==1 // UNCOMMENT ME
*drop if hrnumhou==2 & sumretired==2 & is_basic==1 // UNCOMMENT ME


**** THese are alternate sample restrictions we did not choose. ******
* exclude 1 and 2 person HHs where both everyone is retired (pemlr==5)
*drop if (h_numper==2 & sumretired==2) | (h_numper==1 & sumretired==1) // OR uncomment me

* exclude 1 person HHs under age 22 where person is in school
*drop if h_numper==1 & age<=22 & prnlfsch==1 // NILF activity in school // AND/OR uncomment me
*drop if hrnumhou==1 & age<=22 & prnlfsch==1
**********************************************************************



* make a unified age variable
g age = prtage if is_basic==1
replace age = a_age if is_asec==1
drop if age==.

* make a unified sex variable
g sex = pesex if is_basic==1
replace sex = a_sex if is_asec==1


g kid = (age<18)
g adult = (age>=18)
g elderly = (age>64)

* make marital status variables
g marital = (a_maritl<4) if is_asec==1
replace marital = (pemaritl<4) if is_basic==1
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


** age of reference person 
g age_refperson = age if refperson==1
bys hrhhid hrhhid2 yearmth: egen age_hher = max(age_refperson) if is_basic==1

* spousal employment status
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
* but, as we see later, inclusion of this variable in the regressions weakens the fit, even though it's significant.

** ftype in asec is prfamtyp
g familytype = ftype if is_asec==1
replace familytype = prfamtyp if is_basic==1

* h_tenure is hetenure - update this is missing for all observations
*g hh_tenure = h_tenure if is_asec==1
*replace hh_tenure = hptenure if is_basic==1

* make indicator for having at least one child under 6
g under6 = (fownu6>=1) if is_asec==1
replace under6 = 1 if is_basic==1 & (prchld!=3 | prchld!=4 | prchld!=10 | prchld!=-1)


* carry AGI across the family - initially the only people with agi values were the reference people for each family
bys ph_seq: egen fam_agi = max(agi)

* drop the observations of kids.
preserve 
keep if age<18
save kidsonly_`x', replace
restore

drop if age<16


** use the log of ftotval
g lnftotval = ln(ftotval)
g lnfearnval = ln(fearnval)
g lnfam_agi = ln(fam_agi)


** make household level labor force participation rate. 
gen E = (pemlr<=2) 
gen U = (pemlr>=3 & pemlr<=4)
gen N = (pemlr>=5)
gen pop = (E==1 | U == 1 | N == 1)
gen LF = (E==1 | U == 1)


bys ph_seq: egen hh_lfp1 = mean(LF) if is_asec==1
bys hrhhid hrhhid2 yearmth: egen hh_lfp2 = mean(LF) if is_basic==1
g hh_lfp = hh_lfp1
replace hh_lfp = hh_lfp2 if is_basic==1

** indicator for military service
replace peafever = 3 if peafever==-1


*trying to tweak model to improve predictive 
g age2 = age*age

recode age (0/15 = 0) (16/19 = 1) (20/24 = 2) (25/29 = 3) (30/34 = 4) (35/39 = 5) (40/44 = 6) (45/49 = 7) (50/54 = 8) (55/59 = 9) (60/64 = 10) (65/. = 11), generate(age_bin)

g hisp = (pehspnon==1)


** Regressions

regress lnftotval age age2 i.elderly i.hefaminc i.race##i.max_educ i.min_educ i.spousemp i.peafever i.hrhtype c.numadult i.sex##i.marital c.numkid##i.under6 if is_asec==1
predict phat_lnftotval

regress lnfam_agi age age2 i.elderly i.hefaminc i.race##i.max_educ i.min_educ i.spousemp i.peafever i.hrhtype c.numadult i.sex##i.marital c.numkid##i.under6 if is_asec==1
predict phat_lnfam_agi 

regress lnfearnval age age2 i.elderly i.hefaminc i.race##i.max_educ i.min_educ i.spousemp i.peafever i.hrhtype c.numadult i.sex##i.marital c.numkid##i.under6 if is_asec==1
predict phat_lnfearnval

local varlist = "ftotval fam_agi fearnval"
foreach varname in `varlist'{
	clonevar clone_`varname' = `varname'
	clonevar clone_ln`varname' = ln`varname'
	*replace `varname' = phat_`varname' if `varname'==. // this fills in the original with the imputed values for the ones previously missing, letting the ASEC ppl keep their actual values.
	replace ln`varname' = phat_ln`varname' if ln`varname'==.
	g unlog_`varname' = exp(ln`varname')
	g unlog_phat_`varname' = exp(phat_ln`varname') // This holds the predicted values for everybody, even ASEC.
}



** Fixed categories
recode unlog_phat_ftotval (0/25000 = 1) (25000.01/49999.99 = 2) (50000/99999.99 = 3) (100000/149999.99 = 4) (150000/. = 5), generate(fixed2_cat)

recode unlog_ftotval (0/25000 = 1) (25000.01/49999.99 = 2) (50000/99999.99 = 3) (100000/149999.99 = 4) (150000/. = 5), generate(fixed1_cat)

xtile p_qtile = unlog_phat_ftotval, nquantiles(5)
xtile actual_qtile = unlog_ftotval, nquantiles(5)

save loglinear_imputed_`x', replace
}


