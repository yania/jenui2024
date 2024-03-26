# Load packages
library(httr)
library(rlist)
library(jsonlite)
#library(listviewer)
library(tidyverse)

args = commandArgs(trailingOnly=TRUE)

# Base enpoint as variable
url_sonar <- 'https://sonarqube.your.url/' # Your Sonar instance
# Authentication with token generation in SonarQube instance
token<- 'your security token generated on your sonarqube' # Your token

# Our contests is for teams not individual
teams_ids <- c( '01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19','20') # 20 is for testing

# There is a rule, the teams in the contests must assing a key to the sonarqube project 
# For example, team 01 in course 22-23 must assign their project the key your.prefix.ds22-23-01
projects_key_prefix <- 'your.prefix.ds22-23-' 

# test if there is at least one argument: if not, return an error
if (length(args)>1) {
  stop("Use with none or one argument", call.=FALSE)
} else if (length(args)==1) {
  updated_projectKey <- args[1]
  login <- updated_projectKey
  login <- gsub(projects_key_prefix, "", login)
#  login <- gsub(projects_key_suffix, "", login)
  if (! login %in% teams_ids) {
    stop("Use with a project according key naming conventions in this contest")
  }
}

sonar_web_api_request_get <- function(command, parameters, pageIndex='') {
  petition <- paste0(url_sonar, command, parameters, pageIndex)
  # Construct API request with authentication
  GET(url = petition, authenticate(user=token,password = '') )
}

# Command
to_obtain_all_metrics <- 'api/metrics/search?'
# Parameters
params <- ''

#Inicialization
i <- 1
metrics_data_frame <- NULL
repeat {
  # Construct API request with authentication and pagination
  pagination <- paste0('p=', i)
  metrics <- sonar_web_api_request_get(to_obtain_all_metrics, params, pagination)
  
  ## Examine response components
  #str(metrics)
  #names(metrics)
  # Process API request content 
  metrics_content <- content(metrics)
  ## Examine response content
  # jsonedit(metrics_content, mode='view')
  
  # Apply function across all elements (each metrics in Sonar)
  # to extract the key, name, description and type
  metrics_data_frame_sub <- lapply(metrics_content$metrics, function(x) {
    df <- data_frame(key          = x$key,
                     name         = x$name,
                     type         = x$type
    )
  }) %>% bind_rows()
  metrics_data_frame <- bind_rows(metrics_data_frame, metrics_data_frame_sub)
  # ps is pagesize in this API
  how_many_pages <- metrics_content$total/metrics_content$ps
  
  if (i < how_many_pages) {i <- i+1}
  else {break}
}

# UnComment/Comment to view/hide data frame
#View(metrics_data_frame)
#write.csv(metrics_data_frame, file = '/your/path/results-sonarwebhook/metrics.csv', row.names=FALSE)

# Obtaining all project with prefix in name. It is case insensitive.
# Command
obtain_projects <- 'api/projects/search?'
# Parameters
params <- paste0('q=', projects_key_prefix)

# Construct API request with authentication. There is no pagination in result
pagination <- ''
projects <- sonar_web_api_request_get(obtain_projects, params, pagination)

# # Examine response components
# names(projects)
# Process API request content
projects_content <- content(projects)

# Uncomment for json fancy visualization
#jsonedit(projects_content, mode='view')

# Apply function across all elements (each project in SonarQube server in our study) 
# to extract the key, id and name
projects_data_frame <- lapply(projects_content$components, function(x) {
  df <- data_frame(key          = x$key,
                   name         = x$name,
                   lastAnalysisDate = x$lastAnalysisDate
  )
}) %>% bind_rows()

projects_data_frame <- filter(projects_data_frame, grepl('your.prefix.ds22-23*',key))

# Uncomment to view the data frame  
#View(projects_data_frame)

# Obtain some metrics to project level of given projects
# iterate over de projectKeys and integrate results
projectKeys <- projects_data_frame$key

# Define which metrics are going to be obtained
metricsKeys <- c(
                 'lines', 'ncloc', 'comment_lines', 'classes',
                 'violations','blocker_violations','major_violations','minor_violations','info_violations',
                 'vulnerabilities','bugs','code_smells',
                 'duplicated_blocks', 'duplicated_lines','duplicated_lines_density',
                 'sqale_rating','sqale_index','sqale_debt_ratio', 'effort_to_reach_maintainability_rating_a',
		 'reliability_remediation_effort', 'security_remediation_effort',
		 'complexity', 'cognitive_complexity'
                 #,
                 #'tests','test_success_density',
                 #'coverage','line_coverage',
                 #'branch_coverage','conditions_to_cover'
)

