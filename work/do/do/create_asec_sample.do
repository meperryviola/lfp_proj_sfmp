** THis file creates the CPS ASEC sample, 

global datapath "/home/c1mep01/Work/madison_cps/data"
cd "$datapath"

use asec2020, clear
append using asec2021, force
append using asec2022, force
save asec_raw_20to22.dta, replace

* this syntax from enriquez
/*** Load Data ***/

use year a_age pemlr a_maritl h_hhnum peridnum perrp ftotval agi filestat /// 
	 marsupwt a_lineno ph_seq pf_seq a_hga a_sex prdtrace peafever ///
	 htotval pehspnon prcitshp hefaminc hrhtype fearnval hrhtype gestfips ///
	 using asec_raw_20to22, clear
	
/*** Prepare Data ***/

* switch from survey year to reference year
replace year = year-1

* this syntax also from enriquez
* duplicate 2021 to use for 2022 values
gen dupe = 1
replace dupe = 2 if year == 2021
expand dupe, gen(doppel)
replace year = 2022 if doppel == 1
drop dupe doppel

**
g is_asec=1

g age = a_age if is_asec==1


drop if age==.

g kid = (age<18)
g adult = (age>=18)
g elderly = (age>64)


g adult_age = age if adult==1
bys year ph_seq pf_seq: egen mean_age = mean(adult_age)

g mean_age2 = mean_age*mean_age

* make count kids variable - note this is number of kids in the same household as the person.
bys year ph_seq pf_seq: egen numkid = sum(kid) if is_asec==1
bys year ph_seq pf_seq: egen numadult = sum(adult) if is_asec==1
gen famsize = numadult +numkid
* indicate if age of youngest child is less than 6
g under6 = (age<6)
bys year ph_seq pf_seq: g sum_under6 = sum(under6)
g share_under6 = sum_under6/numkid // Share of children in the family under age 6
replace share_under6 = 0 if numkid==0


* count number of elderly people in household
bys year ph_seq pf_seq: egen sum_elderly = sum(elderly)
g share_elderly = sum_elderly/numadult // Share of adults in the family above 65

g educ = a_hga
replace educ = 1 if educ<39
replace educ = 2 if educ==39
replace educ = 3 if educ>=40 & educ<43
replace educ = 4 if educ==43 
replace educ = 5 if educ>43 & educ<.
label define edlabel 1 "LTHS" 2 "HS grad" 3 "some coll" 4 "Bachelors" 5 "Adv deg"
label values educ edlabel

* make var to capture the maximum level of education attained by any member of the family.
bys year ph_seq pf_seq: egen max_educ = max(educ) 
* repeat to make a minimum education level var.
g educ_adult = educ if adult==1
bys year ph_seq pf_seq: egen min_educ = min(educ_adult)

g marital = (a_maritl<4) if is_asec==1
replace marital = 0 if marital!=1
bys year ph_seq pf_seq: egen count_married = sum(marital)
g share_married = count_married/numadult // share of adults in family that are married

* share of family that is Black
g black = (prdtrace==2)
bys year ph_seq pf_seq: egen sum_black = sum(black)
g share_black = sum_black/famsize

* share of family that is Hispanic
g hisp = (pehspnon==1)
bys year ph_seq pf_seq: egen sum_hisp = sum(hisp)
g share_hisp = sum_hisp/famsize

* share of family that is immigrant
g immg = (prcitshp>=4 & prcitshp<=5)
bys year ph_seq pf_seq: egen sum_immg = sum(immg)
g share_immg = sum_immg/famsize


* ratio of children to adults 
g kid_ratio = numkid/numadult

* carry AGI across the family - initially the only people with agi values were the reference people for each family
replace agi = ftotval if filestat>=6 // set agi to family income for nonfiling families. 
bys year ph_seq pf_seq: egen fam_agi = max(agi)


save asec_20to22_inc, replace

/*
bys year ph_seq pf_seq: egen min_lineno = min(a_lineno)
g famhead = (a_lineno==min_lineno)

g sex = a_sex

** age of family head
g age_fh = age if famhead==1

* want sex of family head
g sex_fh = sex if famhead==1

g marital = (a_maritl<4) if is_asec==1
replace marital = 0 if marital!=1
g marital_fh = marital if famhead==1 

g race = prdtrace if is_asec==1
replace race = 1 if race==1
replace race = 2 if race==2
replace race = 3 if race>2 & race<.
g race_fh = race if famhead==1

g hisp = (pehspnon==1)
g hisp_fh = hisp if famhead==1

* carry AGI across the family - initially the only people with agi values were the reference people for each family
replace agi = ftotval if filestat>=6 // set agi to family income for nonfiling families. 
bys year ph_seq pf_seq: egen fam_agi = max(agi)


** indicator for famhead military service
g vetstat = (peafever==1)
g vetstat_fh = vetstat if famhead==1

*trying to tweak model to improve predictive 
g age2 = age*age
g age_fh2 = age_fh*age_fh

g elderly_fh = elderly if famhead==1

save asec_20to22_inc, replace

** 
collapse numkid numadult sumretired max_educ elderly_fh hrhtype min_educ age_fh sex_fh marital_fh race_fh hisp_fh vetstat_fh age_fh2 ftotval fearnval agi fam_agi  htotval is_asec (max) under6 hefaminc, by(year ph_seq pf_seq)

save asec_20to22_collapsed, replace
