# Workday Platform Scraper
# =========================
# Scrapes job listings from Workday-based career sites
# Used by: Applied Materials, NXP Semiconductors

library(rvest)
library(httr)
library(dplyr)
library(purrr)
library(stringr)
library(lubridate)

source("config/scraper_config.R")
source("scrapers/utils.R")

#' Scrape jobs from a Workday career page
#'
#' @param company_name Name of the company
#' @param base_url Base URL of the Workday career site
#' @param max_pages Maximum number of pages to scrape
#' @return Dataframe of job listings
scrape_workday <- function(company_name, base_url, max_pages = 50) {
  
  log_message(paste("Starting Workday scrape for", company_name))
  
  all_jobs <- list()
  page <- 1
  has_next_page <- TRUE
  
  while (has_next_page && page <= max_pages) {
    
    log_message(paste("Scraping page", page, "for", company_name))
    
    # Construct page URL
    page_url <- construct_workday_url(base_url, page)
    
    # Fetch page with retry logic
    response <- fetch_with_retry(page_url)
    
    if (is.null(response)) {
      log_message(paste("Failed to fetch page", page, "- stopping"), level = "WARN")
      break
    }
    
    # Parse HTML
    page_content <- read_html(response)
    
    # Extract job listings
    jobs <- parse_workday_job_list(page_content, base_url)
    
    if (length(jobs) == 0) {
      log_message(paste("No jobs found on page", page, "- stopping"))
      has_next_page <- FALSE
    } else {
      all_jobs <- c(all_jobs, list(jobs))
      
      # Check for next page
      has_next_page <- check_workday_next_page(page_content)
      
      if (has_next_page) {
        page <- page + 1
        Sys.sleep(SCRAPER_CONFIG$delay_between_requests)
      }
    }
  }
  
  # Combine all jobs
  if (length(all_jobs) > 0) {
    jobs_df <- bind_rows(all_jobs)
    log_message(paste("Found", nrow(jobs_df), "total jobs for", company_name))
  } else {
    jobs_df <- data.frame()
    log_message(paste("No jobs found for", company_name), level = "WARN")
  }
  
  return(jobs_df)
}

#' Parse Workday job listing page
#'
#' @param page_content HTML content from read_html
#' @param base_url Base URL for constructing full job URLs
#' @return Dataframe of jobs
parse_workday_job_list <- function(page_content, base_url) {
  
  # Extract job elements
  job_elements <- page_content %>%
    html_elements("li[data-automation-id='jobPostingItem']")
  
  if (length(job_elements) == 0) {
    # Try alternative selector
    job_elements <- page_content %>%
      html_elements("div.jobs-list-item")
  }
  
  if (length(job_elements) == 0) {
    return(data.frame())
  }
  
  # Extract data from each job
  jobs <- map_df(job_elements, function(job) {
    
    # Extract basic info
    title <- job %>%
      html_element("[data-automation-id='jobTitle']") %>%
      html_text2() %>%
      str_trim()
    
    location <- job %>%
      html_element("[data-automation-id='locations']") %>%
      html_text2() %>%
      str_trim()
    
    job_link <- job %>%
      html_element("a[data-automation-id='jobTitle']") %>%
      html_attr("href")
    
    # Construct full URL
    if (!is.na(job_link) && !str_detect(job_link, "^http")) {
      job_url <- paste0(base_url, job_link)
    } else {
      job_url <- job_link
    }
    
    # Posted date (if available)
    posted_date <- job %>%
      html_element("[data-automation-id='postedOn']") %>%
      html_text2() %>%
      parse_date_string()
    
    # Return structured data
    tibble(
      job_title = if_else(is.na(title), NA_character_, title),
      location = if_else(is.na(location), NA_character_, location),
      job_url = if_else(is.na(job_url), NA_character_, job_url),
      posting_date = posted_date
    )
  })
  
  # Filter out invalid entries
  jobs <- jobs %>%
    filter(!is.na(job_title), !is.na(job_url))
  
  return(jobs)
}

#' Scrape detailed job information from a Workday job page
#'
#' @param job_url URL of the specific job posting
#' @return List with detailed job information
scrape_workday_job_details <- function(job_url) {
  
  log_message(paste("Fetching job details:", job_url), level = "DEBUG")
  
  # Fetch page
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
  
  # Extract full job description
  description_html <- page_content %>%
    html_element("[data-automation-id='jobPostingDescription']")
  
  if (is.na(description_html)) {
    # Try alternative selector
    description_html <- page_content %>%
      html_element("div.job-description, div.jobdescription")
  }
  
  # Parse structured sections from description
  description_text <- description_html %>%
    html_text2()
  
  # Extract specific sections using pattern matching
  details <- extract_job_sections(description_text)
  
  # Additional delay before next request
  Sys.sleep(SCRAPER_CONFIG$delay_between_requests)
  
  return(details)
}

#' Construct Workday pagination URL
#'
#' @param base_url Base Workday career site URL
#' @param page Page number
#' @return Full URL with pagination parameters
construct_workday_url <- function(base_url, page) {
  
  # Workday uses offset-based pagination
  offset <- (page - 1) * SCRAPER_CONFIG$jobs_per_page
  
  if (str_detect(base_url, "\\?")) {
    sep <- "&"
  } else {
    sep <- "?"
  }
  
  url <- paste0(base_url, sep, "offset=", offset)
  
  return(url)
}

#' Check if Workday page has a next page
#'
#' @param page_content HTML content from read_html
#' @return TRUE if next page exists, FALSE otherwise
check_workday_next_page <- function(page_content) {
  
  next_button <- page_content %>%
    html_element("button[data-uxi-widget-type='paginationNext']")
  
  if (is.na(next_button)) {
    return(FALSE)
  }
  
  # Check if button is disabled
  is_disabled <- next_button %>%
    html_attr("disabled")
  
  return(is.na(is_disabled))
}

#' Main function to scrape a Workday company with full details
#'
#' @param company_name Name of the company
#' @param base_url Base URL of career site
#' @param fetch_details Whether to fetch full job details (slower)
#' @return Dataframe of jobs with all available details
scrape_workday_company <- function(company_name, base_url, fetch_details = TRUE) {
  
  log_message(paste("=== Starting scrape for", company_name, "==="))
  start_time <- Sys.time()
  
  # Get job listings
  jobs <- scrape_workday(company_name, base_url)
  
  if (nrow(jobs) == 0) {
    log_message(paste("No jobs found for", company_name), level = "WARN")
    return(data.frame())
  }
  
  # Optionally fetch full details for each job
  if (fetch_details) {
    log_message(paste("Fetching details for", nrow(jobs), "jobs"))
    
    # Add progress indicator
    pb <- txtProgressBar(min = 0, max = nrow(jobs), style = 3)
    
    jobs <- jobs %>%
      rowwise() %>%
      mutate({
        details <- scrape_workday_job_details(job_url)
        setTxtProgressBar(pb, cur_group_id())
        details
      }) %>%
      ungroup()
    
    close(pb)
  }
  
  # Add company name and scrape metadata
  jobs <- jobs %>%
    mutate(
      company_name = company_name,
      scraped_at = Sys.time()
    )
  
  end_time <- Sys.time()
  duration <- as.numeric(difftime(end_time, start_time, units = "secs"))
  
  log_message(paste("Completed", company_name, "in", round(duration, 2), "seconds"))
  log_message(paste("Total jobs:", nrow(jobs)))
  
  return(jobs)
}
