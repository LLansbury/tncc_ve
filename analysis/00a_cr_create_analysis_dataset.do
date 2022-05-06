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

/*Variables for pos and neg tests during each of the time period - first period 1 jan 21- 8 jun 21, second period 9 jun 21-24 nov 21, third period 25 nov 21 - 15 mar 22) */

gen postestdate_first_period=positive_test_1_date
gen postestdate_second_period=positive_test_1_date
gen postestdate_third_period=positive_test_1_date

gen negtestdate_first_period=negative_test_result_1_date
gen negtestdate_second_period=negative_test_result_1_date
gen negtestdate_third_period=negative_test_result_1_date

local dates "covid_vax_1_date covid_vax_2_date  covid_vax_3_date covid_vax_4_date covid_vax_pfizer_1_date covid_vax_pfizer_2_date covid_vax_pfizer_3_date covid_vax_pfizer_4_date covid_vax_az_1_date covid_vax_az_2_date covid_vax_az_3_date covid_vax_az_4_date prior_positive_test_date prior_admitted_for_covid_date positive_test_1_date negative_test_result_1_date primary_care_covid_case_1_date admitted_1_date coviddeath_date death_date postestdate_first_period postestdate_second_period postestdate_third_period negtestdate_first_period negtestdate_second_period negtestdate_third_period prior_pc_covid_case_date"

foreach var of local dates {
gen `var'2=date(`var', "YMD")
format `var'2 %d
}

/******ENSURE ONLY TESTS DONE BETWEEN 01 Jan 2021 and 8 June 2021 are included FOR THE FIRST PERIOD****/

replace postestdate_first_period2=. if positive_test_1_date2<22281|positive_test_1_date2>22439
tab postestdate_first_period2

replace negtestdate_first_period2=. if negative_test_result_1_date2<22281|negative_test_result_1_date2>22439
tab negtestdate_first_period2

/*Ensure only tests between 09 Jun 21 and 24 Nov 21 are included for second period (mainly delta)*/

replace postestdate_second_period2=. if positive_test_1_date2<22440|positive_test_1_date2>22608
tab postestdate_second_period2

replace negtestdate_second_period2=. if negative_test_result_1_date2<22440|negative_test_result_1_date2>22608
tab negtestdate_second_period2

/*Ensure only tests between 25 nov 21 and 15 mar 22 are included for THIRD period (mainly omicron)*/

replace postestdate_third_period2=. if positive_test_1_date2<22609|positive_test_1_date2>22719
tab postestdate_third_period2

replace negtestdate_third_period2=. if negative_test_result_1_date2<22609|negative_test_result_1_date2>22719
tab negtestdate_third_period2

local string "bmi sex stp region care_home_type"

foreach var of local string {
    encode `var', gen (`var'2)
	
}

gen carehome = care_home_type2
recode carehome 1/3=1 .=0

///***DEFINE COVID DIAGNOSIS, 1 = positive Covid test, 0 = negative Covid test)***///
//** Generate a variable for positive test and negative tests (excluding neg tests that are within 3 weeks of a positive test) **//




gen pos=positive_test_1_date2
replace pos=. if prior_positive_test_date!=""
recode pos min/max=1
tab pos

gen neg= negative_test_result_1_date2
replace neg=. if prior_positive_test_date!=""
recode neg min/max=1
tab neg

gen testtime=positive_test_1_date2-negative_test_result_1_date2 
recode testtime -21/20=0
recode neg 1=. if testtime==0
tab testtime

///***GENERATE A VARIABLE FOR IMMUNOCOMPROMISED PEOPLE***///

gen immcomp=0
recode immcomp 0=1 if haematological_cancer==1|bone_marrow_transplant==1|permanant_immunosuppression==1|temporary_immunosuppression==1|solid_organ_transplant==1|chemo_or_radio==1


//early summary of data
summ age, detail

gen ageg = age
recode ageg 18/39=1 40/64=2 65/79=3 80/max=4 min/17=.

local desc "ageg sex2 bmi2 carehome has_follow_up_previous_year ethnicity_16 ethnicity region2 imd symptomatic_people chronic_cardiac_disease diabetes_type_1 diabetes_type_2 diabetes_unknown_type current_copd dmards dementia dialysis solid_organ_transplantation chemo_or_radio intel_dis_incl_downs_syndrome lung_cancer cancer_excl_lung_and_haem haematological_cancer bone_marrow_transplant cystic_fibrosis sickle_cell_disease permanant_immunosuppression temporary_immunosuppression psychosis_schiz_bipolar asplenia immcomp"

