# FMI forecast test

# # Install GDAL and rgdal based on this: http://www.kyngchaos.com/software/frameworks
# install.packages(c("devtools"))
# library(devtools)
# install_github("rOpenGov/rwfs")
# install_github("rOpenGov/fmi")
library("fmi")
library("rgdal")
message("Remember to open RStudio with 'open -a rstudio'")

fmi.api.key <- scan(file="mybike-shiny/fmi_api.txt", what="character")

# Get historical weather data
request <- FMIWFSRequest(fmi.api.key=fmi.api.key)
request$setParameters(request="getFeature",
                      storedquery_id="fmi::observations::weather::daily::timevaluepair",
                      starttime="2014-01-01",
                      endtime="2014-01-01",
                      bbox="19.09,59.3,31.59,70.13",
                      parameters="rrday,snow,tday,tmin,tmax")
client <- FMIWFSClient()
layers <- client$listLayers(request=request)
response <- client$getLayer(request=request, layer=layers[1], crs="+proj=longlat +datum=WGS84", swapAxisOrder=TRUE, parameters=list(splitListFields=TRUE))

# process output
temp <- response@data$gml_id[1]

request <- FMIWFSRequest(fmi.api.key=fmi.api.key)
client <- FMIWFSClient()
response <- client$getDailyWeather(request=request, 
                                   startDateTime=as.POSIXlt("2013-01-01"), 
                                   endDateTime=as.POSIXlt("2013-01-01"))

## TRY TO GET FORECAST DATA ############


# # Does not work
# request <- FMIWFSRequest(fmi.api.key=fmi.api.key)
# request$setParameters(request="getFeature", storedquery_id="fmi::forecast::hirlam::surface::point::multipointcoverage", place="helsinki")
# client <- FMIWFSClient()
# layers <- client$listLayers(request=request)
# response <- client$getLayer(request=request, layer=layers[1], crs="+proj=longlat +datum=WGS84", swapAxisOrder=TRUE, parameters=list(splitListFields=TRUE))

# request <- FMIWFSRequest(fmi.api.key=fmi.api.key)
# request$setParameters(request="getFeature", storedquery_id="fmi::forecast::hirlam::surface::obsstations::timevaluepair")
# client <- FMIWFSClient()
# layers <- client$listLayers(request=request)
# response <- client$getLayer(request=request, layer=layers[1], crs="+proj=longlat +datum=WGS84", swapAxisOrder=TRUE, parameters=list(splitListFields=TRUE))

# Works now!
request <- FMIWFSRequest(fmi.api.key=fmi.api.key)
request$setParameters(request="getFeature", storedquery_id="fmi::forecast::hirlam::surface::point::timevaluepair", place="helsinki")
client <- FMIWFSClient()
layers <- client$listLayers(request=request)
response.all <- client$getLayer(request=request, layer=layers[1], crs="+proj=longlat +datum=WGS84", swapAxisOrder=TRUE, parameters=list(splitListFields=TRUE, explodeCollections=TRUE))

# Try to add parameters
request <- FMIWFSRequest(fmi.api.key=fmi.api.key)
request$setParameters(request="getFeature",
                      starttime="2014-10-30T20:00:00Z",
                      endtime="2014-10-30T22:00:00Z",
                      timestep="15",
                      timesteps="10",
                      storedquery_id="fmi::forecast::hirlam::surface::point::timevaluepair",
                      place="helsinki",
                      parameters="Temperature,Humidity,WindDirection,WindSpeedMS,WeatherSymbol3,Precipitation1h,PrecipitationAmount")
client <- FMIWFSClient()
layers <- client$listLayers(request=request)
response <- client$getLayer(request=request, layer=layers[1], crs="+proj=longlat +datum=WGS84", swapAxisOrder=TRUE, parameters=list(splitListFields=TRUE, explodeCollections=TRUE))

# Current time
trunc(Sys.time(), "min")
# end time
trunc(Sys.time(), "min") + 15*60*16




# processForecastResponse(response) {
#   
#   
# }