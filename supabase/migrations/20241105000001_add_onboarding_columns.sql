-- Add Onboarding Support to user_profiles
-- This migration converts the user_profiles VIEW to a TABLE and adds onboarding columns

-- Drop the existing view if it exists
drop view if exists public.user_profiles;

-- Create the user_profiles table with all columns
create table public.user_profiles (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references auth.users(id) on delete cascade not null unique,
    
    -- Existing Instagram fields (from view)
    email text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    instagram_username text,
    instagram_user_id text,
    instagram_connected boolean default false,
    instagram_connected_at timestamp with time zone,
    
    -- New Onboarding fields
    onboarding_completed boolean default false not null,
    business_category text,
    website_url text,
    
    -- Business information (scraped from website)
    business_summary text,
    business_value_proposition text,
    business_description text,
    
    -- Brand assets (scraped from website)
    brand_colors jsonb default '[]'::jsonb, -- Array of hex color codes
    logo_url text,
    brand_images jsonb default '[]'::jsonb, -- Array of image URLs
    
    -- Metadata
    website_analyzed_at timestamp with time zone,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create indexes for efficient lookups
create index user_profiles_user_id_idx on public.user_profiles(user_id);
create index user_profiles_onboarding_completed_idx on public.user_profiles(onboarding_completed);

-- Enable RLS on user_profiles
alter table public.user_profiles enable row level security;

-- User Profiles Policies
create policy "Users can view their own profile"
    on public.user_profiles for select
    using (auth.uid() = user_id);

create policy "Users can insert their own profile"
    on public.user_profiles for insert
    with check (auth.uid() = user_id);

create policy "Users can update their own profile"
    on public.user_profiles for update
    using (auth.uid() = user_id);

create policy "Users can delete their own profile"
    on public.user_profiles for delete
    using (auth.uid() = user_id);

-- Function to automatically create profile on user signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
    insert into public.user_profiles (user_id, email, created_at, onboarding_completed)
    values (new.id, new.email, new.created_at, false)
    on conflict (user_id) do nothing;
    return new;
end;
$$ language plpgsql security definer;

-- Trigger to create profile when user signs up
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute procedure public.handle_new_user();

-- Migrate existing data from instagram_connections if any users exist
-- This will populate instagram fields for existing users
insert into public.user_profiles (user_id, email, created_at, instagram_username, instagram_user_id, instagram_connected, instagram_connected_at)
select 
    au.id as user_id,
    au.email,
    au.created_at,
    ic.instagram_username,
    ic.instagram_user_id,
    ic.is_connected as instagram_connected,
    ic.connected_at as instagram_connected_at
from auth.users au
left join public.instagram_connections ic on au.id = ic.user_id
on conflict (user_id) do update set
    instagram_username = excluded.instagram_username,
    instagram_user_id = excluded.instagram_user_id,
    instagram_connected = excluded.instagram_connected,
    instagram_connected_at = excluded.instagram_connected_at;

-- Recreate the view for backward compatibility (if needed)
-- This view now reads from the table instead
create or replace view public.user_profiles_view as
select 
    user_id,
    email,
    created_at,
    instagram_username,
    instagram_user_id,
    instagram_connected,
    instagram_connected_at
from public.user_profiles;
