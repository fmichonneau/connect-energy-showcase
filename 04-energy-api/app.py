"""Energy access API: serves the energy_indicators pin as JSON."""

import os
import time
from pathlib import Path
from typing import Literal

import pandas as pd
import pins
from fastapi import FastAPI, HTTPException, Query
from fastapi.responses import RedirectResponse
from pydantic import BaseModel

CACHE_SECONDS = 600

app = FastAPI(
    title="Energy access API",
    description=(
        "Access to electricity, renewable energy share, GDP per capita, and population "
        "from the Data360 API, refreshed daily by the energy-pipeline "
        "document on Posit Connect."
    ),
    version="1.0.0",
)


def energy_board():
    """Pin board and pin name: Connect when running there, a local folder otherwise."""
    name = os.getenv("ENERGY_PIN", "energy_indicators")
    if os.getenv("CONNECT_SERVER") and os.getenv("CONNECT_API_KEY"):
        board = pins.board_connect()
        if "/" not in name:
            name = f"{board.user_name}/{name}"
        return board, name
    local_dir = os.getenv("ENERGY_PINS_DIR", Path(__file__).resolve().parent.parent / "_pins")
    return pins.board_folder(str(local_dir)), name.split("/")[-1]


_cache: dict = {"loaded_at": 0.0, "data": None, "meta": None}


def energy_data() -> tuple[pd.DataFrame, dict]:
    """Read the pin, at most once every CACHE_SECONDS."""
    if _cache["data"] is None or time.time() - _cache["loaded_at"] > CACHE_SECONDS:
        board, name = energy_board()
        _cache["data"] = board.pin_read(name)
        _cache["meta"] = board.pin_meta(name).user
        _cache["loaded_at"] = time.time()
        print(f"Loaded pin {name}: {len(_cache['data']):,} rows")
    return _cache["data"], _cache["meta"]


class Indicator(BaseModel):
    code: str
    label: str
    unit: str
    latest_year: int


class Area(BaseModel):
    iso3: str
    name: str
    area_type: str
    region: str
    income_group: str | None


class Observation(BaseModel):
    iso3: str
    name: str
    year: int
    value: float


class LatestValue(BaseModel):
    year: int
    value: float


class AreaLatest(Area):
    values: dict[str, LatestValue]


class Status(BaseModel):
    source: str
    refreshed_at: str
    rows: int


@app.get("/", include_in_schema=False)
def root():
    return RedirectResponse(url="docs")


@app.get("/status", response_model=Status, summary="When the data was last refreshed")
def status():
    data, meta = energy_data()
    return Status(source=meta["source"], refreshed_at=meta["refreshed_at"], rows=len(data))


@app.get("/indicators", response_model=list[Indicator], summary="List indicators")
def indicators():
    data, _ = energy_data()
    out = (
        data.groupby(["indicator", "indicator_label", "unit"], as_index=False)["year"]
        .max()
        .rename(columns={"indicator": "code", "indicator_label": "label", "year": "latest_year"})
    )
    return out.to_dict(orient="records")


@app.get("/areas", response_model=list[Area], summary="List countries, regions, and the world")
def areas(
    area_type: Literal["country", "region", "world"] | None = Query(None, description="Filter by area type"),
    region: str | None = Query(None, description="Region, for example 'Sub-Saharan Africa'"),
):
    data, _ = energy_data()
    out = data[["iso3", "name", "area_type", "region", "income_group"]].drop_duplicates("iso3")
    if area_type:
        out = out[out["area_type"] == area_type]
    if region:
        out = out[out["region"] == region]
    out = out.astype(object).where(out.notna(), None)
    return out.sort_values("name").to_dict(orient="records")


@app.get(
    "/observations/{indicator}",
    response_model=list[Observation],
    summary="Time series for one indicator",
)
def observations(
    indicator: str,
    area: list[str] = Query(["WLD"], description="One or more ISO3 or region codes, for example KEN or SSF"),
    from_year: int = Query(2000, ge=2000),
    to_year: int | None = Query(None),
):
    data, _ = energy_data()
    if indicator not in set(data["indicator"]):
        raise HTTPException(status_code=404, detail=f"Unknown indicator '{indicator}'. See /indicators.")
    rows = data[(data["indicator"] == indicator) & data["iso3"].isin(area) & (data["year"] >= from_year)]
    if to_year is not None:
        rows = rows[rows["year"] <= to_year]
    return rows[["iso3", "name", "year", "value"]].sort_values(["iso3", "year"]).to_dict(orient="records")


@app.get(
    "/latest",
    response_model=list[AreaLatest],
    summary="Latest value of every indicator, per area",
)
def latest(
    region: str | None = Query(None, description="Region, for example 'Sub-Saharan Africa'"),
    area_type: Literal["country", "region", "world"] = Query("country"),
):
    data, _ = energy_data()
    rows = data[data["area_type"] == area_type]
    if region:
        rows = rows[rows["region"] == region]
    last = rows.sort_values("year").groupby(["iso3", "indicator"]).tail(1)

    result = []
    for iso3, group in last.groupby("iso3"):
        first = group.iloc[0]
        result.append({
            "iso3": iso3,
            "name": first["name"],
            "area_type": first["area_type"],
            "region": first["region"],
            "income_group": None if pd.isna(first["income_group"]) else first["income_group"],
            "values": {
                r.indicator: {"year": int(r.year), "value": float(r.value)}
                for r in group.itertuples()
            },
        })
    return sorted(result, key=lambda r: r["name"])
