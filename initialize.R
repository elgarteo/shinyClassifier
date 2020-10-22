library(yaml)
library(purrr)
library(shinymanager)

# Function to create user data table
.create_users <- function(config) {
  credentials <- map_dfr(config$user, function(x) {
    map_dfc(x, function(y) y)
  })
  create_db(
    credentials_data = credentials,
    sqlite_path = "user.sqlite", # will be created
  )
}
# Function to save config
.create_config <- function(config) {
  title <- config$title
  questions <- map(config$question, function(x) {
    choice <- map_chr(x$choice, function(y) y$value)
    choice <- setNames(choice, map_chr(x$choice, function(y) y$name))
    x$choice <- choice
    x
  })
  type <- config$type
  skin <- config$skin
  save(title, questions, type, skin, file = "config.rda", compress = FALSE)
}
# Function to read config.yaml and initialize app
initilize_app <- function(file = "config.yaml") {
  config <- read_yaml(file)
  .create_users(config)
  .create_config(config)
}
# Function to prepare data
prep_data <- function(file = "data.csv", dist = TRUE) {
  # read data and config
  data <- read.csv(file)
  load("config.rda")
  users <- read_db_decrypt("user.sqlite")
  non_admin <- users[users$admin == "FALSE", ]
  # add choice columns
  result <- map_dfc(questions, function(x) {
    tmp <- data.frame(choice = rep(NA, nrow(data)))
    names(tmp) <- x$value
    tmp
  })
  result <- cbind(data, result)
  # add problem column
  result <- cbind(result, data.frame(problem = rep(FALSE, nrow(data))))
  if (dist) {
    # randomly assign data for each user
    pool <- 1:nrow(result)
    remainder <- nrow(result) %% nrow(non_admin)
    for (i in seq_along(non_admin$user)) {
      # compute sample size for each user
      if (i <= remainder)
        n <- ceiling(nrow(result) / nrow(non_admin))
      else
        n <- floor(nrow(result) / nrow(non_admin))
      # randomly assign index to user
      u <- non_admin$user[i]
      idx <- sample(pool, n)
      pool <- pool[!pool %in% idx]
      tmp <- data.frame(user = rep(u, n))
      saveRDS(cbind(result[idx, ], tmp), paste0("data_", u, ".rds"), compress = FALSE)
    }
  } else {
    # distribute same data for each user for reliability test
    for (x in non_admin$user) {
      tmp <- data.frame(user = rep(x, nrow(data)))
      saveRDS(cbind(result, tmp), paste0("data_", x, ".rds"), compress = FALSE)
    }
  }
}
