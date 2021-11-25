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


log using logs/00a_cr_create_analysis_dataset.txt, replace t




//importing data

import delimited "output/input.csv"

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
gen testtime = positive_test_1_date2-negative_test_result_1_date2
recode testtime -21/20=0
recode nocovid 1=. if testtime==0

gen covid2= covid
recode covid2 .=0 if nocovid==1



//early summary of data
summ age, detail

gen ageg = age
recode ageg 18/39=1 40/64=2 65/79=3 80/max=4 min/17=.

local desc "ageg sex2 bmi2 carehome has_follow_up_previous_year ethnicity_16 ethnicity region2 imd symptomatic_people chronic_cardiac_disease diabetes_type_1 diabetes_type_2 diabetes_unknown_type current_copd dmards dementia dialysis solid_organ_transplantation chemo_or_radio intel_dis_incl_downs_syndrome lung_cancer cancer_excl_lung_and_haem haematological_cancer bone_marrow_transplant cystic_fibrosis sickle_cell_disease permanant_immunosuppression temporary_immunosuppression psychosis_schiz_bipolar asplenia"

foreach var of local desc {
    tab `var'
}

//Pfizer vaccine doses 1 and 2
gen pfizerd1 = covid_vax_pfizer_1_date2
recode pfizerd1 min/max=1

gen pfizerd2 = covid_vax_pfizer_2_date2
recode pfizerd2 min/max=1


//time between pfizer vaccine dose 1 and either a positive or negative test
gen timevacpfd1neg = negative_test_result_1_date2-covid_vax_pfizer_1_date2
recode timevacpfd1neg 0/20=1 21/max=2
recode timevacpfd1neg min/-1=.
tab timevacpfd1neg

gen timevacpfd1pos = positive_test_1_date2-covid_vax_pfizer_1_date2
recode timevacpfd1pos 0/20=1 21/max=2
recode timevacpfd1pos min/-1=.
tab timevacpfd1pos

gen timevacpfizerd1=timevacpfd1pos
recode timevacpfizerd1 .=1 if timevacpfd1neg==1
recode timevacpfizerd1 .=2 if timevacpfd1neg==2
tab timevacpfizerd1

//time between pfizer vaccine dose 2 and either a positive or negative test
gen timevacpfd2neg = negative_test_result_1_date2-covid_vax_pfizer_2_date2
recode timevacpfd2neg 0/13=1 14/max=2
recode timevacpfd2neg min/-1=.
tab timevacpfd2neg

gen timevacpfd2pos = positive_test_1_date2-covid_vax_pfizer_2_date2
recode timevacpfd2pos 0/13=1 14/max=2
recode timevacpfd2pos min/-1=.
tab timevacpfd2pos

gen timevacpfizerd2=timevacpfd2pos
recode timevacpfizerd2 .=1 if timevacpfd2neg==1
recode timevacpfizerd2 .=2 if timevacpfd2neg==2
tab timevacpfizerd2

//** AZ VACCINE doses 1 and 2 (LL added)

gen azd1 = covid_vax_az_1_date2
recode azd1 min/max=1

gen azd2 = covid_vax_az_2_date2
recode azd2 min/max=1

//time between AZ vaccine dose 1 and either a positive or negative test
gen timevacazd1neg = negative_test_result_1_date2-covid_vax_az_1_date2
recode timevacazd1neg 0/20=1 21/max=2
recode timevacazd1neg min/-1=.
tab timevacazd1neg

gen timevacazd1pos = positive_test_1_date2-covid_vax_az_1_date2
recode timevacazd1pos 0/20=1 21/max=2
recode timevacazd1pos min/-1=.
tab timevacazd1pos

gen timevacazd1=timevacazd1pos
recode timevacazd1 .=1 if timevacazd1neg==1
recode timevacazd1 .=2 if timevacazd1neg==2
tab timevacazd1

//time between AZ vaccine dose 2 and either a positive or negative test
gen timevacazd2neg = negative_test_result_1_date2-covid_vax_az_2_date2
recode timevacazd2neg 0/13=1 14/max=2
recode timevacazd2neg min/-1=.
tab timevacazd2neg

gen timevacazd2pos = positive_test_1_date2-covid_vax_az_2_date2
recode timevacazd2pos 0/13=1 14/max=2
recode timevacazd2pos min/-1=.
tab timevacazd2pos

gen timevacazd2=timevacazd2pos
recode timevacazd2 .=1 if timevacazd2neg==1
recode timevacazd2 .=2 if timevacazd2neg==2
tab timevacazd2


//to get unvaccinated people (1=unvaccinated, 0=vaccinated)
gen novaccine=1
recode novaccine 1=0 if timevacpfizerd1==1|timevacpfizerd2==1|timevacazd1==1|timevacazd2==1|timevacpfizerd1==2|timevacpfizerd2==2|timevacazd1==2|timevacazd2==2
recode novaccine 0=2 if covid_vax_pfizer_1_date2>positive_test_1_date2
recode novaccine 0=2 if covid_vax_az_1_date2 > positive_test_1_date2


gen pd1t1 = timevacpfizerd1
recode pd1t1 2=.
recode pd1t1 .=0 if novaccine==1
tab pd1t1

gen pd1t2 = timevacpfizerd1
recode pd1t2 1=. 
recode pd1t2 .=0 if novaccine==1
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

gen az1t1 = timevacazd1
recode az1t1 2=.
recode az1t1 .=0 if novaccine==1
tab az1t1

gen az1t2 = timevacazd1
recode az1t2 1=. 
recode az1t2 .=0 if novaccine==1
recode az1t2 2=1
tab az1t2


gen az2t1 = timevacazd2
recode az2t1 2=. 
recode az2t1 .=0 if novaccine==1
tab az2t1

gen az2t2 = timevacazd2
recode az2t2 1=. 
recode az2t2 .=0 if novaccine==1
recode az2t2 2=1
tab az2t2

//Cut off time periods for dose 1 analyses for people receiving second dose//

recode pd1t1 1=. if pd2t1==1|pd2t2==1
recode pd1t2 1=. if pd2t1==1|pd2t2==1

recode az1t1 1=. if az2t1==1|az2t2==1
recode az1t2 1=. if az2t1==1|az2t2==1

gen symptoms=0
recode symptoms 0=1 if symptomatic_people=="Y"
tab symptoms


// vaccine % and univariate analysis //- by age group, any type, d1, d2- grousp 0-20- 21+ and D2 14+ and time period before janry 8th and after
		

local desc2 "pd1t1 pd1t2 pd2t1 pd2t2 az1t1 az1t2 az2t1 az2t2 sex2 bmi2 carehome has_follow_up_previous_year  ethnicity region2 imd chronic_cardiac_disease diabetes_type_1 diabetes_type_2 diabetes_unknown_type current_copd dmards dementia dialysis solid_organ_transplantation chemo_or_radio intel_dis_incl_downs_syndrome lung_cancer cancer_excl_lung_and_haem haematological_cancer cystic_fibrosis sickle_cell_disease permanant_immunosuppression temporary_immunosuppression psychosis_schiz_bipolar asplenia"

	
foreach var of local desc2 {
tab `var' covid2, col
mhodds  covid2 `var'
}	

local desc3 "carehome chronic_cardiac_disease diabetes_type_1 diabetes_type_2 diabetes_unknown_type current_copd dmards dementia dialysis solid_organ_transplantation chemo_or_radio intel_dis_incl_downs_syndrome lung_cancer cancer_excl_lung_and_haem haematological_cancer cystic_fibrosis sickle_cell_disease permanant_immunosuppression temporary_immunosuppression psychosis_schiz_bipolar asplenia "

foreach var of local desc3 {
tab `var'
logistic pd1t1 covid2 if `var'==1 & symptoms==1

logistic pd1t2 covid2 if `var'==1 & symptoms==1

logistic pd2t1 covid2 if `var'==1 & symptoms==1

logistic pd2t2 covid2 if `var'==1 & symptoms==1

logistic az1t1 covid2 if `var'==1 & symptoms==1

logistic az1t2 covid2 if `var'==1 & symptoms==1

logistic az2t1 covid2 if `var'==1 & symtpoms==1

logistic az2t2 covid2 if `var'==1 & symtpoms==1

}
//univariate and then mulivariate
			
