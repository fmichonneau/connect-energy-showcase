# energy-pipeline (Quarto, Python)

Downloads six World Development Indicators from the public Data360 API, holds back implausible values, computes "people without electricity", and writes everything to the pin `energy_indicators`. Every other app reads that pin.

**Show during the demo:** the Schedule tab (daily), the history of past renders, the "Data checks" section, and the pin itself on Connect. If a run fails (for example, the API is down), Connect emails the owner with a link to the log.

The data check currently holds back one value that is wrong at the source: Chad, rural access to electricity, 2024 = 100% (0.4% in 2023). Both Data360 and the WDI v2 API report it.

## Run locally

```bash
uv venv -p 3.13 .venv && uv pip install -p .venv -r requirements.txt
QUARTO_PYTHON=.venv/bin/python quarto render index.qmd
```

This writes the pin to the folder board `../_pins`.

## Deploy

Import from Git (see `../README.md`), folder `01-energy-pipeline`. Then:

- **Schedule** tab: daily at 6:00 AM ET. Run it once now so the pin exists before you deploy the other items.
- Tag it `energy-showcase`.

The pin is owned by whoever owns this content item. Deploy the other items as the same user, or set `ENERGY_PIN=<owner>/energy_indicators` on their Runtime tab (environment variables).
