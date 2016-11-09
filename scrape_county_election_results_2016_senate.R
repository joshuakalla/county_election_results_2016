rm(list=ls())
library(htmltab)
library(plyr)
library(dplyr)


# Load Data ----

wd <- '/Users/joshkalla/Desktop/county_election_results_2016'
#load county-fips-state file
state_county_fips <- read.csv(
  file.path(wd, 'state_county_fips.csv'), stringsAsFactors=FALSE)
#unique state file for competitive senate elections
unique_state <- read.csv(file.path(wd, 'unique_state_senate.csv'), 
                         stringsAsFactors=FALSE)
#keep only states we care about
state_county_fips <- subset(state_county_fips, state_county_fips$abbr_state %in% unique_state$abbr_state)

# Scrape ------

grab_data <- function(state){
  url <- sprintf("http://townhall.com/election/2016/senate/%s/county", state)
  # Try to grab
  state_result <- try(htmltab::htmltab(
    doc = url, which = '//*[@id="election-live"]/table[2]'))
  if('data.frame' %in% class(state_result)){
    # clean up names
    state_result <- state_result %>%
      rename(county = `County Results >> County`,
             candidate = `County Results >> Candidate`,
             votes = Votes,
             percent_won = `% Won`) %>%
      mutate(abbr_state = state,
             percent_complete = gsub('[[:alpha:]]|%|[[:blank:]]|[[:punct:]]', '', county),
             county = gsub('[[:digit:]]|%', '', county))
      
  } else {
    state_result <- data.frame(abbr_state = state, stringsAsFactors = F)
  }
  state_result
}

#loop over unique state file
results <- lapply(unique_state$abbr_state, function(i){
  print(i)
  res <- grab_data(i)
  # sometimes the page refreshes, so if that happens, 
  # wait for 5 seconds and try again.
  if(nrow(res) == 1){
    Sys.sleep(5)
    print('sleepy time!')
    res <- grab_data(i)
  }
  return(res)
})

# Export ---
z <- dplyr::bind_rows(results)

# merge to get fips
res <- merge(
  z %>% mutate(county = stringr::str_trim(tolower(county))),
  state_county_fips %>% mutate(county = stringr::str_trim(county)),
                 by = c("abbr_state", "county"), all = TRUE)

other.candidate <- c("Aaron Day", "Edward Clifford", "Phil Anderson",
                     "Brian Chabot", "Fred Ryman", "Johnathan McFarland",
                     "Kenton McMillen", "None of these candidates",
                     "Sean Haugh", "Tom Sawyer", "Jarrod Williams",
                     "Jonathan Dine", "Lucy Brenton", "Tony Gumina",
                     "Scott Summers", "Tom Jones")
dem.candidate <- c("Jason Kander", "Katie McGinty", "Maggie Hassan",
                   "Russ Feingold", "Evan Bayh", "Catherine Cortez Masto",
                   "Deborah Ross", "Tammy Duckworth")
rep.candidate <- c("Todd Young", "Joe Heck", "Kelly Ayotte",
                   "Mark Kirk", "Richard Burr", "Ron Johnson",
                   "Pat Toomey", "Roy Blunt")

res$candidate[res$candidate %in% other.candidate] <- "other"
res$candidate[res$candidate %in% dem.candidate] <- "democrat"
res$candidate[res$candidate %in% rep.candidate] <- "republican"

#convert to numeric
res$votes <- as.numeric(gsub(",", "", res$votes))
res$percent_won <- as.numeric(sub("%", "", res$percent_won))
res$percent_complete <- as.numeric(res$percent_complete) #this is funky, sorry!

#consolidate republican candidates
res <- ddply(res, c("abbr_state", "county", "candidate"), numcolwise(sum))

write.csv(res, "county_election_results_2016_senate.csv", row.names=FALSE)
