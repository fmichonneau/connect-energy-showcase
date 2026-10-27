# country-cards (Node.js, Express)

One card per country for a chosen region, sorted by the number of people without electricity. The data comes from the `energy-api` content item, not from the pin.

**Show during the demo:**

- Node.js runs on Connect like any other content type (generally available since Connect 2026.06.0).
- The Runtime tab: `ENERGY_API_URL` points at the energy-api content item.
- No API key anywhere: Connect gives every content item a short-lived key for its owner in `CONNECT_API_KEY`, and the app sends it to the API.

## Run locally

Start `energy-api` on port 8000 first, then:

```bash
npm install
ENERGY_API_URL=http://127.0.0.1:8000 npm start
```

## Deploy

Import from Git (see `../README.md`), folder `05-country-cards`. Deploy `04-energy-api` first. Then set `ENERGY_API_URL` on the Runtime tab (environment variables) to the energy-api URL, for example `https://<server>/energy-api/`, and add the `energy-showcase` tag.

Regenerating the manifest needs rsconnect-python 1.29.0 or later: `rsconnect write-manifest nodejs --overwrite -x node_modules .`
