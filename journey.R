# Get data from Journey planner API

library("rjson")
library("RCurl")
library("reshape2")

source("functions.R")

# Define route
start.address <- "Kalevanvainio 5"
end.address <- "Kamppi"

# Geocode
start.coords <- geocode_journey(start.address)
end.coords <- geocode_journey(end.address)

# Get cycling route and process into a data frame
route.list <- cycling_route(start.coords, end.coords)
route.points.df <- do.call(rbind, lapply(route.list$path, process_path))

# point.list <- lapply(route.list$path, function(path) {res=t(sapply(path$points, function(point) c(point$x, point$y))); colnames(res) <- c("lon", "lat"); res})
# route.df <- as.data.frame(do.call(rbind, point.list))
  
# Get corresponding map area from OSM
library("ggmap")
# Define bounding box based on route
# route.bbox <- c(min(start.coords["lon"], end.coords["lon"])-0.01,
#           min(start.coords["lat"], end.coords["lat"])-0.01,
#           max(start.coords["lon"], end.coords["lon"])+0.01,
#           max(start.coords["lat"], end.coords["lat"])+0.01)
# route.map <- ggmap::get_map(location=route.bbox, source="osm", crop=TRUE, color="bw")

# Get one map for helsinki region and crop for route
hel.bbox <- c(24.5, 60.1, 25.3, 60.4)
# hel.map <- ggmap::get_map(location=hel.bbox, source="osm", color="bw")#, crop=TRUE)
# save(hel.map, file="mybike-shiny/helsinki_map1.RData")
hel.map <- ggmap::get_map(location=hel.bbox, source="stamen", maptype="toner")
save(hel.map, file="mybike-shiny/helsinki_map_stamen-toner.RData")

load("mybike-shiny/helsinki_map1.RData")

# Plot map and route
p.route <- ggmap(hel.map) + geom_path(data=route.points.df, aes(x=x, y=y), colour="red", size=3) + 
  xlim(range(route.points.df$x)+c(-0.01, 0.01)) + 
  ylim(range(route.points.df$y)+c(-0.01, 0.01))
p.route <- ggmap(hel.map) + geom_path(data=route.points.df, aes(x=x, y=y, colour=z), size=3) + 
  xlim(range(route.points.df$x)+c(-0.01, 0.01)) + 
  ylim(range(route.points.df$y)+c(-0.01, 0.01))
# Add: elevation, type, different routes?

# Plot elevation
route.points.df$ind <- 1:nrow(route.points.df)
p.profile <- ggplot(route.points.df, aes(x=ind, y=z)) + geom_path()
