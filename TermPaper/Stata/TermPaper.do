clear all
set more off
*use TermPaperDataTennisWomen.dta


****************   DATA GENERATION    *******************
*use menstennisdata.dta
*use womenstennisdata.dta

replace winner_rank = "2102" if winner_rank == "NA"
replace loser_rank = "2102" if loser_rank == "NA"
replace winner_ht = "." if winner_ht == "NA"
replace loser_ht = "." if loser_ht == "NA"
replace winner_age = "." if winner_age == "NA"
replace loser_age = "." if loser_age == "NA"


destring loser_rank, replace
destring winner_rank, replace
destring winner_ht, replace
destring loser_ht, replace
destring winner_age, replace
destring loser_age, replace 
destring tourney_id, replace


*convert from centimeters to meters 
replace winner_ht = winner_ht/100
replace loser_ht = loser_ht/100

gen HigherRankVictory = 0
replace HigherRankVictory = 1 if winner_rank < loser_rank  

*grand slam dummies
gen Australia = 0
replace Australia = 1 if tourney_name == "Australian Open"
gen USopen = 0
replace USopen = 1 if tourney_name == "US Open"
gen Wimbledon = 0
replace Wimbledon = 1 if tourney_name == "Wimbledon"
*french open not called french open in this data
gen French = 0
replace French = 1 if tourney_name == "French Open"
replace French = 1 if tourney_name == "Roland Garros"

gen DIFRANKING = 0
replace DIFRANKING = abs(ln(loser_rank) - ln(winner_rank))

gen DIFHEIGHT = 0
replace DIFHEIGHT = winner_ht - loser_ht if winner_rank < loser_rank 
replace DIFHEIGHT = loser_ht - winner_ht if winner_rank > loser_rank 
*same thing squared 
gen DIFHEIGHT2 = DIFHEIGHT^2
gen DIFAGE = 0 
replace DIFAGE = winner_age - loser_age if winner_rank < loser_rank 
replace DIFAGE = loser_age - winner_age if winner_rank > loser_rank
gen DIFAGE2 = DIFAGE^2

gen BOTHRIGHT = 0
replace BOTHRIGHT = 1 if winner_hand == "R" & loser_hand == "R"
gen BOTHLEFT = 0
replace BOTHLEFT = 1 if winner_hand == "L" & loser_hand == "L"
gen LEFTL = 0
* if winner L, loser R, and winner was ranked lower
replace LEFTL = 1 if winner_hand == "L" & loser_hand == "R" & loser_rank < winner_rank
* if loser L, winner R, and loser was ranked lower
replace LEFTL = 1 if loser_hand == "L" & winner_hand == "R" & loser_rank > winner_rank
gen LEFTH = 0
*winner L, loser R, winner rank better than loser rank
replace LEFTH = 1 if winner_hand == "L" & loser_hand == "R" & winner_rank < loser_rank
*loser L, winner R, loser ranked higher than winner 
replace LEFTH = 1 if loser_hand == "L" & winner_hand == "R" & winner_rank > loser_rank

*lots of unknown values here
sum BOTHRIGHT BOTHLEFT LEFTH LEFTL
tab winner_hand   


*export and try in python 
*export delimited using "L:\Sports\tennis_data_w_needs_python.csv", replace

*date = yyyymmdd.. so 5 yrs = date - 50000 (ymmdd)
*if rank better than or equal to 10 in past 5 years
gen EXTOP10H = 0
gen EXTOP10L = 0

*brief intermission to do bestranklast5yrs in python 
gen bestranklast5yrsW = 2200
gen bestranklast5yrsL = 2200

replace bestranklast5yrsW = maxrankpast1 if maxrankpast1 < maxrankpast2
replace bestranklast5yrsW = maxrankpast2 if maxrankpast2 < maxrankpast1
replace bestranklast5yrsW = maxrankpast1 if maxrankpast1 == maxrankpast2

replace bestranklast5yrsL = maxrankpast1l if maxrankpast1l < maxrankpast2l
replace bestranklast5yrsL = maxrankpast2l if maxrankpast2l < maxrankpast1l
replace bestranklast5yrsL = maxrankpast1l if maxrankpast1l == maxrankpast2l

