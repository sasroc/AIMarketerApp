-- Add thumbnail_url column to media_items table
-- This stores a separate thumbnail image URL for videos

alter table public.media_items
    add column if not exists thumbnail_url text;

-- Add index for efficient lookups
create index if not exists media_items_thumbnail_url_idx on public.media_items(thumbnail_url);

