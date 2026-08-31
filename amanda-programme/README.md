# The Programme

The page served at `https://srv1738178.hstgr.cloud/amanda` — a repertory season:
what we've seen, what's booked, and what's up for a vote.

```
index.html                        the whole page (markup, styles, script)
.github/workflows/deploy.yml      copies it to the VPS on every push to main
.github/scripts/check_page.py     refuses to deploy a malformed page
deploy.sh                         same deploy, run by hand
```

## What is and isn't in here

Only the page. The voting panel calls `/amanda/api/state` and `/amanda/api/vote`,
which are served by a FastAPI app running under uvicorn on the VPS. That app's
source lives elsewhere and is untouched by this repo — deploying only replaces
the HTML file the app serves.

## Deploying

Push to `main`. The workflow checks the page, stamps the commit SHA into it as an
HTML comment, rsyncs it to the server, and then fetches the live URL to confirm
that SHA is actually being served. If the fetch doesn't find it, the deploy fails
loudly rather than reporting a success that didn't happen.

### One-time setup

Under **Settings → Secrets and variables → Actions**:

| | Name | Value |
|---|---|---|
| Secret | `SSH_HOST` | `srv1738178.hstgr.cloud` |
| Secret | `SSH_USER` | the deploy user on the VPS |
| Secret | `SSH_KEY` | the **private** half of the deploy key, whole file including header and footer lines |
| Secret | `SSH_PORT` | only if SSH isn't on 22 |
| Secret | `SSH_KNOWN_HOSTS` | output of `ssh-keyscan srv1738178.hstgr.cloud` — see below |
| Variable | `TARGET_PATH` | directory the app reads the page from, e.g. `/srv/amanda/static` |
| Variable | `SITE_URL` | `https://srv1738178.hstgr.cloud/amanda` |

Generate the key pair on your machine, not on the server:

```sh
ssh-keygen -t ed25519 -f ~/.ssh/amanda_deploy -N "" -C "amanda-programme deploy"
ssh-copy-id -i ~/.ssh/amanda_deploy.pub USER@srv1738178.hstgr.cloud
pbcopy < ~/.ssh/amanda_deploy          # the private key -> SSH_KEY
```

`SSH_KNOWN_HOSTS` is optional but worth setting — without it the workflow accepts
whatever host key the server presents on the day, which is one fewer check against
being pointed at the wrong machine:

```sh
ssh-keyscan srv1738178.hstgr.cloud
```

If you don't know `TARGET_PATH`, find it on the server. The app is serving the page
from somewhere — look for where it mounts static files or reads a template:

```sh
grep -rn "amanda" /etc/systemd/system/*.service       # find the app's working dir
grep -rn "StaticFiles\|FileResponse\|Jinja2Templates" /path/to/app
```

### Deploying by hand

`deploy.sh` does the same thing without GitHub, reading the same settings from the
environment:

```sh
SSH_USER=you SSH_HOST=srv1738178.hstgr.cloud \
TARGET_PATH=/srv/amanda/static ./deploy.sh
```

## Editing the page

It's one self-contained file — no build step, no dependencies. Open `index.html`
in a browser to preview. The voting panel won't work locally, because its API only
exists on the server; everything else renders exactly as it will live.

Sections, in order: the hero, `01 · Retrospective` (what we've seen, as numbered
ticket stubs), `02 · Feature Presentation` (the one big booked thing), `03 · Also
Confirmed` (booked, still upcoming), `04 · Now Programming` (the vote).

When something in *Also Confirmed* has happened, move it up into the retrospective:
change the `<a class="stub booked">` wrapper to `<article class="stub">`, swap the
month/day in `.stub-no` for the next `No.` in the sequence, replace the `✓ Confirmed`
cell with a `.stars` rating and a `.lab` label, and renumber anything below it.
