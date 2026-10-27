library(shiny)
library(bslib)
library(dplyr)
library(DT)
library(duckdb) # querychat runs SQL on data frames through DuckDB
library(ellmer)
library(pins)
library(nanoparquet) # pins reads Parquet pins through nanoparquet
library(querychat)

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

# On Connect, an Anthropic integration sets ANTHROPIC_API_KEY for this content.
# Locally, the app uses a personal Posit AI account, even if ANTHROPIC_API_KEY is
# set in your own environment. ENERGY_CHAT_PROVIDER ("anthropic" or "posit")
# overrides the choice.
chat_client <- function() {
  model <- Sys.getenv("ENERGY_CHAT_MODEL")
  model <- if (nzchar(model)) model
  on_connect <- Sys.getenv("POSIT_PRODUCT") == "CONNECT"
  has_key <- nzchar(Sys.getenv("ANTHROPIC_API_KEY"))
  provider <- Sys.getenv("ENERGY_CHAT_PROVIDER")
  if (!nzchar(provider)) provider <- if (on_connect && has_key) "anthropic" else "posit"

  if (provider == "anthropic") {
    list(
      client = chat_anthropic(model = model),
      label = if (on_connect) "Anthropic, through a Connect integration" else "Anthropic, local API key"
    )
  } else {
    list(
      client = chat_posit(model = model),
      label = if (on_connect) "Posit AI" else "Posit AI, personal account (local)"
    )
  }
}

pin <- energy_board()
energy <- pin_read(pin$board, pin$name) |>
  select(iso3, name, area_type, region, income_group, indicator, year, value) |>
  tidyr::pivot_wider(names_from = indicator, values_from = value) |>
  mutate(year = as.integer(year)) |>
  arrange(name, year)

provider <- chat_client()

qc <- QueryChat$new(
  energy,
  table_name = "energy",
  client = provider$client,
  tools = c("filter", "query"),
  history = FALSE,
  greeting = paste(
    "Ask a question about electricity access and development since 2000.",
    "For example:",
    "",
    "* Which five countries gained the most electricity access since 2015?",
    "* Show low income countries where rural access is below 20%.",
    "* How many people in Sub-Saharan Africa lacked electricity each year?",
    sep = "\n"
  ),
  data_description = "data_description.md"
)

ui <- page_sidebar(
  window_title = "Ask the energy data",
  title = tagList(
    "Ask the energy data",
    span(class = "badge text-bg-light border ms-2 fw-normal", paste("Model:", provider$label))
  ),
  theme = bs_theme(
    version = 5,
    primary = "#2a78d6",
    bg = "#fcfcfb",
    fg = "#0b0b0b",
    base_font = font_collection("system-ui", "-apple-system", "Segoe UI", "sans-serif")
  ),
  sidebar = qc$sidebar(),
  card(
    full_screen = TRUE,
    card_header(textOutput("view_title", inline = TRUE)),
    DTOutput("table"),
    card_footer(code(textOutput("sql", inline = TRUE)))
  )
)

server <- function(input, output, session) {
  qc_vals <- qc$server()

  output$view_title <- renderText(
    if (isTruthy(qc_vals$title())) qc_vals$title() else "All areas and years"
  )
  output$sql <- renderText(
    if (isTruthy(qc_vals$sql())) qc_vals$sql() else "SELECT * FROM energy"
  )
  output$table <- renderDT({
    df <- as.data.frame(qc_vals$df())
    decimals <- names(df)[vapply(df, is.double, logical(1))]
    table <- datatable(
      df,
      rownames = FALSE,
      class = "display compact nowrap",
      fillContainer = TRUE,
      options = list(dom = "tip", pageLength = 15, scrollX = TRUE)
    )
    if (length(decimals) > 0) table <- formatRound(table, decimals, digits = 1)
    table
  })
}

shinyApp(ui, server)
