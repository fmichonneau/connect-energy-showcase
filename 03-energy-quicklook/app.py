"""Energy quick-look: one country's electricity access at a glance."""

import os
from pathlib import Path

import altair as alt
import pandas as pd
import pins
import streamlit as st

BLUE, ORANGE, AQUA = "#2a78d6", "#eb6834", "#1baf7a"
INK_2, GRID = "#52514e", "#e1e0d9"
BASELINE_YEAR = 2015

st.set_page_config(page_title="Energy quick-look", layout="wide")


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


@st.cache_data(ttl=600)
def load_energy() -> tuple[pd.DataFrame, dict]:
    board, name = energy_board()
    data = board.pin_read(name)
    print(f"Loaded pin {name}: {len(data):,} rows")
    return data, board.pin_meta(name).user


def axis_chart(chart: alt.Chart) -> alt.Chart:
    return chart.configure_axis(gridColor=GRID, domainColor=GRID, labelColor=INK_2, titleColor=INK_2).configure_view(
        strokeWidth=0
    )


energy, meta = load_energy()
countries = (
    energy.query("area_type == 'country'")[["iso3", "name"]].drop_duplicates().sort_values("name")
)
names = countries["name"].tolist()

st.title("Energy quick-look")
country = st.selectbox("Country", names, index=names.index("Kenya") if "Kenya" in names else 0)
print(f"Viewing {country}")

df = energy[energy["name"] == country]


def series(indicator: str) -> pd.DataFrame:
    return df[df["indicator"] == indicator].sort_values("year")


access = series("elec_access")
no_elec = series("pop_no_elec")

# Headline numbers
col1, col2, col3 = st.columns(3)
if not access.empty:
    latest = access.iloc[-1]
    base = access[access["year"] == BASELINE_YEAR]
    delta = f"{latest['value'] - base['value'].iloc[0]:+.1f} points since {BASELINE_YEAR}" if not base.empty else None
    col1.metric(f"Access to electricity, {latest['year']}", f"{latest['value']:.1f}%", delta)
if not no_elec.empty:
    latest = no_elec.iloc[-1]
    col2.metric(f"People without electricity, {latest['year']}", f"{latest['value'] / 1e6:,.1f} million")
renew = series("renewable_share")
if not renew.empty:
    latest = renew.iloc[-1]
    col3.metric(f"Renewable share of energy use, {latest['year']}", f"{latest['value']:.0f}%")

left, right = st.columns(2)

with left:
    st.subheader("Access to electricity")
    lines = df[df["indicator"].isin(["elec_access", "elec_access_urban", "elec_access_rural"])].replace(
        {"indicator_label": {
            "Access to electricity": "Total",
            "Access to electricity, urban": "Urban",
            "Access to electricity, rural": "Rural",
        }}
    )
    chart = (
        alt.Chart(lines)
        .mark_line(strokeWidth=2, point=alt.OverlayMarkDef(size=30))
        .encode(
            x=alt.X("year:O", title=None, axis=alt.Axis(labelAngle=0, values=list(range(2000, 2030, 5)))),
            y=alt.Y("value:Q", title="% of population", scale=alt.Scale(domain=[0, 100])),
            color=alt.Color(
                "indicator_label:N",
                title=None,
                scale=alt.Scale(domain=["Total", "Urban", "Rural"], range=[BLUE, AQUA, ORANGE]),
                legend=alt.Legend(orient="top"),
            ),
            tooltip=[alt.Tooltip("indicator_label:N", title="Series"), "year:O",
                     alt.Tooltip("value:Q", format=".1f", title="%")],
        )
        .properties(height=320)
    )
    st.altair_chart(axis_chart(chart), width="stretch")

with right:
    st.subheader("People without electricity")
    bars = (
        alt.Chart(no_elec.assign(millions=no_elec["value"] / 1e6))
        .mark_bar(color=BLUE, cornerRadiusTopLeft=4, cornerRadiusTopRight=4)
        .encode(
            x=alt.X("year:O", title=None, axis=alt.Axis(labelAngle=0, values=list(range(2000, 2030, 5)))),
            y=alt.Y("millions:Q", title="Millions of people"),
            tooltip=["year:O", alt.Tooltip("millions:Q", format=",.2f", title="Millions")],
        )
        .properties(height=320)
    )
    st.altair_chart(axis_chart(bars), width="stretch")

st.caption(f"Source: {meta['source']}. Data refreshed {meta['refreshed_at']} by the energy-pipeline document.")
