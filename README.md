# BillsNow — Buffalo Bills live score app + widget (iOS 15)

A small, native SwiftUI app for iPad/iPhone running **iOS 15** (built for the
iPad Air 2 on iOS 15.8.3) that shows the Bills' current game — live score,
clock, possession, down & distance, play-by-play, scoring summary, box score,
rosters and news — with a **home-screen widget** that keeps the live score
visible at a glance.

Everything is driven by free, public data:

| What | Source | Notes |
|---|---|---|
| Live score, plays, box score, rosters | ESPN public NFL API (`site.api.espn.com`) | Unofficial but the de-facto standard for hobby apps; no key needed. A second host (`site.web.api.espn.com`) is used automatically when the first one refuses the request. |
| News | WGRZ Buffalo RSS + Buffalo Rumblings (SB Nation) RSS | Both verified working. |

**Only the widget matters?** It's the star of the show. Sizes: Small, Medium
and Large, all with the Bills navy/red scorebug look, team logos, a pulsing
LIVE badge, game clock/quarter, possession indicator, down & distance, last
play and a scoring summary on the large size. Tap the widget to open the app.

---

## The two apps in this project

```
BillsNow.xcodeproj
├── BillsNow        (the app)
│   ├── Game tab    navy scoreboard card → Live feed / Scoring / Stats / Roster
│   ├── News tab    two RSS feeds, rows open articles in Safari
│   └── deep link   billsnow://game (used by the widget)
├── BillsWidget     (the home-screen widget)
│   └── BillsLiveScore  StaticConfiguration timeline provider
└── Shared          models + ESPN client + RSS parser + App Group cache,
                    compiled into BOTH targets
```

Both targets share the **App Group `group.com.billsnow.shared`**. The app
caches the newest game snapshot there after every fetch; the widget renders
that instantly and then refreshes live data on its own cadence:

* while a game is **live** → ask iOS for a new timeline every ~30 s
* game **upcoming** → every ~30 min, tighter near kickoff
* game **over** → every few hours (moves on to the next Bills game)

> Widgets can't run in real time — iOS schedules those reloads and throttles
> them, so expect updates on the order of a minute or two, not milliseconds.

## What the "game" logic shows

The app and widget both use one resolver: **the live game if one is on, else
the next scheduled game, else the most recent finished one.** It starts from
the current-week scoreboard and falls back to the full-season schedule
(handles byes, weeks with no Bills game and the off-season).

- Pre-game: matchup, kickoff time/countdown, records, venue, TV, odds, weather.
- Live: score + clock, possession and down & distance, "last play", live
  feed (plays refresh every 30 s), scoring summary as it happens.
- Final: result, winner highlight, full scoring summary, team stats and
  player leaders (passing/rushing/receiving/…), both rosters grouped by
  position with starters marked.

---

## Building

You need **Xcode 13+** — a Mac, or free macOS runners in the cloud. The
widget needs an SDK that knows WidgetKit, so any recent Xcode is fine even
though the app targets iOS 15.

### No Mac? Build free with GitHub Actions (recommended)

The repo ships a ready-made workflow (`.github/workflows/build.yml`) that
compiles the app **and** the widget on GitHub's macOS machines and uploads
the unsigned `.ipa` as a downloadable artifact. Builds are **free** — macOS
runners are free for public repositories (private repos get ~200
macOS-minutes/month on the free plan, which is still dozens of builds).

1. Create a new GitHub repository (public = completely free).
2. Push this project folder as the repository root:

   ```bash
   git init
   git add -A
   git commit -m "BillsNow - Buffalo Bills live score app + widget"
   git branch -M main
   git remote add origin git@github.com:YOURUSER/BillsNow.git
   git push -u origin main
   ```

3. Open the **Actions** tab → **Build BillsNow** → **Run workflow** (it also
   runs automatically on every push).
4. When the run finishes (~5 min), open it and download the **BillsNow-ipa**
   artifact. Artifacts are kept 90 days by default.
5. Install it with any option below — the jailbroken paths need no Mac, no
   Apple ID, and no re-signing.

> First run may show a warning that a workflow is being set up; GitHub
> enables Actions automatically on new repos.

### Fastest (with a Mac): run from Xcode

1. Open `BillsNow.xcodeproj`.
2. Select the **BillsNow** scheme (it builds the widget too).
3. In Signing & Capabilities pick your Team for **both** targets
   (BillsNow *and* BillsWidget — they must share the same team so the app
   group works).
