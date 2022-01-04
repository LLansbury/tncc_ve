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
recode novaccine 1=0 if pfizerd1==1|pfizerd2==1|azd1==1|azd2==1
recode novaccine 0=1 if covid_vax_pfizer_1_date2>positive_test_1_date2 & covid_vax_pfizer_1_date2!=.
recode novaccine 0=1 if covid_vax_pfizer_2_date2>positive_test_1_date2 & covid_vax_pfizer_2_date2!=.
recode novaccine 0=1 if covid_vax_pfizer_1_date2>negative_test_result_1_date2 & covid_vax_pfizer_1_date2!=.
recode novaccine 0=1 if covid_vax_pfizer_2_date2>negative_test_result_1_date2 & covid_vax_pfizer_2_date2!=.
recode novaccine 0=1 if covid_vax_az_1_date2>positive_test_1_date2 & covid_vax_az_1_date2!=.
recode novaccine 0=1 if covid_vax_az_2_date2>positive_test_1_date2 & covid_vax_az_2_date2!=.
recode novaccine 0=1 if covid_vax_az_1_date2>negative_test_result_1_date2 & covid_vax_az_1_date2!=.
recode novaccine 0=1 if covid_vax_az_2_date2>negative_test_result_1_date2 & covid_vax_az_2_date2!=.


gen pd1t1 = timevacpfizerd1
recode pd1t1 .=0 if novaccine==1 & positive_test_1_date2!=.| negative_test_result_1_date2!=.
recode pd1t1 2=.
tab pd1t1

gen pd1t2 = timevacpfizerd1
recode pd1t2 1=.
recode pd1t2 .=0 if novaccine==1 & positive_test_1_date2!=.| negative_test_result_1_date2!=.
recode pd1t2 2=1
tab pd1t2


gen pd2t1 = timevacpfizerd2
recode pd2t1 .=0 if novaccine==1 & positive_test_1_date2!=.| negative_test_result_1_date2!=.
recode pd2t1 2=. 
tab pd2t1

gen pd2t2 = timevacpfizerd2
recode pd2t2 1=. 
recode pd2t2 .=0 if novaccine==1 & positive_test_1_date2!=.| negative_test_result_1_date2!=.
recode pd2t2 2=1
tab pd2t2

gen az1t1 = timevacazd1
recode az1t1 .=0 if novaccine==1 & positive_test_1_date2!=.| negative_test_result_1_date2!=.
recode az1t1 2=.
tab az1t1

gen az1t2 = timevacazd1
recode az1t2 1=. 
recode az1t2 .=0 if novaccine==1 & positive_test_1_date2!=.| negative_test_result_1_date2!=.
recode az1t2 2=1
tab az1t2


gen az2t1 = timevacazd2
recode az2t1 .=0 if novaccine==1 & positive_test_1_date2!=.| negative_test_result_1_date2!=.
recode az2t1 2=. 
tab az2t1

gen az2t2 = timevacazd2
recode az2t2 1=. 
recode az2t2 .=0 if novaccine==1 & positive_test_1_date2!=.| negative_test_result_1_date2!=.
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

//To get positive and negative results for each specific time period 0=neg test, 1=pos test//

/*Pfizer dose 1*/
/*Unvaccinated 0=negative test, 1=positive test in that time period*/

gen unvacpd1t1res=.
recode unvacpd1t1res .=0 if pd1t1==0 & covid2==0 & testtime!=0 & az1t1!=1 & az1t2!=1 & az2t1!=1 & az2t2!=1
recode unvacpd1t1res .=1 if pd1t1==0 & covid2==1 & az1t1!=1 & az1t2!=1 & az2t1!=1 & az2t2!=1
tab unvacpd1t1res

/*vaccinated 0=nega test, 1=pos test during that time period*/
gen vacpd1t1res =.
recode vacpd1t1res .=0 if pd1t1==1 & covid2==0 & az1t1!=1 & az1t2!=1 & az2t1!=1 & az2t2!=1
recode vacpd1t1res .=1 if pd1t1==1 & covid2==1 & az1t1!=1 & az1t2!=1 & az2t1!=1 & az2t2!=1
tab vacpd1t1res

/*Then combine to get separated test result for vacc & unvac combined*/

gen pfd1res0to20 = vacpd1t1res
recode pfd1res0to20 .=0 if unvacpd1t1res==0 
recode pfd1res0to20 .=1 if unvacpd1t1res==1 
tab pfd1res0to20
 
/**Pfizer dose 1 >=21 days **/

