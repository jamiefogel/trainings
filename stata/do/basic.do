// This is a one-line comment
* This is also a one-line comment

/*
   This is a block comment, which needs to be closed
   Block comments are convenient for longer notes
   The next line closes the block comment
*/

/*
   Filename: basic.do
   Author: Zachary Kimball
   Date: August 8, 2011
   Purpose: Illustrate basic Stata concepts
*/

/*
   This code initiates a log file
   The basic syntax is 'log using <filename>'
   Always keep logs of your do-files so you can check on exactly what happened -- and
     so you can replicate and old version, if necessary

   This particular block of code is more complicated than 'basic' -- it will be explained
     further in the advanced section
*/
local filename "basic"
capture log close `filename'
local d = td(`c(current_date)')
local start_time = tc(`c(current_time)')
local tstamp =  string(year(`d')) + string(month(`d'),"%02.0f") + string(day(`d'),"%02.0f") + string(hh(`start_time'),"%02.0f") + string(mm(`start_time'),"%02.0f") + string(ss(`start_time'),"%02.0f")
// Open log with overwriting
log using "logs/`filename'_`tstamp'.log", replace name(`filename')

// Display current working directory (for logging purposes)
pwd

// Clear almost everything from memory (but not macros)
clear all
// Turn off page-by-page output so that the do-file can run without user interaction
set more off
// Set memory to a sufficient size for the data we're using
set mem 1g

/*
   We import CSV data on house prices from the Case-Shiller price indices
   (This data was prepped from Haver in advance)

   Data for Boston is in two pieces, before/after January 2000, so it has to be combined
*/
/*
   Parse CSV data for Case-Shiller Boston house-price indices pre-2000
   (The _comma_ option tells the *insheet* command that the file is comma-delimited -- *insheet*
     can normally determine this for itself, but it never hurts to clarify your intentions)
*/
insheet using data/bos_pre00.csv, comma

// List the data so we see what things look like
// (normally this wouldn't be necessary or would be done outside of a do-file using the data browser -- the *browse* command)
list

// Save data as a Stata data file
// (the _replace_ option tell the save command that it is allowed to overwrite a previous file)
save data/boston, replace

// Parse CSV data for Case-Shiller Boston house-price indices post-1999
// (the _clear_ option tells the insheet command that it is okay to replace the current dataset in memory)
insheet using data/bos_post99.csv, comma clear

// Add the pre-2000 data to the end of the dataset in order to get coverage for all the months
// (only Stata-format data can be appended, hence why the CSV had to be imported and saved first)
append using data/boston

// Save the combined dataset, overwriting the first
save data/boston, replace


/*
   Data from New York covers the time period from 1987 to the present in one file
*/
// Parse CSV data for Case-Shiller New York house-price indices
insheet using data/new_york.csv, comma clear

// Save data as a Stata data file
save data/new_york, replace


/*
   Case-Shiller has a "Composite 20" metric that takes data from 20 metro areas
   These data begin in January 2000
*/
// Parse CSV data for Case-Shiller Composite 20 house-price indices
insheet using data/comp20.csv, comma clear


/*
   We now have several files covering similar time periods at the same frequency (monthly),
     each for a different region
   
   In order to combine these files together, we want to match up the dates and record a house-price index
     value for each region, for example:
     year	month	comp20	new_york	boston
     2000	1	100	100		100.92

   In Stata, this happens with a *merge*, in this case merging on the year and month
   Since there is only one year-month pair in each dataset, this is a "one-to-one merge"
*/
// Merge New York numbers in with Composite 20 numbers
merge 1:1 year month using data/new_york

/*
   Note the output from the *merge* command:
	Result                           # of obs.
	-----------------------------------------
	not matched                           156
	from master                             0	(_merge==1)
	from using                            156	(_merge==2)
	
	matched                               137	(_merge==3)
	-----------------------------------------

   The "master" data is the data in memory and the "using" data is the data from the file

   Since the New York data begin before the Composite 20 data, some of the using data is not matched
*/

/*
   The merge leaves us with a variable called "_merge" that indicates the source of the data point
   If we want to see the results of the merge again, we can write *tabulate _merge* (or just *tab* for short)
*/
// Revisit the status of the merge
// (*tab* is short for *tabulate* -- many Stata commands permit such shortcuts)
tab _merge

// Remove the _merge variable in order to prepare for the next merge
drop _merge


// Merge Boston numbers in with New York and Composite 20 numbers
merge 1:1 year month using data/boston

/*
   Note the output from the *merge* command:
	Result                           # of obs.
	-----------------------------------------
	not matched                            24
	from master                             0	(_merge==1)
	from using                             24	(_merge==2)
	
	matched                               293	(_merge==3)
	-----------------------------------------

   Since the Boston data begins in 1985, two years before the New York data, there are 24 unmatched months
*/

// Now we take a look at the data again to see how things went
// (again, we normally wouldn't do this in a real do-file)
list

// Let's remove the Boston data before 1987 so that the two time series are of equal length
// (In this case, we could also have written, for example, *drop if year < 1987* --
//   there's usually more than one way to effect the same result)
drop if _merge == 2

// Remove the resulting _merge variable
drop _merge


/*
   Notice that the Composite 20 has periods (".") for the months that are missing data
   This is Stata's default notation for missing numeric values
   A missing (that is, a ".") essentially takes on the value of infinity, so
     the test *n < .* is true for all real n.

   Other missing values are available, indexed alphabetically, such that
       *n < . < .a < .b < ... < .y < .z*
     but these are rarely used
*/

/*
   Notice also that the *merge* command sorted all of the matched observations by the values of the merge criteria
   This is part of the default behavior of *merge* -- we can do it ourselves for the whole dataset with *sort year month*
   The *sort* command, however, can only sort in ascending order
   Use the *gsort* command instead to sort in ascending/descending order
*/
// Make sure the data is sorted by year and month
sort year month

/*
   In order to keep things neat for other users (including future you),
     it is always a good idea to label your variables

   We do so with the *label* command, which also implements many other helpful labeling options
*/
// Label the variables (using Haver names)
label variable comp20 "S&P/Case-Shiller Home Price Index: Composite 20 (NSA, Jan-00=100)"
label variable new_york "S&P/Case-Shiller Home Price Index: New York (NSA, Jan-00=100)"
label variable boston "S&P/Case-Shiller Home Price Index: Boston (NSA, Jan-00=100)"

// Take a look at one of the uses of labels by "decribing" the data
describe

/*
   Numeric variables are often coded to signify different things
   Stata can assign labels to those values in order to make them more accessible
   The numeric codes are retained for data purposes but the labels are displayed when browsing the data

   Labels such as these should usually only be used when codes are otherwise confusing or difficult to remember
*/
// Example: labeling months of the year
label define month_labels 1 "January" 2 "February" 3 "March" 4 "April" 5 "May" 6 "June"
label define month_labels 7 "July" 8 "August" 9 "September" 10 "October" 11 "November" 12 "December", add
label values month month_labels

// Try browsing the data (the *browse* command) to see the effect of these labels

// Now we remove these particular labels (months of the year are quite clear on their own, so this is probably overkill)
label drop month_labels

// We can also attach notes to the variables or to the dataset itself for later reference, if desired
// Here we define a dataset note
note : "Data source: S&P, Fiserv, and MacroMarkets LLC"


/*
   We create a variable that will allow us to do useful things in our advanced section
   Normally, data like this should be merged in from an authoritative source in order to prevent errors
   However, here we want to demonstrate the creation and manipulation of variables
*/
// Create (*generate*) indicator for NBER recessions
// August 1990 - March 1991
gen recession = 1 if (year == 1990 & month >= 8) & (year == 1991 & month <= 3)
// April 2001 - November 2001
replace recession = 1 if year == 2001 & (month >= 4 & month <= 11)
// January 2008 - June 2009
replace recession = 1 if year >= 2008 & (year < 2009 | (year == 2009 & month <= 6))
// Now all other values for the recession flag (currently missing) should be zero
replace recession = 0 if recession >= .

// Generate a table of the recession indicators with Stata's *tabulate* command
tab recession

/*
   Stata's *egen* command, for +e+xtensions to +gen+erate, is a powerful tool that
     can handle a number of additional functions
   In particular, it operates well on subgroups of data using the _by_ option
   Here, we use the _sd()_ function to get the standard deviation
*/
// Get Boston stdev by year
egen bos_sd = sd(boston), by(year)

// Check on the basic stats of all variables (mean, stdev, min/max, etc)
summarize

// Check detailed stats for Boston's standard deviation with the _detail_ option
sum bos_sd, detail

// Create a variable in Stata date format to accomodate both year and month
gen s_date = ym(year, month)

// Try browsing the data (the *browse* command) to see the effect of this command
// The Stata dates are just numbers, we can get them to display in a more useful way by formatting them

// Format date variables to monthly
format s_date %tm

// Browse the data again to see the effect of formatting

// Save a Stata file with the combined data
save data/combined, replace

// Additional topics: preserve/restore, collapse, joinby

// Report on the time it took to run the do-file (more on this in the advanced session)
local end_time = tc(`c(current_time)')
disp "Time elapsed running do-file: " trunc(hours(`end_time' - `start_time')) " hrs, " trunc(mod(minutes(`end_time' - `start_time'),60)) " mins, " trunc(mod(seconds(`end_time' - `start_time'),60)) " secs"

// Close log file of given filename
log close `filename'
