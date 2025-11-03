-- Add support for carousel posts (multiple images per post)
-- This migration creates a junction table between posts and media items

-- Create post_media_items junction table
create table public.post_media_items (
    id uuid primary key default uuid_generate_v4(),
    post_id uuid references public.generated_posts(id) on delete cascade not null,
    media_item_id uuid references public.media_items(id) on delete cascade not null,
    position integer not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    unique(post_id, media_item_id)
);

-- Create index for performance
create index post_media_items_post_id_idx on public.post_media_items(post_id);
create index post_media_items_media_item_id_idx on public.post_media_items(media_item_id);

-- Enable RLS on post_media_items
alter table public.post_media_items enable row level security;

-- Post Media Items Policies (inherit from post)
create policy "Users can view their own post media items"
    on public.post_media_items for select
    using (exists (
        select 1 from public.generated_posts
        where generated_posts.id = post_media_items.post_id
        and generated_posts.user_id = auth.uid()
    ));

create policy "Users can insert their own post media items"
    on public.post_media_items for insert
    with check (exists (
        select 1 from public.generated_posts
        where generated_posts.id = post_media_items.post_id
        and generated_posts.user_id = auth.uid()
    ));

create policy "Users can update their own post media items"
    on public.post_media_items for update
    using (exists (
        select 1 from public.generated_posts
        where generated_posts.id = post_media_items.post_id
        and generated_posts.user_id = auth.uid()
    ));

create policy "Users can delete their own post media items"
    on public.post_media_items for delete
    using (exists (
        select 1 from public.generated_posts
        where generated_posts.id = post_media_items.post_id
        and generated_posts.user_id = auth.uid()
    ));

-- Migrate existing data from media_item_id to post_media_items
-- For existing posts with media_item_id, create corresponding post_media_items entries
insert into public.post_media_items (post_id, media_item_id, position)
select id, media_item_id, 0
from public.generated_posts
where media_item_id is not null;

-- Note: We keep media_item_id column for backward compatibility during transition
-- It will be deprecated but not dropped yet to avoid breaking existing queries

-- Update the get_posts_ready_for_publishing function to handle carousel posts
drop function if exists get_posts_ready_for_publishing();

create or replace function get_posts_ready_for_publishing()
returns table (
    post_id uuid,
    user_id uuid,
    caption text,
    media_urls text[],
    media_types text[],
    scheduled_date timestamp with time zone
) as $$
begin
    return query
    select 
        gp.id as post_id,
        gp.user_id,
        gp.caption,
        array_agg(mi.cloud_url order by pmi.position) as media_urls,
        array_agg(mi.type order by pmi.position) as media_types,
        gp.scheduled_date
    from public.generated_posts gp
    left join public.post_media_items pmi on gp.id = pmi.post_id
    left join public.media_items mi on pmi.media_item_id = mi.id
    where gp.status = 'scheduled'
        and gp.scheduled_date <= now()
        and gp.instagram_post_id is null
    group by gp.id, gp.user_id, gp.caption, gp.scheduled_date
    order by gp.scheduled_date asc
    limit 10; -- Process 10 posts at a time to avoid rate limits
end;
$$ language plpgsql security definer;

