# airqualityapp

A Shiny-based R application for visualizing PM2.5 air quality data across cities. This interactive app allows users to view PM2.5 concentration trends over time and explore measurement stations on an interactive map.

##  Features

- **City Selector**: Choose a city to view time-series plots of PM2.5 concentrations.
- **Interactive Map**: Visualize the locations of monitoring stations across Europe.
- **Dynamic Plotting**: Displays line or point plots depending on data availability.
- **Map-to-Plot Sync**: Clicking a marker updates the plot automatically.

##  Installation

To install the development version from GitHub:

```r
# install.packages("devtools")
devtools::install_github("Programming-The-Next-Step-2025/air-quality-app")
Launch the App
Make sure the openaq.csv file is in your working directory. Then run:

library(airqualityapp)
startApp()
CSV File Requirements
The app expects a file named openaq.csv with at least the following columns:

Pollutant: Must include "PM2.5"

Coordinates: Comma-separated latitude and longitude


Dependencies
The following R packages are used:

shiny

shinydashboard

leaflet

ggplot2

utils

Author:
Chrystalla Georgiou
