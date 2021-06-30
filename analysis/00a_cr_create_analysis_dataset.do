/*==============================================================================
DO FILE NAME:			00a_cr_create_analysis_dataset
PROJECT:				VE in COVID-19 test negative design
DATE: 					15 June 2020 
AUTHOR:					L Lansbury and T McKeever
								
DESCRIPTION OF FILE:	program 00, data management for NSAID project  
						reformat variables 
						categorise variables
						label variables 
DATASETS USED:			data in memory (from output/input_xxx.csv)
DATASETS CREATED: 		none
OTHER OUTPUT: 			logfiles, printed to folder analysis/$logdir
							
==============================================================================*/

* Open a log file

** this is the pathname they use in their file- which does not quite help me on the pathname for you filr tr[p
log using $logdir\00a_cr_create_analysis_dataset, replace t




//importing data

import delimited "/Users/mszlel/Documents/GitHub/tncc_ve/output/input.csv"

rename prior_primary_care_covid_case_da prior_pc_covid_case_date

local dates "covid_vax_1_date covid_vax_2_date  covid_vax_3_date covid_vax_4_date covid_vax_pfizer_1_date covid_vax_pfizer_2_date covid_vax_pfizer_3_date covid_vax_pfizer_4_date covid_vax_az_1_date covid_vax_az_2_date covid_vax_az_3_date covid_vax_az_4_date prior_positive_test_date prior_pc_covid_case_date prior_admitted_for_covid_date positive_test_1_date negative_test_result_1_date primary_care_covid_case_1_date admitted_1_date coviddeath_date death_date"

foreach var of local dates {
gen `var'2=date(`var', "YMD")
format `var'2 %d
}

local string "bmi sex stp region care_home_type"

foreach var of local string {
    encode `var', gen (`var'2)
	
}

gen carehome = care_home_type2
recode carehome 1/3=1 .=0

//Covid diagnosis
gen covid = positive_test_1_date2
recode covid min/max=1
tab covid

gen nocovid = negative_test_result_1_date2
recode nocovid min/max=1
tab nocovid

//exclude if neg result within 3 weeks of positive_test_1_date
gen covid2= covid

recode covid2 .=0 if nocovid==1

gen testtime = positive_test_1_date2-negative_test_result_1_date2

//early summary of data
summ age, detail

gen ageg = age
recode ageg 18/39=1 40/64=2 65/79=3 80/max=4 min/17=.

local desc "ageg sex2 bmi2 carehome has_follow_up_previous_year ethnicity_16 ethnicity region2 imd chronic_cardiac_disease diabetes_type_1 diabetes_type_2 diabetes_unknown_type current_copd dmards dementia dialysis solid_organ_transplantation chemo_or_radio intel_dis_incl_downs_syndrome lung_cancer cancer_excl_lung_and_haem haematological_cancer bone_marrow_transplant cystic_fibrosis sickle_cell_disease permanant_immunosuppression temporary_immunosuppression psychosis_schiz_bipolar asplenia"

