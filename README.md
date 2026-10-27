# Energy access showcase: demo content for Posit Connect

Small apps built around one dataset, each chosen to show a Connect feature rather than to be a full product. Every item deploys to Posit Connect from this repository as Git-backed content.

| Folder | Content type | Connect feature it carries |
| --- | --- | --- |
| `01-energy-pipeline` | Quarto document, Python | Scheduled rendering, pins, run history, failure emails |
| `02-energy-dashboard` | Shiny for R | Runtime settings, usage metrics, live update from a Git push, custom URL |
| `03-energy-quicklook` | Streamlit | Environment rebuilt from `requirements.txt`, logs |
| `04-energy-api` | FastAPI | Generated API docs, API keys, access control on an API |
| `05-country-cards` | Node.js (Express) | New content type, environment variables, one content item calling another |
| `06-weekly-energy-brief` | Quarto document, R | Schedules, custom email, conditional sending |
| `08-energy-chat` | Shiny for R with querychat | AI provider credentials kept out of code |

## Data contract

`01-energy-pipeline` writes one pin, `energy_indicators` (Parquet), that every other app reads. Long format, one row per area, indicator, and year, from 2000 onward:

| Column | Type | Notes |
| --- | --- | --- |
| `iso3` | string | ISO3 code for countries; `SSF`, `SAS`, `EAS`, `LCN`, `MEA`, `ECS`, `NAC` for regions; `WLD` for the world |
| `name` | string | Display name |
| `area_type` | string | `country`, `region`, or `world` |
| `region` | string | WDI region of a country; for a region row, its own name; `World` for `WLD` |
| `income_group` | string | Countries only; missing for regions and the world |
| `indicator` | string | Short code, see below |
| `indicator_label` | string | Display label |
| `unit` | string | Display unit |
| `year` | integer | |
| `value` | double | |

| `indicator` | Label | Unit |
| --- | --- | --- |
| `elec_access` | Access to electricity | % of population |
| `elec_access_rural` | Access to electricity, rural | % of rural population |
| `elec_access_urban` | Access to electricity, urban | % of urban population |
| `renewable_share` | Renewable energy consumption | % of total final energy consumption |
| `gdp_pc` | GDP per capita | current US$ |
| `population` | Population | people |
| `pop_no_elec` | People without electricity | people (population × (100 − access) / 100) |

Pin metadata: `source`, `refreshed_at` (ISO 8601, UTC), `start_year`, `latest_years` (indicator to latest year).

## Where the pin lives

- On Connect, `CONNECT_SERVER` and `CONNECT_API_KEY` are set automatically for every content item, so apps use `board_connect()`. The pin is owned by whoever owns the pipeline. R reads it with the bare name; Python needs `user/name` and the helpers add the owner's user name.
- Locally, with no `CONNECT_SERVER`, apps read a folder board at `apps/_pins` (override with `ENERGY_PINS_DIR`). Run the pipeline once to create it.
- `ENERGY_PIN` overrides the pin name in either case. Set it to `owner/energy_indicators` if the apps are owned by someone other than the pipeline owner.

If an administrator turns off the automatic `CONNECT_API_KEY` (`Applications.DefaultAPIKeyEnv`), set `CONNECT_API_KEY` in each item's Runtime tab (environment variables) instead.

## Shared look

Region colors are fixed per region, so a region keeps its color in every app:

| Region | Code | Color |
| --- | --- | --- |
| Sub-Saharan Africa | SSF | `#2a78d6` |
| South Asia | SAS | `#eb6834` |
| East Asia & Pacific | EAS | `#1baf7a` |
| Latin America & Caribbean | LCN | `#eda100` |
| Middle East, North Africa, Afghanistan & Pakistan | MEA | `#e87ba4` |
| Europe & Central Asia | ECS | `#008300` |
| North America | NAC | `#6250d6` |
| World (reference line, dashed) | WLD | `#52514e` |

Single-series charts use `#2a78d6`. Ink: primary `#0b0b0b`, secondary `#52514e`, muted `#898781`, gridlines `#e1e0d9`, surface `#fcfcfb`. Font: system sans.

## Local development

```bash
# 1. Build the data (Python 3.13 virtual environment)
cd 01-energy-pipeline
uv venv -p 3.13 .venv && uv pip install -p .venv -r requirements.txt
QUARTO_PYTHON=.venv/bin/python quarto render index.qmd
```

Then run any app from its folder; see the README in each folder.

## Deploying to Connect

Each folder is a separate content item with its own `manifest.json`. The manifest tells Connect the content type, the entry point, the language versions, and the packages to install. Connect deploys everything in the folder that is committed to Git (it uses `git archive`), so keep virtual environments, `node_modules`, and rendered output out of the repository; `.gitignore` handles that.

**First deployment of each item**

1. On Connect: **Content** > **Publish** > **Import from Git**.
2. Enter the repository URL and pick the branch (`main`).
3. Pick the folder. Connect lists every folder that contains a `manifest.json`.
4. Enter a title and click **Deploy Content**.

Deploy `01-energy-pipeline` first and let it run once, so the pin exists. Then `04-energy-api`, then the rest.

**Updating**

1. Change the code. If you added or removed a package, regenerate the manifest (table below).
2. Commit and push.
3. Connect checks the branch every 15 minutes by default. To deploy immediately: **Settings** > **Source** > **Update Now**.

Only items whose folder changed are redeployed. Connect cannot mix update methods: Git-backed content cannot also be updated from Posit Publisher or `rsconnect::deployApp()`.

**Regenerating a manifest** (run from the item's folder)

| Folder | Command |
| --- | --- |
| `01-energy-pipeline` | `rsconnect write-manifest quarto --overwrite -x .venv -x index.html -x index_files index.qmd` |
| `02-energy-dashboard` | `Rscript -e 'rsconnect::writeManifest(appPrimaryDoc = "app.R")'` |
| `03-energy-quicklook` | `rsconnect write-manifest streamlit --overwrite -x .venv .` |
| `04-energy-api` | `rsconnect write-manifest fastapi --overwrite -e app:app -x .venv .` |
| `05-country-cards` | `rsconnect write-manifest nodejs --overwrite -x node_modules .` |
| `06-weekly-energy-brief` | `Rscript -e 'rsconnect::writeManifest(appFiles = "index.qmd", appPrimaryDoc = "index.qmd", quarto = TRUE)'` |
| `08-energy-chat` | `Rscript -e 'rsconnect::writeManifest(appFiles = c("app.R", "data_description.md"))'` |

Python packages come from each folder's `requirements.txt`: edit it first, then regenerate. R packages come from your installed library, so the manifest records the versions you have locally. The `rsconnect` commands need rsconnect-python 1.29.0 or later (Node.js support).