*if winner is the higher rank, and if he has been top 10, then == 1
*if loser is the higher rank, and if he has been top 10, then == 1
replace EXTOP10H = 1 if bestranklast5yrsW < 11 & winner_rank < loser_rank
replace EXTOP10H = 1 if bestranklast5yrsL < 11 & winner_rank > loser_rank

replace EXTOP10L = 1 if bestranklast5yrsW < 11 & loser_rank < winner_rank
replace EXTOP10L = 1 if bestranklast5yrsL < 11 & loser_rank > winner_rank


*this is our LHS variable
gen HIGHERRANKEDVICTORY = 0
replace HIGHERRANKEDVICTORY = 1 if winner_rank < loser_rank




*merge in data with match rounds included (forgot this in initial data)
*we have a few duplicates keeping us from merging 
duplicates report winner_id loser_id tourney_id tourney_date
*duplicates drop winner_id loser_id tourney_id tourney_date, force
merge 1:1 winner_id loser_id tourney_id tourney_date using men_data_with_rounds.dta, keepusing(round)

*difference between higher and lower ranked players' rounds reached in prev 
* year's tournament. Round = 0 if player did not play. Gen round reached if
* tourney id == tourney id, year = year - 1 for each player, for each of the 4
* grand slams

*7 rounds total: r128 r64 r32 r16 qf sf f

gen roundtest = -9999
replace roundtest = 1 if round == "R128"
replace roundtest = 2 if round == "R64"
replace roundtest = 3 if round == "R32"
replace roundtest = 4 if round == "R16"
replace roundtest = 5 if round == "QF"
replace roundtest = 6 if round == "SF"
replace roundtest = 7 if round == "F"
rename round round_string
rename roundtest round
* see if it worked 
tab round if tourney_level == "G"

gen prevseason = season - 1
*top round reached by player in each tourney 
egen TopRoundCurrentW = max(round), by(winner_id tourney_name season)
egen TopRoundCurrentL = max(round), by(loser_id tourney_name season)

gen winid2 = winner_id
gen tourn2 = tourney_name

*I don't think we actually use these two lines anywhere
*gen TopRoundPrev = -9999
*replace TopRoundPrev = TopRoundCurrent if (season==prevseason & winner_id == winid2 & tourn2 == tourney_name )


*pasted in data from python script that got top round reached in prev. yr
replace max_round_prev_yrw = 0 if max_round_prev_yrw == -9999
replace max_round_prev_yr2w = 0 if max_round_prev_yr2w == -9999
replace max_round_prev_yrl = 0 if max_round_prev_yrl == -9999
replace max_round_prev_yr2l = 0 if max_round_prev_yr2l == -9999


/*
the two vars for winner and loser are top round won and top round lost
during the previous year's tourney. Both are needed since some players reach 
a high round and then lose, and other never lose at all (i.e. the champions)
*/
gen toproundprevw = 0
gen toproundprevl = 0
replace toproundprevw = max_round_prev_yrw if max_round_prev_yrw > max_round_prev_yr2w
replace toproundprevw = max_round_prev_yr2w if max_round_prev_yr2w >= max_round_prev_yrw

replace toproundprevl = max_round_prev_yrl if max_round_prev_yrl > max_round_prev_yr2l
replace toproundprevl = max_round_prev_yr2l if max_round_prev_yr2l >= max_round_prev_yrl


gen toproundprevhigh = 0
gen toproundprevlow = 0
replace toproundprevhigh = toproundprevw if winner_rank < loser_rank
replace toproundprevhigh = toproundprevl if loser_rank < winner_rank
replace toproundprevlow = toproundprevl if loser_rank > winner_rank
replace toproundprevlow = toproundprevw if winner_rank > loser_rank

*DIFROTOUR = rd by higher ranked in prev yr's tourn - rd by lower in prev yr's tourn
gen difrotour = toproundprevhigh - toproundprevlow

*gen round dummies
gen round2 = 0
replace round2 = 1 if round == 2
gen round3 = 0
replace round3 = 1 if round == 3
gen round4 = 0
replace round4 = 1 if round == 4
gen quarterfinal = 0 
replace quarterfinal = 1 if round == 5
gen semifinal = 0 
replace semifinal = 1 if round == 6
gen final = 0 
replace final = 1 if round == 7