# Command
to_obtain_measures_of_some_metrics <- 'api/measures/component?'
# Parameters: projectKey and metricKeys are used as parameters

# Initialization
project_measures_data_frame <- NULL
projects_measures_data_frame <- NULL

for (projectKey in projectKeys) {
  params_list <- list(component = paste0('componentKey=', projectKey), 
                      metricsKeys = paste0('metricKeys=',paste0(metricsKeys, collapse=','))
  )
  params <- paste0(params_list, collapse='&')
  # Construct API request with authentication (no pagination)
  measures <- sonar_web_api_request_get(to_obtain_measures_of_some_metrics,params)
  
  # Inicialization (measures per project)
  measures_data_frame <- NULL
  ## Examine response components
  #names(measures)
  # Process API request content 
  measures_content <- content(measures)
  ## Examine response content
  #jsonedit(measures_content, mode='view')
  
  # Apply function across all list elements (each metric in the request)
  # to extract the metric name and measure value
  measures_data_frame <- lapply(measures_content$component$measures, function(x) {
    df <- data_frame(
      metric = x$metric,
      value = x$value
    )
  }) %>% bind_rows() %>% spread(metric, value, fill=0) 
  
  #measures_data_frame$project <- c(projectKey)
  
  #change column order in data frame
  #column_order <- c("project", metricsKeys)
  #project_measures_data_frame <- measures_data_frame[, column_order]
  projects_measures_data_frame <- bind_rows(projects_measures_data_frame, measures_data_frame)
}

# UnComment/Comment to view/hide data frame
# View(projects_measures_data_frame)

# Response of the request is treated as character type. Convert the type of measures' values to numeric 
projects_measures_data_frame_asnumbers <- modify_at(projects_measures_data_frame, metricsKeys, as.numeric)
projects_measures_data_frame_asnumbers <- cbind(projects_measures_data_frame_asnumbers, projectKeys)
projects_measures_data_frame_asnumbers[is.na(projects_measures_data_frame_asnumbers)] <- 0
#projects_measures_data_frame_asnumbers$ranking_points <- with(projects_measures_data_frame_asnumbers, 3*branch_coverage + (60*5-sqale_index) + (100-duplicated_lines_density))
projects_measures_data_frame_asnumbers$ranking_points <- with(projects_measures_data_frame_asnumbers, sqale_debt_ratio+duplicated_lines_density+reliability_remediation_effort+security_remediation_effort)
# UnComment/Comment to view/hide data frame
#View(projects_measures_data_frame_asnumbers)


# Creating new columns
#projects_measures_data_frame_asnumbers$comment_density <- with(projects_measures_data_frame_asnumbers, comment_lines/ncloc)
# projects_measures_data_frame_asnumbers$smells_density <- with(projects_measures_data_frame_asnumbers, code_smells/ncloc)
#projects_measures_data_frame_asnumbers$code_to_test <- with(projects_measures_data_frame_asnumbers, tests/ncloc)

# UnComment/Comment to view/hide data frame
# View(projects_measures_data_frame_asnumbers)

if (length(args)==1) {
  projects_measures_data_frame_asnumbers <- dplyr::filter(projects_measures_data_frame_asnumbers, projectKeys == updated_projectKey)
}

#home <- try(system("echo $HOME", intern = TRUE))
#pathToRanking <- paste0(home, '/ranking.csv')
basePathToRanking <- '/your/leaderboard/results-sonarwebhook/ranking-'
pathToRanking <- paste0(basePathToRanking, updated_projectKey, '.csv')
#write.csv(projects_measures_data_frame_asnumbers, file = pathToRanking, row.names=FALSE)
write.table(projects_measures_data_frame_asnumbers, file=pathToRanking, row.names=FALSE, col.names=FALSE, sep=",")
write.table(projects_measures_data_frame_asnumbers, file='concabecera', row.names=FALSE, col.names=TRUE, sep=",")
cmd <- paste0('/your/leaderboard/submit2checkedleaderboard.sh $(< ',pathToRanking,')')
#cmd <- paste0('/your/leaderboard/submit2leaderboard.sh $(< ',pathToRanking,')')
print(cmd)
system(cmd)
