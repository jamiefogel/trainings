
local filepath "/home/UserID/trainings/stata/tex/"

sysuse auto
twoway (scatter price mpg) (lfit price mpg), title(s1color_alt) ///
	caption(Source: Stata auto data set) scheme(s1color_alt)
graph export `filepath'price_mpg_figure_s1color_alt.eps, replace as(eps) 


twoway (scatter price mpg) (lfit price mpg), title(s1color) ///
	caption(Source: Stata auto data set) scheme(s1color)
graph export `filepath'price_mpg_figure_s1color.eps, replace as(eps)


twoway (scatter price mpg) (lfit price mpg), title(economist) ///
	caption(Source: Stata auto data set) scheme(economist)
graph export `filepath'price_mpg_figure_economist.eps, replace as(eps)


/****************************************************************************************************
haver use example
****************************************************************************************************/

/* This code will work in PC Stata only 
haver use LR RECESSM2 using "G:\Deptdata\Research\Haver\USECON.DAT", clear

// Formatting date variable
rename time date
format date %tmMon_YY //Format the variable so that it will be labeled as a date
tsset date

//Only use 1960-present
keep if date >= ym(1960,1)

// Adjust recession indicator series for consistency with unemployment rate
sum LR
gen Recession = (r(max)+1)*RECESSM2

// Plot and export the series
#delimit ;
twoway 
	(bar Recession date, fintensity(100) lcolor(gs13) fcolor(gs13))
	(tsline LR)
	, ylabel(0(4)12);
graph export "S:\trainings\stata\tex\haver-example.eps", replace as(eps); 
  
*/
#delimit cr  
  

/****************************************************************************************************
File read/write example
****************************************************************************************************/
set more off

sysuse colorschemes, clear
levelsof scheme, local(list) //Stores all possible values of the variable in the specified macro
 
// Open the file to be written to and referencing it with the handle "writefile"
capture file close writefile
file open writefile using /home/UserID/trainings/stata/do/schemne_list.txt, write replace

foreach m of local list{
	// Write each element of the macro "list", followed by the endline character 
	file write writefile `"`m'"' _n
}

file close writefile

// Open the file to be read from and referencing it with the handle "readfile"
capture file close readfile
file open readfile using /home/UserID/trainings/stata/do/schemne_list.txt, read

// Read a line and save it in the macro "line"
file read readfile line
while r(eof)==0{ // Read until reaching the end of the file ( r(eof)==1 )
	di `"`line'"'
	file read readfile line
}

file close readfile



/****************************************************************************************************
encode/decode example
****************************************************************************************************/

//Returning to our favorite auto data set, let's encode the variable "make"
sysuse auto, clear
encode make, generate(make_numeric)

sysuse auto, clear
decode foreign, gen(foreign_string)





/****************************************************************************************************
Matching and replacing text
****************************************************************************************************/

local bestpackage "Stata"
di strmatch("`bestpackage'","Excel")
di strmatch("`bestpackage'","Stata")

local dumb "Excel is great for statistics. I love Excel!"
local smart = subinstr("`dumb'", "Excel", "Stata", .)
di "`smart'"



/****************************************************************************************************
Macro extended functions
****************************************************************************************************/

// Assigning to `months' a list of the 12 months
local months `c(Months)'
local summer "June July August"

// Remove the summer months
local not_too_hot : list months - summer

// Replace all instances of "January" with "Jan"
local not_too_hot : subinstr local not_too_hot "January" "Jan", all

// Putting list into alphabetical order
local not_too_hot : list sort not_too_hot

// Accessing the length of the macro
local len : length local not_too_hot
display "`len'"

display "`not_too_hot'"