foreach var of local desc {
    tab `var'
}

//**Generate variable for people with symptoms, 0 no symtpoms, 1 symptoms**//

gen syx = .
recode syx .=1 if symptomatic_people=="Y"
recode syx .=0 if symptomatic_people=="N"
tab syx

//** DEFINE POS TEST WITH SYMPTOMS**//
gen pos_syx = pos
recode pos_syx 1=. if syx==0|syx==.
tab pos_syx

//**DEFINE NEG test with symptoms**//

gen neg_syx = neg
recode neg_syx 1=. if syx==0|syx==.
tab neg_syx

//**GENERATE A VARIABLE FOR SYMPTOMATIC PEOPLE WHO HAVE A TEST RESULT (either positive or neg) 1= positive test with syx, 0== neg test with symptoms**//

gen tested_syx = pos_syx
recode tested_syx .=0 if neg_syx==1
tab tested_syx

///***FIRST PERIOD - ANY VACCINE***///

/***Any first dose vaccine received before a pos or neg test in first period***/
/*Positive test after dose 1 but before dose 2*/

gen vax1prepostest_first_period=postestdate_first_period2-covid_vax_1_date2
recode vax1prepostest_first_period min/-1=.  /*to exclude -ve numbers ie testesd before pfizer dose 1) */

recode vax1prepostest_first_period 0/max=1
recode vax1prepostest_first_period 1=. if covid_vax_2_date2<postestdate_first_period2
recode vax1prepostest_first_period 1=. if pos_syx!=1

tab vax1prepostest_first_period

/*Two different time periods for pos test after dose 1*/

gen timepos_vax1=positive_test_1_date2-covid_vax_1_date2
recode timepos_vax1 min/-1=.
recode timepos_vax1 0/20=1
recode timepos_vax1 21/max=2

gen vax1_pos_0to20_first_period=vax1prepostest_first_period
recode vax1_pos_0to20_first_period 1=. if timepos_vax1==2
tab vax1_pos_0to20_first_period

gen vax1_pos_21plus_first_period=vax1prepostest_first_period
recode vax1_pos_21plus_first_period 1=. if timepos_vax1==1
tab vax1_pos_21plus_first_period

/*Negative test after dose 1 but before dose 2*/

gen vax1prenegtest_first_period=negtestdate_first_period2-covid_vax_1_date2
recode vax1prenegtest_first_period min/-1=.

recode vax1prenegtest_first_period 0/max=1
recode vax1prenegtest_first_period 1=. if covid_vax_2_date2<negtestdate_first_period2

recode vax1prenegtest_first_period 1=. if neg_syx!=1

tab vax1prenegtest_first_period

/*Two different time periods for neeg test after dose 1*/

gen timeneg_vax1=negative_test_result_1_date2-covid_vax_1_date2
recode timeneg_vax1 min/-1=.
recode timeneg_vax1 0/20 =1
recode timeneg_vax1 21/max=2

gen vax1_neg_0to20_first_period=vax1prenegtest_first_period
recode vax1_neg_0to20_first_period 1=. if timeneg_vax1==2
tab vax1_neg_0to20_first_period

gen vax1_neg_21plus_first_period=vax1prenegtest_first_period
recode vax1_neg_21plus_first_period 1=. if timeneg_vax1==1
tab vax1_neg_21plus_first_period

/*Combine 0-20 day post any vaccine dose 1 pos and neg results for those vaccinated within 20 days of being tested*/

gen vax1t1_vax=vax1_pos_0to20_first_period
recode vax1t1_vax .=1 if vax1_neg_0to20_first_period==1

tab vax1t1_vax

/*Combine 21+ days post dose 1 any vaccine pos and neg results for those vaccinated >21 but before d2*/

gen vax1t2_vax=vax1_pos_21plus_first_period
recode vax1t2_vax .=1 if vax1_neg_21plus_first_period==1
tab vax1t2_vax

//**Generate a variable for people vaccinated with any vaccine DOSE 2 prior to the test date during the FIRST PERIOD Jan to Jun**//

gen vax2prepostest_first_period=postestdate_first_period2-covid_vax_2_date2
recode vax2prepostest_first_period min/-1=.  /*to exclude -ve numbers ie testesd before dose 2 ) */

recode vax2prepostest_first_period 0/max=1
recode vax2prepostest_first_period 1=. if covid_vax_3_date2<postestdate_first_period2
recode vax2prepostest_first_period 1=. if pos_syx!=1

tab vax2prepostest_first_period

******************************************************************************8

/*Two different time periods for pos test after dose 2 - first period*/

gen timepos_vax2=positive_test_1_date2-covid_vax_2_date2
recode timepos_vax2 min/-1=.
recode timepos_vax2 0/13=1
recode timepos_vax2 14/max=2

gen vax2_pos_0to13_first_period=vax2prepostest_first_period
recode vax2_pos_0to13_first_period 1=. if timepos_vax2==2
tab vax2_pos_0to13_first_period

gen vax2_pos_14plus_first_period=vax2prepostest_first_period
recode vax2_pos_14plus_first_period 1=. if timepos_vax2==1
tab vax2_pos_14plus_first_period

/*Negative test after dose 2 but before dose 3*/

gen vax2prenegtest_first_period=negtestdate_first_period2-covid_vax_2_date2
recode vax2prenegtest_first_period min/-1=.

recode vax2prenegtest_first_period 0/max=1
recode vax2prenegtest_first_period 1=. if covid_vax_3_date2<negtestdate_first_period2

recode vax2prenegtest_first_period 1=. if neg_syx!=1

tab vax2prenegtest_first_period

/*Two different time periods for neeg test after dose 1*/

gen timeneg_vax2=negative_test_result_1_date2-covid_vax_2_date2
recode timeneg_vax2 min/-1=.
recode timeneg_vax2 0/13 =1
recode timeneg_vax2 14/max=2

gen vax2_neg_0to13_first_period=vax2prenegtest_first_period
recode vax2_neg_0to13_first_period 1=. if timeneg_vax2==2
tab vax2_pos_0to13_first_period

gen vax2_neg_14plus_first_period=vax2prenegtest_first_period
recode vax2_neg_14plus_first_period 1=. if timeneg_vax2==1
tab vax2_neg_14plus_first_period

/*Combine 0-20 day post any vaccine dose 1 pos and neg results for those vaccinated within 20 days of being tested*/

gen vax2t1_vax=vax2_pos_0to13_first_period
recode vax2t1_vax .=1 if vax2_neg_0to13_first_period==1

tab vax2t1_vax

/*Combine 21+ days post dose 1 any vaccine pos and neg results for those vaccinated >21 but before d2*/

gen vax2t2_vax=vax2_pos_14plus_first_period
recode vax2t2_vax .=1 if vax2_neg_14plus_first_period==1
tab vax2t2_vax


//**GENERATE A VARIABLE FOR PEOPLE VACCINATED WITH PFIZER DOSE 1 PRIOR TO THE TEST DATE**//

/* Positive test after dose 1 but before dose 2*/

gen pf1prepositivetest = postestdate_first_period2 - covid_vax_pfizer_1_date2
recode pf1prepositivetest min/-1=.  /*to exclude -ve numbers ie testesd before pfizer dose 1) */

recode pf1prepositivetest 0/max=1
recode pf1prepositivetest 1=. if covid_vax_pfizer_2_date2<positive_test_1_date2 /*(so that people are not included if they first test pos after SECOND dose) */

recode pf1prepositivetest 1=. if pos_syx!=1 /* (to exclude people who had a positive test but did not have symptoms) */

tab pf1prepositivetest

//**Get the 2 different time periods for dose 1**//
/*Pd1 received before a positive test 0 to 20 days after vaccine, and >21 days after dose 1*/

gen timepos_pd1=positive_test_1_date2 - covid_vax_pfizer_1_date2
recode timepos_pd1 min/-1=.
recode timepos_pd1 0/20=1
recode timepos_pd1 21/max=2

gen pd1_pos_0to20=pf1prepositivetest
recode pd1_pos_0to20 1=. if timepos_pd1==2
tab pd1_pos_0to20

gen pd1_pos_21plus=pf1prepositivetest
recode pd1_pos_21plus 1=. if timepos_pd1==1
tab pd1_pos_21plus


/* Negative test after dose 1 but before dose 2*/  

gen pf1prenegtest = negtestdate_first_period2 - covid_vax_pfizer_1_date2
recode pf1prenegtest min/-1=. /* to exclude those with a negative test prior to first pfzer dose*/

recode pf1prenegtest 0/max=1
recode pf1prenegtest 1=. if covid_vax_pfizer_2_date2<negative_test_result_1_date2

recode pf1prenegtest 1=. if neg_syx!=1 /*to exclude people who had a negative test but did not have symptoms*/

tab pf1prenegtest


/* Pd1 received before a NEG test: 0 to 20 days after vaccine and >21 days after dose 1
*/

gen timeneg_pd1=negative_test_result_1_date2 - covid_vax_pfizer_1_date2
recode timeneg_pd1 min/-1=.
recode timeneg_pd1 0/20=1
recode timeneg_pd1 21/max=2

gen pd1_neg_0to20=pf1prenegtest
recode pd1_neg_0to20 1=. if timeneg_pd1==2
tab pd1_neg_0to20

gen pd1_neg_21plus=pf1prenegtest
recode pd1_neg_21plus 1=. if timeneg_pd1==1
tab pd1_neg_21plus 

/*COMBINE 0-20 DAY POST PFIZER DOSE 1 pos and neg RESULTS for those vaccinated within 20 days of being tested (t1) */
gen pd1t1_vax=pd1_pos_0to20
recode pd1t1_vax .=1 if pd1_neg_0to20==1

tab pd1t1_vax 

/*COMBINE 21 plus day post pfizer dose 1 pos and neg results for those vaccinated more than 21 days before (t2) */

gen pd1t2_vax=pd1_pos_21plus
recode pd1t2_vax .=1 if pd1_neg_21plus==1
tab pd1t2_vax

//**GENERATE A VARIABLE FOR PEOPLE VACCINATED WITH PFIZER DOSE 2 PRIOR TO THE TEST DATE**//

/* Positive test after dose 2 but before dose 3 of ANY Covid vaccine*/

gen pf2prepositivetest = postestdate_first_period2 - covid_vax_pfizer_2_date2
recode pf2prepositivetest min/-1=.  /*to exclude -ve numbers ie tested before pfizer dose 2) */


recode pf2prepositivetest 0/max=1
recode pf2prepositivetest 1=. if covid_vax_3_date2<positive_test_1_date2 /*(so that people are not included if they first test pos after THIRD dose of ANY vaccine) */

recode pf2prepositivetest 1=. if pos_syx!=1 /* (to exclude people who had a positive test but did not have symptoms) */

tab pf2prepositivetest

//**Get the 2 different time periods for dose 2**//
/* Pd2 received before a  positive test: 0 to 13 days after vaccine, and >14 days after dose 2 */

gen timepos_pd2=positive_test_1_date2 - covid_vax_pfizer_2_date2
recode timepos_pd2 min/-1=.
recode timepos_pd2 0/13=1
recode timepos_pd2 14/max=2

gen pd2_pos_0to13=pf2prepositivetest
recode pd2_pos_0to13 1=. if timepos_pd2==2
tab pd2_pos_0to13

gen pd2_pos_14plus=pf2prepositivetest
recode pd2_pos_14plus 1=. if timepos_pd2==1
tab pd2_pos_14plus

/* Negative test after dose 2 but before dose 3 of any vaccine*/  

gen pf2prenegtest = negtestdate_first_period2 - covid_vax_pfizer_2_date2
recode pf2prenegtest min/-1=. /* to exclude those with a negative test prior to second pfzer dose*/

recode pf2prenegtest 0/max=1
recode pf2prenegtest 1=. if covid_vax_3_date2<negative_test_result_1_date2

recode pf2prenegtest 1=. if neg_syx!=1 /*to exclude people who had a negative test but did not have symptoms*/

tab pf2prenegtest


/*Pd2 received before a NEGATIVE test: 0 to 13 days after vaccine, and 14 days after dose 1**/


gen timeneg_pd2=negative_test_result_1_date2 - covid_vax_pfizer_2_date2
recode timeneg_pd2 min/-1=.
recode timeneg_pd2 0/13=1
recode timeneg_pd2 14/max=2

gen pd2_neg_0to13=pf2prenegtest
recode pd2_neg_0to13 1=. if timeneg_pd2==2
tab pd2_neg_0to13

gen pd2_neg_14plus=pf2prenegtest
recode pd2_neg_14plus 1=. if timeneg_pd2==1
tab pd2_neg_14plus 

/*COMBINE 0-13 DAY POST PFIZER DOSE 2 pos and neg RESULTS for those vaccinated within 13 days of being tested (t1) */
gen pd2t1_vax=pd2_pos_0to13
recode pd2t1_vax .=1 if pd2_neg_0to13==1

tab pd2t1_vax 

/*COMBINE 14 plus day post pfizer dose 2 pos and neg results for those vaccinated more than 14 days before (t2) */

gen pd2t2_vax=pd2_pos_14plus
recode pd2t2_vax .=1 if pd2_neg_14plus==1
tab pd2t2_vax


////****ASTRA-ZENECA****////

//**GENERATE A VARIABLE FOR PEOPLE VACCINATED WITH AZ DOSE 1 PRIOR TO THE TEST DATE**//

/* Positive test after dose 1 but not after dose 2*/

gen az1prepositivetest = postestdate_first_period2 - covid_vax_az_1_date2
recode az1prepositivetest min/-1=.  /*to exclude -ve numbers ie testesd before AZ dose 1) */


recode az1prepositivetest 0/max=1
recode az1prepositivetest 1=. if covid_vax_az_2_date2<positive_test_1_date2 /*(so that people are not included if they first test pos after SECOND dose) */

recode az1prepositivetest 1=. if pos_syx!=1 /* (to exclude people who had a positive test but did not have symptoms) */

tab az1prepositivetest

//**Get the 2 different time periods for dose 1**//
/*AZ1 received before positive test 0 to 20 days after vaccine, and >21 days after dose 1*/

gen timepos_az1=positive_test_1_date2 - covid_vax_az_1_date2
recode timepos_az1 min/-1=.
recode timepos_az1 0/20=1
recode timepos_az1 21/max=2

gen az1_pos_0to20=az1prepositivetest
recode az1_pos_0to20 1=. if timepos_az1==2

gen az1_pos_21plus=az1prepositivetest
recode az1_pos_21plus 1=. if timepos_az1==1
tab az1_pos_21plus


/* Negative test after dose 1 but before dose 2*/  

gen az1prenegtest = negtestdate_first_period2 - covid_vax_az_1_date2
recode az1prenegtest min/-1=. /* to exclude those with a negative test prior to first az dose*/

recode az1prenegtest 0/max=1
recode az1prenegtest 1=. if covid_vax_az_2_date2<negative_test_result_1_date2

recode az1prenegtest 1=. if neg_syx!=1 /*to exclude people who had a negative test but did not have symptoms*/

tab az1prenegtest

/*combine az1prenegtest and az1prepositivetest*/

gen az1pre_pos_or_neg_test=az1prepositivetest
recode az1pre_pos_or_neg_test .=1 if az1prenegtest==1

tab az1pre_pos_or_neg_test

/* AZ1 received before a NEG test: 0 to 20 days after dose 1, andd >21 days after dose 1
*/

gen timeneg_az1=negative_test_result_1_date2 - covid_vax_az_1_date2
recode timeneg_az1 min/-1=.
recode timeneg_az1 0/20=1
recode timeneg_az1 21/max=2

gen az1_neg_0to20=az1prenegtest
recode az1_neg_0to20 1=. if timeneg_az1==2
tab az1_neg_0to20

gen az1_neg_21plus=az1prenegtest
recode az1_neg_21plus 1=. if timeneg_az1==1
tab az1_neg_21plus 

/*COMBINE 0-20 DAY POST AZ DOSE 1 pos and neg RESULTS for those vaccinated within 20 days of being tested (t1) */
gen az1t1_vax=az1_pos_0to20
recode az1t1 .=1 if az1_neg_0to20==1

tab az1t1_vax 

/*COMBINE 21 plus day post AZ dose 1 pos and neg results for those vaccinated more than 21 days before (t2) */

gen az1t2_vax=az1_pos_21plus
recode az1t2_vax .=1 if az1_neg_21plus==1
tab az1t2_vax

//**GENERATE A VARIABLE FOR PEOPLE VACCINATED WITH AZ DOSE 2 PRIOR TO THE TEST DATE**//

/* Positive test after dose 2 but before dose 3 of any vaccine*/

gen az2prepositivetest = postestdate_first_period2 - covid_vax_az_2_date2
recode az2prepositivetest min/-1=.  /*to exclude -ve numbers ie tested before az dose 2) */


recode az2prepositivetest 0/max=1
recode az2prepositivetest 1=. if covid_vax_3_date2<positive_test_1_date2 /*(so that people are not included if they first test pos after THIRD dose of ANY vaccine) */

recode az2prepositivetest 1=. if pos_syx!=1 /* (to exclude people who had a positive test but did not have symptoms) */

tab az2prepositivetest

//**Get the 2 different time periods for dose 2**//
/* AZ2 received before a positive test: 0 to 13 days after vaccine, and >14 days after dose 2 */

gen timepos_az2=positive_test_1_date2 - covid_vax_az_2_date2
recode timepos_az2 min/-1=.
recode timepos_az2 0/13=1
recode timepos_az2 14/max=2

gen az2_pos_0to13=az2prepositivetest
recode az2_pos_0to13 1=. if timepos_az2==2

gen az2_pos_14plus=az2prepositivetest
recode az2_pos_14plus 1=. if timepos_az2==1
tab az2_pos_14plus

/* Negative test after dose 2 but before dose 3*/  

gen az2prenegtest = negtestdate_first_period2 - covid_vax_az_2_date2
recode az2prenegtest min/-1=. /* to exclude those with a negative test prior to second AZ dose*/

recode az2prenegtest 0/max=1
recode az2prenegtest 1=. if covid_vax_3_date2<negative_test_result_1_date2

recode az2prenegtest 1=. if neg_syx!=1 /*to exclude people who had a negative test but did not have symptoms*/

tab az2prenegtest

/*AZ2 received before a NEG test: 0 to 13 days after vaccine, and >14 days after dose 2**/


gen timeneg_az2=negative_test_result_1_date2 - covid_vax_az_2_date2
recode timeneg_az2 min/-1=.
recode timeneg_az2 0/13=1
recode timeneg_az2 14/max=2

gen az2_neg_0to13=az2prenegtest
recode az2_neg_0to13 1=. if timeneg_az2==2
tab az2_neg_0to13

gen az2_neg_14plus=az2prenegtest
recode az2_neg_14plus 1=. if timeneg_az2==1
tab az2_neg_14plus 

/*COMBINE 0-13 DAY POST AZ DOSE 2 pos and neg RESULTS for those vaccinated within 13 days of being tested (t1) */
gen az2t1_vax=az2_pos_0to13
recode az2t1_vax .=1 if az2_neg_0to13==1

tab az2t1_vax 

/*COMBINE 14 plus day post AZ dose 2 pos and neg results for those vaccinated more than 14 days before (t2) */

gen az2t2_vax=az2_pos_14plus
recode az2t2_vax .=1 if az2_neg_14plus==1
tab az2t2_vax


////*************************UNVACCINATED************************////

///***CREATE A VARIABLE FOR PEOPLE WHO ARE UNVACCINATED PRIOR TO THE TEST DATE***///

//** generate a variable for receipt of ANY Covid vaccine at anytime**//

gen vax1recd=1
recode vax1recd 1=. if covid_vax_1_date2==.

//**create var to identify people with no record of first dose of ANY Covid vaccine, or had it after testerd, and who were symtpomatic**//

gen unvax_any_pretest=.
recode unvax_any_pretest .=1 if vax1recd!=1
recode unvax_any_pretest .=1 if covid_vax_1_date2>positive_test_1_date2 & vax1recd==1
recode unvax_any_pretest .=1 if covid_vax_1_date2>negative_test_result_1_date2 & vax1recd==1

recode unvax_any_pretest 1=. if tested_syx==.

tab unvax_any_pretest

//**generate a variable for receipt of first dose of either Pf or AZ at anytime**//

gen pf1recd=1
recode pf1recd 1=. if covid_vax_pfizer_1_date2==. /*i.e. have no record of 1st dose of Pfizer*/

gen az1recd=1
recode az1recd 1=. if covid_vax_az_1_date2==.



//** create a variable to identify unvaccinated people (==1), either never had first dose of vaccine or had it after tested, and who were symptomatic and tested**//

gen unvacpretest=.

recode unvacpretest .=1 if pf1recd!=1 & az1recd!=1 /*(no record of ever having first dose of either Pf or AZ. I THINK IT does need to be '&' here, not '|'; if it is 'OR', people who have a record of first dose of either vaccine will be counted as  unvaccinated, which will not be correct)*/

/*change to unvaccinated if had positive/negative result prior to first vaccine dose*/

recode unvacpretest .=1 if covid_vax_pfizer_1_date2>positive_test_1_date2 & pf1recd==1 
recode unvacpretest .=1 if covid_vax_az_1_date2>positive_test_1_date2 & az1recd==1
recode unvacpretest .=1 if covid_vax_pfizer_1_date2>negative_test_result_1_date2 & pf1recd==1
recode unvacpretest .=1 if covid_vax_az_1_date2>negative_test_result_1_date2 & az1recd==1

recode unvacpretest 1=. if tested_syx==.

tab unvacpretest  

///*** Combine variables for vaccinated pre tested with  unvaccinated pre tested to get VACCINATION STATUS (0==unvaccinated, 1==vaccinated) for each time period ***///

/*ANY covid vaccine*/

gen vax_status_any1_0to20=vax1t1_vax
recode vax_status_any1_0to20 .=0 if unvax_any_pretest==1
tab vax_status_any1_0to20

gen vax_status_any1_21plus=vax1t2_vax
recode vax_status_any1_21plus .=0 if unvax_any_pretest==1


//***ADDITIONAL CODE SO PEOPLE WHO WERE VACCINATED AND HAD TEST RESULT IN TIME PERIOD 1 ARE NOT STILL COUNTED AS UNVACCINATED IN THE LATER TIME PERIOD ***///
recode vax_status_any1_21plus 0=. if vax_status_any1_0to20==1
recode vax_status_any1_21plus 1=. if vax_status_any1_0to20==1

tab vax_status_any1_21plus

gen vax_status_any2_0to13=vax2t1_vax
recode vax_status_any2_0to13 .=0 if unvax_any_pretest==1

recode vax_status_any2_0to13 0=. if vax_status_any1_0to20==1|vax_status_any1_21plus==1
recode vax_status_any2_0to13 1=. if vax_status_any1_0to20==1|vax_status_any1_21plus==1
tab vax_status_any2_0to13

gen vax_status_any2_14plus=vax2t2_vax
recode vax_status_any2_14plus .=0 if unvax_any_pretest==1

recode vax_status_any2_14plus 0=. if vax_status_any1_0to20==1|vax_status_any1_21plus==1|vax_status_any2_0to13==1
recode vax_status_any2_14plus 1=. if vax_status_any1_0to20==1|vax_status_any1_21plus==1|vax_status_any2_0to13==1
tab vax_status_any2_14plus


/*PFIZER*/

gen vax_status_pf1_0to20=pd1t1_vax
recode vax_status_pf1_0to20 .=0 if unvacpretest==1
tab vax_status_pf1_0to20

gen vax_status_pf1_21plus=pd1t2_vax
recode vax_status_pf1_21plus .=0 if unvacpretest==1


//***ADDITIONAL CODE SO PEOPLE WHO WERE VACCINATED AND HAD TEST RESULT IN TIME PERIOD 1 ARE NOT STILL COUNTED AS UNVACCINATED IN THE LATER TIME PERIOD ***///
recode vax_status_pf1_21plus 0=. if vax_status_pf1_0to20==1
recode vax_status_pf1_21plus 1=. if vax_status_pf1_0to20==1
*************************
tab vax_status_pf1_21plus


gen vax_status_pf2_0to13=pd2t1_vax
recode vax_status_pf2_0to13 .=0 if unvacpretest==1

recode vax_status_pf2_0to13 0=. if vax_status_pf1_0to20==1|vax_status_pf1_21plus==1
recode vax_status_pf2_0to13 1=. if vax_status_pf1_0to20==1|vax_status_pf1_21plus==1
tab vax_status_pf2_0to13

gen vax_status_pf2_14plus=pd2t2_vax
recode vax_status_pf2_14plus .=0 if unvacpretest==1

recode vax_status_pf2_14plus 0=. if vax_status_pf1_0to20==1|vax_status_pf1_21plus==1|vax_status_pf2_0to13==1
recode vax_status_pf2_14plus 1=. if vax_status_pf1_0to20==1|vax_status_pf1_21plus==1|vax_status_pf2_0to13==1
tab vax_status_pf2_14plus

/*ASTRA ZENECA*/

gen vax_status_az1_0to20=az1t1_vax
recode vax_status_az1_0to20 .=0 if unvacpretest==1
tab vax_status_az1_0to20

gen vax_status_az1_21plus=az1t2_vax
recode vax_status_az1_21plus .=0 if unvacpretest==1

//***ADDITIONAL CODE SO PEOPLE WHO WERE VACCINATED AND HAD TEST RESULT IN TIME PERIOD 1 ARE NOT COUNTED AS UNVACCINATED IN THE LATER TIME PERIOD 2***///
recode vax_status_az1_21plus 0=. if vax_status_az1_0to20==1
recode vax_status_az1_21plus 1=. if vax_status_az1_0to20==1
tab vax_status_az1_21plus

gen vax_status_az2_0to13=az2t1_vax
recode vax_status_az2_0to13 .=0 if unvacpretest==1

recode vax_status_az2_0to13 0=. if vax_status_az1_0to20==1|vax_status_az1_21plus==1
recode vax_status_az2_0to13 1=. if vax_status_az1_0to20==1|vax_status_az1_21plus==1
tab vax_status_az2_0to13

gen vax_status_az2_14plus=az2t2_vax
recode vax_status_az2_14plus .=0 if unvacpretest==1

recode vax_status_az2_14plus 0=. if vax_status_az1_0to20==1|vax_status_az1_21plus==1|vax_status_az2_0to13==1
recode vax_status_az2_14plus 1=. if vax_status_az1_0to20==1|vax_status_az1_21plus==1|vax_status_az2_0to13==1
tab vax_status_az2_14plus


// vaccine % and univariate analysis //- by age group, any type, d1, d2- grousp 0-20- 21+ and D2 14+ and time period before janry 8th and after
		

local desc2 "sex2 bmi2 carehome has_follow_up_previous_year  ethnicity region2 imd chronic_cardiac_disease diabetes_type_1 diabetes_type_2 diabetes_unknown_type current_copd dmards dementia dialysis solid_organ_transplantation chemo_or_radio intel_dis_incl_downs_syndrome lung_cancer cancer_excl_lung_and_haem haematological_cancer cystic_fibrosis sickle_cell_disease permanant_immunosuppression temporary_immunosuppression psychosis_schiz_bipolar asplenia immcomp"

	
foreach var of local desc2 {
tab `var' tested_syx, col
mhodds  tested_syx `var'
}	

local desc3 "carehome chronic_cardiac_disease diabetes_type_1 diabetes_type_2 diabetes_unknown_type current_copd dmards dementia dialysis solid_organ_transplantation chemo_or_radio intel_dis_incl_downs_syndrome lung_cancer cancer_excl_lung_and_haem haematological_cancer cystic_fibrosis sickle_cell_disease permanant_immunosuppression temporary_immunosuppression psychosis_schiz_bipolar asplenia "

foreach var of local desc3 {
tab `var'

tab tested_syx vax_status_any1_0to20 if `var'==1
logistic tested_syx vax_status_any1_0to20 if `var'==1

tab tested_syx vax_status_any1_21plus if `var'==1
logistic tested_syx vax_status_any1_21plus if `var'==1

tab tested_syx vax_status_any2_0to13 if `var'==1
logistic tested_syx vax_status_any2_0to13 if `var'==1

tab tested_syx vax_status_any2_14plus if `var'==1
logistic tested_syx vax_status_any2_14plus if `var'==1


tab tested_syx vax_status_pf1_0to20 if `var'==1
logistic tested_syx vax_status_pf1_0to20 if `var'==1 

tab tested_syx vax_status_pf1_21plus if `var'==1
logistic tested_syx vax_status_pf1_21plus if `var'==1 

tab tested_syx vax_status_pf2_0to13 if `var'==1
logistic tested_syx vax_status_pf2_0to13 if `var'==1 

tab tested_syx vax_status_pf2_14plus if `var'==1 
logistic tested_syx vax_status_pf2_14plus if `var'==1 

tab tested_syx vax_status_az1_0to20 if `var'==1
logistic tested_syx vax_status_az1_0to20 if `var'==1 

tab tested_syx vax_status_az1_21plus if `var'==1
logistic tested_syx vax_status_az1_21plus if `var'==1 

tab tested_syx vax_status_az2_0to13 if `var'==1
logistic tested_syx vax_status_az2_0to13 if `var'==1 

tab tested_syx vax_status_az2_14plus if `var'==1 
logistic tested_syx vax_status_az2_14plus if `var'==1 

}

			
///*VACCINE EFFICACY***///

