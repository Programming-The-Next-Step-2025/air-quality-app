#' @import shiny
#' @import shinydashboard
#' @import leaflet
#' @import sf
#' @import utils
#' @import ggplot2


# Load the CSV with semicolon separator
air_data <- air_data <- read.csv(system.file("extdata", "openaq.csv", package = "PM25App"), sep = ";", stringsAsFactors = FALSE)

# Split the Coordinates column into Latitude and Longitude
coords <- strsplit(air_data$Coordinates, ",")
lat <- sapply(coords, function(x) as.numeric(x[1]))
lon <- sapply(coords, function(x) as.numeric(x[2]))

# Add Latitude and Longitude as new columns
air_data$Latitude <- lat
air_data$Longitude <- lon

# Convert Last Updated column to Date-Time (if needed)
air_data$LastUpdated <- as.POSIXct(air_data$Last.Updated, format="%Y-%m-%dT%H:%M:%S", tz="UTC")

# Step 1: Filter only PM2.5 records
pm25_data <- air_data[air_data$Pollutant == "PM2.5", ]

# Step 2: Remove rows with missing city names
pm25_data <- pm25_data[!is.na(pm25_data$City), ]

# Step 3: Keep cities with more than one observation
city_counts <- table(pm25_data$City)
cities_with_multiple_rows <- names(city_counts[city_counts > 1])

# Step 4: Keep cities with more than one unique timestamp
city_timestamps <- aggregate(LastUpdated ~ City, data = pm25_data, FUN = function(x) length(unique(x)))
cities_with_multiple_times <- city_timestamps$City[city_timestamps$LastUpdated > 1]

# Step 5: Intersect both conditions
valid_cities <- intersect(cities_with_multiple_rows, cities_with_multiple_times)
pm25_data <- pm25_data[pm25_data$City %in% valid_cities, ]

pm25_data <- pm25_data[!is.na(pm25_data$City) & pm25_data$City != "", ]
pm25_data <- pm25_data[grepl("[A-Za-z]", pm25_data$City), ]
# UI
ui <- shinydashboard::dashboardPage(
  shinydashboard::dashboardHeader(title = "PM2.5 Air Quality in Europe"),
  shinydashboard::dashboardSidebar(
    selectInput("selected_city", "Select a city:", choices = sort(unique(pm25_data$City)))
  ),
  shinydashboard::dashboardBody(
    fluidRow(
      shinydashboard::box(
        title = "PM2.5 by City", status = "primary", solidHeader = TRUE, width = 6,
        plotOutput("pm25_plot")
      ),
      shinydashboard::box(
        title = "Map of PM2.5 Stations", status = "info", solidHeader = TRUE, width = 6,
        leaflet::leafletOutput("pm25_map", height = "500px")
      )
    )
  )
)

#server
server <- function(input, output, session) {

  # Load the cleaned PM2.5 data once
  pm25_data <- load_pm25_data()

  # Reactively filter based on selected city
  filtered <- reactive({
    filtered_data(input$selected_city, pm25_data)
  })

  # Render the plot
  output$pm25_plot <- renderPlot({
    data <- filtered()
    if (nrow(data) == 0) {
      plot.new()
      text(0.5, 0.5, "No data available for selected city", cex = 1.2)
    } else if (nrow(data) == 1) {
      ggplot(data, aes(x = LastUpdated, y = Value)) +
        geom_point(color = "darkred", size = 3) +
        labs(title = paste("PM2.5 on", input$selected_city),
             x = "Date", y = "PM2.5 (µg/m³)") +
        theme_minimal()
    } else {
      ggplot(data, aes(x = LastUpdated, y = Value)) +
        geom_line(color = "darkred") +
        labs(title = paste("PM2.5 Over Time in", input$selected_city),
             x = "Date", y = "PM2.5 (µg/m³)") +
        theme_minimal()
    }
  })

  # Render the map
  output$pm25_map <- leaflet::renderLeaflet({
    leaflet::leaflet(pm25_data) %>%
      leaflet::addTiles() %>%
      leaflet::addCircleMarkers(
        lng = ~Longitude,
        lat = ~Latitude,
        label = ~paste(City, "<br>PM2.5:", Value),
        color = "red",
        radius = 3,
        layerId = ~City
      )
  })

  # Allow clicking on map markers to update the city selector
  observeEvent(input$pm25_map_marker_click, {
    city_clicked <- input$pm25_map_marker_click$id
    if (!is.null(city_clicked)) {
      updateSelectInput(session, "selected_city", selected = city_clicked)
    }
  })
}

#' @export
startApp <- function() {
  shinyApp(ui = ui, server = server)
}
startApp()
