rm(list=ls())
library(htmltab)
library(plyr)
setwd("~/Desktop/county_election_results_2016")

#load county-fips-state file
state_county_fips <- read.csv('state_county_fips.csv', stringsAsFactors=FALSE)

#unique state file
unique_state <- read.csv('unique_state.csv', stringsAsFactors=FALSE)

#loop over unique state file
results <- NA
for (i in 1:nrow(unique_state)) {
  url <- paste0("http://townhall.com/election/2016/president/", unique_state[i,1], "/county")
  state_result <- htmltab(doc = url, which = '//*[@id="election-live"]/table[2]')
  state_result <- rename(state_result, c("County Results >> County"  = "county", "County Results >> Candidate" = "candidate",
                   "Votes" = "votes", "% Won" = "percent_won"))
  state_result$abbr_state <- rep(unique_state[i,1], nrow(state_result))
  results <- rbind(results, state_result)
}

results <- results[-1,] #remove first NA
results$county <- gsub('[0-9]+', '', results$county) #remove the 0; I'm guessing this will change to different numbers
results$county <- gsub('%', '', results$county) #remove the %
results$county <- tolower(results$county) #lower-case county to match state_county_fips

results <- merge(results, state_county_fips, by = c("abbr_state", "county")) #merge to get fips

write.csv(results, "county_election_results_2016.csv")
