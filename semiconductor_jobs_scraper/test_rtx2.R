setwd("C:/Users/grege/OneDrive/Documents/TXSemiModel/semiconductor_jobs_scraper")
source("config/scraper_config.R")
source("scrapers/utils.R")
source("scrapers/workday_scraper.R")

library(httr)
library(jsonlite)
library(stringr)

url <- "https://globalhr.wd5.myworkdayjobs.com/wday/cxs/globalhr/REC_RTX_Ext_Gateway/job/US-TX-MCKINNEY-513WC--2501-W-University-Dr--WING-C-BLDG/Senior-Mechanical-Engineer_01824562"
resp <- GET(url, user_agent(SCRAPER_CONFIG$user_agent), add_headers("Accept" = "application/json"))
data <- fromJSON(content(resp, as = "text", encoding = "UTF-8"), simplifyVector = FALSE)
raw_html <- data$jobPostingInfo$jobDescription
stripped <- strip_workday_boilerplate(raw_html)

# Extract raw section between "Qualifications You Must Have" and "Qualifications We Prefer"
match <- str_match(stripped, "(?si)Qualifications You Must Have(.*?)(?=Qualifications We Prefer|$)")
if (!is.na(match[1, 2])) {
  cat("Raw qual section:\n")
  cat(match[1, 2], "\n")
}
