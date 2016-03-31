capt copy http://www.cmaxxsports.com/downloads/gamestate3.zip . , replace
unzipfile gamestate3.zip, replace
use gamestate3, clear

set more off 

*a representation of current num. of outs and which bases are populated 
gen state = 1000*outs + 100*on1 + 10*on2 + on3

*gen run increment variable: runs at time of ab - runs at end of inning 
gen rinc = 0
replace rinc = hinnendruns - hruns if atbat == "H"
replace rinc = vinnendruns - vruns if atbat == "V"

sort state 
tabstat rinc if inn<9, by(state) stat(n mean)

reg rinc i.state

predict rhat
sort state
by state: gen id=_n
list state rhat if id == 1

