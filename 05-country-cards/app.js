// Country cards: one card per country, built from the energy-api content item.
const express = require('express');

const app = express();
const port = process.env.PORT || 3000;
const host = process.env.HOST || '127.0.0.1';

// Address of the energy-api content item, set in the Runtime tab (environment variables) on Connect.
const apiUrl = (process.env.ENERGY_API_URL || 'http://127.0.0.1:8000').replace(/\/+$/, '');
// Connect gives every content item a short-lived API key for its owner.
const apiKey = process.env.CONNECT_API_KEY;

const REGIONS = [
  'Sub-Saharan Africa',
  'South Asia',
  'East Asia & Pacific',
  'Latin America & Caribbean',
  'Middle East, North Africa, Afghanistan & Pakistan',
  'Europe & Central Asia',
  'North America',
];

async function fetchLatest(region) {
  const url = `${apiUrl}/latest?region=${encodeURIComponent(region)}`;
  const headers = apiKey ? { Authorization: `Key ${apiKey}` } : {};
  const res = await fetch(url, { headers });
  if (!res.ok) {
    throw new Error(`energy-api returned ${res.status} for ${url}`);
  }
  return res.json();
}

const escapeHtml = (s) =>
  String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);

const pct = (v) => (v == null ? 'n/a' : `${v.value.toFixed(0)}%`);
const millions = (v) => {
  if (v == null) return 'n/a';
  const m = v.value / 1e6;
  return m >= 1 ? `${m.toFixed(1)} M` : `${Math.round(v.value / 1e3)} K`;
};

function card(area) {
  const v = area.values;
  const access = v.elec_access;
  const width = access ? Math.max(0, Math.min(100, access.value)) : 0;
  return `
  <article class="card">
    <header>
      <h2>${escapeHtml(area.name)}</h2>
      <span class="muted">${escapeHtml(area.income_group || '')}</span>
    </header>
    <p class="big">${pct(access)}</p>
    <p class="muted">of people have electricity${access ? ` (${access.year})` : ''}</p>
    <div class="bar" role="img" aria-label="Access to electricity ${pct(access)}">
      <div style="width:${width}%"></div>
    </div>
    <dl>
      <div><dt>Rural</dt><dd>${pct(v.elec_access_rural)}</dd></div>
      <div><dt>Urban</dt><dd>${pct(v.elec_access_urban)}</dd></div>
      <div><dt>Without power</dt><dd>${millions(v.pop_no_elec)}</dd></div>
    </dl>
  </article>`;
}

function page(region, areas, error) {
  const options = REGIONS.map(
    (r) => `<option${r === region ? ' selected' : ''}>${escapeHtml(r)}</option>`,
  ).join('');
  const sorted = [...areas].sort(
    (a, b) => (b.values.pop_no_elec?.value ?? -1) - (a.values.pop_no_elec?.value ?? -1),
  );
  const body = error
    ? `<p class="error">Could not reach the energy API: ${escapeHtml(error.message)}</p>`
    : `<section class="grid">${sorted.map(card).join('')}</section>`;

  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Country cards: electricity access</title>
<style>
  :root { --ink: #0b0b0b; --ink-2: #52514e; --muted: #898781; --line: #e1e0d9;
          --surface: #fcfcfb; --page: #f9f9f7; --accent: #2a78d6; }
  * { box-sizing: border-box; }
  body { margin: 0; font-family: system-ui, -apple-system, "Segoe UI", sans-serif;
         background: var(--page); color: var(--ink); }
  main { max-width: 1200px; margin: 0 auto; padding: 2rem 1.5rem; }
  h1 { margin: 0 0 .25rem; font-size: 1.75rem; }
  .lede { color: var(--ink-2); margin: 0 0 1.5rem; }
  form { margin-bottom: 1.5rem; }
  select { font: inherit; padding: .4rem .6rem; border: 1px solid var(--line); border-radius: 6px; }
  .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(230px, 1fr)); gap: 1rem; }
  .card { background: var(--surface); border: 1px solid var(--line); border-radius: 10px; padding: 1rem 1.1rem; }
  .card header { display: flex; justify-content: space-between; align-items: baseline; gap: .5rem; }
  .card h2 { font-size: 1.05rem; margin: 0; }
  .muted { color: var(--muted); font-size: .8rem; margin: 0; }
  .big { font-size: 2.2rem; font-weight: 600; margin: .6rem 0 0; }
  .bar { height: 8px; background: var(--line); border-radius: 4px; margin: .6rem 0 .8rem; overflow: hidden; }
  .bar div { height: 100%; background: var(--accent); border-radius: 4px; }
  dl { display: flex; justify-content: space-between; margin: 0; }
  dt { color: var(--muted); font-size: .75rem; }
  dd { margin: 0; font-weight: 600; font-variant-numeric: tabular-nums; }
  .error { color: #d03b3b; }
  footer { color: var(--muted); font-size: .8rem; margin-top: 2rem; }
</style>
</head>
<body>
<main>
  <h1>Electricity access by country</h1>
  <p class="lede">Latest World Development Indicators, sorted by the number of people without electricity.</p>
  <form method="get">
    <label for="region">Region</label>
    <select id="region" name="region" onchange="this.form.submit()">${options}</select>
    <noscript><button type="submit">Show</button></noscript>
  </form>
  ${body}
  <footer>Node.js app on Posit Connect. Data from the energy-api content item.</footer>
</main>
</body>
</html>`;
}

app.get('/', async (req, res) => {
  const region = REGIONS.includes(req.query.region) ? req.query.region : REGIONS[0];
  try {
    const areas = await fetchLatest(region);
    res.send(page(region, areas));
  } catch (err) {
    console.error(err);
    res.status(502).send(page(region, [], err));
  }
});

app.listen(port, host, () => {
  console.log(`country-cards listening on ${host}:${port}, using energy-api at ${apiUrl}`);
});