4. Connect the iPad and hit Run. Deployment target is iOS 15.0.

### Command line

```bash
# Signed for a real device (plug in the iPad):
TEAM_ID=YOURTEAMID ./scripts/build.sh

# No Apple ID needed — unsigned build + .ipa for sideloading:
./scripts/build-unsigned.sh      # → build/BillsNow.ipa
```

---

## Installing on the jailbroken iPad Air 2 (iOS 15.8.3, Dopamine)

The app is 100% stock iOS — no jailbreak features used — it just needs to get
onto a device that Apple won't sign for anymore. Pick whichever you like:

**Option A — Sideloadly / AltStore (no jailbreak needed)**
1. Grab `BillsNow.ipa` from the GitHub Actions artifact (or build it with
   `./scripts/build-unsigned.sh` on a Mac).
2. Open it in [Sideloadly](https://sideloadly.io) (Windows/Mac), log in with
   a free Apple ID, install. Free accounts must re-sign every 7 days.
   Sideloadly re-signs the embedded widget extension and app-group
   entitlements automatically.

**Option B — TrollStore (jailbroken, no re-signing)**
TrollStore supports iOS 15.x on the iPad Air 2.
1. Download the `BillsNow-ipa` artifact from GitHub Actions.
2. Airdrop/copy `BillsNow.ipa` to the iPad, open in Filza →
   *Share → TrollStore* (or import straight into TrollStore). It signs the
   app *and* the nested widget extension with the project entitlements.

**Option C — pure Dopamine (jailbroken)**
If you prefer keeping it inside your jailbreak:
1. Download the `BillsNow-ipa` artifact from GitHub Actions and unzip it, or
   grab the `BillsNow-app` artifact (an unzipped `.app` bundle).
2. Copy `BillsNow.app` to the iPad and install via Filza, then ldid-sign
   both binaries with the project entitlements:

```bash
# On the iPad, from the folder containing BillsNow.app (jailbroken shell):
ldid -S BillsNow/BillsNow.entitlements "BillsNow.app/BillsNow"
ldid -S BillsNow/BillsNow.entitlements "BillsNow.app/PlugIns/BillsWidget.appex"
uicache -p /path/to/BillsNow.app      # then reboot SpringBoard or uicache -a
```

**After installing (all options):** add the widget by long-pressing the home
screen → *+* → search "Bills" → pick a size. Give the widget a few seconds on
first run; if it ever shows "No Bills game right now", open the app once —
that primes the shared cache.

### If the widget never shows any live data

1. Open the app once and confirm the Game tab shows the Bills game — that
   proves network access works on the device.
2. Wait 1–2 minutes on the home screen; WidgetKit reloads are budgeted.
3. Check that the app **and** the widget were signed with the same
   entitlements (the App Group is what lets the widget reuse cached data).
4. Remember ESPN is a free, unofficial API — occasionally it rate-limits or
   changes shape. The app degrades gracefully, but if scores stop updating
   for everyone, check the endpoints are still alive.

---

## Data & privacy notes

* No analytics, no tracking, no accounts — the app only talks to ESPN and the
  two RSS feeds.
* ESPN team logos and the NFL colors are used editorially for scores/news.
* The "Bills" icon is a plain monogram, not the club logo, so nothing here is
  endorsed by or affiliated with the Buffalo Bills / NFL. Re-generate it any
  time with `python3 scripts/make-icons.py`.

## Structure cheat-sheet

```
Shared/
  BillsModels.swift      Codable wire models for ESPN scoreboard/summary JSON
  BillsGame.swift        one Codable "snapshot" model the app & widget render,
                         built from the wire models
  ESPNClient.swift       async client + "which Bills game?" resolver
  BillsBrand.swift       NFL colors, Color(hex:), TeamLogo/TeamBadge views
  SharedCache.swift      App Group JSON cache
  RSSParser.swift        RSS 2.0 + Atom parser (WGRZ, Buffalo Rumblings)
  SampleGame.swift       realistic snapshot used by the widget gallery
BillsNow/                app: Game tab (live feed/scoring/stats/roster) + News tab
BillsWidget/             timeline provider + widget views
```

### Changing the news feeds

Edit `BillsNewsSources.all` in `BillsNow/BillsNow/ViewModels/NewsViewModel.swift`.
