# Weekly energy brief (Quarto, R)

A one-page brief on Sub-Saharan Africa: people without electricity, access compared with the world, and the ten countries with the most people without electricity. The document also defines a custom email.

## Connect features to point at

- **Schedule tab:** weekly, Monday 7:00 AM ET, with "Send email after update" checked and a group as recipients.
- **Custom email:** the subject is computed from the data, the chart is inline, and the top-10 table is attached as a CSV.
- **Conditional sending:** the brief only emails when there is new data (see below).
- **History:** previous renders of the report stay available on Connect.

## Conditional sending

The `.email-scheduled` block tells Connect whether to send the scheduled email. The document sends only when the latest year of electricity access data is newer than `LAST_SENT_YEAR`:

- `LAST_SENT_YEAR` unset, or `0`: the email is sent.
- `LAST_SENT_YEAR=2024` (the current latest year): the render runs, the report updates, and no email goes out.

To show it during the demo, set `LAST_SENT_YEAR` in the Runtime tab and run the report. A production version would store the last year sent, for example in a pin, instead of setting it by hand.

## Run locally

Run `01-energy-pipeline` once so `apps/_pins` exists, then from this folder:

```bash
quarto render index.qmd
```

This writes `index.html` (the report) and `email-preview/index.html` (the email as Connect will send it). `LAST_SENT_YEAR=2024 quarto render index.qmd` shows the suppressed case: `.output_metadata.json` then has `"rsc_email_suppress_scheduled": true`.

## Deploy

Import from Git (see `../README.md`), folder `06-weekly-energy-brief`. Then:

- **Schedule** tab: weekly, Monday 7:00 AM ET, send email to a group (for example `energy-team`).
- Tag `energy-showcase`.

Connect sends the custom email for scheduled runs and when you use **Email now**, not when you publish or run the report manually.

## Known issue

With Quarto 1.10.19, a `%` sign in the email subject makes the render fail (`invalid use of '%' in replacement string`). The subject says "percent" for that reason. A `%` in the email body is fine.
