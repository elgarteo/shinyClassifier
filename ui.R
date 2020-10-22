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
  fluidRow(
    # navigation
    uiOutput("nav"),
    # media
    box(uiOutput("data"), width = 12),
    # questions
    tags$div(id = "questions")
  )
)

ui <- fluidPage(
  useShinyjs(),
  dashboardPage(header, sidebar, body, skin = skin)
)

secure_app(ui, enable_admin = TRUE)