///***ADJUSTING FOR TIME OF TESTING***///

/*Generate a variable for ISO week for week of test*/

gen ISOweekpos =int((doy(7*int((positive_test_1_date2-mdy(1,1,1900))/7)+ mdy(1,1,1900) + 3)+6)/7)
gen ISOweekneg =int((doy(7*int((negative_test_result_1_date2-mdy(1,1,1900))/7)+ mdy(1,1,1900) + 3)+6)/7)
gen isoweek=ISOweekpos
replace isoweek=ISOweekneg if isoweek==.

/*gen numbered time periods 1 to 3*/

gen timeperiod=.
replace timeperiod=1 if postestdate_first_period2!=.|negtestdate_first_period2!=.
replace timeperiod=2 if postestdate_second_period2!=.|negtestdate_second_period2!=.
replace timeperiod=3 if postestdate_third_period2!=.|negtestdate_third_period2!=.

/*tab to check if reporting of symptoms differs between the tike periods (tested_syx : 0 = neg test but symptoms; 1= pos test with symtpoms)*/

tab tested_syx timeperiod

//**CROSS TABS AND OVERALL unadjusted and adjusted ORs, including separate model with adjustment for test week**//

/*ANY COVID VACCINE DOSES 1 & 2 FOR FIRST PERIOD JAN TO JUN 2021*/

