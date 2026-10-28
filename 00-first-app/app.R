library(shiny)
library(bslib)

# Share of the population with access to electricity, 2000 onwards
access <- read.csv("electricity-access.csv")
regions <- setdiff(unique(access$area), "World")

ui <- page_sidebar(
  title = "Access to electricity",
  sidebar = sidebar(
    selectInput("region", "Region", choices = regions, selected = "Sub-Saharan Africa")
  ),
  card(
    card_header(textOutput("heading")),
    plotOutput("trend")
  )
)

server <- function(input, output) {
  output$heading <- renderText(paste(input$region, "compared with the world"))

  output$trend <- renderPlot({
    region <- access[access$area == input$region, ]
    world <- access[access$area == "World", ]
    plot(world$year, world$access, type = "l", lty = 2, lwd = 2, col = "#52514e",
         ylim = c(0, 100), xlab = "", ylab = "% of population", las = 1, bty = "n")
    lines(region$year, region$access, lwd = 3, col = "#2a78d6")
    legend("bottomright", legend = c(input$region, "World"), col = c("#2a78d6", "#52514e"),
           lty = c(1, 2), lwd = c(3, 2), bty = "n")
  }, res = 96)
}

shinyApp(ui, server)
