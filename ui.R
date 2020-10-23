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
  # monitor enter key press
  tags$script('$(document).on("keyup", function(e) {
  if(e.keyCode == 13){
    Shiny.onInputChange("enterkey", Math.random());
  }
  });'),
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