tab tested_syx vax_status_any1_0to20
logistic  tested_syx vax_status_any1_0to20 
logistic  tested_syx vax_status_any1_0to20  i.ageg sex2 carehome bmi2 i.ethnicity i.region2 i.imd i.isoweek

tab tested_syx vax_status_any1_21plus
logistic  tested_syx vax_status_any1_21plus 
logistic  tested_syx vax_status_any1_21plus  i.ageg sex2 carehome bmi2 i.ethnicity i.region2 i.imd i.isoweek

tab tested_syx vax_status_any2_0to13
logistic  tested_syx vax_status_any2_0to13 
logistic  tested_syx vax_status_any2_0to13  i.ageg sex2 carehome bmi2 i.ethnicity i.region2 i.imd i.isoweek

tab tested_syx vax_status_any2_14plus
logistic  tested_syx vax_status_any2_14plus 
logistic  tested_syx vax_status_any2_14plus  i.ageg sex2 carehome bmi2 i.ethnicity i.region2 i.imd i.isoweek


/*PFIZER DOSES 1 & 2*/

tab tested_syx vax_status_pf1_0to20
logistic  tested_syx vax_status_pf1_0to20 
logistic  tested_syx vax_status_pf1_0to20  i.ageg sex2 carehome bmi2 i.ethnicity i.region2 i.imd i.isoweek

