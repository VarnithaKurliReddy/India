#------------------------------------------------------------------------------#

#			Calculating distance to cities within 200km radius from sample Villages_Andhra and road intensity for each village

#------------------------------------------------------------------------------#

## PURPOSE: 	This is code for Calculating distance to cities in 200km radius from sample Villages_Andhra and road intensity for each village

# 1. SETTINGS
# 1.1. Load packages - Load main packages, but other may be loaded in
# each code.


# 2. FILE PATHS
# 2.1. Dropbox and GitHub paths - Automatically defines Dropbox and 
# Github paths which are references for all other paths in the project
# 2.2. Folder paths - Define sub folders paths


# 3. SECTIONS
# 3.1. Load the shape file for Villages_Andhra and the sample
# file for Villages_Andhra Pradesh.
# 3.2. Convert the polygon shape file to point shape file.
# 3.3. Load the Urban population data set and merge with spatial point dataframe.
# 3.4.  Build 200km buffer around sample villages and intersect with cities in the buffer.
# 3.5. Calculate distance between sample village to cities in that buffer
# 3.6  Merge with the road intensity file for only sample villages.

## Written by:	                                        Varnitha Kurli Reddy

## Last updated:                                        March 2019

#------------------------------------------------------------------------------#
#### 1. SETTINGS ####

# Set warnings 
options(warn = 0)

#### Delete everything already in R memory
# (Equivalent to clear all in Stata)
rm(list = ls())

#-------------------------#
#### 1.1 Load packages ####
library(Hmisc)
library(raster)
library(rgdal)
library(rgeos)
library(maptools)
library(RColorBrewer)
library(classInt)
library(sf)
install.packages(tmap)
library(tmap)
library(foreign)
install.packages("readstata13")
library(readstata13)
library(tidyverse)

#------------------------------------------------------------------------------#
#### 2. FILE PATHS 	####

#### 2.1. Dropbox and GitHub paths	####

# Varnitha Laptop
if (Sys.getenv("USERNAME") == "wb538005" ){
  Shape <- file.path("C:/Users/WB538005/WBG/Forhad J. Shilpi - Lu/India/SouthAsiaBoundaries")
  folder<-file.path("C:/Users/WB538005/WBG/Forhad J. Shilpi - Lu/India")
  Sample<-file.path("C:/Users/WB538005/WBG/Forhad J. Shilpi - Lu/India/Sample Villages")
  }

#### 3.1 Load the shape file for Villages_Andhra and the sample
#        file for Villages_Andhra Pradesh.
#-------------------------------------------------------------------------------
########
####Load the shape file####
########
Villages_Andhra<- readOGR(dsn=Shape, layer="India_L4_28_Andhra Pradesh_adm_boundaries")
Villages_Andhra_sample<-read.dta13(file = paste(file.path(Sample,"AP_viil_smp_march2019.dta")))
Villages_Andhra_sample$sample=1
names(Villages_Andhra_sample)[names(Villages_Andhra_sample)=="villagecode"]<-"L4_CODE"
Villages_Andhra@data<-left_join(Villages_Andhra@data,Villages_Andhra_sample,by="L4_CODE")
Villages_Andhra@data$statecode<-NULL
Villages_Andhra@data$districtcode<-NULL
Villages_Andhra@data$blockcode<-NULL
Villages_Andhra@data[is.na(Villages_Andhra@data)]<-0
#------------------------------------------------------------------
#### 3.2 Convert the polygon shape file to point shape file.

#-------------------------------------------------------------------------------
points_Villages_Andhra<- getSpPPolygonsLabptSlots(Villages_Andhra)
points_Villages_Andhra <- SpatialPointsDataFrame(coords=points_Villages_Andhra, data=Villages_Andhra@data, proj4string=CRS("+proj=longlat +ellps=clrk66"))
#check if the sample villages are being plotted correctly.
Villages_subset<-subset(points_Villages_Andhra[points_Villages_Andhra@data$sample==1,])
plot(Villages_subset)
#-------------------------------------------------------------------------------
#### 3.3 Load the Urban population data set and merge with spatial point dataframe. Subset to cities and check by plotting.
#-------------------------------------------------------------------------------
library(readxl)
Urban_new<-read_excel(file =paste(file.path(folder,"Urban_new.xls")))
names(Urban_new)[names(Urban_new)=="l4_code"]<-"L4_CODE"
Urban_new<-Urban_new[,c(12,15)]
cities_subset<- getSpPPolygonsLabptSlots(Villages_Andhra)
cities_subset <- SpatialPointsDataFrame(coords=points_Villages_Andhra, data=Villages_Andhra@data, proj4string=CRS("+proj=longlat +ellps=clrk66"))
cities_subset@data<-merge(cities_subset@data,Urban_new,by="L4_CODE")
colnames(cities_subset@data)[colnames(cities_subset@data)=="pop"] <- "city"
cities_subset@data[is.na(cities_subset@data)]<-0
cities_subset@data$city[cities_subset@data$city>0] <-1
#check if the cities are being plotted correctly.
plot(cities_subset)
#--------------------
#----------------------------------------------------
#####
 # 3.3 Make a 200km buffer around the sample villages. 
#-----------------------------------------------------------------
require(maptools)
require(geosphere) 
Villages_subset@proj4string <- cities_subset@proj4string
#create booths with 200km buffer
sample_buffer200km <- gBuffer(Villages_subset, byid = TRUE, width =200)
cities_subset@proj4string <- sample_buffer200km@proj4string
#intesection cities
selected_cities <- raster::intersect(sample_buffer200km,cities_subset)

# 3.6  Merge with the road intensity file for only sample villages.

names(RoadInt)[names(RoadInt)=="l4_code"]<-"L4_CODE"
merged<-merge(Villages_subset@data,RoadInt,by="L4_CODE")
write.csv(merged, file = "merged.csv")
write.csv(cities_subset@data, file = "cities.csv")
