shinyUI(fluidPage(
  
  # Include googel analytics script (updated 8.10.2014)
  # tags$head(includeScript("google-analytics.js")),
  
  # Application title
  titlePanel("MyBike (under development)"),
  
  sidebarLayout(
    sidebarPanel(
      # Adjust size
      tags$head(
        tags$style(type="text/css", "select { width: 200px; }"),
        tags$style(type="text/css", "textarea { max-width: 180px; }"),
        tags$style(type="text/css", ".jslider { max-width: 200; }"),
        tags$style(type='text/css', ".well { max-width: 200px; }"),
        tags$style(type='text/css', ".span4 { max-width: 200px; }")
      ),
      helpText("Here you can study your cycling routes and analyze them together with some open data sources."),
      p("Made by", a("@ouzor", href="https://twitter.com/ouzor")),
      #       helpText(a("Datalähde: Sotkanet", href="http://www.sotkanet.fi", target="_blank")),
      p("Source code in", a("GitHub", href="https://github.com/ouzor/mybike", target="_blank")),
      p("Data sources used: ADD")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Route",
                 h3("Define cycling route"),
                 selectInput("routeSource", "Route source", choices=c("Journey Planner API" = "journeyplanner", "GPX upload" = "gpxupload"), selected="journeyplanner"),
                 conditionalPanel(
                   condition = "input.routeSource == 'journeyplanner'",
                   #                    div(class="row",
                   #                        div(class="span2", textInput("start.address", "Start address", value = "Kamppi")),
                   #                        div(class="span2", textInput("end.address", "End address", value = "Tapiola"))
                   #                    ),
                   textInput("start.address", "Start address", value = "Kamppi"),
                   textInput("end.address", "End address", value = "Tapiola"),
                   textInput("via.addresses", "Via (separate with ';')", value= "Leppävaara;Malmi"),
                   #                  submitButton("Submit"),
                   # http://stackoverflow.com/questions/17704182/r-submitbutton-and-conditionalpanel
                   h3("Route info"),
                   sliderInput("cycling.speed", "Cycling speed (km/h)", min=10, max=40, value=20, step = 5),
                   sliderInput("step.interval", "Waypoint interval (minutes)", min=60, max=120, value=60, step=60),
                   p(htmlOutput("route_info")),
                   plotOutput("route_map_ggplot")
#                    h3("Plot route profile"),
#                    p("Note! x-axis needs to be fixed to match the distance!"),
#                    plotOutput("route_profile_ggplot")
                 ),
                 conditionalPanel(
                   condition = "input.routeSource == 'gpxupload'",
                   h3("Feature to be implemented")
                 )
        ),
        tabPanel("Forecast",
                 selectInput("forecastSource", "Weather forecast source",
                             choices=c("Forecast.io" = "fio", "FMI" = "fmi"), selected="fio"),
                 conditionalPanel(
                   condition = "input.forecastSource == 'fio'",
                   h3("Weather forecast table"),
                   sliderInput("forecast.length", "Number of hours to show",
                               min=1, max=10, value=5, step = 1),
                   htmlOutput("fio_gvistable")
                   
                   #                   tableOutput("fio_xtable")
                 ),
                 
                 conditionalPanel(
                   condition = "input.forecastSource == 'fmi'",
                   h3("Feature to be implemented"),
                   htmlOutput("fmi_gvistable")
                 ),
                 h3("TODO"),
                 p("- Fix time to start from the correct hour"),
                 p("- Implement visualization of relevant data")
        )
#         tabPanel("Accidents",
#                  h3("Plot bike accidents data and your route"),
#                  p("Note that accident data is only available in Helsinki!"),
#                  plotOutput("accidents_plot"),
#                  h3("TODO"),
#                  p("- Add filter for accident type")
# 
#         ),
#         tabPanel("Cycling analysis",
#                  h3("TODO"),
#                  p("- Process, aalyze and visualize data from a set of gpx measurements"),
#                  p("- Combine with accident data")
#         ),
#         tabPanel("Information",
#                  h3("Idea"),
#                  p("To be added"),
#                  h3("Data sources"),
#                  p("To be added: journey planner, forecast.io, fmi, accidents from hri"),
#                  p("New data: digitraffic?")
#         )
      )
    )
  )
))