tab tested_syx vax_status_pf1_21plus
logistic  tested_syx vax_status_pf1_21plus 
logistic  tested_syx vax_status_pf1_21plus  i.ageg sex2 carehome bmi2 i.ethnicity i.region2 i.imd i.isoweek

tab tested_syx vax_status_pf2_0to13
logistic  tested_syx vax_status_pf2_0to13 
logistic  tested_syx vax_status_pf2_0to13  i.ageg sex2 carehome bmi2 i.ethnicity i.region2 i.imd i.isoweek

tab tested_syx vax_status_pf2_14plus
logistic  tested_syx vax_status_pf2_14plus 
logistic  tested_syx vax_status_pf2_14plus  i.ageg sex2 carehome bmi2 i.ethnicity i.region2 i.imd i.isoweek

/*AZ DOSES 1 & 2*/

tab tested_syx vax_status_az1_0to20
logistic  tested_syx vax_status_az1_0to20 
logistic  tested_syx vax_status_az1_0to20  i.ageg sex2 carehome bmi2 i.ethnicity i.region2 i.imd i.isoweek

tab tested_syx vax_status_az1_21plus
logistic  tested_syx vax_status_az1_21plus 
logistic  tested_syx vax_status_az1_21plus  i.ageg sex2 carehome bmi2 i.ethnicity i.region2 i.imd i.isoweek

tab tested_syx vax_status_az2_0to13
logistic  tested_syx vax_status_az2_0to13 
logistic  tested_syx vax_status_az2_0to13  i.ageg sex2 carehome bmi2 i.ethnicity i.region2 i.imd i.isoweek

tab tested_syx vax_status_az2_14plus
logistic  tested_syx vax_status_az2_14plus 
logistic  tested_syx vax_status_az2_14plus  i.ageg sex2 carehome bmi2 i.ethnicity i.region2 i.imd i.isoweek

//**IMMUNOCOMPROMISED unadjusted and adjusted ORs**//

/*ANY vaccine*/
tab tested_syx vax_status_any1_0to20 if immcomp==1
logistic  tested_syx vax_status_any1_0to20  if immcomp==1
logistic  tested_syx vax_status_any1_0to20  i.ageg carehome sex2 i.isoweek if immcomp==1

tab tested_syx vax_status_any1_21plus if immcomp==1
logistic  tested_syx vax_status_any1_21plus if immcomp==1
logistic  tested_syx vax_status_any1_21plus  i.ageg carehome sex2 i.isoweek if immcomp==1

tab tested_syx vax_status_any2_0to13 if immcomp==1
logistic  tested_syx vax_status_any2_0to13 if immcomp==1
logistic  tested_syx vax_status_any2_0to13  i.ageg carehome sex2 i.isoweek if immcomp==1 

tab tested_syx vax_status_any2_14plus if immcomp==1
logistic  tested_syx vax_status_any2_14plus if immcomp==1
logistic  tested_syx vax_status_any2_14plus  i.ageg carehome sex2 i.isoweek if immcomp==1

/*PFIZER DOSES 1 & 2*/

tab tested_syx vax_status_pf1_0to20 if immcomp==1
logistic  tested_syx vax_status_pf1_0to20 if immcomp==1
logistic  tested_syx vax_status_pf1_0to20  i.ageg carehome sex2 i.isoweek if immcomp==1

tab tested_syx vax_status_pf1_21plus if immcomp==1
logistic  tested_syx vax_status_pf1_21plus if immcomp==1
logistic  tested_syx vax_status_pf1_21plus  i.ageg carehome sex2 i.isoweek if immcomp==1

tab tested_syx vax_status_pf2_0to13 if immcomp==1
logistic  tested_syx vax_status_pf2_0to13 if immcomp==1
logistic  tested_syx vax_status_pf2_0to13  i.ageg carehome sex2 i.isoweek if immcomp==1 

tab tested_syx vax_status_pf2_14plus if immcomp==1
logistic  tested_syx vax_status_pf2_14plus if immcomp==1
logistic  tested_syx vax_status_pf2_14plus  i.ageg carehome sex2 i.isoweek if immcomp==1

/*AZ DOSES 1 & 2*/

tab tested_syx vax_status_az1_0to20 if immcomp==1
logistic  tested_syx vax_status_az1_0to20 if immcomp==1
logistic  tested_syx vax_status_az1_0to20  i.ageg carehome sex2 i.isoweek if immcomp==1

tab tested_syx vax_status_az1_21plus if immcomp==1
logistic  tested_syx vax_status_az1_21plus if immcomp==1
logistic  tested_syx vax_status_az1_21plus  i.ageg carehome sex2 i.isoweek if immcomp==1 

tab tested_syx vax_status_az2_0to13 if immcomp==1
logistic  tested_syx vax_status_az2_0to13 if immcomp==1
logistic  tested_syx vax_status_az2_0to13  i.ageg carehome sex2 i.isoweek if immcomp==1

tab tested_syx vax_status_az2_14plus if immcomp==1
logistic  tested_syx vax_status_az2_14plus if immcomp==1
logistic  tested_syx vax_status_az2_14plus  i.ageg carehome sex2 i.isoweek if immcomp==1


/////////////***************SECOND PERIOD 9 Jun 2021 to 24 November 2021****************//////////////////

/***Any first dose vaccine received before a pos or neg test in SECOND period***/
/*Positive test after dose 1 but before dose 2*/

tab tested_syx if timeperiod==2

gen vax1prepostest_second_period=postestdate_second_period2-covid_vax_1_date2
recode vax1prepostest_second_period min/-1=.  /*to exclude -ve numbers ie tested before any dose 1) */

recode vax1prepostest_second_period 0/max=1
recode vax1prepostest_second_period 1=. if covid_vax_2_date2<postestdate_second_period2

tab vax1prepostest_second_period tested_syx if timeperiod==2

recode vax1prepostest_second_period 1=. if pos_syx!=1

tab vax1prepostest_second_period

/*Two different time periods for pos test after dose 1*/

gen vax1_pos_0to20_second_period=vax1prepostest_second_period
recode vax1_pos_0to20_second_period 1=. if timepos_vax1==2
tab vax1_pos_0to20_second_period

gen vax1_pos_21plus_second_period=vax1prepostest_second_period
recode vax1_pos_21plus_second_period 1=. if timepos_vax1==1
tab vax1_pos_21plus_second_period

/*Negative test after dose 1 but before dose 2*/

gen vax1prenegtest_second_period=negtestdate_second_period2-covid_vax_1_date2
recode vax1prenegtest_second_period min/-1=.

recode vax1prenegtest_second_period 0/max=1
recode vax1prenegtest_second_period 1=. if covid_vax_2_date2<negtestdate_second_period2

tab vax1prenegtest_second_period tested_syx if timeperiod==2

recode vax1prenegtest_second_period 1=. if neg_syx!=1

tab vax1prenegtest_second_period

/*Two different time periods for neg test after dose 1*/

gen vax1_neg_0to20_second_period=vax1prenegtest_second_period
recode vax1_neg_0to20_second_period 1=. if timeneg_vax1==2
tab vax1_pos_0to20_second_period

