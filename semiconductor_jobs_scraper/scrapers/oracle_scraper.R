# Oracle CX Platform Scraper
# ===========================
# Scrapes job listings from Oracle Cloud CX career sites
# Used by: Texas Instruments

library(rvest)
library(httr)
library(dplyr)

source("config/scraper_config.R")
source("scrapers/utils.R")

#' Scrape jobs from Oracle CX career page
#'
#' @param company_name Name of the company
#' @param base_url Base URL of the Oracle CX career site
#' @param max_pages Maximum number of pages to scrape
#' @return Dataframe of job listings
scrape_oracle <- function(company_name, base_url, max_pages = 50) {
  
  log_message(paste("Starting Oracle CX scrape for", company_name))
  
  # Oracle CX sites often use a search API
  # This is a template - actual implementation depends on site structure
  
  all_jobs <- list()
  page <- 0
  
  while (page < max_pages) {
    
    log_message(paste("Scraping page", page + 1, "for", company_name))
    
    # Oracle typically uses offset-based pagination
    # Example: ?offset=20&limit=20
    page_url <- paste0(base_url, "?offset=", page * 20, "&limit=20")
    
    response <- fetch_with_retry(page_url)
    
    if (is.null(response)) {
      log_message("Failed to fetch page - stopping", level = "WARN")
      break
    }
    
    page_content <- read_html(response)
    
    # Extract job tiles (this selector may need adjustment)
    job_elements <- page_content %>%
      html_elements("div[class*='job-tile'], article[class*='job']")
    
    if (length(job_elements) == 0) {
      log_message("No more jobs found - stopping")
      break
    }
    
    # Parse jobs
    jobs <- map_df(job_elements, function(job) {
      
      title <- job %>%
        html_element("h3, h4, [class*='title']") %>%
        html_text2() %>%
        str_trim()
      
      location <- job %>%
        html_element("[class*='location']") %>%
        html_text2() %>%
        str_trim()
      
      job_link <- job %>%
        html_element("a") %>%
        html_attr("href")
      
      # Construct full URL
      if (!is.na(job_link) && !str_detect(job_link, "^http")) {
        # Parse base domain from base_url
        base_domain <- str_extract(base_url, "^https?://[^/]+")
        job_url <- paste0(base_domain, job_link)
      } else {
        job_url <- job_link
      }
      
      tibble(
        job_title = title,
        location = location,
        job_url = job_url,
        posting_date = Sys.Date()  # Often not available on list page
      )
    })
    
    jobs <- jobs %>% filter(!is.na(job_title), !is.na(job_url))
    
    if (nrow(jobs) > 0) {
      all_jobs <- c(all_jobs, list(jobs))
    }
    
    page <- page + 1
    Sys.sleep(SCRAPER_CONFIG$delay_between_requests)
  }
  
  if (length(all_jobs) > 0) {
    jobs_df <- bind_rows(all_jobs)
    log_message(paste("Found", nrow(jobs_df), "total jobs for", company_name))
  } else {
    jobs_df <- data.frame()
  }
  
  return(jobs_df)
}

#' Scrape detailed job information from Oracle CX job page
#'
#' @param job_url URL of the specific job posting
#' @return List with detailed job information
scrape_oracle_job_details <- function(job_url) {
  
  log_message(paste("Fetching Oracle CX job details:", job_url), level = "DEBUG")
  
  response <- fetch_with_retry(job_url)
  
  if (is.null(response)) {
    return(list(
      job_responsibilities = NA_character_,
      min_education = NA_character_,
      min_experience = NA_character_,
      preferred_qualifications = NA_character_,
      salary_range = NA_character_
    ))
  }
  
  page_content <- read_html(response)
  
  # Extract job description
  # Oracle sites often have class names like 'job-description'
  description_html <- page_content %>%
    html_element("div[class*='description'], div[class*='detail']")
  
  description_text <- description_html %>%
    html_text2()
  
  # Parse sections
  details <- extract_job_sections(description_text)
  
  Sys.sleep(SCRAPER_CONFIG$delay_between_requests)
  
  return(details)
}

#' Main function to scrape an Oracle CX company
#'
#' @param company_name Name of the company
#' @param base_url Base URL of career site
#' @param fetch_details Whether to fetch full job details
#' @return Dataframe of jobs
scrape_oracle_company <- function(company_name, base_url, fetch_details = TRUE) {
  
  log_message(paste("=== Starting Oracle CX scrape for", company_name, "==="))
  start_time <- Sys.time()
  
  jobs <- scrape_oracle(company_name, base_url)
  
  if (nrow(jobs) == 0) {
    log_message(paste("No jobs found for", company_name), level = "WARN")
    return(data.frame())
  }
  
  if (fetch_details) {
    log_message(paste("Fetching details for", nrow(jobs), "jobs"))
    
    pb <- txtProgressBar(min = 0, max = nrow(jobs), style = 3)
    
    jobs <- jobs %>%
      rowwise() %>%
      mutate({
        details <- scrape_oracle_job_details(job_url)
        setTxtProgressBar(pb, cur_group_id())
        details
      }) %>%
      ungroup()
    
    close(pb)
  }
  
  jobs <- jobs %>%
    mutate(
      company_name = company_name,
      scraped_at = Sys.time()
    )
  
  end_time <- Sys.time()
  duration <- as.numeric(difftime(end_time, start_time, units = "secs"))
  
  log_message(paste("Completed", company_name, "in", round(duration, 2), "seconds"))
  
  return(jobs)
}
