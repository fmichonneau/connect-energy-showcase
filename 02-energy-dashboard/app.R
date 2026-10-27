library(shiny)
library(bslib)
library(bsicons)
library(dplyr)
library(DT)
library(pins)
library(nanoparquet) # pins reads Parquet pins through nanoparquet
library(plotly)

# Live update demo: edit this title in Positron, then commit and push.
app_title <- "Energy access explorer"

indicator_choices <- c(
  "Access to electricity (% of population)" = "elec_access",
  "Rural access to electricity (% of rural population)" = "elec_access_rural",
  # Live update demo: uncomment the next line to add urban access.
  # "Urban access to electricity (% of urban population)" = "elec_access_urban",
  "Renewable energy (% of final energy consumption)" = "renewable_share",
  "GDP per capita (current US$)" = "gdp_pc",
  "People without electricity" = "pop_no_elec"
)

# Fixed region colors, shared by every app in the showcase.
region_colors <- c(
  "Sub-Saharan Africa" = "#2a78d6",
  "South Asia" = "#eb6834",
  "East Asia & Pacific" = "#1baf7a",
  "Latin America & Caribbean" = "#eda100",
  "Middle East, North Africa, Afghanistan & Pakistan" = "#e87ba4",
  "Europe & Central Asia" = "#008300",
  "North America" = "#6250d6",
  "World" = "#52514e"
)

energy_board <- function() {
  name <- Sys.getenv("ENERGY_PIN", "energy_indicators")
  if (nzchar(Sys.getenv("CONNECT_SERVER")) && nzchar(Sys.getenv("CONNECT_API_KEY"))) {
    list(board = board_connect(auth = "envvar"), name = name)
  } else {
    list(
      board = board_folder(Sys.getenv("ENERGY_PINS_DIR", "../_pins")),
      name = basename(name)
    )
  }
}

format_value <- function(x, indicator) {
  switch(
    indicator,
    gdp_pc = paste0("$", formatC(round(x), format = "d", big.mark = ",")),
    pop_no_elec = paste0(formatC(x / 1e6, format = "f", digits = 1, big.mark = ","), " million"),
    paste0(formatC(x, format = "f", digits = 1), "%")
  )
}

latest <- function(data) {
  data |>
    group_by(iso3) |>
    slice_max(year, n = 1, with_ties = FALSE) |>
    ungroup()
}

ui <- page_sidebar(
  title = app_title,
  theme = bs_theme(
    version = 5,
    primary = "#2a78d6",
    bg = "#fcfcfb",
    fg = "#0b0b0b",
    base_font = font_collection("system-ui", "-apple-system", "Segoe UI", "sans-serif")
  ),
  sidebar = sidebar(
    selectInput("indicator", "Indicator", choices = indicator_choices),
    selectInput(
      "region",
      "Countries in region",
      choices = setdiff(names(region_colors), "World"),
      selected = "Sub-Saharan Africa"
    ),
    p(
      class = "small text-muted",
      "Source: World Development Indicators, via the Data360 API."
    )
  ),
  layout_column_wrap(
    width = "220px",
    fill = FALSE,
    value_box(
      title = "World, latest year",
      value = textOutput("world_value"),
      showcase = bs_icon("globe2"),
      showcase_layout = "top right",
      p(textOutput("world_year", inline = TRUE))
    ),
    value_box(
      title = "Sub-Saharan Africa, latest year",
      value = textOutput("ssa_value"),
      showcase = bs_icon("lightning-charge"),
      showcase_layout = "top right",
      p(textOutput("ssa_year", inline = TRUE))
    ),
    value_box(
      title = "Data refreshed",
      value = textOutput("refreshed"),
      showcase = bs_icon("arrow-repeat"),
      showcase_layout = "top right",
      p("by the scheduled pipeline")
    )
  ),
  layout_columns(
    col_widths = c(8, 4),
    card(
      full_screen = TRUE,
      card_header(textOutput("chart_title", inline = TRUE)),
      plotlyOutput("trend", height = "100%")
    ),
    card(
      full_screen = TRUE,
      card_header(textOutput("table_title", inline = TRUE)),
      DTOutput("countries")
    )
  )
)

