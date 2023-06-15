* Produce summary statistics for each of the 16 cells created by the stratifiers in Enriquez et al's weighted hotdeck procedure. 

// written by Madison Perry 4/27/2023

global dopath "C:\Users\c1mep01\OneDrive - FR Banks\childtaxcredit_proj_sfmp\work\do"
global datapath "C:\Users\c1mep01\OneDrive - FR Banks\madison_cps\data"
global texpath "C:\Users\c1mep01\OneDrive - FR Banks\childtaxcredit_proj_sfmp\documentation\tex"
*global datapath "/home/c1mep01/Work/madison_cps/data" // cluster
*global texpath "/home/c1mep01/Work/childtaxcredit_proj_sfmp/documentation/tex"

forvalues x = 2020/2022 {
	clear
cd "$datapath"

* use the ASEC file to see what kind of differentiation we can see between the mean observed values of these cells
use asec`x', clear

* make the variables I'll use as stratifiers

* make a unified age variable
g age = a_age 

* make a unified sex variable
g sex = a_sex 


g kid = (age<18)
*g youngkid = (age<6)
g adult = (age>=18)
g elderly = (age>64)

* make marital status variables
g marital = (a_maritl<4) 

replace marital = 0 if marital!=1

* make count kids variable - note this is number of kids in the same household as the person.
bys year ph_seq: egen numkid = sum(kid) 
bys year ph_seq: egen numadult = sum(adult) 


* make number of kids bins
g numkid_bin = 0 if numkid==0
replace numkid_bin = 1 if numkid==1
replace numkid_bin = 2 if numkid==2 | numkid==3
replace numkid_bin = 3 if numkid>=4

* carry AGI across the family
bys ph_seq: egen fam_agi = max(agi)

label define marital_label 0 "Unmarried" 1 "Married"
label define elderly_label 0 "Under 65" 1 "65+"
label define kids_label 0 "None" 1 "1 child" 2 "2-3 children" 3 "4+ children"

label values elderly elderly_label
label values marital marital_label
label values numkid_bin kids_label

drop if age<18

* print tables of cell means
cd "$texpath"
table (marital elderly) (numkid_bin) (hefaminc), stat(frequency) nformat(%7.0fc mean) nototals
collect export cellsize_`x'.tex, replace 

table (marital elderly) (numkid_bin) (hefaminc), stat(mean ftotval) nformat(%7.0fc mean) nototals
collect export cellmeans_ftotval_`x'.tex, replace 

table hefaminc (), stat(mean ftotval fam_agi fearnval) nformat(%7.0fc mean) 
collect export means_by_hefam`x'.tex, replace 

}

