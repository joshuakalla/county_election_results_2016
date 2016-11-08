rm(list=ls())
library(htmltab)
library(dplyr)

# Load Data ----

wd <- '/home/awang/county_election_results_2016/'
#load county-fips-state file
state_county_fips <- read.csv(
  file.path(wd, 'state_county_fips.csv'), stringsAsFactors=FALSE)
#unique state file
unique_state <- read.csv(file.path(wd, 'unique_state.csv'), 
                         stringsAsFactors=FALSE)

# Scrape ------

grab_data <- function(state){
  url <- sprintf("http://townhall.com/election/2016/president/%s/county", state)
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
res <- aiHelper::merge2(
  z %>% mutate(county = stringr::str_trim(tolower(county))),
  state_county_fips %>% mutate(county = stringr::str_trim(county)),
                 by = c("abbr_state", "county"), all = TRUE)

# View(subset(res, is.na(fips)))

write.csv(res, "county_election_results_2016.csv", row.names=FALSE)