gen unvacpd1t2res=.
recode unvacpd1t2res .=0 if pd1t2==0 & covid2==0 & testtime!=0 & az1t1!=1 & az1t2!=1 & az2t1!=1 & az2t2!=1
recode unvacpd1t2res .=1 if pd1t2==0 & covid2==1 & az1t1!=1 & az1t2!=1 & az2t1!=1 & az2t2!=1
tab unvacpd1t2res

gen vacpd1t2res =.
recode vacpd1t2res .=0 if pd1t2==1 & covid2==0 & az1t1!=1 & az1t2!=1 & az2t1!=1 & az2t2!=1
recode vacpd1t2res .=1 if pd1t2==1 & covid2==1 & az1t1!=1 & az1t2!=1 & az2t1!=1 & az2t2!=1
tab vacpd1t2res

gen pfd1res21plus = vacpd1t2res
recode pfd1res21plus .=0 if unvacpd1t2res==0
recode pfd1res21plus .=1 if unvacpd1t2res==1 
tab pfd1res21plus

/*Pfizer dose 2* 0-13 days*/

gen unvacpd2t1res=.
recode unvacpd2t1res .=0 if pd2t1==0 & covid2==0 & testtime!=0 & az1t1!=1 & az1t2!=1 & az2t1!=1 & az2t2!=1
recode unvacpd2t1res .=1 if pd2t1==0 & covid2==1 & az1t1!=1 & az1t2!=1 & az2t1!=1 & az2t2!=1
tab unvacpd2t1res

gen vacpd2t1res =.
recode vacpd2t1res .=0 if pd2t1==1 & covid2==0 & az1t1!=1 & az1t2!=1 & az2t1!=1 & az2t2!=1
recode vacpd2t1res .=1 if pd2t1==1 & covid2==1 & az1t1!=1 & az1t2!=1 & az2t1!=1 & az2t2!=1
tab vacpd2t1res

gen pfd2res0to13 = vacpd2t1res
recode pfd2res0to13 .=0 if unvacpd2t1res==0 
recode pfd2res0to13 .=1 if unvacpd2t1res==1 
tab pfd2res0to13

/*Pfizer dose 2 14 days  plus*/

gen unvacpd2t2res=.
recode unvacpd2t2res .=0 if pd2t2==0 & covid2==0 & testtime!=0 & az1t1!=1 & az1t2!=1 & az2t1!=1 & az2t2!=1
recode unvacpd2t2res .=1 if pd2t2==0 & covid2==1 & az1t1!=1 & az1t2!=1 & az2t1!=1 & az2t2!=1
tab unvacpd2t2res

gen vacpd2t2res =.
recode vacpd2t2res .=0 if pd2t2==1 & covid2==0 & az1t1!=1 & az1t2!=1 & az2t1!=1 & az2t2!=1
recode vacpd2t2res .=1 if pd2t2==1 & covid2==1 & az1t1!=1 & az1t2!=1 & az2t1!=1 & az2t2!=1
tab vacpd2t2res

gen pfd2res14plus = vacpd2t2res
recode pfd2res14plus .=0 if unvacpd2t2res==0
recode pfd2res14plus .=1 if unvacpd2t2res==1 
tab pfd2res14plus


/*AZ dose 1, day 0 to 20*/

gen unvacaz1t1res=.
recode unvacaz1t1res .=0 if az1t1==0 & covid2==0 & testtime!=0 & pd1t1!=1 & pd1t2!=1 & pd2t1!=1 & pd2t2!=1
recode unvacaz1t1res .=1 if az1t1==0 & covid2==1 & pd1t1!=1 & pd1t2!=1 & pd2t1!=1 & pd2t2!=1
tab unvacaz1t1res

gen vacaz1t1res =.
recode vacaz1t1res .=0 if az1t1==1 & covid2==0 & pd1t1!=1 & pd1t2!=1 & pd2t1!=1 & pd2t2!=1
recode vacaz1t1res .=1 if az1t1==1 & covid2==1 & pd1t1!=1 & pd1t2!=1 & pd2t1!=1 & pd2t2!=1
tab vacaz1t1res

gen azd1res0to20 = vacaz1t1res
recode azd1res0to20 .=0 if unvacaz1t1res==0 
recode azd1res0to20 .=1 if unvacaz1t1res==1 
tab azd1res0to20

/*AZ dose 1, day 21 plus*/

