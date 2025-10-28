-- Instagram Integration Tables and Fields
-- This migration adds support for Instagram OAuth and post publishing

-- Add Instagram connection fields to users (via metadata table)
create table public.instagram_connections (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references auth.users(id) on delete cascade not null unique,
    
    -- Instagram Account Info
    instagram_user_id text not null,
    instagram_username text not null,
    
    -- Facebook Page Info (required for Instagram Business API)
    facebook_page_id text not null,
    facebook_page_name text,
    
    -- Access Tokens
    access_token text not null,
    token_expires_at timestamp with time zone not null,
    
    -- Connection Status
    is_connected boolean default true,
    last_token_refresh timestamp with time zone default timezone('utc'::text, now()),
    
    -- Timestamps
    connected_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Add Instagram post ID to generated_posts
alter table public.generated_posts
    add column instagram_post_id text,
    add column instagram_permalink text,
    add column published_at timestamp with time zone,
    add column error_message text;

-- Create index for efficient lookups
create index instagram_connections_user_id_idx on public.instagram_connections(user_id);
create index instagram_connections_instagram_user_id_idx on public.instagram_connections(instagram_user_id);
create index generated_posts_instagram_post_id_idx on public.generated_posts(instagram_post_id);

-- Enable RLS on instagram_connections
alter table public.instagram_connections enable row level security;

-- Instagram Connections Policies
create policy "Users can view their own Instagram connection"
    on public.instagram_connections for select
    using (auth.uid() = user_id);

create policy "Users can insert their own Instagram connection"
    on public.instagram_connections for insert
    with check (auth.uid() = user_id);

create policy "Users can update their own Instagram connection"
    on public.instagram_connections for update
    using (auth.uid() = user_id);

create policy "Users can delete their own Instagram connection"
    on public.instagram_connections for delete
    using (auth.uid() = user_id);

-- Function to check for posts that need to be published
-- This will be called by a scheduled Edge Function
create or replace function get_posts_ready_for_publishing()
returns table (
    post_id uuid,
    user_id uuid,
    caption text,
    media_url text,
    scheduled_date timestamp with time zone
) as $$
begin
    return query
    select 
        gp.id as post_id,
        gp.user_id,
        gp.caption,
        mi.cloud_url as media_url,
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

-- Function to update post status after publishing
create or replace function update_post_after_publishing(
    p_post_id uuid,
    p_instagram_post_id text,
    p_instagram_permalink text,
    p_success boolean,
    p_error_message text default null
)
returns void as $$
begin
    if p_success then
        update public.generated_posts
        set 
            status = 'posted',
            instagram_post_id = p_instagram_post_id,
            instagram_permalink = p_instagram_permalink,
            published_at = now(),
            error_message = null,
            updated_at = now()
        where id = p_post_id;
    else
        update public.generated_posts
        set 
            status = 'failed',
            error_message = p_error_message,
            updated_at = now()
        where id = p_post_id;
    end if;
end;
$$ language plpgsql security definer;

-- Create a view for user profile with Instagram status
create or replace view user_profiles as
select 
    au.id as user_id,
    au.email,
    au.created_at,
    ic.instagram_username,
    ic.instagram_user_id,
    ic.is_connected as instagram_connected,
    ic.connected_at as instagram_connected_at
from auth.users au
left join public.instagram_connections ic on au.id = ic.user_id;


