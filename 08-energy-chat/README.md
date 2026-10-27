# Ask the energy data (Shiny for R with querychat)

A chat in the sidebar turns questions into SQL over the energy data (one row per area and year, indicators as columns). The table shows the result and the footer shows the SQL that produced it. The badge in the header names the model provider in use.

## Where the model credentials come from

| Where the app runs | Provider | Credential |
| --- | --- | --- |
| Your laptop (default) | Posit AI (`ellmer::chat_posit()`) | Your personal Posit AI sign-in, cached on your machine |
| Connect, with an Anthropic integration attached | Anthropic (`ellmer::chat_anthropic()`) | `ANTHROPIC_API_KEY`, set by Connect from the integration |

Locally the app uses Posit AI even if `ANTHROPIC_API_KEY` is set in your own environment. Set `ENERGY_CHAT_PROVIDER` to `anthropic` or `posit` to override, and `ENERGY_CHAT_MODEL` to pick a model.

Do not deploy this app with your personal Posit AI credentials. On Connect, attach an Anthropic integration in the content's Runtime tab (**Add Integrations**). Without one, the app starts but the chat cannot sign in.

## Before the demo

Sign in to Posit AI once from the Positron console so the token is cached:

```r
ellmer::chat_posit()$chat("Hello")
```

Follow the device code prompt. Later runs reuse the cached token.

## Run locally

Run `01-energy-pipeline` once so `apps/_pins` exists, then from this folder:

```r
shiny::runApp()
```

Questions that work well:

- Which five countries gained the most electricity access since 2015?
- Show low income countries where rural access is below 20%.
- How many people in Sub-Saharan Africa lacked electricity each year?

The chat can filter the table and run queries. Chart generation is off because it needs the `ggsql` package.

## Deploy

Import from Git (see `../README.md`), folder `08-energy-chat`. Then, on the Runtime tab, **Add Integrations** and pick an Anthropic integration if the server has one. Without one, the app starts but the chat cannot reach a model; run it locally in Positron instead.

`duckdb` is loaded explicitly in `app.R` because querychat only suggests it, and Connect would not install it otherwise.