*******************************************************************
*			regressions, tables, plots
*******************************************************************
*first table of regressions (M1, M2, M3)
probit higherrankedvictory difranking extop10h extop10l difrotour difheight difheight2 difage difage2 leftl lefth bothleft round2 round3 round4 quarterfinal semifinal final australia french wimbledon if tourney_level == "G" & season <2009 & season > 2004
predict phat
gen predrange = "0-10" if phat < .1
replace predrange = "10-20" if phat < .2 & phat >= .1
replace predrange = "20-30" if phat < .3 & phat >=.2
replace predrange = "30-40" if phat < .4 & phat >=.3
replace predrange = "40-50" if phat < .5 & phat >=.4
replace predrange = "50-60" if phat < .6 & phat >=.5
replace predrange = "60-70" if phat < .7 & phat >=.6
replace predrange = "70-80" if phat < .8 & phat >=.7
replace predrange = "80-90" if phat < .9 & phat >=.8
replace predrange = "90-100" if phat < 1 & phat >=.9
tab predrange if tourney_level == "G" & season < 2009 & season > 2004
tab predrange higherrankedvictory if tourney_level == "G" & season < 2009 & season > 2004, row chi2
brier higherrankedvictory phat
drop phat predrange

probit higherrankedvictory difheight difheight2 difage difage2 leftl lefth bothleft round2 round3 round4 quarterfinal semifinal final australia french wimbledon if tourney_level == "G" & season <2009 & season > 2004
predict phat
gen predrange = "0-10" if phat < .1
replace predrange = "10-20" if phat < .2 & phat >= .1
replace predrange = "20-30" if phat < .3 & phat >=.2
replace predrange = "30-40" if phat < .4 & phat >=.3
replace predrange = "40-50" if phat < .5 & phat >=.4
replace predrange = "50-60" if phat < .6 & phat >=.5
replace predrange = "60-70" if phat < .7 & phat >=.6
replace predrange = "70-80" if phat < .8 & phat >=.7
replace predrange = "80-90" if phat < .9 & phat >=.8
replace predrange = "90-100" if phat < 1 & phat >=.9
tab predrange if tourney_level == "G" & season < 2009 & season > 2004
tab predrange higherrankedvictory if tourney_level == "G" & season < 2009 & season > 2004, row chi2
brier higherrankedvictory phat
drop phat predrange

probit higherrankedvictory difranking extop10h extop10l difrotour round2 round3 round4 quarterfinal semifinal final australia french wimbledon if tourney_level == "G" & season <2009 & season > 2004
predict phat
gen predrange = "0-10" if phat < .1
replace predrange = "10-20" if phat < .2 & phat >= .1
replace predrange = "20-30" if phat < .3 & phat >=.2
replace predrange = "30-40" if phat < .4 & phat >=.3
replace predrange = "40-50" if phat < .5 & phat >=.4
replace predrange = "50-60" if phat < .6 & phat >=.5
replace predrange = "60-70" if phat < .7 & phat >=.6
replace predrange = "70-80" if phat < .8 & phat >=.7
replace predrange = "80-90" if phat < .9 & phat >=.8
replace predrange = "90-100" if phat < 1 & phat >=.9
tab predrange if tourney_level == "G" & season < 2009 & season > 2004
tab predrange higherrankedvictory if tourney_level == "G" & season < 2009 & season > 2004, row chi2
brier higherrankedvictory phat
drop phat predrange



**********************************************************************  
*			Test accuracy by predicting out of sample
**********************************************************************
probit higherrankedvictory difranking extop10h extop10l difrotour difheight difheight2 difage difage2 leftl lefth bothleft round2 round3 round4 quarterfinal semifinal final australia french wimbledon if tourney_level == "G" & season <2009 & season > 2004
eststo
predict phat if season == 2009 & tourney_name == "Australian Open"
gen predrange = "0-10" if phat < .1
replace predrange = "10-20" if phat < .2 & phat >= .1
replace predrange = "20-30" if phat < .3 & phat >=.2
replace predrange = "30-40" if phat < .4 & phat >=.3
replace predrange = "40-50" if phat < .5 & phat >=.4
replace predrange = "50-60" if phat < .6 & phat >=.5
replace predrange = "60-70" if phat < .7 & phat >=.6
replace predrange = "70-80" if phat < .8 & phat >=.7
replace predrange = "80-90" if phat < .9 & phat >=.8
replace predrange = "90-100" if phat < 1 & phat >=.9
tab predrange higherrankedvictory if tourney_level == "G" & season == 2009 & tourney_name == "Australian Open", row chi2
brier higherrankedvictory phat
drop phat predrange

