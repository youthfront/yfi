-- ================================================================
-- YouthFront India — Migration 001
-- Run in Supabase SQL Editor after the base schema is live.
-- Adds: article body + slug, current_issue table
-- ================================================================


-- ────────────────────────────────────────────────────────────────
-- 1. ADD COLUMNS TO articles
--    slug       — URL-safe identifier: "unpaid-internship-silence"
--    body       — full article text (markdown or plain paragraphs)
--    reading_time — editor-set estimate in minutes (optional)
--    tags       — comma-separated topic tags (optional display)
-- ────────────────────────────────────────────────────────────────

alter table articles
  add column if not exists slug         text unique,
  add column if not exists body         text,
  add column if not exists reading_time integer,   -- minutes
  add column if not exists tags         text;       -- "student rights, employment"


-- Back-fill slugs for existing seeded articles
-- (these mirror the seeded titles — update if your titles differ)
update articles set slug = 'unpaid-internship-silence'
  where title ilike '%Internship Was Unpaid%';

update articles set slug = 'cuet-centralised-failure'
  where title ilike '%CUET%';

update articles set slug = 'movement-leaders-graduate'
  where title ilike '%Leaders Graduate%';

update articles set slug = 'climate-report-alarming-policy-next-term'
  where title ilike '%Climate Report%';

-- Any article still missing a slug gets a generated fallback
-- (run manually if you add more seeded articles before using the dashboard)
-- update articles set slug = 'article-' || id where slug is null;


-- ────────────────────────────────────────────────────────────────
-- 2. CURRENT ISSUE
--    One row — the editor controls what "right now" the site is
--    vocal about. Surfaced as its own section on the landing page.
--    Only one active row at a time (enforced by partial unique index).
-- ────────────────────────────────────────────────────────────────

create table if not exists current_issue (
  id          bigint generated always as identity primary key,
  headline    text        not null,    -- "45 lakh graduates. Zero jobs."
  subtext     text,                    -- 1–2 sentence context
  cta_label   text        not null default 'Read More',
  cta_url     text,                    -- external link or /article/slug
  active      boolean     not null default true,
  updated_at  timestamptz not null default now()
);

-- Only one active issue at a time
create unique index if not exists one_active_issue
  on current_issue (active)
  where active = true;

-- Seed with first issue
insert into current_issue (headline, subtext, cta_label, cta_url, active)
values (
  'Over 1.3 crore youth enter the workforce every year. Formal jobs created in 2023: under 30 lakh.',
  'The gap is not a statistic. It is a policy decision made by people who will retire before it becomes their problem.',
  'See the Demands →',
  '#demands',
  true
)
on conflict do nothing;

-- RLS
alter table current_issue enable row level security;

create policy "public read active issue"
  on current_issue for select using (active = true);

create policy "editors full access current_issue"
  on current_issue for all using (auth.role() = 'authenticated');


-- ────────────────────────────────────────────────────────────────
-- 3. SLUG INDEX — fast lookups for article read pages
-- ────────────────────────────────────────────────────────────────

create index if not exists articles_slug_idx on articles (slug);
create index if not exists articles_published_idx on articles (published, created_at desc);


-- ────────────────────────────────────────────────────────────────
-- 4. HELPER: auto-generate slug from title on insert
--    Fires when an article is inserted without a slug.
--    Converts title to lowercase-hyphenated, strips punctuation.
-- ────────────────────────────────────────────────────────────────

create or replace function generate_article_slug()
returns trigger language plpgsql as $$
declare
  base_slug text;
  final_slug text;
  counter   integer := 0;
begin
  if new.slug is not null and new.slug != '' then
    return new;
  end if;

  -- convert title → slug
  base_slug := lower(new.title);
  base_slug := regexp_replace(base_slug, '[^a-z0-9\s-]', '', 'g');
  base_slug := regexp_replace(base_slug, '\s+', '-', 'g');
  base_slug := trim(both '-' from base_slug);
  base_slug := substring(base_slug from 1 for 80);

  final_slug := base_slug;

  -- ensure uniqueness
  loop
    exit when not exists (select 1 from articles where slug = final_slug and id != coalesce(new.id, -1));
    counter    := counter + 1;
    final_slug := base_slug || '-' || counter;
  end loop;

  new.slug := final_slug;
  return new;
end;
$$;

drop trigger if exists article_slug_trigger on articles;
create trigger article_slug_trigger
  before insert on articles
  for each row execute function generate_article_slug();


-- ────────────────────────────────────────────────────────────────
-- DONE.
-- After running this migration:
-- 1. The article read page (yfi-article.html) fetches by slug.
-- 2. The dashboard gains a body/slug/tags editor for each article.
-- 3. The landing page surfaces the current_issue section.
-- 4. New articles inserted via the dashboard get slugs auto-generated.
-- ────────────────────────────────────────────────────────────────
