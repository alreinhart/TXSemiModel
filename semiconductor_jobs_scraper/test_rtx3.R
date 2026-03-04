setwd("C:/Users/grege/OneDrive/Documents/TXSemiModel/semiconductor_jobs_scraper")
source("config/scraper_config.R")
source("scrapers/utils.R")
source("scrapers/workday_scraper.R")

library(httr)
library(jsonlite)
library(stringr)

# Check if Applied Materials job URL is still valid
cat("=== Checking AMAT job ===\n")
resp <- GET(
  "https://amat.wd1.myworkdayjobs.com/wday/cxs/amat/External/job/Austin-TX/Process-Engineer-V---Austin--TX_R2511978",
  user_agent(SCRAPER_CONFIG$user_agent),
  add_headers("Accept" = "application/json")
)
cat("AMAT status:", status_code(resp), "\n")

# Get a fresh AMAT job
cat("\n=== Getting fresh AMAT job ===\n")
resp2 <- POST(
  "https://amat.wd1.myworkdayjobs.com/wday/cxs/amat/External/jobs",
  body = '{"appliedFacets":{},"limit":1,"offset":0,"searchText":""}',
  content_type_json(),
  user_agent(SCRAPER_CONFIG$user_agent)
)
amat_data <- fromJSON(content(resp2, as="text", encoding="UTF-8"), simplifyVector=FALSE)
amat_path <- amat_data$jobPostings[[1]]$externalPath
cat("AMAT path:", amat_path, "\n")

result_amat <- scrape_workday_job_details(
  "https://amat.wd1.myworkdayjobs.com/External",
  amat_path
)
cat("RESP:", substr(result_amat$job_responsibilities, 1, 100), "\n")
cat("EDU:", substr(result_amat$min_education, 1, 100), "\n")
cat("SAL:", result_amat$salary_range, "\n")

# Check Samsung
cat("\n=== Checking Samsung job ===\n")
resp3 <- GET(
  "https://sec.wd3.myworkdayjobs.com/wday/cxs/sec/Samsung_Careers/job/Austin-TX/Director--Product-Strategy_R103461",
  user_agent(SCRAPER_CONFIG$user_agent),
  add_headers("Accept" = "application/json")
)
cat("Samsung status:", status_code(resp3), "\n")

# Get a fresh Samsung job
resp4 <- POST(
  "https://sec.wd3.myworkdayjobs.com/wday/cxs/sec/Samsung_Careers/jobs",
  body = '{"appliedFacets":{},"limit":1,"offset":0,"searchText":""}',
  content_type_json(),
  user_agent(SCRAPER_CONFIG$user_agent)
)
sam_data <- fromJSON(content(resp4, as="text", encoding="UTF-8"), simplifyVector=FALSE)
sam_path <- sam_data$jobPostings[[1]]$externalPath
cat("Samsung path:", sam_path, "\n")

result_sam <- scrape_workday_job_details(
  "https://sec.wd3.myworkdayjobs.com/Samsung_Careers",
  sam_path
)
cat("RESP:", substr(result_sam$job_responsibilities, 1, 100), "\n")
cat("EDU:", substr(result_sam$min_education, 1, 100), "\n")
cat("SAL:", result_sam$salary_range, "\n")

# Debug RTX Senior Mech Eng min quals extraction
cat("\n=== RTX Senior Mech Eng: debug min quals ===\n")
url <- "https://globalhr.wd5.myworkdayjobs.com/wday/cxs/globalhr/REC_RTX_Ext_Gateway/job/US-TX-MCKINNEY-513WC--2501-W-University-Dr--WING-C-BLDG/Senior-Mechanical-Engineer_01824562"
resp5 <- GET(url, user_agent(SCRAPER_CONFIG$user_agent), add_headers("Accept" = "application/json"))
data5 <- fromJSON(content(resp5, as="text", encoding="UTF-8"), simplifyVector=FALSE)
raw <- data5$jobPostingInfo$jobDescription
stripped <- strip_workday_boilerplate(raw)

# Test with bullets_only = FALSE
min_qual_patterns <- c("Qualifications\\s+You\\s+Must\\s+Have\\s*:?")
min_text <- extract_workday_section(stripped, min_qual_patterns, bullets_only = FALSE, allow_bold_subheadings = TRUE)
cat("Min qual text (no bullets_only):\n", min_text, "\n")
