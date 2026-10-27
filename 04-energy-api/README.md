# energy-api (FastAPI)

JSON API over the `energy_indicators` pin. The `country-cards` Node.js app calls it.

| Endpoint | Returns |
| --- | --- |
| `/status` | Source and refresh time of the data |
| `/indicators` | Indicator codes, labels, units, latest year |
| `/areas` | Countries, regions, and the world, filterable by `area_type` and `region` |
| `/observations/{indicator}?area=KEN&area=SSF&from_year=2010` | Time series |
| `/latest?region=Sub-Saharan Africa` | Latest value of every indicator, per country |

**Show during the demo:** the generated documentation page (the content's landing page), "Try it out" on `/latest`, then a call with an API key from a terminal:

```bash
curl -H "Authorization: Key $CONNECT_API_KEY" "<content-url>/observations/elec_access?area=KEN"
```

Set access to "All users, login required" so every call needs a key. A plumber API in R works the same way on Connect.

## Run locally

```bash
uv venv -p 3.13 .venv && uv pip install -p .venv -r requirements.txt uvicorn
.venv/bin/uvicorn app:app --port 8000
```

## Deploy

Import from Git (see `../README.md`), folder `04-energy-api`. Then:

- **Access**: "All users, login required", so every call needs an API key.
- **Custom URL**: `/energy-api/`. `country-cards` uses it.
- Tag `energy-showcase`.
