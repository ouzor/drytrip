# Test forecast.io

library(devtools)
# Had to fork to change to use SI units
install_github("ouzor/Rforecastio")

library(Rforecastio)
library(ggplot2)
library(plyr)

fio.api.key <- scan(file="mybike-shiny/dark_sky_api.txt", what="character")

# my.latitude = "43.2673"
# my.longitude = "-70.8618"
# 
# fio.list <- fio.forecast(fio.api.key, my.latitude, my.longitude, sslverifypeer=FALSE)
# fio.gg <- ggplot(data=fio.list$hourly.df, aes(x=time, y=temperature))
# fio.gg <- fio.gg + labs(y="Readings", x="", title="Hourly Readings")
# fio.gg <- fio.gg + geom_line(aes(y=humidity*100), color="green", size=0.25)
# fio.gg <- fio.gg + geom_line(aes(y=temperature), color="red", size=0.25)
# fio.gg <- fio.gg + geom_line(aes(y=dewPoint), color="blue", size=0.25)
# fio.gg <- fio.gg + theme_bw()
# fio.gg

# For route starting point
lon <- "24.80071"
lat <- "60.18348"
fio.list <- fio.forecast(fio.api.key, lat, lon)#sslverifypeer=FALSE)

"https://api.forecast.io/forecast/6c09ad5ceef1835696562448cae6e68c/60.18348,24.80071/?units=si" 
# Plot
# p.fio <- ffplot(fio.list$hourly.df, aes(x=))
