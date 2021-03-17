library(shiny)
library(shinydashboard)
library(shinymanager)
library(shinyjs)

load("config.rda")

header <- dashboardHeader(
  title = title,
  tags$li(
    class = "dropdown",
    tags$li(class = "dropdown", uiOutput("logged_user")),
    tags$li(class = "dropdown", actionLink("logout", "Logout"))
  )
)
sidebar <- dashboardSidebar(disable = TRUE)
body <- dashboardBody(
  tags$link(rel = "stylesheet", type = "text/css", href = "styles.css"),
  tags$script(src = "shortcut.js"),
  fluidRow(
    # navigation
    uiOutput("nav"),
    # media
    uiOutput("data"),
    # questions
    tags$div(id = "questions")
  )
)

ui <- fluidPage(
  useShinyjs(),
  tags$head(tags$link(rel = "shortcut icon", href = "favicon.ico")),
  dashboardPage(header, sidebar, body, skin = skin)
)

secure_app(ui, enable_admin = TRUE)
