# YouthFront India

Independent youth-led political platform. Essays, demands, petitions.

**Stack:** Vanilla HTML/CSS/JS · Supabase · Cloudflare Pages

---

## File Structure

```
/
├── index.html          # Main landing page
├── article.html        # Article read page (fetches by ?slug=)
├── dashboard.html      # Editor dashboard (password protected)
├── favicon.svg         # Tab icon — finger + pen mark
├── og-image.svg        # Social share card source (export as og-image.jpg)
├── og-image.jpg        # Export manually — required for social sharing
├── sitemap.xml         # Search engine sitemap
├── robots.txt          # Crawler rules (dashboard excluded)
├── _headers            # Cloudflare Pages cache + security headers
└── yfi-migration.sql   # Run once in Supabase SQL Editor before deploying
```

---

## Deploy

### 1. Supabase — run migration first
Open Supabase SQL Editor and run `yfi-migration.sql`.
This adds `slug`, `body`, `tags`, `reading_time` to the articles table
and creates the `current_issue` table.

### 2. Export the OG image
Open `og-image.svg` in a browser.
Screenshot or export at exactly **1200×630px**.
Save as `og-image.jpg` in this folder.

### 3. Cloudflare Pages
Connect this repo to Cloudflare Pages.
- Build command: *(none — static files)*
- Output directory: `/` (root)
- All files deploy as-is.

### 4. Verify Supabase RLS
Confirm Row Level Security is ON for:
- `submissions` — auth required for writes
- `members` — auth required for writes
- `petition_sigs` — auth required for writes

### 5. First launch
- Login to `dashboard.html`
- Go to **Current Issue** → enter the first confrontational headline
- The hero renders it live

---

## Article URLs

```
/article.html?slug=your-article-slug
```

Slugs are auto-generated from titles on publish.
Manually set in the dashboard article editor if needed.

---

## Editor Access

Add authorised email addresses to the `ALLOWED_EDITORS` array
in `dashboard.html`. Currently client-side only — ensure Supabase
RLS policies enforce auth at the database level.

---

## Palette

| Token       | Hex       | Use                        |
|-------------|-----------|----------------------------|
| Charcoal    | `#282420` | Hero bg, footer, sidebar   |
| Marigold    | `#E89C18` | Primary accent, stats      |
| Marigold 2  | `#C07C10` | Hover states               |
| Paper       | `#F0EDE4` | Body bg, card surfaces     |
| Red         | `#B82018` | CTAs, petition, danger     |
| Teal        | `#1A6358` | Live indicators            |

## Fonts

- **Display/Body:** Fraunces (Google Fonts) — italic 700/900
- **UI/Labels:** Epilogue (Google Fonts) — 400/500/600/700

---

*Independent. No party. No sponsor. Est. 2026, New Delhi.*
