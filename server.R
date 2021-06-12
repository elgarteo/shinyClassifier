library(shiny)
library(shinydashboard)
library(shinymanager)
library(DT)
library(purrr)
library(magrittr)

function(session, input, output) {
  # check credentials
  res_auth <- secure_server(
    check_credentials = check_credentials("user.sqlite")
  )
  # draw interface
  session_info <- reactiveValues()
  observeEvent(res_auth, {
    # header
    req(res_auth$user)
    output$logged_user <- renderUI({
      div(class = "username", icon("user"), " ", res_auth$user)
    })
    observeEvent(input$logout, {
      session$reload()
    })
    load("config.rda")
    # body
    if (res_auth$admin == "FALSE") {
      ##----- interface for ordinary user -----
      data_file <- paste0("data_", res_auth$user, ".rds")
      if (file.exists(data_file)) {
        data <- readRDS(data_file)
        # find out which content to load first
        session_info$current <- ifelse(any(data$completed), max(which(data$completed)) + 1, 1)
        # draw navigation bar
        output$nav <- renderUI({
          if (session_info$current > 1) {
            prev_btn <- tags$div(class = "col-xs-4 nav-bar text-left", 
                                 actionButton("go_prev", "< Previous", class = "btn-sm", width = "80px"))
          } else {
            prev_btn <- tags$div(class = "col-xs-4 nav-bar text-left", 
                                 disabled(actionButton("go_prev", "< Previous", class = "btn-sm", width = "80px")))
          }
          if (session_info$current < nrow(data)) {
            next_btn <- tags$div(class = "col-xs-4 nav-bar text-right", 
                                 actionButton("go_next", "Next >", class = "btn-sm", width = "80px"))
          } else {
            next_btn <- tags$div(class = "col-xs-4 nav-bar text-right", 
                                 disabled(actionButton("go_next", "Next >", class = "btn-sm", width = "80px"))) 
          }
          box(
            class = "nav-box",
            prev_btn,
            tags$div(class = "col-xs-4 nav-bar text-center", textOutput("progress")),
            next_btn,
            width = 12
          )
        })
        output$progress <- renderText({
          paste0(session_info$current, " of ", nrow(data))
        })
        observeEvent(input$go_prev, {
          session_info$current <- session_info$current - 1
        })
        observeEvent(input$go_next, {
          session_info$current <- session_info$current + 1
        })
        # draw content
        output$data <- renderUI({
          if (type == "image") {
            box(
              div(
                a(href = data$data[session_info$current], target = "_blank", 
                  img(class = "media-content", src = data$data[session_info$current])
                ),
                style = "text-align: center;"
              ), width = 6
            )
          } else if (type == "text") {
            box(
              div(data$data[session_info$current])
            )
          }
        })
        # draw questions
        observeEvent(session_info$current, {
          removeUI(selector = "#questions > .col-sm-6", multiple = TRUE)
          ui <- map(questions, function(x) {
            selected <- data[[x$value]][[session_info$current]]
            if (x$type == "checkbox") {
              checkboxGroupInput(inputId = x$value, label = x$text, choices = x$choice, inline = TRUE,
                                 selected = ifelse(is.na(selected), x$choice[1], selected))
            } else if (x$type == "radio") {
              radioButtons(inputId = x$value, label = x$text, choices = x$choice, inline = TRUE,
                           selected = ifelse(is.na(selected), x$choice[1], selected))
            } else if (x$type == "selectize") {
              selectInput(inputId = x$value, label = x$text, choices = x$choice, 
                          selected = ifelse(is.na(selected), x$choice[1], selected),
                          multiple = ifelse(is.null(x$multiple), FALSE, x$multiple))
            }
          })
          insertUI(
            selector = "#questions",
            ui = box(
              ui, hr(),
              checkboxInput("problem", "Mark as problematic", 
                            value = ifelse(is.na(data$problem[session_info$current]), 
                                           FALSE, data$problem[session_info$current])),
              actionButton("submit", "Submit"),
              width = 6
            )
          )
        })
        # submit behaviour
        observeEvent(input$submit, {
          # log choices and mark completed
          for (x in questions) {
            ans <- input[[x$value]]
            if (length(ans) == 0) {
              data[[x$value]][session_info$current] <<- NA
            } else if (length(ans) == 1) {
              data[[x$value]][session_info$current] <<- ans
            } else {
              data[[x$value]][session_info$current] <<- I(list(ans))
            }
            data$completed[session_info$current] <<- TRUE
          }
          # log problem flag
          data[["problem"]][session_info$current] <<- input[["problem"]]
          # save
          saveRDS(data, paste0("data_", res_auth$user, ".rds"), compress = FALSE)
          # to next item
          if (session_info$current != nrow(data)) {
            session_info$current <- session_info$current + 1
          } else if (all(map_lgl(questions, function(x) !any(is.na(data[[x$value]]))))) {
            # til end and finished all 
            showModal(modalDialog(
              title = "Congratulation",
              "You have finished classifying all the content.",
              easyClose = TRUE, footer = NULL
            ))
          } else {
            # til end and unfinished
            showModal(modalDialog(
              title = "Warning",
              "You have not finished classifying all the content. Please check again.",
              easyClose = TRUE, footer = NULL
            ))
          }
        })
        # monitor key press
        observeEvent(input$submitKey, {
          click("submit")
        })
        observeEvent(input$prevKey, {
          click("go_prev")
        })
        observeEvent(input$nextKey, {
          click("go_next")
        })
        observeEvent(input$choiceKey, {
          if (input$choiceKey[3] == "radio") {
            updateRadioButtons(session, input$choiceKey[1], selected = input$choiceKey[2])
          } else if (input$choiceKey[3] == "checkbox") {
            to_select <- c(input[[input$choiceKey[1]]], input$choiceKey[2])
            updateCheckboxGroupInput(session, input$choiceKey[1], selected = to_select)
          } else if (input$choiceKey[3] == "selectize") {
            if (input$choiceKey[4] == "TRUE") {
              to_select <- c(input[[input$choiceKey[1]]], input$choiceKey[2])
              updateSelectizeInput(session, input$choiceKey[1], selected = to_select)
            } else {
              updateSelectizeInput(session, input$choiceKey[1], selected = input$choiceKey[2])
            }
          }
        })
      } else {
        # No data file found for user
        showModal(modalDialog(
          title = "Warning",
          "No task has been assigned to you. Please contact the administrator.",
          easyClose = TRUE, footer = NULL
        ))
      }
    } else if (res_auth$admin == "TRUE") {
      ##----- interface for admin user -----
      users <- read_db_decrypt("user.sqlite")
      non_admin <- users$user[users$admin == "FALSE"]
      # draw navigation bar
      output$nav <- renderUI({
        box(
          column(
            tags$div(class = "nav", selectInput("user", "Select user:", non_admin, width = "110px")),
            htmlOutput("progress"),
            width = 12, align = "center"
          ),
          width = 12
        )
      })
      # draw result table
      output$data <- renderUI({
        box(
          dataTableOutput("result"),
          style = "overflow-x: scroll;", width = 12
        )
      })
      observeEvent(input$user, {
        removeUI(selector = "#questions > .col-sm-12", multiple = TRUE)
        data_file <- paste0("data_", input$user, ".rds")
        if (file.exists(data_file)) {
          data <- readRDS(data_file)
          # update progress
          output$progress <- renderText({
            sprintf("%i out of %i completed</br>Last access: %s", 
                    sum(data$completed),  nrow(data), file.info(data_file)$ctime)
          })
          # render table
          output$result <- renderDataTable({
            if (type == "image")
              data$data <- paste0("<a href='", data$data, "' target='_blank'><img src='",
                                  data$data, "' class='table-thumbnail'/></a>")
            datatable(data, rownames = FALSE, escape = FALSE,
                      selection = list(mode = "single"), style = "bootstrap",
                      options = list(orderClasses = TRUE))
          })
          # download buttons
          if (any(map_lgl(data, is.list))) {
            # refuse to draw download button if data is nested
            insertUI(
              selector = "#questions",
              ui = box(
                p("The data is nested as there exists at least one question allowing selection of multiple answers.
                  Nested data cannot be exported as CSV. Please retrieve the RDS files from backend instead."),
                width = 12
              )
            )
          } else {
            # draw download buttons if data not nested
            insertUI(
              selector = "#questions",
              ui = box(
                downloadButton("export_all", "Download all data"),
                downloadButton("export_user", "Download user data"),
                width = 12
              )
            )
            output$export_all <- downloadHandler(
              filename = paste0("data_", format(Sys.time(), "%Y%m%d_%H%M"), ".csv"),
              content = function(file) {
                files <- list.files(pattern = "data_")
                data <- map_dfr(files, function(x) {
                  readRDS(x)
                })
                write.csv(data, file, row.names = FALSE)
              }
            )
            output$export_user <- downloadHandler(
              filename = paste0("data_", input$user, "_", format(Sys.time(), "%Y%m%d_%H%M"), ".csv"),
              content = function(file) {
                data <- readRDS(paste0("data_", input$user, ".rds"))
                write.csv(data, file, row.names = FALSE)
              }
            )
          }
        } else {
          # No data file found for user
          showModal(modalDialog(
            title = "Warning",
            "No task has been assigned to this user.",
            easyClose = TRUE, footer = NULL
          ))
          output$result <- renderDataTable({})
        }
      })
    }
  }, ignoreNULL = TRUE)
}