probit higherrankedvictory difheight difheight2 difage difage2 leftl lefth bothleft round2 round3 round4 quarterfinal semifinal final australia french wimbledon if tourney_level == "G" & season <2009 & season > 2004
eststo
predict phat if season == 2009 & tourney_name == "Australian Open" 
gen predrange = "0-10" if phat < .1
replace predrange = "10-20" if phat < .2 & phat >= .1
replace predrange = "20-30" if phat < .3 & phat >=.2
replace predrange = "30-40" if phat < .4 & phat >=.3
replace predrange = "40-50" if phat < .5 & phat >=.4
replace predrange = "50-60" if phat < .6 & phat >=.5
replace predrange = "60-70" if phat < .7 & phat >=.6
replace predrange = "70-80" if phat < .8 & phat >=.7
replace predrange = "80-90" if phat < .9 & phat >=.8
replace predrange = "90-100" if phat < 1 & phat >=.9
tab predrange if tourney_level == "G" & season == 2009 & tourney_name == "Australian Open"
tab predrange higherrankedvictory if tourney_level == "G" & season == 2009 & tourney_name == "Australian Open", row chi2
brier higherrankedvictory phat
drop phat predrange

probit higherrankedvictory difranking extop10h extop10l difrotour round2 round3 round4 quarterfinal semifinal final australia french wimbledon if tourney_level == "G" & season <2009 & season > 2004
eststo
predict phat if season == 2009 & tourney_name == "Australian Open"
gen predrange = "0-10" if phat < .1
replace predrange = "10-20" if phat < .2 & phat >= .1
replace predrange = "20-30" if phat < .3 & phat >=.2
replace predrange = "30-40" if phat < .4 & phat >=.3
replace predrange = "40-50" if phat < .5 & phat >=.4
replace predrange = "50-60" if phat < .6 & phat >=.5
replace predrange = "60-70" if phat < .7 & phat >=.6
replace predrange = "70-80" if phat < .8 & phat >=.7
replace predrange = "80-90" if phat < .9 & phat >=.8
replace predrange = "90-100" if phat < 1 & phat >=.9
tab predrange higherrankedvictory if tourney_level == "G" & season == 2009 & tourney_name == "Australian Open", row chi2
brier higherrankedvictory phat
drop phat predrange

esttab, compress

*graph of probwin vs agedif for men  (find a way to sync the graphs over one another if possible)
probit higherrankedvictory difage if tourney_level == "G" & season <2009 & season > 2004
predict winhat
scatter winhat difage

************   gen summary table, compare to the original study   ************
*uncommment the year drops for an exact replication 
*drop if season < 2005
*drop if season > 2008
*drop if tourney_level != "G"

sum higherrankedvictory difranking extop10h extop10l difheight difheight2 difage difage2 leftl lefth bothleft bothright if tourney_level == "G" & season < 2009 & season > 2004


************************************************************
*			bring in the other ratings systems 
************************************************************
*rpi
drop _merge
merge m:1 winner_id season using rpi_women.dta
replace rpi = 0 if games_playes < 14
rename rpi rpi_w
drop winp owp oowp games_playes _merge

merge m:1 loser_id season using rpi_women.dta
replace rpi = 0 if games_playes < 14
rename rpi rpi_l
drop winp owp oowp games_playes _merge

*elo
merge m:1 winner_id season using elo_women.dta
rename rating elo_w
drop games win draw loss lag _merge

merge m:1 loser_id season using elo_women.dta
rename rating elo_l
drop games win draw loss lag _merge

*pagerank
merge m:1 winner_id season using pagerankwomen.dta
rename score pagerank_w
drop _merge

merge m:1 loser_id season using pagerankwomen.dta
rename score pagerank_l
drop _merge

corr rpi_w elo_w pagerank_w
corr rpi_l elo_l pagerank_l

*gen h and l versions of rankings to get rankdiff vars
*logs (exact comparison)
gen difranking_rpi = 0
replace difranking_rpi = abs(ln(rpi_w) - ln(rpi_l))
gen difranking_elo = 0
replace difranking_elo = abs(ln(elo_w) - ln(elo_l))
gen difranking_pr = 0
replace difranking_pr = abs(ln(pagerank_w) - ln(pagerank_l))

