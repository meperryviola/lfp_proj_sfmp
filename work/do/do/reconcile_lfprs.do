** Objective: identify single and multi-family households

* Problem: my lfpr for <25k family income group is not matching Shigeru's <25k hh income group's lfpr
* Difference hinges on the fact that family and HH are different.
* some families live in multi-family households and may have combined HH income greater than 25k
* 

* another consideration is that Shigeru's income categories are made off of income totals that we computed ourselves. These contain things that weren't in htotval. 

global datapath "/home/c1mep01/Work/madison_cps/data"
global logpath "/home/c1mep01/Work/childtaxcredit_proj_sfmp/work/logs"
global texpath "/home/c1mep01/Work/childtaxcredit_proj_sfmp/work/tex"
*cd "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data"
cd "$datapath"

use loglinear_imputed_2019, clear
append using loglinear_imputed_2020, force
append using loglinear_imputed_2021, force

keep if is_asec==1

** show the relationship between ftotval and unlog_ftotval
* assert unlog_ftotval==ftotval // is overwhelmingly false. Why would doing something and then undoing it change the values 
g check = unlog_ftotval/ftotval
sum check // shows us the differences are miniscule.
browse ftotval unlog_ftotval if check==. // the ones who have 0 for ftotval or . 


** check if it affects the thresholds at all
assert fixed1_cat==1 if ftotval<25000.00
*browse ftotval unlog_ftotval if ftotval<25000.00 & fixed1_cat!=1 // this shows just the cases where ftotval==0 or ftotval is negative. unlog_ftotval takes a missing value for those. Doesn't appear to affect anyone else's threshold assignment.

* fix the yearmth variable for ASEC observations:
forvalues x = 2020/2022 {
	replace yearmth = `x'03 if is_asec==1 & year==`x'
}

* fix the year and month components into a time variable

replace year = 2019 if yearmth<202001 // somehow year got messed up for 2019. I don't know where.

g time = ym(year, month)
format time %tm

replace LF = LF*100

** make indicator for not in primary family (nipf). Will use this to identify people in multifamily HHs. 

/*
g nipf=.

bys ph_seq year: replace nipf = (a_famtyp>=3) if is_asec==1
bys hrhhid hrhhid2 yearmth: replace nipf = (prfamtyp>=3) if is_basic==1

g otherfam = .
bys ph_seq year: replace otherfam = sum(nipf) if is_asec==1 // this counts the number of people per HH who are not in the primary family. It does not count the number of distinct other families. Only the number of people outside the primary family.
bys hrhhid hrhhid2 yearmth: replace otherfam = sum(nipf) if is_basic==1

g multifam = (otherfam>=1) // indicator for person lives in HH with at least one person not in the primary family. 
*/

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



table (multifam) (year)  if fixed1_cat==1 & is_asec==1, stat(frequency) nformat(%6.0fc) // NOTICE this overstates the number of people in case 1 bc we did not condition on having htotval<25000.
* the above is useful bc it gives the grand total for the universe.

table () (year) if unlog_ftotval<25000.00 & is_asec==1, stat(frequency) nformat(%6.0fc) // double checking that the condition fixed1_cat==1 is equivalent to unlog_ftotval<25000.00

** check how much the ftotval vs. unlog_ftotval distinction changes counts
table () (year) if ftotval<25000.00 & is_asec==1, stat(frequency) nformat(%6.0fc) 

browse ftotval unlog_ftotval if ftotval>=25000.00 & unlog_ftotval<25000.00
browse ftotval unlog_ftotval if ftotval>=25000.00 & fixed1_cat==1
browse ftotval unlog_ftotval if fixed1_cat!=1 & unlog_ftotval<25000.00

** how many people have zero or negative ftotval?
table () (year) if ftotval==0 & is_asec==1, stat(frequency) nformat(%6.0fc)

table () (year) if ftotval<0 & is_asec==1, stat(frequency) nformat(%6.0fc)



**# Is this a problem? It differs from another 
table () (year) [fweight=marsupwt] if ftotval<25000.00 & ftotval>0, stat(mean LF) nformat(%6.1fc)

table () (year) [fweight=marsupwt] if unlog_ftotval<25000.00 & is_asec==1, stat(mean LF) nformat(%6.1fc)


******* use ftotval this point on *************
** because we are just making summary statistics using bucketed ASEC actual income values.


*** these make table 1 information ***
table (multifam) (year)  if ftotval<25000.00 & htotval<25000.00 & is_asec==1, stat(frequency) nformat(%6.0fc)

