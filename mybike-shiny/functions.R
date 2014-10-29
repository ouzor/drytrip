# Auxiliary functions

# Process route points
process_path <- function(path.point) {
  
  # Slow
  #  points.df <- reshape2::dcast(melt(path.point$points), L1 ~ L2)
  # Faster
  points.df <- as.data.frame(t(sapply(path.point$points, function(point) c(point$x, point$y, point$z))))
  names(points.df) <- c("x", "y", "z")
  points.df$type <- path.point$type
  return(points.df)
}

summarise_path <- function(route.list) {
  
  route.info.df <- as.data.frame(t(sapply(route.list$path, function(x) c(x$name, x$type, x$length))), stringsAsFactors = FALSE)
  names(route.info.df) <- c("name", "type", "length")
  route.info.df$length <- as.numeric(route.summary.df$length)
}

# Get route
cycling_route <- function(start.coords, end.coords, profile="kleroshortest") {
  # Process input
  from <- paste(start.coords, collapse=",")
  to <- paste(end.coords, collapse=",")
  
  api.url <- "api.reittiopas.fi/hsl/prod/?request=cycling&user=ouzor&pass=louhos&format=json&epsg_in=wgs84&epsg_out=wgs84&elevation=1"
  query.url <- paste0(api.url, "&from=", from, "&to=", to, "&profile=", profile)
  curl <- RCurl::getCurlHandle(cookiefile = "")
  res.json <- suppressWarnings(RCurl::getForm(uri=query.url, curl=curl))
  res.list <- rjson::fromJSON(res.json)
  
  return(res.list)
}

# Geocode call
geocode_journey <- function(query) {
  
  # Replace space
  query <- gsub(" ", "%20", query)
  api.url <- "http://api.reittiopas.fi/hsl/prod/?request=geocode&user=ouzor&pass=louhos&format=json&epsg_out=wgs84"
  query.url <- paste0(api.url, "&key=", query)
  curl <- RCurl::getCurlHandle(cookiefile = "")
  res.json <- suppressWarnings(RCurl::getForm(uri=query.url, curl=curl))
  
  res.list <- rjson::fromJSON(res.json)
  if (length(res.list)>0) {
    coords <- as.numeric(unlist(strsplit(res.list[[1]]$coords, split=",")))
    names(coords) <- c("lon", "lat")
    return(coords)
  } else {
    message("No results found")
    return(NULL)
  }
}


