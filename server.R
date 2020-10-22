library(shiny)
library(shinydashboard)
library(shinymanager)
library(DT)
library(purrr)
library(magrittr)

server <- function(session, input, output) {
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
      # ordinary users
      data <- readRDS(paste0("data_", res_auth$user, ".rds"))
      # find out which content to load first
      session_info$current <- map_int(questions, function(x) {
        tmp <- data[[x$value]]
        # return last content if all finished
        if (!any(is.na(tmp)))
          return(length(tmp))
        # return first unfinished content by default
        which(is.na(tmp))[1]
      }) %>%
        min(.)
      # draw navigation bar
      output$nav <- renderUI({
        box(
          column(
            tags$div(class = "nav", actionButton("go_prev", "< Previous", class = "btn-sm")),
            width = 4
          ),
          column(
            tags$div(class = "nav", textOutput("progress")),
            width = 4, align = "center"
          ),
          column(
            tags$div(class = "nav", actionButton("go_next", "Next >", class = "btn-sm")),
            width = 4, align = "right"
          ),
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
      observeEvent(session_info$current, {
        toggleState("go_prev", condition = session_info$current > 1)
        toggleState("go_next", condition = session_info$current < nrow(data))
      })
      # draw content
      output$data <- renderUI({
        if (type == "image") {
          div(
            a(
              href = data$data[session_info$current], target = "_blank", 
              img(class = "media-content", src = data$data[session_info$current])
            ), 
            style = "text-align: center;"
          )
        } else if (type == "text") {
          div(data$data[session_info$current])
        }
      })
      # draw questions
      observeEvent(session_info$current, {
        removeUI(selector = "#questions > .col-sm-12", multiple = TRUE)
        ui <- map(questions, function(x) {
          selected <- data[[x$value]][session_info$current]
          radioButtons(inputId = x$value, label = x$text, choices = x$choice, 
                       selected = ifelse(is.na(selected), x$choice[1], selected))
        })
        insertUI(
          selector = "#questions",
          ui = box(
            ui,
            checkboxInput("problem", "Mark as problematic", value = data[["problem"]][session_info$current]),
            actionButton("submit", "Submit"),
            width = 12
          )
        )
      })
      # submit behaviour
      observeEvent(input$submit, {
        # log choices
        for (x in questions) {
          data[[x$value]][session_info$current] <<- input[[x$value]]
        }
        # log problem flag
        data[["problem"]][session_info$current] <<- input[["problem"]]
        # save
        saveRDS(data, paste0("data_", res_auth$user, ".rds"), compress = FALSE)
        # to next
        if (session_info$current != nrow(data)) {
          session_info$current <- session_info$current + 1
        } else if (all(map_lgl(questions, function(x) !any(is.na(data[[x$value]]))))) {
          # til end and finished all 
          showModal(modalDialog(
            title = "Congratulation",
            "You have finished marking all the content!",
            easyClose = TRUE,
            footer = NULL
          ))
        } else {
          # til end and unfinished
          showModal(modalDialog(
            title = "Warning",
            "You have not finished marking all the content! Please check again.",
            easyClose = TRUE,
            footer = NULL
          ))
        }
      })
    } else if (res_auth$admin == "TRUE") {
      # admin user
      users <- read_db_decrypt("user.sqlite")
      non_admin <- users$user[users$admin == "FALSE"]
      # draw navigation bar
      output$nav <- renderUI({
        box(
          column(
            tags$div(class = "nav", selectInput("user", "Select user:", non_admin, width = "110px")),
            width = 12, align = "center"
          ),
          width = 12
        )
      })
      # draw result table
      output$data <- renderUI({
        dataTableOutput("result")
      })
      output$result <- renderDataTable({
        data <- readRDS(paste0("data_", input$user, ".rds"))
        datatable(data, rownames = FALSE, escape = FALSE,
                  selection = list(mode = "single"), style = "bootstrap",
                  options = list(orderClasses = TRUE))
      })
    }
  }, ignoreNULL = TRUE)
}

shinyServer(server)
