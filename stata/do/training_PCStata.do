
/*
        training.do
        Jamie Fogel
        July 31, 2013

        This code is derived from Zack Kimball's 2011 Stata training
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
cd S:\trainings\stata\
local directory "S:\trainings\stata\"
pwd

/* The below code opens a log file called training_`suffix', where `suffix' is the date and time. This is useful
because if you put this code at the top of your do file it will create a new log for each run of your program and
if you need to look at old versions of your code you a have a record */
local filename "training"
capture log close `filename'
local d = td(`c(current_date)')
local start_time = tc(`c(current_time)')
local tstamp =  string(year(`d')) + string(month(`d'),"%02.0f") + string(day(`d'),"%02.0f") + string(hh(`start_time'),"%02.0f") + string(mm(`start_time'),"%02.0f") + string(ss(`start_time'),"%02.0f")
log using "`directory'logs\`filename'_`tstamp'.log", replace name(`filename')


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
save data\auto.dta, replace


/* Some practice loading and saving data */
	/* Load a data set*/
	use data\auto.dta, clear

	/* Load a subset of variables from the same data set */
	use make price mpg rep78 headroom foreign using data\auto.dta, clear
	
	/* Load only observations for foreign cars from the same data set */
	use if foreign==1 using data\auto.dta, clear
	
	/* Load only a subset of variables and obsrvations for foreign cars from the same data set */
	use make price mpg rep78 headroom foreign if foreign==1 using data\auto.dta, clear

        /* Save the data set we just loaded */
        save data\auto_subset.dta, replace


	/* Output the data set in memory as a .csv file */
	outsheet using data\auto.csv, comma replace
	/* Output the data set in memory as an Excel .xlsx file */
	export excel using "data\auto.xlsx", firstrow(variables) replace

	/* Input data from a .csv file */
	insheet using  `directory'data\auto.csv, comma clear
	/* Input data from a .xlsx file */
	import excel "data\auto.xlsx", sheet("Sheet1") firstrow clear


/* Appending and merging data sets */

        /* Suppose we have data on labor market status split into two data sets --- Pre-1994 and Post-1994. We
                can combine the two by first loading one, and then appending the other */

        use data\basic_labor_force_pre1994.dta, clear
        gen year = year(dofm(date))
        tab year
        append using data\basic_labor_force_post1994.dta
        replace year = year(dofm(date))
        tab year

        save data\basic_labor_force.dta, replace

        /* Now, let's add a measure of inflation to our data set. Since this means adding variables to our existing
                observations, rather than adding observations to our existing variables, we need to merge the data
                sets. Since both inflation and labor force status are both measured at monthly intervals, we can
                perform a simple 1:1 merge. This means that the same variable, in this case date, uniquely identifies
                observations in both data sets. */

        /* We can quickly check to be sure that date uniquely identifies the data set in memory, although this isn't
                actually necessary because the merge command will check and issue an error if date does not uniquely
                identify both data sets */
        isid date

        /* Now the actual merge command */
        merge 1:1 date using data\cpi.dta

        /* Let's look at how many of the observations were successfully merged. We do this by tabulating _merge,
                a variable created by the merge command. */
        tab _merge

        /* Now suppose we want to add GDP data to our data set. GDP, however, is measured at quarterly
                frequencies. If we tried to merge 1:1 we would get an error. There are two possible solutions
                to this issue. First, we could simply merge each quarter's GDP to all three months within that
                quarter. We do this with a many-to-on merge. Alternatively, we might transform our labor force
                and inflation data set to quarterly frequencies. We would accomplish this using collapse*/

        preserve

        /* Below I perform a many-to-one merge. This means that the merge variable does not uniquely identify
                observations in the master data set (data set in memory) but does uniquely identify observations
                in the using dataset. First we must create the merge variable, quarter, since we are merging at
                quarterly frequency but our existing date variable is measured at monthly frequency. (quarter
                already exists in the GDP data set we are merging with) We also must drop the _merge variable
                created by the previous merge or else we will get an error when this merge tries to create it */
        drop _merge
        gen quarter = qofd(dofm(date))
        merge m:1 quarter using data\gdp.dta
        tab _merge
        drop _merge

        /* Note:
                --- one-to-many (1:m) merges are analagous to many-to-one, however the merge variable uniquely
                identifies observations in the master rather than using data set.
                --- The merge variable could actually be a set of variables which together uniquely identify
                observations. For eaxample, instead of a single date variable we might have had year and month.
        */

        restore

        /* Now, instead of adding GDP to each month, we will calculate quarterly averages of the unemployment
                rate and inflation rate and merge this 1:1 with GDP. */
        gen quarter = qofd(dofm(date))
        collapse (mean) u cpi, by(quarter)
        merge 1:1 quarter using data\gdp.dta
        tab _merge
        drop _merge

        /*
        M:M merges also exist in Stata but you should never use them. For details (and proof that Stata Corp
               has a sense of humor, see the documentation by typing ``help merge''.  If you think you want to
                perform a M:M merge, you may actually want a ``joinby''.
        */

/* Generating and manipulating variables */
        /* Stata's GENERATE command creates a new variable and defines it as you specify and REPLACE replaces
                some or all observations of an existing variable. Below we use both GENERATE and REPLACE to
                create a recession indicator (to add recession bars to a figure you can use the user-written
		command NBERCYCLES but you will have to look it up yourself) as well as a dummy for whether or not
                unemployment exceeds 6.5%. */
        use data\basic_labor_force.dta, clear

	/* Let's start by creating a month variable using some of Stata's date/time functions (for more on this topic
		type "help datetime" or Google "Stata dates" and check out some of the search results). */
	gen month = month(dofm(date))

	gen 	recession = 1 if (year == 1948 & month >= 11) | (year == 1949 & month <= 10)
	replace recession = 1 if (year == 1953 & month >= 7) | (year == 1954 & month <= 5)
	replace recession = 1 if (year == 1957 & month >= 8) | (year == 1958 & month <= 4)
	replace recession = 1 if (year == 1960 & month >= 4) | (year == 1961 & month <= 2)
	replace recession = 1 if (year == 1969 & month >= 12) | (year == 1970 & month <= 11)
	replace recession = 1 if (year == 1973 & month >= 11) | (year==1974) | (year == 1975 & month <= 3)
	replace recession = 1 if (year == 1980 & (month >= 1 & month <= 7))
	replace recession = 1 if (year == 1981 & month >= 7) | (year == 1982 & month <= 11)
	replace recession = 1 if (year == 1990 & month >= 8) | (year == 1991 & month <= 3)
	replace recession = 1 if year == 2001 & (month >= 4 & month <= 11)
	replace recession = 1 if year >= 2008 & (year < 2009 | (year == 2009 & month <= 6))
	replace recession = 0 if missing(recession)

	/* An alternative to the above, which does the exact same thing, is below. It might be a good idea to think
		about why they are identical on your own but I am happy to answer any questions.

	gen 	recession = ( ((year == 1948 & month >= 11) | (year == 1949 & month <= 10))                 ///
	replace recession =  | ((year == 1953 & month >= 7) | (year == 1954 & month <= 5))                  ///
	replace recession =  | ((year == 1957 & month >= 8) | (year == 1958 & month <= 4))                  ///
	replace recession =  | ((year == 1960 & month >= 4) | (year == 1961 & month <= 2))                  ///
	replace recession =  | ((year == 1969 & month >= 12) | (year == 1970 & month <= 11))                ///
	replace recession =  | ((year == 1973 & month >= 11) | (year==1974) | (year == 1975 & month <= 3))  ///
	replace recession =  | ((year == 1980 & (month >= 1 & month <= 7)))                                 ///
	replace recession =  | ((year == 1981 & month >= 7) | (year == 1982 & month <= 11))                 ///
	replace recession =  | ((year == 1990 & month >= 8) | (year == 1991 & month <= 3))                  ///
	replace recession =  | ( year == 2001 & (month >= 4 & month <= 11))                                 ///
	replace recession =  | ( year >= 2008 & (year < 2009 | (year == 2009 & month <= 6))) )
        */

        /*

        Stata's EGEN command, for +e+xtensions to +gen+erate, is a powerful tool that
                can handle a number of additional functions. For much more detail type "help egen"
        In particular, it operates well on subgroups of data using the _by_ option */

        /* We can use EGEN's TOTAL function to count the number of months in which the economy was in a recession*/
        egen tot_months_recession = total(recession)

        /* We can also calculate the mean unemployment rate */
        egen mean_u = mean(u)

        /* Now let's get really fancy and calculate the mean unemployment rate for each year. This requires us
                to use the BY prefix */
        bysort year: egen annual_mean_u = mean(u)
        

/* Labeling variables, values, and the data set */

        /* Stata allows us to label variables, values, and add notes to either variables or the entire data set */
        label variable recession "NBER Recession Indicator" 

        /* Value labels are useful for dummy or categorical variables */
        label define recession 0 "Not in Recession" 1 "Recession"
        label values recession recession

        /* Attach a note to the data set */
        note: This data set was created for the summer 2013 RA training 
  
/* A brief introduction to macros */

	/* A Stata macro is what most programming languages call a variable; they can be
		used to store content, numeric or string, which can then be inserted elsewhere in
		the code by invoking the macro. Macros can be local or global in scope, with the
		former existing solely within the program or do-file in which they are defined and
		the latter remaining available until they are dropped (macro drop macroname) or Stata
		is closed. */
	
	* Local macros
	local l1 "p"
	local l2 "i"
	gen `l1'`l2' = c(pi)
	
	* Global macros
	global myglobal "My Global Macro"
	di "$myglobal"
	di "${myglobal}"

	/* Macros can be very useful for storing filepaths. */
	local directory "S:\trainings\stata\"
	ls "`directory'"

/*******************************************************************************************************************
********************************************************************************************************************
 Discuss scope
********************************************************************************************************************
*******************************************************************************************************************/ 



log close `filename'
