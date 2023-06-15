
* obj: compute full amount individuals would get based on assumption that the kids they are claiming as their own is indeed the number of children in the house.
* apply proper phaseout based on whether they are married filing jointly or not.

// This file was last updated 5/9/2023 by Madison Perry

* note that we can't differentiate between Head of Household and Single filers that have a dependent.
* They have similar phaseouts, except the first threshold. 

* note also that this file is meant to come after the indiv-level imputation of ftotval fam_agi and fearnval 
* this file takes in the variables "ftotval" "fam_agi" and "fearnval" with the assumption that the imputed values have been filled in under these variable names. THe originals of those variables are called "clone_`varname'".


global datapath "/home/c1mep01/Work/madison_cps/data"
cd "$datapath"

**** Pick the imputed dataset from list below:
*use EJT_replication, clear // This is the hotdeck-imputed set.
*use linear2_imputed, clear // this is the linear-predicted 
*use mice_imputed, clear // this is mice-imputed

* add the kids back in, only to  count them and get their ages
append using kids_obs_preimpute2019, force
append using kids_obs_preimpute2020, force
append using kids_obs_preimpute2021, force

* keep only the basic observations
keep if is_basic==1


* compute maximum possible annual benefit based on number of kids and ages and eligibility
capture drop youngkid
g youngkid = (prtage<6)
g oldkid = (prtage<18 & youngkid!=1)

bys hrhhid hrhhid2 yearmth: egen num_youngkids = sum(youngkid)
bys hrhhid hrhhid2 yearmth: egen num_oldkids = sum(oldkid)

* THis just shows that prnmchld is unreliable bc of double counting if both spouses claim own-children
*It's also number of own kids. Not number of own kids PRESENT IN HH.
bys hrhhid hrhhid2 yearmth: egen num_ownkids = sum(prnmchld)

*browse num_ownkids num_oldkids num_youngkids // evidence of doublecounting

* drop the kids again now
drop if age<18

* split individuals into filer status based on marital status and age. 
g filerstat = .
replace filerstat=1 if pemaritl==1 | pemaritl==2 // MFJ
replace filerstat=2 if prtage<18 // Dependent children - this should be empty
replace filerstat=3 if prtage>18 & filerstat!=1 // single

* mark eligibility using number of own children (PRNMCHLD). Differentiate by marital status.
g elig = 1 if prnmchld>0 & prnmchld!=. & filerstat==1 // married and eligible adults
replace elig = 2 if prnmchld>0 & prnmchld!=. & filerstat==3 // unmarried and eligible adults


* this is annual and is only representing the possible in-hand (REFUNDABLE) amount. 
g maxtotal_ctc = 1400*(num_oldkids + num_youngkids) if year!=2021 & fearnval>2500 & (elig==1 | elig==2) // computing pre-reform max refundable benefit amount
replace maxtotal_ctc = (3600*(num_youngkids)+3000*(num_oldkids)) if year==2021 & (elig==1 | elig==2)


* use marital status and year to tell which phaseout to apply
g total_ctc = maxtotal_ctc // total_ctc will represent the actual benefit amount once rules are applied.

** Pre-reform rules:
* threshold for decrease for married joint tax unit is 400,000
replace total_ctc = (maxtotal_ctc)-((50)*((fam_agi-400000)/1000)) if elig==1 & year!=2021 // reduce by 50 for every 1000 above threshold 
* threshold for Head of Household or single is 200k
replace total_ctc = (maxtotal_ctc)-((50)*((fam_agi-200000)/1000)) if elig==2 & year!=2021

** Post-reform rules: 
replace total_ctc = (maxtotal_ctc)-((50)*((fam_agi-150000)/1000)) if elig==1 & year==2021 & fam_agi>150000
replace total_ctc = 2000*(num_oldkids+num_youngkids) if elig==1 & (2000*(num_oldkids+num_youngkids))>total_ctc & fam_agi>150000 & fam_agi<400000 // 
replace total_ctc = (total_ctc)-((50)*((fam_agi-400000)/1000)) if elig==1 & year==2021 & fam_agi>400000

replace total_ctc = (maxtotal_ctc)-((50)*((agi-75000)/1000)) if elig==2 & year==2021 & agi>75000
replace total_ctc = 2000*(num_oldkids+num_youngkids) if elig==2 & (2000*(num_oldkids+num_youngkids))>total_ctc & fam_agi>75000 & fam_agi<200000 //
replace total_ctc = (total_ctc)-((50)*((fam_agi-200000)/1000)) if elig==2 & year==2021 & fam_agi>200000


*g advance_ctc = 0.5*(total_ctc) if year==2021

* If married filing jointly, the pair will both be receiving the CTC together as one unit, but the spousal pairs are no longer linked so we can't really treat it like this. everybody is an individual. If someone is a stepdad and doesn't claim the kids as his own-children, we are not considering him to be "treated" with the CTC benefit even though he may be technically receving it along with his wife (who does claim the children)

g refund_ratio = (total_ctc/ftotval) if total_ctc>0 // this ratio should be at the household level

replace refund_ratio = 0 if total_ctc==0 


xtile ratio_pctile = refund_ratio if refund_ratio>0, nquantiles(100)
replace ratio_pctile = 0 if ratio_pctile==.

g advCTC = (yearmth>202107& yearmth<202201)
drop if pemlr == 0

gen E = (pemlr<=2) 
gen U = (pemlr>=3 & pemlr<=4)
gen N = (pemlr>=5)
gen pop = (E==1 | U == 1 | N == 1)
gen LF = (E==1 | U == 1)

table (ratio_pctile) (year) if age<65, stat(mean LF) nformat(%6.2f) // this looks ok.


*** specifically rename total_ctc to whatever data you used. Ex: total_ctc_hd, total_ctc_l2 
rename total_ctc totalctc_l2
rename refund_ratio refund_ratio_l2
rename ratio_pctile ratio_pctile_l2


table ratio_pctile_l2 yearmth if year==2021, stat(mean LF) nformat(%6.2f) // this looks wrong. THe rate appears too low for the sample and I dont understand why


* group pctile by quintiles and group ftotval by quintiles