gen vax1_neg_21plus_second_period=vax1prenegtest_second_period
recode vax1_neg_21plus_second_period 1=. if timeneg_vax1==1
tab vax1_neg_21plus_second_period

/*Combine 0-20 day post any vaccine dose 1 pos and neg results for those vaccinated within 20 days of being tested*/

gen vax1t1_vax_secondperiod=vax1_pos_0to20_second_period
recode vax1t1_vax_secondperiod .=1 if vax1_neg_0to20_second_period==1

tab vax1t1_vax_secondperiod

/*Combine 21+ days post dose 1 any vaccine pos and neg results for those vaccinated >21 but before d2*/

gen vax1t2_vax_secondperiod=vax1_pos_21plus_second_period
recode vax1t2_vax_secondperiod .=1 if vax1_neg_21plus_second_period==1
tab vax1t2_vax_secondperiod

//**Generate a variable for people vaccinated with any vaccine DOSE 2 prior to the test date during the FIRST PERIOD Jan to Jun**//

gen vax2prepostest_second_period=postestdate_second_period2-covid_vax_2_date2
recode vax2prepostest_second_period min/-1=.  /*to exclude -ve numbers ie testesd before dose 2 ) */

recode vax2prepostest_second_period 0/max=1
recode vax2prepostest_second_period 1=. if covid_vax_3_date2<postestdate_second_period2

tab vax2prepostest_second_period tested_syx if timeperiod==2

recode vax2prepostest_second_period 1=. if pos_syx!=1

tab vax2prepostest_second_period

******************************************************************************8

/*Two different time periods for pos test after dose 2 - SECOND period*/

gen vax2_pos_0to13_second_period=vax2prepostest_second_period
recode vax2_pos_0to13_second_period 1=. if timepos_vax2==2
tab vax2_pos_0to13_second_period

gen vax2_pos_14plus_second_period=vax2prepostest_second_period
recode vax2_pos_14plus_second_period 1=. if timepos_vax2==1
tab vax2_pos_14plus_second_period

/*Negative test after dose 2 but before dose 3*/

gen vax2prenegtest_second_period=negtestdate_second_period2-covid_vax_2_date2
recode vax2prenegtest_second_period min/-1=.

recode vax2prenegtest_second_period 0/max=1
recode vax2prenegtest_second_period 1=. if covid_vax_3_date2<negtestdate_second_period2

tab vax2prenegtest_second_period tested_syx if timeperiod==2

recode vax2prenegtest_second_period 1=. if neg_syx!=1

tab vax2prenegtest_second_period

/*Two different time periods for neeg test after dose 1*/

gen vax2_neg_0to13_second_period=vax2prenegtest_second_period
recode vax2_neg_0to13_second_period 1=. if timeneg_vax2==2
tab vax2_pos_0to13_second_period

gen vax2_neg_14plus_second_period=vax2prenegtest_second_period
recode vax2_neg_14plus_second_period 1=. if timeneg_vax2==1
tab vax2_neg_14plus_second_period

/*Combine 0-20 day post any vaccine dose 1 pos and neg results for those vaccinated within 20 days of being tested*/

gen vax2t1_vax_secondperiod=vax2_pos_0to13_second_period
recode vax2t1_vax_secondperiod .=1 if vax2_neg_0to13_second_period==1

tab vax2t1_vax_secondperiod

/*Combine 21+ days post dose 1 any vaccine pos and neg results for those vaccinated >21 but before d2*/

gen vax2t2_vax_secondperiod=vax2_pos_14plus_second_period
recode vax2t2_vax_secondperiod .=1 if vax2_neg_14plus_second_period==1
tab vax2t2_vax_secondperiod
******************************************************************************************
///*** Combine variables for vaccinated pre tested with  unvaccinated pre tested to get VACCINATION STATUS (0==unvaccinated, 1==vaccinated) for each time period ***///

/*ANY covid vaccine*/

gen vax_status_any1_0to20_secperiod=vax1t1_vax_secondperiod
recode vax_status_any1_0to20_secperiod .=0 if unvax_any_pretest==1
tab vax_status_any1_0to20_secperiod

gen vax_status_any1_21plus_secperiod=vax1t2_vax_secondperiod
recode vax_status_any1_21plus_secperiod .=0 if unvax_any_pretest==1


//***ADDITIONAL CODE SO PEOPLE WHO WERE VACCINATED AND HAD TEST RESULT IN TIME PERIOD 1 ARE NOT STILL COUNTED AS UNVACCINATED IN THE LATER TIME PERIOD ***///
recode vax_status_any1_21plus_secperiod 0=. if vax_status_any1_0to20_secperiod==1
recode vax_status_any1_21plus_secperiod 1=. if vax_status_any1_0to20_secperiod==1

tab vax_status_any1_21plus_secperiod

gen vax_status_any2_0to13_secperiod=vax2t1_vax_secondperiod
recode vax_status_any2_0to13_secperiod .=0 if unvax_any_pretest==1

recode vax_status_any2_0to13_secperiod 0=. if vax_status_any1_0to20_secperiod==1|vax_status_any1_21plus_secperiod==1
recode vax_status_any2_0to13_secperiod 1=. if vax_status_any1_0to20_secperiod==1|vax_status_any1_21plus_secperiod==1
tab vax_status_any2_0to13_secperiod

gen vax_status_any2_14plus_secperiod=vax2t2_vax_secondperiod
recode vax_status_any2_14plus_secperiod .=0 if unvax_any_pretest==1

recode vax_status_any2_14plus_secperiod 0=. if vax_status_any1_0to20_secperiod==1|vax_status_any1_21plus_secperiod==1|vax_status_any2_0to13_secperiod==1
recode vax_status_any2_14plus_secperiod 1=. if vax_status_any1_0to20_secperiod==1|vax_status_any1_21plus_secperiod==1|vax_status_any2_0to13_secperiod==1
tab vax_status_any2_14plus_secperiod

//**THIRD DOSE ANY VACCINE**//

gen vax3prepostest_second_period=postestdate_second_period2-covid_vax_3_date2
recode vax3prepostest_second_period min/-1=.  /*to exclude -ve numbers ie testesd before dose 3 ) */

recode vax3prepostest_second_period 0/max=1
recode vax3prepostest_second_period 1=. if covid_vax_4_date2<postestdate_second_period2

tab vax3prepostest_second_period tested_syx if timeperiod==2

recode vax3prepostest_second_period 1=. if pos_syx!=1

tab vax3prepostest_second_period

******************************************************************************8

/*Two different time periods for pos test after dose 2 - SECOND period*/

gen timepos_vax3=positive_test_1_date2-covid_vax_3_date2
recode timepos_vax3 min/-1=.
recode timepos_vax3 0/13=1
recode timepos_vax3 14/max=2

gen vax3_pos_0to13_second_period=vax3prepostest_second_period
recode vax3_pos_0to13_second_period 1=. if timepos_vax3==2
tab vax3_pos_0to13_second_period

gen vax3_pos_14plus_second_period=vax3prepostest_second_period
recode vax3_pos_14plus_second_period 1=. if timepos_vax3==1
tab vax3_pos_14plus_second_period

/*Negative test after dose 1 but before dose 2*/
gen timeneg_vax3=negative_test_result_1_date2-covid_vax_3_date2
recode timeneg_vax3 min/-1=.
recode timeneg_vax3 0/13 =1
recode timeneg_vax3 14/max=2

gen vax3prenegtest_second_period=negtestdate_second_period2-covid_vax_3_date2
recode vax3prenegtest_second_period min/-1=.

recode vax3prenegtest_second_period 0/max=1
recode vax3prenegtest_second_period 1=. if covid_vax_4_date2<negtestdate_second_period2

tab vax3prenegtest_second_period tested_syx if timeperiod==2

recode vax3prenegtest_second_period 1=. if neg_syx!=1

tab vax3prenegtest_second_period

/*Two different time periods for neg test after dose 3*/

gen vax3_neg_0to13_second_period=vax3prenegtest_second_period
recode vax3_neg_0to13_second_period 1=. if timeneg_vax3==2
tab vax3_pos_0to13_second_period

gen vax3_neg_14plus_second_period=vax3prenegtest_second_period
recode vax3_neg_14plus_second_period 1=. if timeneg_vax3==1
tab vax3_neg_14plus_second_period

/*Combine 0-13 day post any vaccine dose 3 pos and neg results for those vaccinated within 13 days of being tested*/

gen vax3t1_vax_secondperiod=vax3_pos_0to13_second_period
recode vax3t1_vax_secondperiod .=1 if vax3_neg_0to13_second_period==1

tab vax3t1_vax_secondperiod

/*Combine 14+ days post dose 3 any vaccine pos and neg results for those vaccinated >14 but before dose 4*/

