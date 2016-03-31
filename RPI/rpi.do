* RPI Madness * 

set more off 

*mean (teamwins) > 0.5.. Is this okay? 
gen teamwins = 0
replace teamwins = 1 if pts > opppts

gen ptdiff = pts - opppts

gen ptratio = pts/opppts

gen lnptdiff = ln(pts/opppts)

gen wp6diff = wp6 - oppwp6
gen owpdiff = owp - oppowp
gen oowpdiff = oowp - oppoowp

gen home = 0
replace home = 1 if neutral == 0

*model 1: LPM estimating wins 

reg teamwins wp6diff owpdiff oowpdiff home
eststo
*normalize coefficients to get implied RPI weights 
display .5488626 /( .5488626 +  1.054479  +  3.233521)
display 1.054479 /( .5488626 +  1.054479  +  3.233521)
display 3.233521 /( .5488626 +  1.054479  +  3.233521)


*model 2: logit 
logit teamwins wp6diff owpdiff oowpdiff home
eststo
display  3.3254 /(  3.3254 +   5.926723   +  18.67036 )
display  5.926723  /(  3.3254 +   5.926723   +  18.67036 )
display  18.67036 /(  3.3254 +   5.926723   +  18.67036 )

*model 3: ptdiff
reg ptdiff wp6diff owpdiff oowpdiff home
eststo
display   23.28122 /(  23.28122 +   39.00135  +   109.9625  )
display   39.00135 /(  23.28122 +   39.00135  +   109.9625  )
display   109.9625 /(  23.28122 +   39.00135  +   109.9625  )


*model 4: wp6diff
reg ptratio wp6diff owpdiff oowpdiff home
eststo
display .392587  / (.392587  + .6440669  +  1.901081)
display .6440669  / (.392587  + .6440669  +  1.901081)
display 1.901081  / (.392587  + .6440669  +  1.901081)


*model 5: lnptdiff
reg lnptdiff wp6diff owpdiff oowpdiff home
eststo
display .3466096  / (.3466096  + .5830883  +  1.661319 )
display .5830883  / (.3466096  + .5830883  +  1.661319 )
display 1.661319  / (.3466096  + .5830883  +  1.661319 )


*linear model comparisons:
esttab, r2 ar2 compress

*nonlinear models 
*1: pt difference
nl (ptdiff = {b0} + {b1}*( (wp6 + {b2}*owp + {b3}*oowp) / (oppwp6 + {b2}*oppowp + {b3}*oppoowp) ) + {b4}*home )
display 1  / (1  +  1.68822  +  4.757153  )
display 1.68822  / (1  +  1.68822  +  4.757153  )
display 4.757153  / (1  +  1.68822  +  4.757153  )

*2: pt ratio 
nl (ptratio = {b0} + {b1}*( (wp6 + {b2}*owp + {b3}*oowp) / (oppwp6 + {b2}*oppowp + {b3}*oppoowp) ) + {b4}*home )
display 1  / (1  +  1.685164  +  4.712763  )
display 1.685164  / (1  +  1.685164  +  4.712763  )
display 4.712763 / (1  +  1.685164  +  4.712763  )

*3: ln pts diff
nl (lnptdiff = {b0} + {b1}*( (wp6 + {b2}*owp + {b3}*oowp) / (oppwp6 + {b2}*oppowp + {b3}*oppoowp) ) + {b4}*home )
display 1  / (1  +  1.702693  +   4.800445  )
display 1.702693 / (1  +  1.702693  +   4.800445  )
display 4.800445 / (1  +  1.702693  +   4.800445  )





