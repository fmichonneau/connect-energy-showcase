# energy-quicklook (Streamlit)

One country at a glance: access to electricity (total, urban, rural), people without electricity, and the renewable share of energy use.

**Show during the demo:**

- The Source tab: Python version and the packages Connect installed from `requirements.txt`. No ticket to IT to install a package.
- The Logs: each visit prints `Viewing <country>`.

## Run locally

```bash
uv venv -p 3.13 .venv && uv pip install -p .venv -r requirements.txt
.venv/bin/streamlit run app.py
```

## Deploy (git-backed)

Import from Git (see `../README.md`), folder `03-energy-quicklook`. Then set Min processes to 1 and the `energy-showcase` tag.

To add a package: add it to `requirements.txt`, then `rsconnect write-manifest streamlit --overwrite -x .venv .`, commit, push.
