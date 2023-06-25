

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