*squared
gen difranking_rpi2 = 0
replace difranking_rpi2 = (rpi_w - rpi_l)^2
gen difranking_elo2 = 0
replace difranking_elo2 = (elo_w - elo_l)^2
gen difranking_pr2 = 0
replace difranking_pr2 = (pagerank_w - pagerank_l)^2

*just plain difference
gen difranking_rpi3 = 0
replace difranking_rpi3 = abs(rpi_w - rpi_l)
gen difranking_elo3 = 0
replace difranking_elo3 = abs(elo_w - elo_l)
gen difranking_pr3 = 0
replace difranking_pr3 = abs(pagerank_w - pagerank_l)


*gen new lhs variables 
gen favwins_rpi = 0
gen favwins_elo = 0
gen favwins_pr = 0

replace favwins_rpi = 1 if rpi_w > rpi_l
replace favwins_elo = 1 if elo_w > elo_l
replace favwins_pr = 1 if pagerank_w > pagerank_l


*see how well they fare
probit favwins_rpi difranking_rpi if tourney_name == "US Open"
probit favwins_rpi difranking_rpi2 if tourney_name == "US Open"
probit favwins_rpi difranking_rpi3 if tourney_name == "US Open"
eststo

probit favwins_elo difranking_elo if tourney_name == "US Open"
probit favwins_elo difranking_elo2 if tourney_name == "US Open"
probit favwins_elo difranking_elo3 if tourney_name == "US Open"
eststo

probit favwins_pr difranking_pr if tourney_name == "US Open"
probit favwins_pr difranking_pr2 if tourney_name == "US Open"
probit favwins_pr difranking_pr3 if tourney_name == "US Open"
eststo

probit higherrankedvictory difranking if tourney_name == "US Open"
eststo
esttab, compress wide



probit higherrankedvictory Elo extop10h extop10l difrotour difheight difheight2 difage difage2 leftl lefth bothleft round2 round3 round4 quarterfinal semifinal final australia french wimbledon if tourney_name == "US Open" & season <2014 & season > 1999
predict phat if season == 2009 & tourney_name == "US Open"
gen predrange = "0-10" if phat < .1
replace predrange = "10-20" if phat < .2 & phat >= .1
replace predrange = "20-30" if phat < .3 & phat >=.2
replace predrange = "30-40" if phat < .4 & phat >=.3
replace predrange = "40-50" if phat < .5 & phat >=.4
replace predrange = "50-60" if phat < .6 & phat >=.5
replace predrange = "60-70" if phat < .7 & phat >=.6
replace predrange = "70-80" if phat < .8 & phat >=.7
replace predrange = "80-90" if phat < .9 & phat >=.8
replace predrange = "90-100" if phat < 1 & phat >=.9
tab predrange higherrankedvictory if tourney_name == "US Open" & season < 2015, row chi2
brier higherrankedvictory phat
drop phat predrange

*elo out of sample
predict phat if season == 2015 & tourney_name == "US Open"
gen predrange = "0-10" if phat < .1
replace predrange = "10-20" if phat < .2 & phat >= .1
replace predrange = "20-30" if phat < .3 & phat >=.2
replace predrange = "30-40" if phat < .4 & phat >=.3
replace predrange = "40-50" if phat < .5 & phat >=.4
replace predrange = "50-60" if phat < .6 & phat >=.5
replace predrange = "60-70" if phat < .7 & phat >=.6
replace predrange = "70-80" if phat < .8 & phat >=.7
replace predrange = "80-90" if phat < .9 & phat >=.8
replace predrange = "90-100" if phat < 1 & phat >=.9
tab predrange higherrankedvictory if tourney_name == "US Open" & season < 2015, row chi2
brier higherrankedvictory phat
drop phat predrange








probit favwins_pr PageRank if tourney_name == "US Open" & season < 2015
eststo

probit favwins_elo Elo if tourney_name == "US Open"& season < 2015
eststo

probit favwins_rpi RPI if tourney_name == "US Open"& season < 2015
eststo

probit higherrankedvictory difranking if tourney_name == "US Open"& season < 2015
eststo
esttab, compress wide pr2



probit favwins_pr PageRank if tourney_name == "US Open" & season < 2015
predict if season == 2015 & tourney_name == "US Open"








//
