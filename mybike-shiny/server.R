library("rjson")
library("RCurl")
library("reshape2")
library("ggplot2")
library("ggmap")
library("Rforecastio")
library("xtable")
library("googleVis")
# Test these?
library("fmi")
library("rgdal")

# Read API keys for fio and fmi
fio.api.key <- scan(file="dark_sky_api.txt", what="character")
fmi.api.key <- scan(file="fmi_api.txt", what="character")



# theme_set(theme_grey(20))
# library(grid)

# Source aux functions
source("functions.R")

# Load helsinki region map
load("helsinki_map1.RData")

# Load bicycle accident data (for Helsinki only)
# load("bike_accidents.RData")

shinyServer(function (input, output) {
  
  ## CYCLING ROUTE #######
  get_route <- reactive({
    message("Retreiving route data")
#     if (is.null(input$start.address) | is.null(input$end.address))
#       return(NULL)
    start.coords <- geocode_place(input$start.address)
    end.coords <- geocode_place(input$end.address)
    if (input$via.addresses!="") {
      message("test1")
      via.addresses <- unlist(strsplit(input$via.addresses, split=";"))
      if (length(via.addresses) > 5)
        stop("Maximum number of via points is five!")
      names(via.addresses) <- via.addresses
      via.coords <- lapply(via.addresses, geocode_place)
      route.list <- cycling_route(start.coords, end.coords, via.coords)
    }
    
    # Get cycling route and process into a data frame
    else {
      route.list <- cycling_route(start.coords, end.coords)
    }
    route.points.df <- do.call(rbind, lapply(route.list$path, process_path))
    route.summary.df <- summarise_route(route.list)
    return(list(points=route.points.df, summary=route.summary.df))
  })  
  
  output$route_info <- renderText({
    route.summary.df <- get_route()$summary
    route.km <- sum(route.summary.df$length)/1000
    texts <- list()
    texts[[1]] <- paste("Route length:", round(route.km, d=2), "km")
    texts[[2]] <- paste("Time estimate at", input$cycling.speed, "km/h is", round(route.km/input$cycling.speed, d=1), "hours")
    route.text <- paste("<big>", paste(unlist(texts), collapse="<br>"), "</big>") 
    return(route.text)
  })
  
  output$route_map_ggplot <- renderPlot({
    message("Plotting route map")
    route.points.df <- get_route()$points
#     if (is.null(route.points.df))
#       stop("Please define route")
    p.route <- ggmap(hel.map) + 
      geom_path(data=route.points.df, aes(x=x, y=y), colour="red", size=3) + # colour=z
      xlim(range(route.points.df$x)+c(-0.01, 0.01)) + 
      ylim(range(route.points.df$y)+c(-0.01, 0.01)) +
      labs(x=NULL, y=NULL, colour="Elevation")
    return(p.route)
  })
  
  output$route_profile_ggplot <- renderPlot({
    message("Plotting route profile")
    route.points.df <- get_route()$points
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
  
  ## FORECAST FROM FMI ######
  get_fmi <- reactive({
    message("Retreiving forecast data from fmi")
  
    request <- FMIWFSRequest(apiKey=fmi.api.key)
    request$setParameters(request="getFeature",
                          starttime="2014-10-30T20:00:00Z",
                          endtime="2014-10-30T22:00:00Z",
                          timestep="15",
                          storedquery_id="fmi::forecast::hirlam::surface::point::timevaluepair",
                          place="helsinki",
                          parameters="Temperature,Humidity,WindDirection,WindSpeedMS,WeatherSymbol3,Precipitation1h,PrecipitationAmount")
    client <- FMIWFSClient()
    layers <- client$listLayers(request=request)
    response <- client$getLayer(request=request, layer=layers[1], crs="+proj=longlat +datum=WGS84", swapAxisOrder=TRUE, parameters=list(splitListFields=TRUE, explodeCollections=TRUE))
    return(response@data)
  })
  
  output$fmi_gvistable <- renderGvis({
    message("Creating forecast table")
    fmi.df <- get_fmi()
    
    return(gvisTable(fmi.df))#, options=list(page='enable', pageSize=20)))
  })
  
  
  
  ## BIKE ACCIDENTS #########
  
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