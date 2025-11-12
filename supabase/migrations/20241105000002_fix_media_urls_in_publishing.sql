-- Fix get_posts_ready_for_publishing to filter out posts without valid media URLs
-- This prevents "undefined" media URLs from being sent to Instagram API

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
    with post_media as (
        select 
            gp.id as post_id,
            gp.user_id,
            gp.caption,
            gp.scheduled_date,
            array_agg(mi.cloud_url order by pmi.position) filter (where mi.cloud_url is not null and mi.cloud_url != '') as media_urls,
            array_agg(mi.type order by pmi.position) filter (where mi.type is not null and mi.cloud_url is not null and mi.cloud_url != '') as media_types
        from public.generated_posts gp
        inner join public.post_media_items pmi on gp.id = pmi.post_id
        inner join public.media_items mi on pmi.media_item_id = mi.id
        where gp.status = 'scheduled'
            and gp.scheduled_date <= now()
            and gp.instagram_post_id is null
            and mi.cloud_url is not null
            and mi.cloud_url != ''
        group by gp.id, gp.user_id, gp.caption, gp.scheduled_date
    )
    select 
        pm.post_id,
        pm.user_id,
        pm.caption,
        pm.media_urls,
        pm.media_types,
        pm.scheduled_date
    from post_media pm
    where pm.media_urls is not null
        and array_length(pm.media_urls, 1) > 0
    order by pm.scheduled_date asc
    limit 10; -- Process 10 posts at a time to avoid rate limits
end;
$$ language plpgsql security definer;