server <- function(input, output, session) {
  # Read per session, so a new pipeline run shows up on the next page load.
  pin <- energy_board()
  energy <- pin_read(pin$board, pin$name)
  meta <- pin_meta(pin$board, pin$name)

  selected <- reactive(filter(energy, indicator == input$indicator))
  label <- reactive(names(indicator_choices)[indicator_choices == input$indicator])

  area_latest <- function(code) {
    row <- selected() |> filter(iso3 == code) |> latest()
    if (nrow(row) == 0) return(list(value = "No data", year = ""))
    list(
      value = format_value(row$value, input$indicator),
      year = paste("Year:", row$year)
    )
  }

  output$world_value <- renderText(area_latest("WLD")$value)
  output$world_year <- renderText(area_latest("WLD")$year)
  output$ssa_value <- renderText(area_latest("SSF")$value)
  output$ssa_year <- renderText(area_latest("SSF")$year)
  output$refreshed <- renderText({
    refreshed <- as.POSIXct(meta$user$refreshed_at, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC")
    format(refreshed, "%d %b %Y, %H:%M UTC")
  })

  output$chart_title <- renderText(paste(label(), "by region"))
  output$table_title <- renderText(paste(input$region, "countries, latest year"))

  output$trend <- renderPlotly({
    axis <- switch(
      input$indicator,
      gdp_pc = list(scale = 1, hover = "$%{y:,.0f}", ticks = "$,.0f"),
      pop_no_elec = list(scale = 1e6, hover = "%{y:,.1f} million", ticks = ",.0f"),
      list(scale = 1, hover = "%{y:.1f}%", ticks = ".0f")
    )
    region_levels <- setdiff(names(region_colors), "World")
    lines <- selected() |>
      filter(area_type %in% c("region", "world")) |>
      mutate(value = value / axis$scale) |>
      arrange(year)
    # The long region name wraps in the legend; colors still match on the factor level.
    legend_names <- sub("North Africa, ", "North Africa,<br>", region_levels)
    regions <- lines |>
      filter(area_type == "region") |>
      mutate(name = factor(name, levels = region_levels, labels = legend_names))
    world <- filter(lines, area_type == "world")

    plot_ly(
      regions,
      x = ~year,
      y = ~value,
      color = ~name,
      colors = setNames(region_colors[region_levels], legend_names),
      type = "scatter",
      mode = "lines",
      line = list(width = 2),
      hovertemplate = axis$hover
    ) |>
      add_trace(
        data = world,
        x = ~year,
        y = ~value,
        name = "World",
        inherit = FALSE,
        type = "scatter",
        mode = "lines",
        line = list(color = region_colors[["World"]], width = 2, dash = "dash"),
        hovertemplate = axis$hover
      ) |>
      layout(
        font = list(family = "system-ui, -apple-system, Segoe UI, sans-serif", color = "#52514e"),
        paper_bgcolor = "#fcfcfb",
        plot_bgcolor = "#fcfcfb",
        hovermode = "x unified",
        xaxis = list(title = "", gridcolor = "#e1e0d9", zeroline = FALSE),
        yaxis = list(
          title = if (axis$scale == 1e6) "millions" else "",
          gridcolor = "#e1e0d9",
          zeroline = FALSE,
          tickformat = axis$ticks
        ),
        legend = list(x = 1.02, xanchor = "left", y = 1, font = list(size = 11))
      ) |>
      config(displayModeBar = FALSE)
  })

  output$countries <- renderDT({
    table <- selected() |>
      filter(area_type == "country", region == input$region) |>
      latest() |>
      arrange(desc(value)) |>
      transmute(
        Country = name,
        Year = as.integer(year),
        Value = format_value(value, input$indicator)
      )

    datatable(
      table,
      rownames = FALSE,
      class = "display nowrap",
      fillContainer = TRUE,
      options = list(dom = "ft", paging = FALSE, ordering = FALSE)
    )
  })
}

shinyApp(ui, server)