// vaccine efficacy overall unadjuste and adjusted for minimal things- in 4 age grousp 18 to 39, 41/64, 65/79 and 80+
///Pfizer dose 1
logistic   pd1t1 covid2 if symptoms==1
logistic   pd1t1 covid2  age sex2 bmi2 i.ethnicity i.region2 i.imd if symptoms==1
logistic   pd1t2 covid2 if symptoms==1
logistic   pd1t2 covid2  age sex2 bmi2 i.ethnicity i.region2 i.imd if symptoms==1


logistic   pd1t1 covid2 if solid_organ_transplantation==1 & symptoms==1
logistic   pd1t1 covid2  age sex2 if solid_organ_transplantation==1 & symptoms==1
logistic   pd1t2 covid2  if solid_organ_transplantation==1 & symptoms==1
logistic   pd1t2 covid2  age sex2 if solid_organ_transplantation==1 & symptoms==1


logistic   pd1t1 covid2 if chemo_or_radio==1 & symptoms==1
logistic   pd1t1 covid2  age sex2 if chemo_or_radio==1 & symptoms==1
logistic   pd1t2 covid2  if chemo_or_radio==1 & symptoms==1
logistic   pd1t2 covid2  age sex2 if chemo_or_radio==1 & symptoms==1





///Pfizer dose 2
logistic   pd2t1 covid2 if symptoms==1
logistic   pd2t1 covid2  age sex2 bmi2 i.ethnicity i.region2 i.imd if symptoms==1
logistic   pd2t2 covid2 if symptoms==1
logistic   pd2t2 covid2  age sex2 bmi2 i.ethnicity i.region2 i.imd if symptoms==1


