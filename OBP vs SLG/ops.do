*James LeDoux
*obp vs slg vs ops

//data setup

//load batting_for first -- now saved as a .dta
set more off
//gen singles
gen h1 = h - (h2 + h3 + hr) 

//league started tracking sacrifice flies
drop if yr < 1954
drop if tm == "LgAvg"


save "L:\Sports\batting_for.dta", replace
//bring in w, l

merge 1:1 tm yr lg using "standings.dta"
drop if tm == ""
// 1528 matched, 122 not . . see what didn't match 
// I believe these non-matches are league averages (1 per league per season)
gen winpct = (w/(w+l))  // this is already in the standings data. . almost identical but let's go with this one 
gen rg1 = r/g  // same deal here. slightly more precise so let's use this version 

gen obp1 = ((h + bb + hbp)/(ab + bb + hbp + sf))
gen slg1 = ((h1 + 2*h2 + 3*h3 + 4*hr)/ab)
gen ops1 = slg1 + obp1
save "L:\Sports\batting_for.dta", replace


use "L:\Sports\gamelogs 9114 v.2.dta", clear
//gen home team singles and visiting team singles 
gen hh1 = hh -(h2b + h3b + hhr)
gen vh1 = vh -(v2b + v3b + vhr)

//drop incomplete games
drop if vputouts < 24
drop if hputouts < 27

gen hrg = (hruns * 27)/vputouts
gen hwins = 1 if hruns > vruns
replace hwins = 0 if vruns > hruns
gen vwins = 1 if vruns > hruns
replace vwins = 0 if hruns > vruns

//save game log data before moving on to next part


clear all
use batting_for.dta

//obp and slg  
graph box obp slg
sum obp slg

corr rg obp slg ops

// regressing rg on each measure individually + one mlr model
reg rg obp
eststo
reg rg slg
eststo
reg rg ops
eststo
reg rg obp slg 
eststo

esttab, r2 ar2
// slg & obp separately > ops > slg > obp  (ranked by rsquared)

//obp elasticity > slg elasticity 
//rg more sensitive to obp despite beta-obp being < beta-slg  (2.49 > 1.42)
reg rg obp
margins, eyex(obp) atmeans
reg rg slg
margins, eyex(slg) atmeans

//obp coefficient and elasticity both alrger in mlr model 
reg rg obp slg 
margins, eyex(slg obp) atmeans

//standardizing for mean/standard deviations (beta regression)
//result looks the same
reg rg obp slg, beta

//comparing mlr with ops alone
//using both seems slightly better.. higher r2, ar2
eststo clear
reg rg obp slg
eststo
reg rg ops
eststo
esttab, r2 ar2

//are obp and slg identical as (ops = slg + obp) implies?
//p-val == 0.000, so reject this hypothesis at 0% level (they are not identical)
reg rg obp slg
test obp = slg

//test true obp and slg component coefficients
eststo clear
gen denom = ab + bb + hbp + sf
gen hdenom = h/denom
gen bbdenom = bb/denom
gen hbpdenom = hbp/denom

reg rg hdenom bbdenom hbpdenom
eststo
test hdenom = bbdenom = hbpdenom  //reject h0: coefficients not equal

gen h1ab = h1/ab
gen h2ab = h2/ab 
gen h3ab = h3/ab
gen hrab = hr/ab

reg rg h1ab h2ab h3ab hrab
eststo
test (hrab = 4) (h3ab = 3) (h2ab = 2) (h1ab = 1) //reject h0 here as well

esttab, r2 ar2 compress

//gen new obp and slg metrics
reg rg h1ab h2ab h3ab hrab
predict slg2
reg rg hdenom bbdenom hbpdenom
predict obp2

/*
reg slg h1ab h2ab h3ab hrab
predict slg2
reg obp hdenom bbdenom hbpdenom
predict obp2
*/


sum obp2 slg2 obp slg  //more or less equal range, mean, standard deviation

//compare new metrics to originals, see if predictive power has changed
reg rg obp2 slg2
reg rg obp slg
//slg now greater in magnitude than obp. Rsquared went down. 


//examine new variable weights. Which are under/overweighted in the original formulas?
//display xyz  (see what I'm actually supposed to do here. These seem too large)
reg rg h1ab h2ab h3ab hrab
reg rg hdenom bbdenom hbpdenom

 
 
 
 ****************************************************************************
 // gamelogs   
 ****************************************************************************
drop if vputouts < 24
drop if hputouts < 27

//scale up home team runs by factor of 27/vputouts
gen hruns2 = hruns * (27/vputouts)
sum hruns hruns2

gen obp = (hh+hbb+hhbp)/(hab+hbb+hhbp+hsf)
gen hh1b = hh- (h2b+h3b+hhr)
gen slg = (hh1b+2*h2b+3*h3b+4*hhr)/hab
gen ops = slg + obp

reg hrg obp
reg hrg slg
reg hrg ops

reg hrg obp slg


gen denom = (hab+hbb+hhbp+hsf)
gen hdenom = hh/denom
gen bbdenom = hbb/denom
gen hbpdenom = hhbp/denom
reg hruns2 hdenom bbdenom hbpdenom

gen h1ab = hh1b/hab
gen h2ab = h2b/hab
gen h3ab = h3b/hab
gen hrab = hhr/hab
reg hruns2 h1ab h2ab h3ab hrab

reg hruns2 obp 
eststo
reg hruns2 slg
eststo
reg hruns2 obp slg
eststo
reg hruns2 ops
eststo
esttab, r2 ar2

//improve the ops statistic 
reg wprcnt obp slg   

reg wprcnt hdenom bbdenom hbpdenom
predict realOBP

reg wprcnt h1ab h2ab h3ab hrab
predict realSLG

//true ratio of slg importance to obp importance 
reg ops realSLG realOBP




