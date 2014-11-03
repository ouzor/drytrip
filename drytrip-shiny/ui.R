shinyUI(fluidPage(
  
  # Include googel analytics script
  tags$head(includeScript("google-analytics.js")),
  
  # Application title
  titlePanel("DryTrip - Cycling trip planner"),
  
  sidebarLayout(position="right",
    sidebarPanel(
      # Adjust size
      tags$head(
        tags$style(type="text/css", "select { width: 280px; }"),
        tags$style(type="text/css", "textarea { max-width: 260px; }"),
        tags$style(type="text/css", ".jslider { max-width: 280; }"),
        tags$style(type='text/css', ".well { max-width: 280px; }"),
        tags$style(type='text/css', ".span4 { max-width: 280px; }")
      ),
      h4("Plan your cycling trips based on weather forecast!"),
      p("Data sources and R packages used:"),
      tags$ul(
        tags$li(a("Reittiopas API", href="http://developer.reittiopas.fi/pages/en/home.php")),
        tags$li(a("Stamen maps", href="http://maps.stamen.com/#terrain/12/37.7706/-122.3782"),
                "with",  a("ggmap", href="https://sites.google.com/site/davidkahle/ggmap")),
        tags$li(a("Forecast API", href="https://developer.forecast.io/"),
                "with", a("Rforecastio", href="https://github.com/ouzor/Rforecastio")),
        tags$li(a("FMI Open Data", href="http://en.ilmatieteenlaitos.fi/open-data-manual-fmi-wfs-services"),
                "with", a("fmi", href="https://github.com/ropengov/fmi"), "(not functional yet!)")
      ),
      p("Source code and development plans at", a("GitHub", href="https://github.com/ouzor/drytrip", target="_blank")),
      p("License:", a("CC BY 4.0", href="http://creativecommons.org/licenses/by/4.0/")),
      p("Made by", a("@ouzor", href="https://twitter.com/ouzor"))
    ),
    mainPanel(
      #       tabsetPanel(
      #         tabPanel("Route",
      
      h3("1. Define cycling route"),
      selectInput("routeSource", "Route source", choices=c("Reittiopas API" = "reittiopas", "GPX upload" = "gpxupload"), selected="reittiopas"),
      
      conditionalPanel(
        condition = "input.routeSource == 'reittiopas'",
        textInput("start.address", "Start address", value = "Kamppi"),
        textInput("end.address", "End address", value = "Kamppi"),
        textInput("via.addresses", "Via (separate with ';')", value= "Olari;Nuuksio;Leppävaara"),
        #  submitButton("Submit"),
        # http://stackoverflow.com/questions/17704182/r-submitbutton-and-conditionalpanel
        h3("2. Check route info"),
        sliderInput("cycling.speed", "Cycling speed (km/h)", min=10, max=40, value=20, step = 5),
        # sliderInput("waypoint.interval", "Waypoint interval (minutes)", min=60, max=120, value=60, step=60),
        htmlOutput("route_info"),
        h4("Route map and waypoints"),
        p("Note! Waypoints are currently set every one hour. This can be adjusted in the future."),
        plotOutput("route_map_ggplot"),
        #                    h3("Plot route profile"),
        #                    p("Note! x-axis needs to be fixed to match the distance!"),
        #                    plotOutput("route_profile_ggplot")
        h3("3. Check weather forecast"),
        selectInput("forecastSource", "Weather forecast source",
                    choices=c("Forecast.io" = "fio", "FMI" = "fmi"), selected="fio"),
        conditionalPanel(
          condition = "input.forecastSource == 'fio'",
          sliderInput("forecast.length", "Number of starting hours to show",
                      min=1, max=10, value=5, step = 1),
          h4("Weather forecast at each waypoint for different starting hours"),
          uiOutput("fio_plot_ui"), # plotOutput("fio_plot")
          p("Known issues: Start times are in GMT+0 time zone (two hours less than in Finland). Latest start time is 24:00.")
        ),
        
        conditionalPanel(
          condition = "input.forecastSource == 'fmi'",
          h3("FMI weather forecast feature to be implemented!")
          #       htmlOutput("fmi_gvistable")
        )
      ),
      
      conditionalPanel(
        condition = "input.routeSource == 'gpxupload'",
        h3("GPX upload feature to be implemented!")
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