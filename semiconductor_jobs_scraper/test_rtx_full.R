setwd("C:/Users/grege/OneDrive/Documents/TXSemiModel/semiconductor_jobs_scraper")
source("config/scraper_config.R")
source("scrapers/utils.R")
source("scrapers/workday_scraper.R")

library(dplyr)

# Run the full scrape for RTX (listing + first 5 details only)
cat("=== Scraping RTX job listings ===\n")
jobs_df <- scrape_workday("RTX", "https://globalhr.wd5.myworkdayjobs.com/REC_RTX_Ext_Gateway?q=TX")
cat("\nTotal jobs found:", nrow(jobs_df), "\n")
cat("Sample locations:\n")
print(head(jobs_df$location, 10))

# Fetch details for first 5 jobs
cat("\n=== Fetching details for first 5 jobs ===\n")
for (i in 1:min(5, nrow(jobs_df))) {
  cat("\n--- Job", i, ":", jobs_df$job_title[i], "---\n")
  cat("Location:", jobs_df$location[i], "\n")

  detail <- scrape_workday_job_details(
    "https://globalhr.wd5.myworkdayjobs.com/REC_RTX_Ext_Gateway",
    jobs_df$external_path[i]
  )
  cat("RESP:", if (!is.na(detail$job_responsibilities)) "YES" else "NA", "\n")
  cat("EDU:", if (!is.na(detail$min_education)) substr(detail$min_education, 1, 100) else "NA", "\n")
  cat("EXP:", if (!is.na(detail$min_experience)) "YES" else "NA", "\n")
  cat("PREF:", if (!is.na(detail$preferred_qualifications)) "YES" else "NA", "\n")
  cat("SAL:", if (!is.na(detail$salary_range)) detail$salary_range else "NA", "\n")
}
