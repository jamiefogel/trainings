
clear
set more off

sysuse auto, clear

local filepath "/home/UserID/trainings/exporting_stata_tables_figures/results/"

/* Let's look at what percentage of the vehicles in our sample are foreign */
tabout foreign using `filepath'tabout_foreign.tex, replace style(tex)

/* Now let's add a column for the percentage */
tabout foreign using `filepath'tabout_foreign2.tex, replace style(tex) cells(freq col) bt

/* A twoway tabulation */
gen over40mpg = mpg > 40
tabout foreign over40mpg using `filepath'tabout_foreign_over40mpg.tex, replace style(tex) cells(freq col)

/* A table with summary statistics for MPG by foreign */
tabout foreign using `filepath'tabout_sumstats.tex, replace sum cells(mean mpg  median mpg mean weight median weight) style(tex)

/* Store regression results from three different specifications */
sysuse auto, clear
eststo clear
eststo: reg price mpg weight
eststo: reg price mpg foreign
eststo: reg price mpg weight foreign


/* Basic Table */
esttab using `filepath'table1.tex,  ///
	replace booktabs 		     ///
	addnote("You can add a footnote here")


/* Alternatively, we could specify names for our regression output */
eststo clear
eststo model1: reg price mpg weight
eststo model2: reg price mpg foreign
eststo model3: reg price mpg weight foreign
