# Energy access explorer (Shiny for R)

A bslib dashboard over the `energy_indicators` pin: pick an indicator, compare the seven regions and the world over time, and list the latest value for each country in a region.

## Connect features to point at

- **Runtime tab:** set Min processes to 1 before the session so the first click is instant, and explain why it matters.
- **Monitoring tab:** who opened the app and when, with no tracking code in the app.
- **Live update from Git** (publishing segment): edit in Positron, commit, push, **Update Now**. Then a custom URL (`/energy-access/`) and sharing with a group.

## The live change

Two edits are ready in `app.R`, both visible as soon as the app reloads:

- Change `app_title` at the top of the file (for example to "Energy access explorer: live update").
- Uncomment the "Urban access to electricity" line in `indicator_choices` to add an indicator.

Then, in Positron:

1. Regenerate the manifest so it matches the code: `rsconnect::writeManifest(appPrimaryDoc = "app.R")`. Neither edit adds a package, so only the checksum of `app.R` changes and Connect reuses the packages it already installed.
2. Source Control view: stage `app.R` and `manifest.json`, commit, push.
3. On Connect: **Settings** > **Source** > **Update Now**, then reload the app.

Do not update R packages between now and the session: the manifest would record new versions and Connect would rebuild the environment during the demo.

## Run locally

Run `01-energy-pipeline` once so `apps/_pins` exists, then from this folder:

```r
shiny::runApp()
```

## Deploy

Import from Git (see `../README.md`), folder `02-energy-dashboard`. Then set Min processes to 1, the custom URL `/energy-access/`, and the `energy-showcase` tag.

`DESCRIPTION` lists the packages the app uses; `rsconnect::writeManifest()` reads it along with `app.R`. If you add a package, add it to `DESCRIPTION` and regenerate the manifest.

On Connect, the app reads the pin owned by the same user. If someone else owns the pipeline, set `ENERGY_PIN` to `owner/energy_indicators` on the Runtime tab.
