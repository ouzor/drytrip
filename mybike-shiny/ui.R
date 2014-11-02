shinyUI(fluidPage(
  
  # Include googel analytics script (updated 8.10.2014)
  # tags$head(includeScript("google-analytics.js")),
  
  # Application title
  titlePanel("Cycling trip planner"),
  
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
      helpText("Plan your cycling trips based on weather forecast!"),
      p("Made by", a("@ouzor", href="https://twitter.com/ouzor")),
      p("Source code in", a("GitHub", href="https://github.com/ouzor/mybike", target="_blank")),
      p("Data sources used: ADD")
    ),
    mainPanel(
      #       tabsetPanel(
      #         tabPanel("Route",
      
      h3("Define cycling route"),
      selectInput("routeSource", "Route source", choices=c("Journey Planner API" = "journeyplanner", "GPX upload" = "gpxupload"), selected="journeyplanner"),
      
      conditionalPanel(
        condition = "input.routeSource == 'journeyplanner'",
        textInput("start.address", "Start address", value = "Kamppi"),
        textInput("end.address", "End address", value = "Kamppi"),
        textInput("via.addresses", "Via (separate with ';')", value= "Olari;Nuuksio;Leppävaara")
        #  submitButton("Submit"),
        # http://stackoverflow.com/questions/17704182/r-submitbutton-and-conditionalpanel
      ),
      
      conditionalPanel(
        condition = "input.routeSource == 'gpxupload'",
        h3("Feature to be implemented")
      ),
      
      
      h3("Route info"),
      sliderInput("cycling.speed", "Cycling speed (km/h)", min=10, max=40, value=20, step = 5),
      # sliderInput("waypoint.interval", "Waypoint interval (minutes)", min=60, max=120, value=60, step=60),
      htmlOutput("route_info"),
      h4("Route map with waypoints every one hour"),
      plotOutput("route_map_ggplot"),
      #                    h3("Plot route profile"),
      #                    p("Note! x-axis needs to be fixed to match the distance!"),
      #                    plotOutput("route_profile_ggplot")
      
      h3("Weather forecast"),
      selectInput("forecastSource", "Weather forecast source",
                  choices=c("Forecast.io" = "fio", "FMI" = "fmi"), selected="fio"),
      conditionalPanel(
        condition = "input.forecastSource == 'fio'",
        sliderInput("forecast.length", "Number of starting hours to show",
                    min=1, max=10, value=5, step = 1),
        h4("Weather forecast at each waypoint for different starting hours"),
        p("Note! Start times are in GMT+0 time zone currently, need to ne fixed!"),
        uiOutput("fio_plot_ui") # plotOutput("fio_plot")
      ),
      
      conditionalPanel(
        condition = "input.forecastSource == 'fmi'",
        h3("Feature to be implemented")
        #       htmlOutput("fmi_gvistable")
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
      #         )
      #      )
    )
  )
))