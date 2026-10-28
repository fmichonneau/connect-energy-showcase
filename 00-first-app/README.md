# First app: from app.R to Connect through Git

A minimal Shiny app (one region compared with the world, from a small CSV) used to show the whole publishing path once: write the app, create its manifest, push it to Git, and import it into Connect.

## Run locally

From this folder:

```r
shiny::runApp()
```

## Publish it from Git

1. Create the manifest from the repository root, in the R console:

   ```r
   rsconnect::writeManifest("00-first-app")
   ```

   This writes `manifest.json` next to `app.R`. It records the content type (`shiny`), the R version, every package with its exact version (shiny, bslib, and their dependencies), and the files in the folder.

2. Commit `app.R`, `electricity-access.csv`, `README.md`, and `manifest.json`, then push.

3. On Connect: **Content** > **Publish** > **Import from Git**. Enter the repository URL, pick the branch, pick the folder `00-first-app`, and deploy.

## Update it

Change the `title` in `app.R`, commit, and push. Then on Connect: **Settings** > **Source** > **Update Now**, or wait for the next automatic check (every 15 minutes by default).

A title change adds no package, so the manifest stays as it is. Run `rsconnect::writeManifest()` again whenever you add, remove, or update a package. If you add a package and skip this step, Connect does not install it, and the app fails when it starts.