table (multifam) (year) if ftotval<25000.00 & htotval>24999.99 & is_asec==1, stat(frequency) nformat(%6.0fc)


* show what happens when remove unlog_ftotval<25000.00 - now that unlog_ftotval is corrected, it's no difference
table (multifam) (year)  if htotval<25000.00 & is_asec==1, stat(frequency) nformat(%6.0fc)

*compare to...
table (multifam) (year) if ftotval<25000.00 & htotval<25000.00 & is_asec==1, stat(frequency) nformat(%6.0fc)



** tabulate the people that have ftotval>htotval
table (multifam) (year)  if ftotval>24999.99 & htotval<25000.00 & is_asec==1, stat(frequency) nformat(%6.0fc)

table (multifam) (year)  if htotval>24999.99 & ftotval<25000.00 & is_asec==1, stat(frequency) nformat(%6.0fc)


******************************************

* mean htotval
table (multifam) (year)  if ftotval<25000.00 & is_asec==1 [fweight=marsupwt], stat(mean htotval) nformat(%6.0fc)

table (multifam) (year)  if htotval<25000.00 & is_asec==1 [fweight=marsupwt], stat(mean htotval) nformat(%6.0fc)

** Labor force participation rates


table (multifam) (year) if ftotval<25000.00 & htotval<25000 & is_asec==1 [fweight=marsupwt], stat(mean LF) nformat(%6.1fc) // cases 1 and 3
table (multifam) (year) if ftotval<25000.00 & htotval>=25000.00 & is_asec==1 [fweight=marsupwt], stat(mean LF) nformat(%6.1fc) // cases 2 and 4

table () (year) [fweight=marsupwt] if ftotval<25000.00, stat(mean LF) nformat(%6.1fc) // Gives madison grand average


table () (year) if ftotval<25000.00 & ftotval>0 & is_asec==1 [fweight=marsupwt], stat(mean LF) nformat(%6.1fc) // OLD for comparison to before unlog_ftotval fix.



** recall that we weren't using htotval to assign income categories - we were using in March our own income accounting
* Household accounting: 

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


recode h_tot_income_calc (0/24999 = 1) (25000/49999 = 2) (50000/99999 = 3) (100000/149999 = 4) (150000/. = 5), generate(income_cat)
label variable income_cat "Household income category"
label define income_cat_labels 1 "up to $24,999" 2 "$25,000-$49,000" 3 "$50,000-$99,999" 4 "$100,000-$149,999" 5 "$150,000+"
label values income_cat income_cat_labels

** try again the tabulation 
table () (year) if income_cat==1 [fweight=marsupwt], stat(frequency)

table () (year) if income_cat==1 [fweight=marsupwt], stat(mean LF) nformat(%6.1fc) // this is super close to Shigeru's numbers.



table (income_cat) (year) [fweight=marsupwt], stat(mean LF) nformat(%6.1fc) // this is super close to Shigeru's numbers.

table () (year) if income_cat==1 & ftotval<25000.00 [fweight=marsupwt], stat(mean LF) nformat(%6.1fc)


g inccat1_ind = (income_cat==1)

** Table 5 & 6 & 7
table (inccat1_ind) (year) [fweight=marsupwt] if ftotval<25000.00, stat(frequency)

table (inccat1_ind) (year) [fweight=marsupwt] if ftotval<25000.00, stat(mean LF) nformat(%6.1fc) 

table () (year) [fweight=marsupwt] if ftotval<25000.00, stat(fvproportion inccat1_ind) nformat(%6.2fc) 
***

** This section just does the same computations in a different way and gets the same results.
g group1 = (income_cat==1 & ftotval<25000.00) // ftotval<25000.00

bys year: sum group1 if is_asec==1 & ftotval<25000.00

g group2 = (income_cat>1 & ftotval<25000.00)
bys year: sum group2 if is_asec==1 & ftotval<25000.00

g group = . // doing this to make the table of weighted averages show nicely.
replace group=group1 if group1==1
replace group=2 if group2==1

** LFPRs again
table (group) (year) if fixed1_cat==1 & is_asec==1 [fweight=marsupwt], stat(mean LF) // Grand average

table () (year) if fixed1_cat==1 & income_cat==1 & is_asec==1 [fweight=marsupwt], stat(mean LF) // gr[fweight=marsupwt]

table () (year) if income_cat==1 & is_asec==1 [fweight=marsupwt], stat(mean LF) // 

table () (year) if income_cat==1 & is_asec==1, stat(mean LF) // 


table () (year) if fixed1_cat==1 & income_cat>1 & is_asec==1 [fweight=marsupwt], stat(mean LF) // group2
