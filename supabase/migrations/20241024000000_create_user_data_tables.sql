-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Media Items Table
create table public.media_items (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references auth.users(id) on delete cascade not null,
    type text not null check (type in ('image', 'video')),
    cloud_url text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Marketing Plans Table (embedded in campaigns but stored for reference)
create table public.campaigns (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references auth.users(id) on delete cascade not null,
    
    -- Marketing Plan fields
    marketing_description text not null default '',
    target_audience text not null default '',
    tone text not null default 'casual',
    hashtags jsonb default '[]'::jsonb,
    call_to_action text not null default '',
    
    -- Schedule fields
    schedule_start_date timestamp with time zone,
    schedule_end_date timestamp with time zone,
    selected_days jsonb default '[]'::jsonb,
    post_times jsonb default '{}'::jsonb,
    posts_per_day jsonb default '{}'::jsonb,
    content_guidelines text not null default '',
    
    -- Campaign metadata
    current_step integer default 0,
    is_draft boolean default true,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Campaign Media Items junction table
create table public.campaign_media_items (
    id uuid primary key default uuid_generate_v4(),
    campaign_id uuid references public.campaigns(id) on delete cascade not null,
    media_item_id uuid references public.media_items(id) on delete cascade not null,
    position integer not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    unique(campaign_id, media_item_id)
);

-- Generated Posts Table
create table public.generated_posts (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references auth.users(id) on delete cascade not null,
    campaign_id uuid references public.campaigns(id) on delete set null,
    media_item_id uuid references public.media_items(id) on delete set null,
    caption text not null,
    scheduled_date timestamp with time zone not null,
    status text not null default 'pending' check (status in ('pending', 'draft', 'scheduled', 'posted', 'failed')),
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Indexes for performance
create index media_items_user_id_idx on public.media_items(user_id);
create index campaigns_user_id_idx on public.campaigns(user_id);
create index campaigns_is_draft_idx on public.campaigns(is_draft);
create index generated_posts_user_id_idx on public.generated_posts(user_id);
create index generated_posts_campaign_id_idx on public.generated_posts(campaign_id);
create index generated_posts_status_idx on public.generated_posts(status);
create index generated_posts_scheduled_date_idx on public.generated_posts(scheduled_date);

-- Row Level Security (RLS) Policies

-- Enable RLS on all tables
alter table public.media_items enable row level security;
alter table public.campaigns enable row level security;
alter table public.campaign_media_items enable row level security;
alter table public.generated_posts enable row level security;

-- Media Items Policies
create policy "Users can view their own media items"
    on public.media_items for select
    using (auth.uid() = user_id);

create policy "Users can insert their own media items"
    on public.media_items for insert
    with check (auth.uid() = user_id);

create policy "Users can update their own media items"
    on public.media_items for update
    using (auth.uid() = user_id);

create policy "Users can delete their own media items"
    on public.media_items for delete
    using (auth.uid() = user_id);

-- Campaigns Policies
create policy "Users can view their own campaigns"
    on public.campaigns for select
    using (auth.uid() = user_id);

create policy "Users can insert their own campaigns"
    on public.campaigns for insert
    with check (auth.uid() = user_id);

create policy "Users can update their own campaigns"
    on public.campaigns for update
    using (auth.uid() = user_id);

create policy "Users can delete their own campaigns"
    on public.campaigns for delete
    using (auth.uid() = user_id);

-- Campaign Media Items Policies (inherit from campaign)
create policy "Users can view their own campaign media items"
    on public.campaign_media_items for select
    using (exists (
        select 1 from public.campaigns
        where campaigns.id = campaign_media_items.campaign_id
        and campaigns.user_id = auth.uid()
    ));

create policy "Users can insert their own campaign media items"
    on public.campaign_media_items for insert
    with check (exists (
        select 1 from public.campaigns
        where campaigns.id = campaign_media_items.campaign_id
        and campaigns.user_id = auth.uid()
    ));

create policy "Users can update their own campaign media items"
    on public.campaign_media_items for update
    using (exists (
        select 1 from public.campaigns
        where campaigns.id = campaign_media_items.campaign_id
        and campaigns.user_id = auth.uid()
    ));

create policy "Users can delete their own campaign media items"
    on public.campaign_media_items for delete
    using (exists (
        select 1 from public.campaigns
        where campaigns.id = campaign_media_items.campaign_id
        and campaigns.user_id = auth.uid()
    ));

-- Generated Posts Policies
create policy "Users can view their own generated posts"
    on public.generated_posts for select
    using (auth.uid() = user_id);

create policy "Users can insert their own generated posts"
    on public.generated_posts for insert
    with check (auth.uid() = user_id);

create policy "Users can update their own generated posts"
    on public.generated_posts for update
    using (auth.uid() = user_id);

create policy "Users can delete their own generated posts"
    on public.generated_posts for delete
    using (auth.uid() = user_id);

-- Storage bucket for media files
insert into storage.buckets (id, name, public)
values ('media-uploads', 'media-uploads', false);

-- Storage policies for media-uploads bucket
create policy "Users can upload their own media"
    on storage.objects for insert
    with check (
        bucket_id = 'media-uploads' and
        auth.uid()::text = (storage.foldername(name))[1]
    );

create policy "Users can view their own media"
    on storage.objects for select
    using (
        bucket_id = 'media-uploads' and
        auth.uid()::text = (storage.foldername(name))[1]
    );

create policy "Users can update their own media"
    on storage.objects for update
    using (
        bucket_id = 'media-uploads' and
        auth.uid()::text = (storage.foldername(name))[1]
    );

create policy "Users can delete their own media"
    on storage.objects for delete
    using (
        bucket_id = 'media-uploads' and
        auth.uid()::text = (storage.foldername(name))[1]
    );