gen unvacaz1t2res=.
recode unvacaz1t2res .=0 if az1t2==0 & covid2==0 & testtime!=0 & pd1t1!=1 & pd1t2!=1 & pd2t1!=1 & pd2t2!=1
recode unvacaz1t2res .=1 if az1t2==0 & covid2==1 & pd1t1!=1 & pd1t2!=1 & pd2t1!=1 & pd2t2!=1
tab unvacaz1t2res

gen vacaz1t2res =.
recode vacaz1t2res .=0 if az1t2==1 & covid2==0 & pd1t1!=1 & pd1t2!=1 & pd2t1!=1 & pd2t2!=1
recode vacaz1t2res .=1 if az1t2==1 & covid2==1 & pd1t1!=1 & pd1t2!=1 & pd2t1!=1 & pd2t2!=1
tab vacaz1t2res

gen azd1res21plus = vacaz1t2res
recode azd1res21plus .=0 if unvacaz1t2res==0
recode azd1res21plus .=1 if unvacaz1t2res==1 
tab azd1res21plus

/**AZ dose 2, day 0 to 13**/

gen unvacaz2t1res=.
recode unvacaz2t1res .=0 if az2t1==0 & covid2==0 & testtime!=0 & pd1t1!=1 & pd1t2!=1 & pd2t1!=1 & pd2t2!=1
recode unvacaz2t1res .=1 if az2t1==0 & covid2==1 & pd1t1!=1 & pd1t2!=1 & pd2t1!=1 & pd2t2!=1
tab unvacaz2t1res

gen vacaz2t1res =.
recode vacaz2t1res .=0 if az2t1==1 & covid2==0 & pd1t1!=1 & pd1t2!=1 & pd2t1!=1 & pd2t2!=1
recode vacaz2t1res .=1 if az2t1==1 & covid2==1 & pd1t1!=1 & pd1t2!=1 & pd2t1!=1 & pd2t2!=1
tab vacaz2t1res

gen azd2res0to13 = vacaz2t1res
recode azd2res0to13 .=0 if unvacaz2t1res==0 
recode azd2res0to13 .=1 if unvacaz2t1res==1 
tab azd2res0to13

/**AZ dose 2 14 days plus*/

gen unvacaz2t2res=.
recode unvacaz2t2res .=0 if az2t2==0 & covid2==0 & testtime!=0 & pd1t1!=1 &pd1t2!=1 & pd2t1!=1& pd2t2!=1
recode unvacaz2t2res .=1 if az2t2==0 & covid2==1 & pd1t1!=1 & pd1t2!=1 & pd2t1!=1 & pd2t2!=1
tab unvacaz2t2res

gen vacaz2t2res =.
recode vacaz2t2res .=0 if az2t2==1 & covid2==0 & pd1t1!=1 & pd1t2!=1 & pd2t1!=1& pd2t2!=1
recode vacaz2t2res .=1 if az2t2==1 & covid2==1 & pd1t1!=1 & pd1t2!=1 & pd2t1!=1 & pd2t2!=1
tab vacaz2t2res

gen azd2res14plus = vacaz2t2res
recode azd2res14plus .=0 if unvacaz2t2res==0 
recode azd2res14plus .=1 if unvacaz2t2res==1 
tab azd2res14plus



// vaccine % and univariate analysis //- by age group, any type, d1, d2- grousp 0-20- 21+ and D2 14+ and time period before janry 8th and after
		

local desc2 "pd1t1 pd1t2 pd2t1 pd2t2 az1t1 az1t2 az2t1 az2t2 sex2 bmi2 carehome has_follow_up_previous_year  ethnicity region2 imd chronic_cardiac_disease diabetes_type_1 diabetes_type_2 diabetes_unknown_type current_copd dmards dementia dialysis solid_organ_transplantation chemo_or_radio intel_dis_incl_downs_syndrome lung_cancer cancer_excl_lung_and_haem haematological_cancer cystic_fibrosis sickle_cell_disease permanant_immunosuppression temporary_immunosuppression psychosis_schiz_bipolar asplenia"

	
foreach var of local desc2 {
tab `var' covid2, col
mhodds  covid2 `var'
}	

local desc3 "carehome chronic_cardiac_disease diabetes_type_1 diabetes_type_2 diabetes_unknown_type current_copd dmards dementia dialysis solid_organ_transplantation chemo_or_radio intel_dis_incl_downs_syndrome lung_cancer cancer_excl_lung_and_haem haematological_cancer cystic_fibrosis sickle_cell_disease permanant_immunosuppression temporary_immunosuppression psychosis_schiz_bipolar asplenia "

