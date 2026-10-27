Energy access and development indicators from the World Development Indicators (WDI), retrieved through the Data360 API. One row per area and year, from 2000 onward.

- `iso3`: ISO3 country code. Regions use WDI aggregate codes: SSF (Sub-Saharan Africa), SAS (South Asia), EAS (East Asia & Pacific), LCN (Latin America & Caribbean), MEA (Middle East, North Africa, Afghanistan & Pakistan), ECS (Europe & Central Asia), NAC (North America). WLD is the world.
- `name`: country, region, or world name.
- `area_type`: `country`, `region`, or `world`. Filter on `area_type = 'country'` when ranking or comparing countries, so regional totals do not appear among them.
- `region`: WDI region of a country. For region rows it is the region's own name; for the world row it is `World`.
- `income_group`: WDI income group (Low income, Lower middle income, Upper middle income, High income). Missing for regions and the world.
- `year`: calendar year.
- `elec_access`: access to electricity, % of population.
- `elec_access_rural`: access to electricity, % of rural population.
- `elec_access_urban`: access to electricity, % of urban population.
- `renewable_share`: renewable energy consumption, % of total final energy consumption. Latest data is older than for the other indicators.
- `gdp_pc`: GDP per capita, current US$.
- `population`: total population.
- `pop_no_elec`: people without electricity, computed as population × (100 − elec_access) / 100.

Missing values mean the indicator is not reported for that area and year. The latest year differs by indicator, so use the latest year with data for the indicator in question rather than the maximum year in the table.