gen vax3t2_vax_secondperiod=vax3_pos_14plus_second_period
recode vax3t2_vax_secondperiod .=1 if vax3_neg_14plus_second_period==1
tab vax3t2_vax_secondperiod
*********************************************************************************************8
///*** Combine variables for vaccinated pre tested with  unvaccinated pre tested to get VACCINATION STATUS (0==unvaccinated, 1==vaccinated) for each time period ***///

/*ANY covid vaccine*/
/*Dose 3 0-13 days (t1)*/

gen vax_status_any3_0to13_secperiod=vax3t1_vax_secondperiod

recode vax_status_any3_0to13_secperiod .=0 if unvax_any_pretest==1
recode vax_status_any3_0to13_secperiod 0=. if vax_status_any2_0to13_secperiod==1|vax_status_any2_14plus_secperiod==1|vax_status_any1_0to20_secperiod==1|vax_status_any1_21plus_secperiod==1
recode vax_status_any3_0to13_secperiod 1=. if vax_status_any2_0to13_secperiod==1|vax_status_any2_14plus_secperiod==1|vax_status_any1_0to20_secperiod==1|vax_status_any1_21plus_secperiod==1
tab vax_status_any3_0to13_secperiod

/*Dose 3, 14 days + (t2)*/

gen vax_status_any3_14plus_secperiod=vax3t2_vax_secondperiod
recode vax_status_any3_14plus_secperiod .=0 if unvax_any_pretest==1

recode vax_status_any3_14plus_secperiod 0=. if vax_status_any3_0to13_secperiod==1|vax_status_any2_0to13_secperiod==1|vax_status_any2_14plus_secperiod==1|vax_status_any1_0to20_secperiod==1|vax_status_any1_21plus_secperiod==1
recode vax_status_any3_14plus_secperiod 1=. if vax_status_any3_0to13_secperiod==1|vax_status_any2_0to13_secperiod==1|vax_status_any2_14plus_secperiod==1|vax_status_any1_0to20_secperiod==1|vax_status_any1_21plus_secperiod==1

tab vax_status_any3_14plus_secperiod


//**CROSS TABS AND OVERALL unadjusted and adjusted ORs, including separate model with adjustment for test week**//

/*ANY COVID VACCINE DOSE 3 FOR SECOND PERIOD JUN TO  NOV 2021*/

tab tested_syx vax_status_any3_0to13_secperiod
logistic  tested_syx vax_status_any3_0to13_secperiod 
logistic  tested_syx vax_status_any3_0to13_secperiod  i.ageg sex2 carehome bmi2 i.ethnicity i.region2 i.imd i.isoweek

tab tested_syx vax_status_any3_14plus_secperiod
logistic  tested_syx vax_status_any3_14plus_secperiod 
logistic  tested_syx vax_status_any3_14plus_secperiod  i.ageg sex2 carehome bmi2 i.ethnicity i.region2 i.imd i.isoweek

/*Immunocompromised 3rd dose any vaccine*/
tab tested_syx vax_status_any3_0to13_secperiod if immcomp==1
logistic  tested_syx vax_status_any3_0to13_secperiod if immcomp==1
logistic  tested_syx vax_status_any3_0to13_secperiod  i.ageg carehome sex2 i.isoweek if immcomp==1 

tab tested_syx vax_status_any3_14plus_secperiod if immcomp==1
logistic  tested_syx vax_status_any3_14plus_secperiod if immcomp==1
logistic  tested_syx vax_status_any3_14plus_secperiod  i.ageg carehome sex2 i.isoweek if immcomp==1

****************************************************************************
//////////////////////THIRD PERIOD 25 Nov 2021 - MARCH 2022/////////
****************************************************************************
tab tested_syx if time_period==3
/***Any first dose vaccine received before a pos or neg test in THIRD period***/
/*Positive test after dose 1 but before dose 2*/

gen vax1prepostest_third_period=postestdate_third_period2-covid_vax_1_date2
recode vax1prepostest_third_period min/-1=.  /*to exclude -ve numbers ie tested before any dose 1) */

recode vax1prepostest_third_period 0/max=1
recode vax1prepostest_third_period 1=. if covid_vax_2_date2<postestdate_third_period2

tab vax1prepostest_third_period tested_syx if timeperiod==3

recode vax1prepostest_third_period 1=. if pos_syx!=1

tab vax1prepostest_third_period

/*Two different time periods for pos test after dose 1*/

gen vax1_pos_0to20_third_period=vax1prepostest_third_period
recode vax1_pos_0to20_third_period 1=. if timepos_vax1==2
tab vax1_pos_0to20_third_period

gen vax1_pos_21plus_third_period=vax1prepostest_third_period
recode vax1_pos_21plus_third_period 1=. if timepos_vax1==1
tab vax1_pos_21plus_third_period

/*Negative test after dose 1 but before dose 2*/

gen vax1prenegtest_third_period=negtestdate_third_period2-covid_vax_1_date2
recode vax1prenegtest_third_period min/-1=.

recode vax1prenegtest_third_period 0/max=1
recode vax1prenegtest_third_period 1=. if covid_vax_2_date2<negtestdate_third_period2

tab vax1prenegtest_third_period tested_syx if timeperiod==3
recode vax1prenegtest_third_period 1=. if neg_syx!=1

tab vax1prenegtest_third_period

/*Two different time periods for neg test after dose 1*/

gen vax1_neg_0to20_third_period=vax1prenegtest_third_period
recode vax1_neg_0to20_third_period 1=. if timeneg_vax1==2
tab vax1_pos_0to20_third_period

gen vax1_neg_21plus_third_period=vax1prenegtest_third_period
recode vax1_neg_21plus_third_period 1=. if timeneg_vax1==1
tab vax1_neg_21plus_third_period

/*Combine 0-20 day post any vaccine dose 1 pos and neg results for those vaccinated within 20 days of being tested*/

gen vax1t1_vax_thirdperiod=vax1_pos_0to20_third_period
recode vax1t1_vax_thirdperiod .=1 if vax1_neg_0to20_third_period==1

tab vax1t1_vax_thirdperiod

/*Combine 21+ days post dose 1 any vaccine pos and neg results for those vaccinated >21 but before d2*/

gen vax1t2_vax_thirdperiod=vax1_pos_21plus_third_period
recode vax1t2_vax_thirdperiod .=1 if vax1_neg_21plus_third_period==1
tab vax1t2_vax_thirdperiod

//**Generate a variable for people vaccinated with any vaccine DOSE 2 prior to the test date during the FIRST PERIOD Jan to Jun**//

gen vax2prepostest_third_period=postestdate_third_period2-covid_vax_2_date2
recode vax2prepostest_third_period min/-1=.  /*to exclude -ve numbers ie testesd before dose 2 ) */

recode vax2prepostest_third_period 0/max=1
recode vax2prepostest_third_period 1=. if covid_vax_3_date2<postestdate_third_period2

tab vax2prepostest_third_period tested_syx if timeperiod==3

recode vax2prepostest_third_period 1=. if pos_syx!=1

tab vax2prepostest_third_period

******************************************************************************8

/*Two different time periods for pos test after dose 2 - SECOND period*/

gen vax2_pos_0to13_third_period=vax2prepostest_third_period
recode vax2_pos_0to13_third_period 1=. if timepos_vax2==2
tab vax2_pos_0to13_third_period

gen vax2_pos_14plus_third_period=vax2prepostest_third_period
recode vax2_pos_14plus_third_period 1=. if timepos_vax2==1
tab vax2_pos_14plus_third_period

/*Negative test after dose 2 but before dose 3*/

gen vax2prenegtest_third_period=negtestdate_third_period2-covid_vax_2_date2
recode vax2prenegtest_third_period min/-1=.

recode vax2prenegtest_third_period 0/max=1
recode vax2prenegtest_third_period 1=. if covid_vax_3_date2<negtestdate_second_period2

tab vax2prenegtest_third_period tested_syx if timeperiod==3
recode vax2prenegtest_third_period 1=. if neg_syx!=1

tab vax2prenegtest_third_period

/*Two different time periods for neeg test after dose 1*/

gen vax2_neg_0to13_third_period=vax2prenegtest_third_period
recode vax2_neg_0to13_third_period 1=. if timeneg_vax2==2
tab vax2_pos_0to13_third_period

gen vax2_neg_14plus_third_period=vax2prenegtest_third_period
recode vax2_neg_14plus_third_period 1=. if timeneg_vax2==1
tab vax2_neg_14plus_third_period

/*Combine 0-20 day post any vaccine dose 1 pos and neg results for those vaccinated within 20 days of being tested*/

gen vax2t1_vax_thirdperiod=vax2_pos_0to13_third_period
recode vax2t1_vax_thirdperiod .=1 if vax2_neg_0to13_third_period==1