foreach var of local desc3 {
tab `var'
logistic pd1t1 pfd1res0to20 if `var'==1 & symptoms==1

logistic pd1t2 pfd1res21plus if `var'==1 & symptoms==1

logistic pd2t1 pfd2res0to13 if `var'==1 & symptoms==1

logistic pd2t2 pfd2res14plus if `var'==1 & symptoms==1

logistic az1t1 azd1res0to20 if `var'==1 & symptoms==1

logistic az1t2 azd1res21plus if `var'==1 & symptoms==1

logistic az2t1 azd2res0to13 if `var'==1 & symptoms==1

logistic az2t2 azd2res14plus if `var'==1 & symptoms==1


}
//univariate and then mulivariate
			
// vaccine efficacy overall unadjuste and adjusted for minimal things
///Pfizer dose 1

logistic   pd1t1 pfd1res0to20 if symptoms==1
logistic   pd1t1 pfd1res0to20  age sex2 bmi2 i.ethnicity i.region2 i.imd if symptoms==1
logistic   pd1t2 pfd1res21plus if symptoms==1
logistic   pd1t2 pfd1res21plus  age sex2 bmi2 i.ethnicity i.region2 i.imd if symptoms==1


logistic   pd1t1 pfd1res0to20 if solid_organ_transplantation==1 & symptoms==1
logistic   pd1t1 pfd1res0to20  age sex2 if solid_organ_transplantation==1 & symptoms==1
logistic   pd1t2 pfd1res21plus  if solid_organ_transplantation==1 & symptoms==1
logistic   pd1t2 pfd1res21plus  age sex2 if solid_organ_transplantation==1 & symptoms==1


logistic   pd1t1 pfd1res0to20 if chemo_or_radio==1 & symptoms==1
logistic   pd1t1 pfd1res0to20  age sex2 if chemo_or_radio==1 & symptoms==1
logistic   pd1t2 pfd1res21plus  if chemo_or_radio==1 & symptoms==1
logistic   pd1t2 pfd1res21plus  age sex2 if chemo_or_radio==1 & symptoms==1


logistic   pd1t1 pfd1res0to20 if permanant_immunosuppression==1 & symptoms==1
logistic   pd1t1 pfd1res0to20  age sex2 if permanant_immunosuppression==1 & symptoms==1
logistic   pd1t2 pfd1res21plus  if permanant_immunosuppression==1 & symptoms==1
logistic   pd1t2 pfd1res21plus  age sex2 if permanant_immunosuppression==1 & symptoms==1

logistic   pd1t1 pfd1res0to20 if temporary_immunosuppression==1 & symptoms==1
logistic   pd1t1 pfd1res0to20  age sex2 if temporary_immunosuppression==1 & symptoms==1
logistic   pd1t2 pfd1res21plus  if temporary_immunosuppression==1 & symptoms==1
logistic   pd1t2 pfd1res21plus  age sex2 if temporary_immunosuppression==1 & symptoms==1


///Pfizer dose 2
logistic   pd2t1 pfd2res0to13 if symptoms==1
logistic   pd2t1 pfd2res0to13  age sex2 bmi2 i.ethnicity i.region2 i.imd if symptoms==1
logistic   pd2t2 pfd2res14plus if symptoms==1
logistic   pd2t2 pfd2res14plus  age sex2 bmi2 i.ethnicity i.region2 i.imd if symptoms==1


logistic   pd2t1 pfd2res0to13 if solid_organ_transplantation==1 & symptoms==1
logistic   pd2t1 pfd2res0to13  age sex2 if solid_organ_transplantation==1 & symptoms==1
logistic   pd2t2 pfd2res14plus  if solid_organ_transplantation==1 & symptoms==1
logistic   pd2t2 pfd2res14plus  age sex2 if solid_organ_transplantation==1 & symptoms==1


logistic   pd2t1 pfd2res0to13 if chemo_or_radio==1 & symptoms==1
logistic   pd2t1 pfd2res0to13  age sex2 if chemo_or_radio==1 & symptoms==1
logistic   pd2t2 pfd2res14plus  if chemo_or_radio==1 & symptoms==1
logistic   pd2t2 pfd2res14plus  age sex2 if chemo_or_radio==1 & symptoms==1

logistic   pd2t1 pfd2res0to13 if permanant_immunosuppression==1 & symptoms==1
logistic   pd2t1 pfd2res0to13  age sex2 if permanant_immunosuppression==1 & symptoms==1
logistic   pd2t2 pfd2res14plus  if permanant_immunosuppression==1 & symptoms==1
logistic   pd2t2 pfd2res14plus  age sex2 if permanant_immunosuppression==1 & symptoms==1

logistic   pd2t1 pfd2res0to13 if temporary_immunosuppression==1 & symptoms==1
logistic   pd2t1 pfd2res0to13  age sex2 if temporary_immunosuppression==1 & symptoms==1
logistic   pd2t2 pfd2res14plus  if temporary_immunosuppression==1 & symptoms==1
logistic   pd2t2 pfd2res14plus  age sex2 if temporary_immunosuppression==1 & symptoms==1


///Astra Zeneca dose 1
logistic   az1t1 azd1res0to20 if symptoms==1
logistic   az1t1 azd1res0to20  age sex2 bmi2 i.ethnicity i.region2 i.imd if symptoms==1
logistic   az1t2 azd1res21plus if symptoms==1
logistic   az1t2 azd1res21plus  age sex2 bmi2 i.ethnicity i.region2 i.imd if symptoms==1


logistic   az1t1 azd1res0to20 if solid_organ_transplantation==1 & symptoms==1
logistic   az1t1 azd1res0to20  age sex2 if solid_organ_transplantation==1 & symptoms==1
logistic   az1t2 azd1res21plus  if solid_organ_transplantation==1 & symptoms==1
logistic   az1t2 azd1res21plus  age sex2 if solid_organ_transplantation==1 & symptoms==1


logistic   az1t1 azd1res0to20 if chemo_or_radio==1 & symptoms==1
logistic   az1t1 azd1res0to20  age sex2 if chemo_or_radio==1 & symptoms==1
logistic   az1t2 azd1res21plus  if chemo_or_radio==1 & symptoms==1
logistic   az1t2 azd1res21plus  age sex2 if chemo_or_radio==1 & symptoms==1

logistic   az1t1 azd1res0to20 if permanant_immunosuppression==1 & symptoms==1
logistic   az1t1 azd1res0to20  age sex2 if permanant_immunosuppression==1 & symptoms==1
logistic   az1t2 azd1res21plus  if permanant_immunosuppression==1 & symptoms==1
logistic   az1t2 azd1res21plus  age sex2 if permanant_immunosuppression==1 & symptoms==1

logistic   az1t1 azd1res0to20 if temporary_immunosuppression==1 & symptoms==1
logistic   az1t1 azd1res0to20  age sex2 if temporary_immunosuppression==1 & symptoms==1
logistic   az1t2 azd1res21plus  if temporary_immunosuppression==1 & symptoms==1
logistic   az1t2 azd1res21plus  age sex2 if temporary_immunosuppression==1 & symptoms==1

///Astra Zeneca dose 2
logistic   az2t1 azd2res0to13 if symptoms==1
logistic   az2t1 azd2res0to13  age sex2 bmi2 i.ethnicity i.region2 i.imd if symptoms==1
logistic   az2t2 azd2res14plus if symptoms==1
logistic   az2t2 azd2res14plus  age sex2 bmi2 i.ethnicity i.region2 i.imd if symptoms==1


logistic   az2t1 azd2res0to13 if solid_organ_transplantation==1 & symptoms==1
logistic   az2t1 azd2res0to13  age sex2 if solid_organ_transplantation==1 & symptoms==1
logistic   az2t2 azd2res14plus  if solid_organ_transplantation==1 & symptoms==1
logistic   az2t2 azd2res14plus  age sex2 if solid_organ_transplantation==1 & symptoms==1


logistic   az2t1 azd2res0to13 if chemo_or_radio==1 & symptoms==1
logistic   az2t1 azd2res0to13  age sex2 if chemo_or_radio==1 & symptoms==1
logistic   az2t2 azd2res14plus  if chemo_or_radio==1 & symptoms==1
logistic   az2t2 azd2res14plus  age sex2 if chemo_or_radio==1 & symptoms==1

logistic   az2t1 azd2res0to13 if permanant_immunosuppression==1 & symptoms==1
logistic   az2t1 azd2res0to13  age sex2 if permanant_immunosuppression==1 & symptoms==1
logistic   az2t2 azd2res14plus  if permanant_immunosuppression==1 & symptoms==1
logistic   az2t2 azd2res14plus  age sex2 if permanant_immunosuppression==1 & symptoms==1

logistic   az2t1 azd2res0to13 if temporary_immunosuppression==1 & symptoms==1
logistic   az2t1 azd1res0to20  age sex2 if temporary_immunosuppression==1 & symptoms==1
logistic   az2t2 azd2res14plus  if temporary_immunosuppression==1 & symptoms==1
logistic   az2t2 azd2res14plus  age sex2 if temporary_immunosuppression==1 & symptoms==1


log close
