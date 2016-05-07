require("data.table")
require("PlayerRatings")
require("ggplot2")

#############################################################################################
#seasonCompact <- fread("/Users/jamesledoux/Documents/Sports-Econometrics/TermPaper/tennis_atp-master/atp_matches_2015.csv")
#teams <- fread(file.path("/Users/jamesledoux/Documents/Sports-Econometrics/TermPaper/tennis_atp-master/atp_players.csv"))
#sampleSubmission <- fread("/Users/jamesledoux/Documents/Sports-Econometrics/TermPaper/NCAAMData/SampleSubmission.csv")

#NOTE: only need to run this part once. Creates the consolidated table with all years included
#files <- list.files(path="/Users/jamesledoux/Documents/Sports-Econometrics/TermPaper/tennis_atp-master", pattern="atp_matches*", full.names=T, recursive=FALSE)

#for (file in files){
# if the merged dataset doesn't exist, create it
#if (!exists('dataset')){
#dataset <- read.table(file, header=TRUE, sep = ",")
#}
# #if the merged dataset does exist, append to it
#if (exists('dataset'')){
#temp_dataset <-read.table(file, header=TRUE, sep = ",")
#dataset<-rbind(dataset, temp_dataset)
#rm(temp_dataset)
#}
#}

#seasonCompact <- dataset
#seasonCompact <- seasonCompact[,names(seasonCompact) %in% c("tourney_id","tourney_level", "tourney_date", "winner_id", "loser_id")]
#seasonCompact$Season = as.integer(substr(seasonCompact$tourney_id, 1, 4))
#seasonCompact = na.omit(seasonCompact)
#write.csv(seasonCompact, '/Users/jamesledoux/Documents/Sports-Econometrics/TermPaper/tennis_data.csv', row.names = FALSE)
#############################################################################################

#Read Files----------
seasonCompact <- fread("/Users/jamesledoux/Documents/Sports-Econometrics/TermPaper/tennis_data.csv")
teams <- fread(file.path("/Users/jamesledoux/Documents/Sports-Econometrics/TermPaper/tennis_atp-master/atp_players.csv"))
sampleSubmission <- fread("/Users/jamesledoux/Documents/Sports-Econometrics/TermPaper/NCAAMData/SampleSubmission.csv")


#fix names in teams df:
teams$fullname = paste(teams$first, teams$last, sep=" ")

#Elo rating for regular seasons----------
allSeasons <- seq(1985, 2015) 


#issue appears to be that there are NAs in some of these final columns (tourn id, win id, loser id)
eloEndOfSeasonList <- lapply(allSeasons, function(season2extractInfo){
  seasonDataDt <- seasonCompact[seasonCompact$Season == season2extractInfo,]
  resultVector <- rep(1, nrow(seasonDataDt))  # all 1's due to data format. Verify this is correct.
  seasonDataDf <- data.frame(tourney_date = seasonDataDt$tourney_date,
                             winner_id = seasonDataDt$winner_id, 
                             loser_id = seasonDataDt$loser_id, 
                             result = resultVector)
  EloRatings <- as.data.frame(elo(seasonDataDf)[1])
  EloRatings$Season = season2extractInfo
  #EloRatingsDt <- rbind(EloRatingsDt, EloRatings)
  #EloRatingsDt <- as.data.table(EloRatings$ratings)
  EloRatingsDt <- EloRatings
  
  return(EloRatingsDt)
})

eloEndOfSeasonList = do.call("rbind", eloEndOfSeasonList)

write.csv(eloEndOfSeasonList, "/Users/jamesledoux/Documents/Sports-Econometrics/TermPaper/TennisEloRatings.csv", row.names = FALSE)
print("Elo ratings extracted")
