** Determine characteristics of Low-LFPR HHs
* meant for use following "impute_loglinear.do"

// last edited 5/31/23

* paths
global datapath "/home/c1mep01/Work/madison_cps/data"
global logpath "/home/c1mep01/Work/childtaxcredit_proj_sfmp/work/logs"

cd "$datapath"

use loglinear_imputed_2019, clear // just using one year for now
keep if is_asec==1 // because I am trying to see if I drop households with low attachment to the labor market, does that bring the LFPRs of the predicted income categories closer to the LFPRs of the actual income categories?

recode unlog_phat_ftotval (0/25000 = 1) (25000.01/49999.99 = 2) (50000/99999.99 = 3) (100000/149999.99 = 4) (150000/. = 5), generate(fixed2_cat)

recode unlog_ftotval (0/25000 = 1) (25000.01/49999.99 = 2) (50000/99999.99 = 3) (100000/149999.99 = 4) (150000/. = 5), generate(fixed1_cat)


* bin age
recode age (0/15 = 0) (16/19 = 1) (20/24 = 2) (25/29 = 3) (30/34 = 4) (35/39 = 5) (40/44 = 6) (45/49 = 7) (50/54 = 8) (55/59 = 9) (60/64 = 10) (65/. = 11), generate(age_bin)


reg hh_lfp i.fixed1_cat##i.elderly age age2  i.hefaminc i.race##i.max_educ i.min_educ i.spousemp i.peafever i.hrhtype c.numadult i.sex##i.marital c.numkid##i.under6 i.h_tenure

** Just start looking at things
g lowlfp = (hh_lfp<0.25)

bys lowlfp: tab elderly

bys lowlfp elderly: tab marital

bys lowlfp marital: tab numkid_bin if elderly==0



bys lowlfp elderly: tab race

tab age_bin if lowlfp==1 // reinforces elderly significance

bys lowlfp race: tab educ if elderly==0

tab age if marital==0 & elderly==0 & lowlfp==1

bys lowlfp elderly: tab numadult_bin
