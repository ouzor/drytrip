# FMI forecast test

# # Install GDAL and rgdal based on this: http://www.kyngchaos.com/software/frameworks
# install.packages(c("devtools"))
# library(devtools)
# install_github("rOpenGov/rwfs")
# install_github("rOpenGov/fmi")
library("fmi")
library("rgdal")
message("Remember to open RStudio with 'open -a rstudio'")

apiKey <- scan(file="fmi_api.txt", what="character")

# Get historical weather data
request <- FMIWFSRequest(apiKey=apiKey)
request$setParameters(request="getFeature",
                      storedquery_id="fmi::observations::weather::daily::timevaluepair",
                      starttime="2014-01-01",
                      endtime="2014-01-01",
                      bbox="19.09,59.3,31.59,70.13",
                      parameters="rrday,snow,tday,tmin,tmax")
client <- FMIWFSClient()
layers <- client$listLayers(request=request)
response <- client$getLayer(request=request, layer=layers[1], crs="+proj=longlat +datum=WGS84", swapAxisOrder=TRUE, parameters=list(splitListFields=TRUE))

## TRY TO GET FORECAST DATA ############


# # Does not work
# request <- FMIWFSRequest(apiKey=apiKey)
# request$setParameters(request="getFeature", storedquery_id="fmi::forecast::hirlam::surface::point::multipointcoverage", place="helsinki")
# client <- FMIWFSClient()
# layers <- client$listLayers(request=request)
# response <- client$getLayer(request=request, layer=layers[1], crs="+proj=longlat +datum=WGS84", swapAxisOrder=TRUE, parameters=list(splitListFields=TRUE))

request <- FMIWFSRequest(apiKey=apiKey)
request$setParameters(request="getFeature", storedquery_id="fmi::forecast::hirlam::surface::obsstations::timevaluepair")
client <- FMIWFSClient()
layers <- client$listLayers(request=request)
response <- client$getLayer(request=request, layer=layers[1], crs="+proj=longlat +datum=WGS84", swapAxisOrder=TRUE, parameters=list(splitListFields=TRUE))

# Works now!
request <- FMIWFSRequest(apiKey=apiKey)
request$setParameters(request="getFeature", storedquery_id="fmi::forecast::hirlam::surface::point::timevaluepair", place="helsinki")
client <- FMIWFSClient()
layers <- client$listLayers(request=request)
response <- client$getLayer(request=request, layer=layers[1], crs="+proj=longlat +datum=WGS84", swapAxisOrder=TRUE, parameters=list(splitListFields=TRUE, explodeCollections=TRUE))