tab vax2t1_vax_thirdperiod

/*Combine 21+ days post dose 1 any vaccine pos and neg results for those vaccinated >21 but before d2*/

gen vax2t2_vax_thirdperiod=vax2_pos_14plus_third_period
recode vax2t2_vax_thirdperiod .=1 if vax2_neg_14plus_third_period==1
tab vax2t2_vax_thirdperiod
*********************************************************************************************8
///*** Combine variables for vaccinated pre tested with  unvaccinated pre tested to get VACCINATION STATUS (0==unvaccinated, 1==vaccinated) for each time period ***///

/*ANY covid vaccine*/

gen vax_status_any1_0to20_thirdperd=vax1t1_vax_thirdperiod
recode vax_status_any1_0to20_thirdperd .=0 if unvax_any_pretest==1
tab vax_status_any1_0to20_thirdperd

gen vax_status_any1_21plus_thirdperd=vax1t2_vax_thirdperiod
recode vax_status_any1_21plus_thirdperd .=0 if unvax_any_pretest==1


//***ADDITIONAL CODE SO PEOPLE WHO WERE VACCINATED AND HAD TEST RESULT IN TIME PERIOD 1 ARE NOT STILL COUNTED AS UNVACCINATED IN THE LATER TIME PERIOD ***///
recode vax_status_any1_21plus_thirdperd 0=. if vax_status_any1_0to20_thirdperd==1
recode vax_status_any1_21plus_thirdperd 1=. if vax_status_any1_0to20_thirdperd==1

tab vax_status_any1_21plus_thirdperd

gen vax_status_any2_0to13_thirdperd=vax2t1_vax_thirdperiod
recode vax_status_any2_0to13_thirdperd .=0 if unvax_any_pretest==1

recode vax_status_any2_0to13_thirdperd 0=. if vax_status_any1_0to20_thirdperd==1|vax_status_any1_21plus_thirdperd==1
recode vax_status_any2_0to13_thirdperd 1=. if vax_status_any1_0to20_thirdperd==1|vax_status_any1_21plus_thirdperd==1
tab vax_status_any2_0to13_thirdperd

gen vax_status_any2_14plus_thirdperd=vax2t2_vax_thirdperiod
recode vax_status_any2_14plus_thirdperd .=0 if unvax_any_pretest==1

recode vax_status_any2_14plus_thirdperd 0=. if vax_status_any1_0to20_thirdperd==1|vax_status_any1_21plus_thirdperd==1|vax_status_any2_0to13_thirdperd==1
recode vax_status_any2_14plus_thirdperd 1=. if vax_status_any1_0to20_thirdperd==1|vax_status_any1_21plus_thirdperd==1|vax_status_any2_0to13_thirdperd==1
tab vax_status_any2_14plus_thirdperd

//**THIRD DOSE ANY VACCINE**//

gen vax3prepostest_third_period=postestdate_third_period2-covid_vax_3_date2
recode vax3prepostest_third_period min/-1=.  /*to exclude -ve numbers ie testesd before dose 3 ) */

recode vax3prepostest_third_period 0/max=1
recode vax3prepostest_third_period 1=. if covid_vax_4_date2<postestdate_third_period2

tab vax3prepostest_third_period tested_syx if timeperiod==3

recode vax3prepostest_third_period 1=. if pos_syx!=1

tab vax3prepostest_third_period

******************************************************************************8

/*Two different time periods for pos test after dose 2 - THIRD period*/

gen vax3_pos_0to13_third_period=vax3prepostest_third_period
recode vax3_pos_0to13_third_period 1=. if timepos_vax3==2
tab vax3_pos_0to13_third_period

gen vax3_pos_14plus_third_period=vax3prepostest_third_period
recode vax3_pos_14plus_third_period 1=. if timepos_vax3==1
tab vax3_pos_14plus_third_period

/*Negative test after dose 3 but before dose 4*/

gen vax3prenegtest_third_period=negtestdate_third_period2-covid_vax_3_date2
recode vax3prenegtest_third_period min/-1=.

recode vax3prenegtest_third_period 0/max=1
recode vax3prenegtest_third_period 1=. if covid_vax_4_date2<negtestdate_third_period2

tab vax3prenegtest_third_period tested_syx if timeperiod==3

recode vax3prenegtest_third_period 1=. if neg_syx!=1

tab vax3prenegtest_third_period

/*Two different time periods for neg test after dose 3*/

gen vax3_neg_0to13_third_period=vax3prenegtest_third_period
recode vax3_neg_0to13_third_period 1=. if timeneg_vax3==2
tab vax3_pos_0to13_third_period

gen vax3_neg_14plus_third_period=vax3prenegtest_third_period
recode vax3_neg_14plus_third_period 1=. if timeneg_vax3==1
tab vax3_neg_14plus_third_period

/*Combine 0-13 day post any vaccine dose 3 pos and neg results for those vaccinated within 13 days of being tested*/

gen vax3t1_vax_thirdperiod=vax3_pos_0to13_third_period
recode vax3t1_vax_thirdperiod .=1 if vax3_neg_0to13_third_period==1

tab vax3t1_vax_thirdperiod

/*Combine 14+ days post dose 3 any vaccine pos and neg results for those vaccinated >14 but before dose 4*/

gen vax3t2_vax_thirdperiod=vax3_pos_14plus_third_period
recode vax3t2_vax_thirdperiod .=1 if vax3_neg_14plus_third_period==1
tab vax3t2_vax_thirdperiod
*********************************************************************************************8
///*** Combine variables for vaccinated pre tested with  unvaccinated pre tested to get VACCINATION STATUS (0==unvaccinated, 1==vaccinated) for each time period ***///

/*ANY covid vaccine*/
/*Dose 3 0-13 days (t1)*/

gen vax_status_any3_0to13_thirdperd=vax3t1_vax_thirdperiod

recode vax_status_any3_0to13_thirdperd .=0 if unvax_any_pretest==1
recode vax_status_any3_0to13_thirdperd 0=. if vax_status_any2_0to13_thirdperd==1|vax_status_any2_14plus_thirdperd==1|vax_status_any1_0to20_thirdperd==1|vax_status_any1_21plus_thirdperd==1
recode vax_status_any3_0to13_thirdperd 1=. if vax_status_any2_0to13_thirdperd==1|vax_status_any2_14plus_thirdperd==1|vax_status_any1_0to20_thirdperd==1|vax_status_any1_21plus_thirdperd==1
tab vax_status_any3_0to13_thirdperd

/*Dose 3, 14 days + (t2)*/

gen vax_status_any3_14plus_thirdperd=vax3t2_vax_thirdperiod
recode vax_status_any3_14plus_thirdperd .=0 if unvax_any_pretest==1

recode vax_status_any3_14plus_thirdperd 0=. if vax_status_any3_0to13_thirdperd==1|vax_status_any2_0to13_thirdperd==1|vax_status_any2_14plus_thirdperd==1|vax_status_any1_0to20_thirdperd==1|vax_status_any1_21plus_thirdperd==1
recode vax_status_any3_14plus_thirdperd 1=. if vax_status_any3_0to13_thirdperd==1|vax_status_any2_0to13_thirdperd==1|vax_status_any2_14plus_thirdperd==1|vax_status_any1_0to20_thirdperd==1|vax_status_any1_21plus_thirdperd==1

tab vax_status_any3_14plus_thirdperd


//**CROSS TABS AND OVERALL unadjusted and adjusted ORs, including separate model with adjustment for test week**//

/*ANY COVID VACCINE DOSE 3 FOR SECOND PERIOD NOV 2021 to MARCH 2022*/

tab tested_syx vax_status_any3_0to13_thirdperd
logistic  tested_syx vax_status_any3_0to13_thirdperd 
logistic  tested_syx vax_status_any3_0to13_thirdperd  i.ageg sex2 carehome bmi2 i.ethnicity i.region2 i.imd i.isoweek

tab tested_syx vax_status_any3_14plus_thirdperd
logistic  tested_syx vax_status_any3_14plus_thirdperd 
logistic  tested_syx vax_status_any3_14plus_thirdperd  i.ageg sex2 carehome bmi2 i.ethnicity i.region2 i.imd i.isoweek

/*Immunocompromised 3rd dose any vaccine*/
tab tested_syx vax_status_any3_0to13_thirdperd if immcomp==1
logistic  tested_syx vax_status_any3_0to13_thirdperd if immcomp==1
logistic  tested_syx vax_status_any3_0to13_thirdperd  i.ageg carehome sex2 i.isoweek if immcomp==1 

tab tested_syx vax_status_any3_14plus_thirdperd if immcomp==1
logistic  tested_syx vax_status_any3_14plus_thirdperd if immcomp==1
logistic  tested_syx vax_status_any3_14plus_thirdperd  i.ageg carehome sex2 i.isoweek if immcomp==1

log close
