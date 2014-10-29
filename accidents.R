# Process accidents data

library("rgdal")

# Data from http://www.hri.fi/fi/dataset/liikenneonnettomuudet-helsingissa


# Download and unzip
data.dir <- tempdir()
zip.file <- "hki_liikenneonnettomuudet.zip"
remote.zip <- paste0("http://www.hel.fi/hel2/tietokeskus/data/helsinki/ksv/", zip.file)
local.zip <-  file.path(data.dir, zip.file)
utils::download.file(remote.zip, destfile = local.zip)
utils::unzip(local.zip, exdir = data.dir)

# Read data
# These are in KKJ2 coordinates => EPSG:2392
filename <- file.path(data.dir, "hki_liikenneonnettomuudet_2000_2012.TAB")
sp <- rgdal::readOGR(filename, layer = rgdal::ogrListLayers(filename), p4s="+init=epsg:3879", drop_unsupported_fields=T, dropNULLGeometries=T)#, encoding="ISO-8859-1", use_iconv=TRUE)
# Transform coordinates
sp <- spTransform(sp, CRS("+proj=longlat +datum=WGS84"))
# Get data frame
accidents.df <- cbind(sp@data[c(1,2,3)], sp@coords)
names(accidents.df) <- c("SeriousLevel", "Year", "Type", "Lon", "Lat")
table(accidents.df$Type)
#   JK    MA    MP    PP 
# 2213 29312  1382  2137 
# Take only bicycle accidens
accidents.df <- droplevels(subset(accidents.df, Type=="PP"))
table(accidents.df$SeriousLevel)
#   1    2    3 
# 627 1154    6 

# Plot on top of helsinki map
load("mybike-shiny/helsinki_map1.RData")
library("ggmap")
p.accidents <- ggmap(hel.map) + 
  geom_point(data=accidents.df, aes(x=Lon, y=Lat), alpha=0.1, colour="red") +
  xlim(24.7, 25.25)

save(accidents.df, file="mybike-shiny/bike_accidents.RData")
