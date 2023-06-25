
sysuse auto, clear
save /home/UserID/trainings/stata/data/auto.dta, replace

clear

/* Load a data set*/
use /home/UserID/trainings/stata/data/auto.dta, clear

/* Load a subset of variables from the same data set */
use make price mpg rep78 headroom foreign using /home/UserID/trainings/stata/data/auto.dta, clear
/* Load only observations for foreign cars from the same data set */
use if foreign==1 using /home/UserID/trainings/stata/data/auto.dta, clear
/* Load only a subset of variables and obsrvations for foreign cars from the same data set */
use make price mpg rep78 headroom foreign if foreign==1 using /home/UserID/trainings/stata/data/auto.dta, clear

/* Output the data set in memory as a .csv file */
outsheet using  /home/UserID/trainings/stata/data/auto.csv, comma replace
/* Output the data set in memory as an Excel .xlsx file */
export excel using "/home/UserID/trainings/stata/data/auto.xlsx", firstrow(variables)

/* Input data from a .csv file */
insheet using  /home/UserID/trainings/stata/data/auto.csv, comma clear
/* Input data from a .xlsx file */
import excel "/home04/UserID/trainings/stata/data/auto.xlsx", sheet("Sheet1") firstrow clear


/* Merge national level monthly data with national quarterly and state monthly data */
