* create cross sectional file of all CPS months August 19 - March 23
** This is the sample needed for replicating Enriquez, Jones, Tedeschi (2023)

* then separately create linked sample of people in cps months May 21 - August 21
** This is a smaller panel that Shigeru wanted.

clear 
set more off

global monthlypath "/home/c1mep01/Work/madison_cps/data/cpsmonthly"
global datapath "/home/c1mep01/Work/madison_cps/data"


cd "$monthlypath"
*cd "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data\cpsmonthly"


* read in the monthly CSVs and save as dta 
local x=202001

while `x' <= 202303{
clear

import delimited "/home/c1mep01/Work/madison_cps/data/cpsmonthly/cpsm`x'.csv"

gen yearmth = `x'
local year=round(`x'/100)
local month=round((`x'-`year'*100))

gen year = `year'
g month = `month'

save cpsm`x', replace


local x = `x' + 1
if (`x'-13)/100 == int((`x'-13)/100) {
    local x = `x' + 88
    }

}

* Note that the DTA files for 2019 monthly basic were pulled from the inherited "Reasons for Nonparticipation" folder.
* this is because those had to be read in from RAW format and the code to do that was in that folder.

forvalues x = 201901/201912 {
use cpsm`x', clear
*gen yearmth = `x'
local year=round(`x'/100)
local month=round((`x'-`year'*100))
gen year = `year'
g month = `month'

destring hrhhid, replace // the 2019 ones had been read in differently so these identifiers were strings but i need them to match the others.
destring hrhhid2, replace

save cpsm`x', replace 
}


** Match the correct ASEC reference year to the basic monthly files from that reference year.
** Example: 2020 ASEC asks about income from 2019 so should go with 2019 basic files.

* Grab 2019 basics
cd "$monthlypath"
use cpsm201901, clear
save impute2019, replace
local x=201902
while `x' <= 201912{
append using cpsm`x', force

local x = `x' + 1
if (`x'-13)/100 == int((`x'-13)/100) {
    local x = `x' + 88
    }
}

* Append the 2020 ASEC
g is_basic=1
cd "$datapath"
append using asec2020
g is_asec=1 if is_basic!=1
save impute2019, replace // save the first set




* grab the 2020 basics
cd "$monthlypath"
use cpsm202001, clear
save impute2020, replace
local x=202002
while `x' <= 202012{
append using cpsm`x', force

local x = `x' + 1
if (`x'-13)/100 == int((`x'-13)/100) {
    local x = `x' + 88
    }
}
* Append the 2021 ASEC
cd "$datapath"
g is_basic=1
append using asec2021
g is_asec=1 if is_basic!=1
save impute2020, replace // save the second set



* grab the 2021-2023 basics
cd "$monthlypath"
use cpsm202101, clear
save impute2021, replace
local x=202102
while `x' <= 202303{
append using cpsm`x', force

local x = `x' + 1
if (`x'-13)/100 == int((`x'-13)/100) {
    local x = `x' + 88
    }
}
* Append the 2022 ASEC
cd "$datapath"
g is_basic=1
append using asec2022
g is_asec=1 if is_basic!=1
save impute2021, replace // save the third set



/* make big cross sectional file of all months August19 - March22
use cpsm201908, clear
save ctc_crosssection, replace
local x=201909
while `x' <= 202303{
append using cpsm`x', force

local x = `x' + 1
if (`x'-13)/100 == int((`x'-13)/100) {
    local x = `x' + 88
    }
}

save ctc_crosssection, replace

** end


* create linked sample of people in May 21 - August 21
use cpsm202105, clear
keep if hrmis == 1 | hrmis == 5
save cpsmonths_ctc_linked, replace

use cpsm202106, clear
keep if hrmis == 2 | hrmis == 6
append using cpsmonths_ctc_linked
save cpsmonths_ctc_linked, replace

use cpsm202107, clear
keep if hrmis == 3 | hrmis == 7
append using cpsmonths_ctc_linked 
save cpsmonths_ctc_linked, replace

use cpsm202108
keep if hrmis == 4 | hrmis==8
append using cpsmonths_ctc_linked 
save cpsmonths_ctc_linked, replace


