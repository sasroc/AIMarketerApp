-- Update get_posts_ready_for_publishing to include media_type
-- This allows the publishing function to properly handle videos vs images

-- Drop the existing function first (required when changing return type)
drop function if exists get_posts_ready_for_publishing();

create or replace function get_posts_ready_for_publishing()
returns table (
    post_id uuid,
    user_id uuid,
    caption text,
    media_url text,
    media_type text,
    scheduled_date timestamp with time zone
) as $$
begin
    return query
    select 
        gp.id as post_id,
        gp.user_id,
        gp.caption,
        mi.cloud_url as media_url,
        mi.type as media_type,
        gp.scheduled_date
    from public.generated_posts gp
    join public.media_items mi on gp.media_item_id = mi.id
    where gp.status = 'scheduled'
        and gp.scheduled_date <= now()
        and gp.instagram_post_id is null
    order by gp.scheduled_date asc
    limit 10; -- Process 10 posts at a time to avoid rate limits
end;
$$ language plpgsql security definer;

