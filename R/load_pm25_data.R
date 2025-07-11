#' Load and Clean PM2.5 Data
#'
#' @return A data frame of cleaned PM2.5 observations.
#' @export
load_pm25_data <- function() {
  data <- read.csv(system.file("extdata", "openaq.csv", package = "appforair"), sep = ";", stringsAsFactors = FALSE)

  coords <- strsplit(data$Coordinates, ",")
  data$Latitude <- sapply(coords, function(x) as.numeric(x[1]))
  data$Longitude <- sapply(coords, function(x) as.numeric(x[2]))
  data$LastUpdated <- as.POSIXct(data$Last.Updated, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC")

  pm25 <- data[data$Pollutant == "PM2.5" & !is.na(data$City) & data$City != "", ]
  pm25 <- pm25[grepl("[A-Za-z]", pm25$City), ]

  city_counts <- table(pm25$City)
  multi_obs <- names(city_counts[city_counts > 1])
  multi_time <- aggregate(LastUpdated ~ City, pm25, function(x) length(unique(x)))
  valid_cities <- intersect(multi_obs, multi_time$City[multi_time$LastUpdated > 1])

  pm25[pm25$City %in% valid_cities, ]
}
