library("rjson")
library("RCurl")
library("reshape2")
# install_github("ouzor/Rforecastio")
library("Rforecastio")
library("ggplot2")
theme_set(theme_bw(16))
library("gridExtra")
library("ggmap")
#library("xtable")
# library("googleVis")
# # Test these?
# library("fmi")
# library("rgdal")

# Read API keys for fio and fmi
fio.api.key <- scan(file="dark_sky_api.txt", what="character")
fmi.api.key <- scan(file="fmi_api.txt", what="character")

# theme_set(theme_grey(20))
# library(grid)

# Source aux functions
source("functions.R")

# Load helsinki region map
load("helsinki_map_stamen-toner.RData")

# Load bicycle accident data (for Helsinki only)
# load("bike_accidents.RData")

# Set time zone to Helsinki
Sys.setenv(TZ="Europe/Helsinki")

shinyServer(function (input, output) {
  
  ## CYCLING ROUTE #######
  get_route <- reactive({
    message("Getting route data")
    #     if (is.null(input$start.address) | is.null(input$end.address))
    #       return(NULL)
    
    route.name <- paste(input$start.address, input$via.addresses, input$end.address, sep="_")
    route.file <- paste0(route.name, ".RData")
    # Read existing route?
    if (file.exists(route.file)) {
      message("Loading route from file: ", route.file)
      load(route.file)
    # Fetch from Reittiopas API      
    } else  {
      message("Retrieving route from Reittiopas API")
      start.coords <- geocode_place(input$start.address)
      end.coords <- geocode_place(input$end.address)
      if (input$via.addresses!="") {
        via.addresses <- unlist(strsplit(input$via.addresses, split="_"))
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
      save(route.list, file=route.file)
    }
    message("TEST!")
    route.points.df <- do.call(rbind, lapply(route.list$path, process_path))
    message("TEST2!!!")
    route.summary.df <- summarise_route(route.list)    
    return(list(points=route.points.df, summary=route.summary.df))
  })  
  
  get_waypoints <- reactive({
    
    route.summary.df <- get_route()$summary
    route.summary.df$CumLength <- cumsum(route.summary.df$length)/1000
    route.summary.df$Time <- route.summary.df$CumLength/input$cycling.speed
    # Waypoints 
    waypoint.interval <- 60
    waypoint.times <- seq(from=0, 
                          to=floor(route.summary.df$Time[nrow(route.summary.df)]),
                          by=waypoint.interval/60)
    waypoint.inds <- sapply(waypoint.times, function(x) which(route.summary.df$Time>x)[1])
    waypoints.df <- route.summary.df[waypoint.inds, ]
    waypoints.df$Ind <- 1:nrow(waypoints.df)
    return(waypoints.df)
  })
  
  output$route_info <- renderText({
    route.summary.df <- get_route()$summary
    route.km <- sum(route.summary.df$length)/1000
    texts <- list()
    texts[[1]] <- paste("Route length:", round(route.km, d=2), "km")
    texts[[2]] <- paste("Time estimate at", input$cycling.speed, "km/h:", round(route.km/input$cycling.speed, d=1), "hours")
    route.text <- paste("<big>", paste(unlist(texts), collapse="<br>"), "</big>") 
    return(route.text)
  })
  
  output$route_map_ggplot <- renderPlot({
    message("Plotting route map")
    route.points.df <- get_route()$points
    waypoints.df <- get_waypoints()
    #     if (is.null(route.points.df))
    #       stop("Please define route")
    p.route <- ggmap(hel.map) + 
      geom_path(data=route.points.df, aes(x=x, y=y), colour="blue", size=3) + # colour=z
      geom_point(data=waypoints.df, colour="red", size=10) + 
      geom_text(data=waypoints.df, aes(label=Ind), colour="white") +
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
    message("Retrieving forecast data from forecast.io")
    # Get forecast data for each waypoint
    waypoints.df <- get_waypoints()
    fio.df <- data.frame()
    for (wi in 1:nrow(waypoints.df)) {
      # Get data
      ihourly.df <- fio.forecast(fio.api.key, waypoints.df$lat[wi], waypoints.df$lon[wi])$hourly.df
      # Take a subset of the fields
      # NOTE! Not all fields always available, at least 'visibility' missing sometimes
      # Max number of fields required is max(forecast.length) + #WP
      
      fields.totake <- c("time", "precipIntensity", "temperature", "windSpeed", "windBearing")
      ihourly.df <- ihourly.df[1:(10+nrow(waypoints.df)), fields.totake]
      ihourly.df$WP <- wi
      fio.df <- rbind(fio.df, ihourly.df)
    }
    # Process times and waypoints
    fio.df$date <- as.Date(fio.df$time)#format(fio.df$time, "%Y-%M-%D")
    fio.df$start.hour.num <- as.numeric(format(fio.df$time, "%H")) - fio.df$WP + 1
    if (any(fio.df$start.hour.num <= 0))
      fio.df$start.hour.num[fio.df$start.hour.num <= 0] <- 24 + fio.df$start.hour.num[fio.df$start.hour.num <= 0]
    return(fio.df)  
    
    #     fio.list <- lapply(waypoints.df$Ind, function(i) {res=fio.forecast(fio.api.key, waypoints.df$lat[i], waypoints.df$lon[i])$hourly.df; res$WP=i; res})
    #     fio.df <- do.call(rbind, fio.list)
    # Simplify for now
    #    fio.df <- fio.df[c("time", "precipIntensity", "temperature", "windSpeed", "windBearing", "WP")] 
  })
  
  output$fio_plot <- renderPlot({
    fio.df <- get_fio()
    # subset based on date and start time
    fio.df <- subset(fio.df, start.hour.num %in% (1:input$forecast.length+fio.df$start.hour.num[1]-1))
    #     fio.df <- subset(fio.df, date==fio.df$date[1] & start.hour %in% (1:input$forecast.length+fio.df$start.hour[1]-1))
    fio.df$start.hour <- factor(paste0(fio.df$start.hour.num, ":00"), levels=paste0(sort(unique(fio.df$start.hour.num)), ":00"))
    
    #    fio.df$WP <- as.character(fio.df$WP)
    fio.df$WP <- factor(fio.df$WP, levels=rev(unique(fio.df$WP)))
    p.precip <- ggplot(fio.df, aes(x=WP, y=precipIntensity)) + 
      #      geom_point(size=3, colour="blue") + 
      facet_grid(start.hour ~ .) + theme(strip.text.y=element_text(angle=0)) +
      labs(x="Waypoint", y="Precipitation") + ggtitle("Precipitation intensity") +
      geom_hline(y=0, linetype="dashed") +
      coord_flip()
    # If only one waypoint, use bars, otherwise use area
    if (length(levels(fio.df$WP))==1) {
      p.precip <- p.precip + geom_bar(stat="identity", fill="blue")
    } else {
      p.precip <- p.precip + geom_area(aes(group=start.hour), fill="blue") 
    }
    p.temp <- ggplot(fio.df, aes(x=WP, y=temperature)) + 
      geom_line(aes(group=start.hour), size=2, colour="red") + 
      geom_point(size=5, colour="red") + 
      facet_grid(start.hour ~ .) + theme(strip.text.y=element_text(angle=0)) +
      labs(x="Waypoint", y="Temperature (C)") + ggtitle("Temperature") + 
      ylim(min(-1, min(fio.df$temperature)), max(11, max(fio.df$temperature))) +
      geom_hline(y=0, linetype="dashed") +
      coord_flip()
    p.wind <- ggplot(fio.df, aes(x=WP, y=windSpeed)) + #geom_line(colour="blue") + 
      geom_point(size=8, colour="lightblue") + 
      geom_text(label="V", colour="black", aes(angle=windBearing)) + 
      facet_grid(start.hour ~ .) + theme(strip.text.y=element_text(angle=0)) +
      labs(x="Waypoint", y="Wind speed (m/s)") + ggtitle("Wind speed and direction") +
      ylim(min(-1, min(fio.df$temperature)), max(11, max(fio.df$temperature))) +
      geom_hline(y=0, linetype="dashed") +
      coord_flip()
    #     p.wind2 <- ggplot(fio.df, aes(x=WP)) +perature))) + 
    #       geom_point(aes(size=windSpeed), y=1, colour="blue") + 
    #       geom_text(aes(size=windSpeed, angle=windBearing), y=1, label="V", colour="white") +    
    #       facet_grid(start.hour ~ .) + theme(strip.text.y=element_text(angle=0)) +
    #       labs(x="Waypoint", y=NULL) + ggtitle("Wind speed (m/s) and direction") +
    #       ylim(0, 2) + scale_size_continuous(limits=c(0, max(fio.df$windSpeed)))
    
    p.fio <- arrangeGrob(p.precip, p.temp, p.wind, nrow=1)
    return(p.fio)
  })
  
  output$fio_plot_ui <- renderUI({
    
    h <- max(200, 100*input$forecast.length)
    plotOutput("fio_plot", height=paste0(h,"px"), width="100%")
  })
  
  #   output$fio_gvistable <- renderGvis({
  #     message("Creating forecast table")
  #     hourly.df <- get_fio()
  #     # Format time to show only Hours:Minutes
  #     hourly.df$time <- format(hourly.df$time, "%H:%M")
  #     # Filter fields
  #     hourly.df <- hourly.df[c("time", "summary",
  #                              "precipIntensity", "precipProbability",
  #                              "temperature", "apparentTemperature", "humidity",
  #                              "windSpeed", "windBearing")]
  #     #    names(hourly.df)[c(3,4,6,8,9)] <- c("precip\nintensity", "precip\nprobability",
  #     #                                       "apparent\ntemperature", "wind\nspeed", "wind\nbearing")
  #     # Show required number of hours
  #     hourly.df <- hourly.df[1:input$forecast.length, ]
  #     
  #     return(gvisTable(hourly.df))#, options=list(page='enable', pageSize=20)))
  #   })
  
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
  
  #   output$fmi_gvistable <- renderGvis({
  #     message("Creating forecast table")
  #     fmi.df <- get_fmi()
  #     
  #     return(gvisTable(fmi.df))#, options=list(page='enable', pageSize=20)))
  #   })
  
  
  
  #   ## BIKE ACCIDENTS #########
  #   
  #   output$accidents_plot <- renderPlot({
  #     route.points.df <- get_route()
  #     if (is.null(route.points.df))
  #       stop("Please define route")
  #     
  #     p.accidents <- ggmap(hel.map) + 
  #       geom_path(data=route.points.df, aes(x=x, y=y), colour="blue", size=3) + 
  #       xlim(range(route.points.df$x)+c(-0.01, 0.01)) + 
  #       ylim(range(route.points.df$y)+c(-0.01, 0.01)) +
  #       geom_point(data=accidents.df, aes(x=Lon, y=Lat), alpha=0.1, colour="red")
  #     return(p.accidents)
  #   })
  
})