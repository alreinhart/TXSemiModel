setwd("C:/Users/grege/OneDrive/Documents/TXSemiModel/semiconductor_jobs_scraper")
source("config/scraper_config.R")
source("scrapers/utils.R")
source("scrapers/workday_scraper.R")

library(httr)
library(jsonlite)
library(stringr)

# Test RTX Senior Mechanical Engineer
cat("=== RTX: Senior Mechanical Engineer ===\n")
result <- scrape_workday_job_details(
  "https://globalhr.wd5.myworkdayjobs.com/REC_RTX_Ext_Gateway",
  "/job/US-TX-MCKINNEY-513WC--2501-W-University-Dr--WING-C-BLDG/Senior-Mechanical-Engineer_01824562"
)
cat("RESP:", substr(result$job_responsibilities, 1, 200), "\n\n")
cat("EDU:", substr(result$min_education, 1, 300), "\n\n")
cat("EXP:", substr(result$min_experience, 1, 300), "\n\n")
cat("PREF:", substr(result$preferred_qualifications, 1, 200), "\n\n")
cat("SAL:", result$salary_range, "\n\n")

# Test RTX Program Cost Controls Manager
cat("=== RTX: Program Cost Controls Manager ===\n")
result2 <- scrape_workday_job_details(
  "https://globalhr.wd5.myworkdayjobs.com/REC_RTX_Ext_Gateway",
  "/job/US-TX-MCKINNEY-513WD--2501-W-University-Dr--WING-D-BLDG/Program-Cost-Controls-Manager_01824560"
)
cat("RESP:", substr(result2$job_responsibilities, 1, 200), "\n\n")
cat("EDU:", substr(result2$min_education, 1, 300), "\n\n")
cat("EXP:", substr(result2$min_experience, 1, 300), "\n\n")
cat("PREF:", substr(result2$preferred_qualifications, 1, 200), "\n\n")
cat("SAL:", result2$salary_range, "\n\n")

# Test Applied Materials (regression check)
cat("=== Applied Materials: regression check ===\n")
result3 <- scrape_workday_job_details(
  "https://amat.wd1.myworkdayjobs.com/External",
  "/job/Austin-TX/Process-Engineer-V---Austin--TX_R2511978"
)
cat("RESP:", substr(result3$job_responsibilities, 1, 200), "\n\n")
cat("EDU:", substr(result3$min_education, 1, 200), "\n\n")
cat("EXP:", substr(result3$min_experience, 1, 200), "\n\n")
cat("PREF:", substr(result3$preferred_qualifications, 1, 200), "\n\n")
cat("SAL:", result3$salary_range, "\n\n")

# Test Samsung (regression check)
cat("=== Samsung: regression check ===\n")
result4 <- scrape_workday_job_details(
  "https://sec.wd3.myworkdayjobs.com/Samsung_Careers",
  "/job/Austin-TX/Director--Product-Strategy_R103461"
)
cat("RESP:", substr(result4$job_responsibilities, 1, 200), "\n\n")
cat("EDU:", substr(result4$min_education, 1, 200), "\n\n")
cat("EXP:", substr(result4$min_experience, 1, 200), "\n\n")
cat("PREF:", substr(result4$preferred_qualifications, 1, 200), "\n\n")
cat("SAL:", result4$salary_range, "\n\n")
