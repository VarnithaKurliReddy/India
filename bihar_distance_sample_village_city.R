#------------------------------------------------------------------------------#

#			Calculating distance to cities within 200km radius from sample Villages_Bihar and road intensity for each village

#------------------------------------------------------------------------------#

## PURPOSE: 	This is code for Calculating distance to cities in 200km radius from sample Villages_Bihar and road intensity for each village

# 1. SETTINGS
# 1.1. Load packages - Load main packages, but other may be loaded in
# each code.


# 2. FILE PATHS
# 2.1. Dropbox and GitHub paths - Automatically defines Dropbox and 
# Github paths which are references for all other paths in the project
# 2.2. Folder paths - Define sub folders paths


# 3. SECTIONS
# 3.1. Load the shape file for Villages_Bihar and the sample
# file for Villages_Bihar Pradesh.
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

#### 3.1 Load the shape file for Villages_Bihar and the sample
#        file for Villages_Bihar Pradesh.
#-------------------------------------------------------------------------------
########
####Load the shape file####
########
Villages_Bihar<- readOGR(dsn=Shape, layer="India_L4_10_Bihar_adm_boundaries")
Villages_Bihar_sample<-read.dta13(file = paste(file.path(Sample,"Bihar_vill_smp_march2019.dta")))
Villages_Bihar_sample$sample=1
names(Villages_Bihar_sample)[names(Villages_Bihar_sample)=="VillageCensusCode"]<-"L4_CODE"
Villages_Bihar@data<-left_join(Villages_Bihar@data,Villages_Bihar_sample,by="L4_CODE")
Villages_Bihar@data[is.na(Villages_Bihar@data)]<-0
#------------------------------------------------------------------
#### 3.2 Convert the polygon shape file to point shape file.

#-------------------------------------------------------------------------------
points_Villages_Bihar <- SpatialPointsDataFrame(coords=coordinates(Villages_Bihar), data=Villages_Bihar@data)
#check if the sample villages are being plotted correctly.
Villages_subset<-subset(points_Villages_Bihar[points_Villages_Bihar@data$sample==1,])
plot(Villages_subset)
#-------------------------------------------------------------------------------
#### 3.3 Load the Urban population data set and merge with spatial point dataframe. Subset to cities and check by plotting.
#-------------------------------------------------------------------------------
library(readxl)
Urban_new<-read_excel(file =paste(file.path(folder,"Urban_new.xls")))
names(Urban_new)[names(Urban_new)=="l4_code"]<-"L4_CODE"
Urban_new<-Urban_new[,c(12,15)]
points_Villages_Bihar@data<-left_join(points_Villages_Bihar@data,Urban_new,by="L4_CODE")
colnames(points_Villages_Bihar@data)[colnames(points_Villages_Bihar@data)=="pop"] <- "city"
points_Villages_Bihar@data[is.na(points_Villages_Bihar@data)]<-0
points_Villages_Bihar@data$city[points_Villages_Bihar@data$city>0] <-1
#check if the cities are being plotted correctly.
urban_subset<-subset(points_Villages_Bihar[points_Villages_Bihar@data$city==1,])
plot(urban_subset)

#--------------------
#----------------------------------------------------
#####
# 3.3 Make a 200km buffer around the sample villages. 
#-----------------------------------------------------------------
# Buffer file from ARCGIS
library(raster)
villages_buffer <- shapefile("C:/Users/WB538005/WBG/Forhad J. Shilpi - Lu/India/SouthAsiaBoundaries/Export_Output.shp")
villages_buffer<- readOGR(dsn="C:/Users/WB538005/WBG/Forhad J. Shilpi - Lu/India/SouthAsiaBoundaries",layer="Export_Output")
sample_villages_buffer<-subset(villages_buffer[villages_buffer@data$sample==1,])


#SUBSET THE BUFFER TO ONLY TO SAMPLE VILLAGES





# 3.6  Merge with the road intensity file for only sample villages.

names(RoadInt)[names(RoadInt)=="l4_code"]<-"L4_CODE"
merged<-merge(Villages_subset@data,RoadInt,by="L4_CODE")
write.csv(merged, file = "bihar_merged.csv")
write.csv(urban_subset@data, file = "bihar_cities.csv")