foreach var of local desc {
    tab `var'
}

//Pfizer vaccine doses 1 and 2
gen pfizerd1 = covid_vax_pfizer_1_date2
recode pfizerd1 min/max=1

gen pfizerd2 = covid_vax_pfizer_2_date2
recode pfizerd2 min/max=1


//time between covid test date and pfizer vaccine
gen timevacpfizerd1 = positive_test_1_date2-covid_vax_pfizer_1_date2
recode timevacpfizerd1 0/20=1 21/max=2
tab timevacpfizerd1

/* As there were negative values remaining after the recoding due to being vaccinated after testing positive I have recoded these to missing values (ie unvaccinated at time of pos test)*/

recode timevacpfizerd1 min/-1=.

gen timevacpfizerd2 = positive_test_1_date2- covid_vax_pfizer_2_date2
recode timevacpfizerd2 0/13=1 14/max=2
tab timevacpfizerd2
recode timevacpfizerd2 min/-1=.

//** AZ VACCINE doses 1 and 2 (LL added)

gen azd1 = covid_vax_az_1_date2
recode azd1 min/max=1

gen azd2 = covid_vax_az_2_date2
recode azd2 min/max=1


//time between covid test date and pfizer vaccine
gen timevacazd1 = positive_test_1_date2-covid_vax_az_1_date2
recode timevacazd1 0/20=1 21/max=2
tab timevacazd1

/* As there were negative values remaining after the recoding due to being vaccinated after testing positive I have recoded these to missing values (ie unvaccinated at time of pos test)*/

recode timevacazd1 min/-1=.

gen timevacazd2 = positive_test_1_date2- covid_vax_az_2_date2
recode timevacazd2 0/13=1 14/max=2
tab timevacazd2
recode timevacazd2 min/-1=.

**/ If we drop novaccine==2, everyone left will be coded as 1, regardless of whether vaccinated or not. Therefore I have generated code 0 for people who have received 1 or 2 doses of either Pfizer or AZ

gen novaccine=1
recode novaccine 1=0 if pfizerd1==1|pfizerd2==1|azd1==1|azd2==1
recode novaccine 0=2 if covid_vax_pfizer_1_date2>positive_test_1_date2
recode novaccine 0=2 if covid_vax_pfizer_1_date2 > negative_test_result_1_date2
recode novaccine 0=2 if covid_vax_az_1_date2 > positive_test_1_date2
recode novaccine 0=2 if covid_vax_az_1_date2 > negative_test_result_1_date2


gen pd1t1 = timevacpfizerd1
recode pd1t1 2=.
recode pd1t1 .=0 if novaccine==1

gen pd1t2 = timevacpfizerd1
recode pd1t2 1=. 
recode pd1t2 .=0 if novaccin==1
recode pd1t2 2=1
tab pd1t2


gen pd2t1 = timevacpfizerd2
recode pd2t1 2=. 
recode pd2t1 .=0 if novaccine==1
tab pd2t1

gen pd2t2 = timevacpfizerd2
recode pd2t2 1=. 
recode pd2t2 .=0 if novaccine==1
recode pd2t2 2=1
tab pd2t2







// vaccine % and univariate analysis //- by age group, any type, d1, d2- grousp 0-20- 21+ and D2 14+ and time period before janry 8th and after
		
local desc2 "pd1t1 pd1t2 pd2t1 pd2t2 sex2 bmi2 carehome has_follow_up_previous_year  ethnicity region2 imd chronic_cardiac_disease diabetes_type_1 diabetes_type_2 diabetes_unknown_type current_copd dmards dementia dialysis solid_organ_transplantation chemo_or_radio intel_dis_incl_downs_syndrome lung_cancer cancer_excl_lung_and_haem haematological_cancer bone_marrow_transplant cystic_fibrosis sickle_cell_disease permanant_immunosuppression temporary_immunosuppression psychosis_schiz_bipolar asplenia"
		
foreach var of local desc2 {
tab `var' covid2, col
mhodds  covid2 `var'
}	

//univariate and then mulivariate
			
// vaccine efficacy overall unadjuste and adjusted for minimal things- in 4 age grousp 18 to 39, 41/64, 65/79 and 80+



logistic   pd1t1 covid2 
logistic   pd1t1 covid2  age sex2 bmi2 i.ethnicity carehome i.ethnicity i.region2 i.imd
logistic   pd1t2 covid2 
logistic   pd1t2 covid2  age sex2 bmi2 i.ethnicity carehome i.ethnicity i.region2 i.imd


logistic   pd1t1 covid2 if solid_organ_transplantation==1
logistic   pd1t1 covid2  age sex2 bmi2 i.ethnicity carehome i.ethnicity i.region2 i.imd if solid_organ_transplantation==1
logistic   pd1t2 covid2  if solid_organ_transplantation==1
logistic   pd1t2 covid2  age sex2 bmi2 i.ethnicity carehome i.ethnicity i.region2 i.imd if solid_organ_transplantation==1


logistic   pd1t1 covid2 if chemo_or_radio==1
logistic   pd1t1 covid2  age sex2 bmi2 i.ethnicity carehome i.ethnicity i.region2 i.imd if chemo_or_radion==1
logistic   pd1t2 covid2  if solid_organ_transplantation==1
logistic   pd1t2 covid2  age sex2 bmi2 i.ethnicity carehome i.ethnicity i.region2 i.imd if chemo_or_radio==1


logistic   pd1t1 covid2 if solid_organ_transplantation==1  & ageg==4
logistic   pd1t1 covid2  age sex2 bmi2 i.ethnicity carehome i.ethnicity i.region2 i.imd if solid_organ_transplantation==1 & ageg==4
logistic   pd1t2 covid2  if solid_organ_transplantation==1  & ageg==4
logistic   pd1t2 covid2  age sex2 bmi2 i.ethnicity carehome i.ethnicity i.region2 i.imd if solid_organ_transplantation==1  & ageg==4


logistic   pd1t1 covid2 if chemo_or_radio==1  & ageg==4
logistic   pd1t1 covid2  age sex2 bmi2 i.ethnicity carehome i.ethnicity i.region2 i.imd if chemo_or_radion==1  & ageg==4
logistic   pd1t2 covid2  if solid_organ_transplantation==1  & ageg==4
logistic   pd1t2 covid2  age sex2 bmi2 i.ethnicity carehome i.ethnicity i.region2 i.imd if chemo_or_radio==1  & ageg==4


logistic   pd1t1 covid2 if solid_organ_transplantation==1  & ageg==3
logistic   pd1t1 covid2  age sex2 bmi2 i.ethnicity carehome i.ethnicity i.region2 i.imd if solid_organ_transplantation==1 & ageg==3
logistic   pd1t2 covid2  if solid_organ_transplantation==1  & ageg==3
logistic   pd1t2 covid2  age sex2 bmi2 i.ethnicity carehome i.ethnicity i.region2 i.imd if solid_organ_transplantation==1  & ageg==3


logistic   pd1t1 covid2 if chemo_or_radio==1  & ageg==3
logistic   pd1t1 covid2  age sex2 bmi2 i.ethnicity carehome i.ethnicity i.region2 i.imd if chemo_or_radion==1  & ageg==3
logistic   pd1t2 covid2  if solid_organ_transplantation==1  & ageg==3
logistic   pd1t2 covid2  age sex2 bmi2 i.ethnicity carehome i.ethnicity i.region2 i.imd if chemo_or_radio==1  & ageg==3

log close
