library("rjson")
library("RCurl")
library("reshape2")
library("ggplot2")
library("ggmap")
library("Rforecastio")
library("xtable")
library("googleVis")

fio.api.key <- scan(file="dark_sky_api.txt", what="character")


# theme_set(theme_grey(20))
# library(grid)

# Source aux functions
source("functions.R")

# Load helsinki region map
load("helsinki_map1.RData")

# Load bicycle accident data (for Helsinki only)
load("bike_accidents.RData")

shinyServer(function (input, output) {
  
  ## CYCLING ROUTE #######
  get_route <- reactive({
    message("Retreiving route data")
    if (is.null(input$start.address) | is.null(input$end.address))
      return(NULL)
    start.coords <- geocode_journey(input$start.address)
    end.coords <- geocode_journey(input$end.address)
    
    # Get cycling route and process into a data frame
    route.list <- cycling_route(start.coords, end.coords)
    route.points.df <- do.call(rbind, lapply(route.list$path, process_path))
    return(route.points.df)
  })  
  
  output$route_map_ggplot <- renderPlot({
    message("Plotting route map")
    route.points.df <- get_route()
    if (is.null(route.points.df))
      stop("Please define route")
    p.route <- ggmap(hel.map) + 
      geom_path(data=route.points.df, aes(x=x, y=y, colour=z), size=3) + 
      xlim(range(route.points.df$x)+c(-0.01, 0.01)) + 
      ylim(range(route.points.df$y)+c(-0.01, 0.01)) +
      labs(x=NULL, y=NULL, colour="Elevation")
    return(p.route)
  })
  
  output$route_profile_ggplot <- renderPlot({
    message("Plotting route profile")
    route.points.df <- get_route()
    if (is.null(route.points.df))
      stop("Please define route")
    route.points.df$ind <- 1:nrow(route.points.df)
    p.profile <- ggplot(route.points.df, aes(x=ind, y=z)) + 
      geom_path() + labs(x=NULL, y="Elevation (m)")
    return(p.profile)
  })
  
  ## WEATHER FORECAST #######
  get_fio <- reactive({
    message("Retreiving forecast data from forecast.io")
    # Use forecast.io
    start.coords <- geocode_journey(input$start.address)
    fio.list <- fio.forecast(fio.api.key, start.coords["lat"], start.coords["lon"])
    return(fio.list$hourly.df)
  })
  
  output$fio_gvistable <- renderGvis({
    message("Creating forecast table")
    hourly.df <- get_fio()
    # Format time to show only Hours:Minutes
    hourly.df$time <- format(hourly.df$time, "%H:%M")
    # Filter fields
    hourly.df <- hourly.df[c("time", "summary",
                             "precipIntensity", "precipProbability",
                             "temperature", "apparentTemperature", "humidity",
                             "windSpeed", "windBearing")]
#    names(hourly.df)[c(3,4,6,8,9)] <- c("precip\nintensity", "precip\nprobability",
 #                                       "apparent\ntemperature", "wind\nspeed", "wind\nbearing")
    # Show required number of hours
    hourly.df <- hourly.df[1:input$forecast.length, ]
    
    return(gvisTable(hourly.df))#, options=list(page='enable', pageSize=20)))
  })
  
#   output$fio_xtable <- renderTable({
#     hourly.df <- get_fio()
#     message(head(hourly.df))
#     
#     return(hourly.df)
#   })

  ## BIKE ACCIDENTS #####
output$accidents_plot <- renderPlot({
  route.points.df <- get_route()
  if (is.null(route.points.df))
    stop("Please define route")

  p.accidents <- ggmap(hel.map) + 
    geom_path(data=route.points.df, aes(x=x, y=y), colour="blue", size=3) + 
    xlim(range(route.points.df$x)+c(-0.01, 0.01)) + 
    ylim(range(route.points.df$y)+c(-0.01, 0.01)) +
    geom_point(data=accidents.df, aes(x=Lon, y=Lat), alpha=0.1, colour="red")
  return(p.accidents)
})

})