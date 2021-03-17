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
    sqlite_path = "user.sqlite",
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
# Function to generate javascript for detecting key press
.generate_js <- function(config) {
  # short cut keys for choice selection
  choice <- map(config$question, function(x) {
    map_chr(x$choice, function(y) {
      if ("keycode" %in% names(y)) {
        sprintf(
          "if (e.keyCode == %d) {\n Shiny.onInputChange('choiceKey', ['%s', '%s']);\n}", 
          y$keycode, x$value, y$value
        )
      } else {
        NA
      }
    })
  })
  choice <- unlist(choice)
  choice <- choice[!is.na(choice)]
  # navigation short cut keys
  if ("shortcut" %in% names(config)) {
    general <- map_chr(config$shortcut, function(x) {
      sprintf(
        "if (e.keyCode == %d) {\n Shiny.onInputChange('%s', Math.random());\n}", 
        x$keycode, ifelse(x$action == "submit", "submitKey", 
                          ifelse(x$action == "prev", "prevKey", "nextKey"))
      )
    })
  } else {
    general <- c()
  }
  # merge and generate js file
  js <- c(choice, general)
  if (length(js)) {
    js <- paste0(js, collapse = " else ")
    js <- paste0("$(document).on('keyup', function(e) {\n", js, "});")
    writeLines(js, "www/shortcut.js")
  } else {
    writeLines("", "www/shortcut.js")
  }
}
# Function to read config.yaml and initialize app
initialize_app <- function(file = "config.yaml") {
  config <- read_yaml(file)
  .create_users(config)
  .generate_js(config)
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
    # distribute same data for every user for reliability test
    for (x in non_admin$user) {
      tmp <- data.frame(user = rep(x, nrow(data)))
      saveRDS(cbind(result, tmp), paste0("data_", x, ".rds"), compress = FALSE)
    }
  }
}