logistic   pd2t1 covid2 if solid_organ_transplantation==1 & symptoms==1
logistic   pd2t1 covid2  age sex2 if solid_organ_transplantation==1 & symptoms==1
logistic   pd2t2 covid2  if solid_organ_transplantation==1 & symptoms==1
logistic   pd2t2 covid2  age sex2 if solid_organ_transplantation==1 & symptoms==1


logistic   pd2t1 covid2 if chemo_or_radio==1 & symptoms==1
logistic   pd2t1 covid2  age sex2 if chemo_or_radio==1 & symptoms==1
logistic   pd2t2 covid2  if chemo_or_radio==1 & symptoms==1
logistic   pd2t2 covid2  age sex2 if chemo_or_radio==1 & symptoms==1




///Astra Zeneca dose 1
logistic   az1t1 covid2 if symptoms==1
logistic   az1t1 covid2  age sex2 bmi2 i.ethnicity i.region2 i.imd if symptoms==1
logistic   az1t2 covid2 if symptoms==1
logistic   az1t2 covid2  age sex2 bmi2 i.ethnicity i.region2 i.imd if symptoms==1


logistic   az1t1 covid2 if solid_organ_transplantation==1 & symptoms==1
logistic   az1t1 covid2  age sex2 if solid_organ_transplantation==1 & symptoms==1
logistic   az1t2 covid2  if solid_organ_transplantation==1 & symptoms==1
logistic   az1t2 covid2  age sex2 if solid_organ_transplantation==1 & symptoms==1


logistic   az1t1 covid2 if chemo_or_radio==1 & symptoms==1
logistic   az1t1 covid2  age sex2 if chemo_or_radio==1 & symptoms==1
logistic   az1t2 covid2  if chemo_or_radio==1 & symptoms==1
logistic   az1t2 covid2  age sex2 if chemo_or_radio==1 & symptoms==1



///Astra Zeneca dose 2
logistic   az2t1 covid2 if symptoms==1
logistic   az2t1 covid2  age sex2 bmi2 i.ethnicity i.region2 i.imd if symptoms==1
logistic   az2t2 covid2 if symptoms==1
logistic   az2t2 covid2  age sex2 bmi2 i.ethnicity i.region2 i.imd if symptoms==1


logistic   az2t1 covid2 if solid_organ_transplantation==1 & symptoms==1
logistic   az2t1 covid2  age sex2 if solid_organ_transplantation==1 & symptoms==1
logistic   az2t2 covid2  if solid_organ_transplantation==1 & symptoms==1
logistic   az2t2 covid2  age sex2 if solid_organ_transplantation==1 & symptoms==1


logistic   az2t1 covid2 if chemo_or_radio==1 & symptoms==1
logistic   az2t1 covid2  age sex2 if chemo_or_radio==1 & symptoms==1
logistic   az2t2 covid2  if chemo_or_radio==1 & symptoms==1
logistic   az2t2 covid2  age sex2 if chemo_or_radio==1 & symptoms==1



log close
