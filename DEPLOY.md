# Deploying Rhythm Twin online

Goal: a public URL anyone can visit, plays the game in their browser, and every TRAIN session uploads anonymously to a database you can download from.

Total setup time: ~20 minutes. Total cost: $0 (free tiers).

## Architecture

```
  [User's browser] --POST JSON--> [Supabase REST API] --> [Postgres table]
                                                              |
                                                              v
                                                  [You: Supabase dashboard --> CSV]
```

No backend code to write. The game posts directly to Supabase's auto-generated REST endpoint. RLS policy restricts anonymous browsers to insert-only.

---

## Step 1 — Set up Supabase (the database)

1. Go to <https://supabase.com> and sign up (free, no credit card).
2. Click **New Project**. Pick any name. Choose a region close to most of your players. Set a strong database password (you won't need it day-to-day).
3. Wait ~2 minutes for the project to provision.
4. In the left nav: **SQL Editor** → **New query**. Paste the contents of `supabase_schema.sql` and run it. You should see "Success. No rows returned."
5. In the left nav: **Project Settings** → **API**. Copy two values:
   - **Project URL** (looks like `https://abcdefgh.supabase.co`)
   - **anon public** key (a long JWT)

You'll paste these into the HTML in Step 2. The anon key is safe to expose — the RLS policy you just created only lets anonymous users INSERT, never SELECT.

## Step 2 — Configure the HTML

Open `index_v3_online.html` in any text editor. Near the top of the `<script>` block, find:

```js
const SUPABASE_URL = '__SUPABASE_URL__';
const SUPABASE_ANON_KEY = '__SUPABASE_ANON_KEY__';
```

Replace the placeholder strings with the two values you copied. Save the file.

## Step 3 — Deploy the static file

Three free options, pick whichever is easiest for you:

### Option A — Netlify Drop (no account needed for a 7-day URL, ~30 seconds)

1. Go to <https://app.netlify.com/drop>.
2. Drag your `index_v3_online.html` onto the page (rename it to `index.html` first so the URL is clean).
3. Netlify gives you a URL like `https://wonderful-rabbit-12345.netlify.app`. Share it.
4. For a permanent URL, sign up for a free Netlify account and "claim" the site.

### Option B — Vercel (free, custom subdomain, GitHub-integrated)

1. Sign up at <https://vercel.com>.
2. Click **Add New** → **Project** → **Continue with Hobby** plan.
3. Drag-drop the file into a new GitHub repo, or use Vercel's GitHub import.
4. Deploy. URL looks like `https://your-project.vercel.app`.

### Option C — GitHub Pages (free, requires GitHub account)

1. Create a new public GitHub repo (e.g., `rhythm-twin`).
2. Upload `index_v3_online.html` as `index.html`.
3. In repo **Settings** → **Pages**, set source to `main` branch, root.
4. Wait ~1 minute. URL appears: `https://yourusername.github.io/rhythm-twin/`.

## Step 4 — Test it

1. Open the deployed URL in an incognito window (simulates a fresh user).
2. The welcome modal should appear asking for a name.
3. Enter a name, click START.
4. Play one TRAIN session.
5. Go back to your Supabase dashboard → **Table Editor** → `twin_sessions`. You should see one new row.

If nothing shows up:
- Open browser DevTools → Console. Look for "Upload failed:" messages.
- Common cause: typo in `SUPABASE_URL` or `SUPABASE_ANON_KEY`.
- Check that the SQL schema ran cleanly (table exists, RLS enabled, policy created).

## Step 5 — Download data

### Quick: CSV from the dashboard

Supabase **Table Editor** → `twin_sessions` → top-right **Export** → **Export to CSV**.

You'll get a single CSV with one row per session and one column per field. The `observations` column will be JSON-encoded text — easy to parse in pandas with `json.loads`.

### Programmatic: query with the service_role key

For automated pulls (e.g., a nightly script), use the service_role key (from the same **API** page — DO NOT put this one in the HTML).

```bash
curl -s "https://YOUR.supabase.co/rest/v1/twin_sessions?select=*&order=created_at.desc" \
  -H "apikey: SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer SERVICE_ROLE_KEY" \
  > all_sessions.json
```

### Python example

```python
import pandas as pd
import requests, json

r = requests.get(
    "https://YOUR.supabase.co/rest/v1/twin_sessions?select=*&limit=5000",
    headers={"apikey": SERVICE_ROLE_KEY, "Authorization": f"Bearer {SERVICE_ROLE_KEY}"},
)
df = pd.json_normalize(r.json())
# Expand observations into one row per tap-segment if you want fine-grained data
print(df[["anon_id", "user_name", "session_num", "level", "player_score", "twin_score_sim"]].head())
```

## Step 6 — Sharing & ethics

Before you blast the link out, decide:
- **Consent**: the in-game modal already says what's being collected. If your IRB/research norms need stronger language, edit the `<p class="consent">…</p>` text in the HTML.
- **Retention**: how long will you keep this data? Supabase lets you set up scheduled deletes if needed.
- **De-anonymization risk**: the only player-supplied field is a chosen display name. Tap timings are not biometric. Still, don't share the raw dataset publicly without a second look.

## Quotas (free-tier limits)

- **Supabase**: 500 MB database, 2 GB egress/month, 50,000 monthly active "users" (anon IDs). Plenty for hundreds of testers.
- **Netlify Drop**: 100 GB bandwidth/month free. The HTML is ~60 KB, so unlimited in practice.
- **Vercel/GitHub Pages**: similar free quotas.

If you blow past these, you'll get an email warning before anything breaks.

## Optional: change names later

The "edit" link beside the player name in the UI re-opens the modal. The anon_id stays the same — so a person's sessions remain linkable across name changes.
