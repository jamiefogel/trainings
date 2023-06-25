
/*
        training.do
        Jamie Fogel
        July 19, 2022

*/

* This is a one-line comment
// This is also a one-line comment

/*
This is a block comment.
Block comments are useful for longer notes or for "commenting out" sections of your code
*/



// Clear existing data set from memory
clear
// Turn off page-by-page output so that the do-file can run without user interaction
set more off

pwd
*cd /home/UserID/trainings/stata/
*local directory "/home/UserID/trainings/stata/"
*pwd

/* The below code opens a log file called training_`suffix', where `suffix' is the date and time. This is useful
because if you put this code at the top of your do file it will create a new log for each run of your program and
if you need to look at old versions of your code you a have a record */
local filename "training"
capture log close `filename'
local d = td(`c(current_date)')
local start_time = tc(`c(current_time)')
local tstamp =  string(year(`d')) + string(month(`d'),"%02.0f") + string(day(`d'),"%02.0f") + string(hh(`start_time'),"%02.0f") + string(mm(`start_time'),"%02.0f") + string(ss(`start_time'),"%02.0f")
log using "`directory'logs/`filename'_`tstamp'.log", replace name(`filename')


set more off

/*******************************************************************************************************************
********************************************************************************************************************
 Discuss filepaths --- make everyone download the data sets and set up the required file structure
********************************************************************************************************************
*******************************************************************************************************************/ 


/*
Change the working directory to `directory'. If you want to run this code on your own computer you will
        need to create the following subdirectories within the directory you have designated as your working
        directory:
        - data
        - do
        - tex
        - logs
You can do this with the mkdir command:
        mkdir /home/UserID/trainings/stata/do
        mkdir /home/UserID/trainings/stata/data
        mkdir /home/UserID/trainings/stata/tex
        mkdir /home/UserID/trainings/stata/logs
*/



/* Open the pre-loaded Stata auto data set and save it in a local directory for future use */
sysuse auto, clear
save data/auto.dta, replace


* Describe and summarize the data
describe
summarize  
// Notice that we don't get any summary stats for the variable make. If we look back at output of the describe command we will notice that this is because make is a string variable, not numeric. We can also see this by "browsing" the data/auto
browse

// Also notice that there are only 69 observations of the variable rep78. This is because 5 observations are missing, which we can confirm below. This is the sort of check that can prevent lots of errors later. If a variable has missing values you want to know exactly why, confirm that missing values don't reflect some sort of problem, and ensure that you are handling missing values appropriately (what is appropriate will depend on the context).
count if missing(rep78)
count if missing(price)


/* Some practice loading and saving data */
	/* Load a data set*/
	use data/auto.dta, clear

	/* Load a subset of variables from the same data set */
	use make price mpg rep78 headroom foreign using data/auto.dta, clear
	
	/* Load only observations for foreign cars from the same data set */
	use if foreign==1 using data/auto.dta, clear
	
	/* Load only a subset of variables and obsrvations for foreign cars from the same data set */
	use make price mpg rep78 headroom foreign if foreign==1 using data/auto.dta, clear

    /* Save the data set we just loaded */
    save data/auto_subset.dta, replace


	/* Export the data set in memory as a .csv file */
	export delimited using data/auto.csv,  replace
	/* Export the data set in memory as an Excel .xlsx file */
	export excel using "data/auto.xlsx", firstrow(variables) replace

	/* Import data from a .csv file */
	import delimited using  `directory'data/auto.csv, clear
	/* Import data from a .xlsx file */
	import excel "data/auto.xlsx", sheet("Sheet1") firstrow clear


/* Appending and merging data sets */

    /* Let's start by splitting the auto data into different pieces and then learn how to put them back together */
	* Keep only foreign cars and save the in a separate data set
	use data/auto.dta, clear
	keep if foreign==1
	br    // abbreviation for browse
	save data/auto_foreign.dta, replace
		
	* Keep only domestic cars and save the in a separate data set
	use data/auto.dta, clear	
	drop if foreign==1
	save data/auto_domestic.dta, replace
	
	* Now let's put them back together using append
	use data/auto_foreign.dta, clear
	append using data/auto_domestic.dta
		

	/* Now let's split the auto data based on variables, not observations	*/
	use data/auto.dta, clear
	keep make price mpg rep78
	isid make  // Confirm that make uniquely identifies the observations
	* isid foreign // An example of what happens when the variable does not uniquely identify the data
	save data/auto_vars1, replace

	use data/auto.dta, clear
	drop price mpg rep78
	isid make  // Confirm that make uniquely identifies the observations
	save data/auto_vars2, replace
	
	use data/auto_vars1, clear
	merge 1:1 make using data/auto_vars2	
		
		
	* _merge is a variable created by the merge command that tells you whether or not each observations was successfully merged. It's always a good idea to look at this variable and if there are any unmerged observations, you should understand exactly why they are unmerged and confirm that this is not a problem. 
	tab _merge
	
	
	/* I have only shown a 1:1 merge in which the same set of variables uniquely identifies observations in both data sets. 1:many and many:1 merges are also possible. For example, suppose in one data set you have a panel of earnings for different workers with multiple observations per worker and in another you have time-invariant worker characteristics. In this case you could merge the time-invariant worker characteristics on to the earnings panel using a many:1 merge. In this case the worker ID would uniquely identify observations in the worker characteristics data but not the earnings panel; each observation in the worker characteristics data would be matched to many observations in the earnings panel. */
		
		
		
/* Let's reshape some data */
	sysuse bplong.dta, clear // Built-in data set with 2 blood pressure readings for each patient
	browse // The data is in "long form" meaning that each reading is a separate observation. Alternatively, we could organize the data in "wide form" in which each reading is a different row and there is only one observation per patient. 
	
	* Let's reshape the data from long to wide
	reshape wide bp, i(patient) j(when)
	/* 
	- i() are variables that uniquely identify the data in wide form
	- j() is the variable on which we are reshaping
	- Notice that instead of the variable bp, we now have 2 variables: bp1 and bp2
	- Also notice that the variable when has disappeared
	*/
	
	* Now let's go back to long form
	reshape long bp, i(patient) j(when)	
	
	
/* Let's collapse the blood pressure data */
	sysuse bplong.dta, clear
	
	* Instead of 2 blood pressure readings for each patient, let's just look at the average 
	collapse (mean) bp (firstnm) sex agegrp , by(patient)
	
	* We could also have collapsed using other statistics, e.g. take the first observation for each patient
	sysuse bplong.dta, clear
	collapse (firstnm) bp (firstnm) sex agegrp , by(patient)

	* Collapse by sex and agegrp
	sysuse bplong.dta, clear	
	collapse (mean) bp, by(sex agegrp)
		
		
		
		
		
/* Generating variables */
	sysuse sp500, clear // Sample data set of SP500 prices
	
	describe date // The date variable is formatted as a Stata date variable. This allows us to do things like extract the month, year, or day. Stata (like other programming languages) has specific ways of handling date and time variables. To learn more type "help datetime". 
	
	// Generate a dummy variable for the month being January
	gen year = year(date)
	gen month = month(date)
	gen Jan = month==1
	tabulate month Jan // Check that this worked correctly. Always useful to perform little checks like this. 
		
	// Now let's create a recession indicator variable	
	gen 	recession = 1 if year == 2001 & (month >= 4 & month <= 11)
	replace recession = 0 if missing(recession)

	/*
	Stata's EGEN command, for +e+xtensions to +gen+erate, is a powerful tool that
			can handle a number of additional functions. For much more detail type "help egen"
	In particular, it operates well on subgroups of data using the _by_ option */

	/* We can use EGEN's TOTAL function to count the number of months in which the economy was in a recession*/
	egen tot_days_recession = total(recession)

	/* We can also calculate the mean closing value by month */
	bysort month: egen mean_close = mean(close)

	
	
	
/* Labeling variables, values, and the data set */

	/* Stata allows us to label variables, values, and add notes to either variables or the entire data set */
	label variable recession "NBER Recession Indicator" 

	/* Value labels are useful for dummy or categorical variables */
	label define recession 0 "Not in Recession" 1 "Recession"
	label values recession recession

	/* Attach a note to the data set */
	note: This data set was created for the 2022 pre-doc training 

/* A brief introduction to macros */

	/* A Stata macro is what most programming languages call a variable; they can be
		used to store content, numeric or string, which can then be inserted elsewhere in
		the code by invoking the macro. Macros can be local or global in scope, with the
		former existing solely within the program or do-file in which they are defined and
		the latter remaining available until they are dropped (macro drop macroname) or Stata
		is closed. */
	
	* Local macros
	local l1 "x"
	local l2 "i"
	*gen `l1'`l2' = c(pi)
	di "`l1' `l2'"
	
	* Global macros
	global myglobal "My Global Macro"
	di "$myglobal"
	di "${myglobal}"

	/* Macros can be very useful for storing filepaths. */
	local directory "/home/UserID/trainings/stata/"
	ls "`directory'"




help browse // Show how the help file shows allowable abbreviations

log close `filename'
