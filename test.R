# Script for testing everything

# library("devtools")
# install_github("ouzor/Rforecastio")
# Load data
load("drytrip-shiny/helsinki_map_stamen-toner.RData")
fio.api.key <- scan(file="drytrip-shiny/dark_sky_api.txt", what="character")
fmi.api.key <- scan(file="drytrip-shiny/fmi_api.txt", what="character")

# Source aux functions
source("drytrip-shiny/functions.R")

input = list()
input$start.address = "Kamppi"
input$end.address = "Kamppi"
input$via.addresses = "Olari_Nuuksio_Leppävaara"
input$cycling.speed = 20
input$forecast.length=5


input = list()
input$start.address = "Kamppi"
input$end.address = "kalevanvainio"
input$via.addresses = ""
input$cycling.speed = 20
input$forecast.length=5

# Try changing time zone
Sys.setenv(TZ="Europe/Paris")
Sys.setenv(TZ="Europe/Helsinki")
