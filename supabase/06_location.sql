-- StickerMatch — Post location (for "near me" distance sorting)
-- Run after 01_schema.sql. Coordinates are captured from the city autocomplete
-- when a post is created; country is snapshotted from the poster's profile and
-- used as the fallback filter when a viewer hasn't granted location access.
-- Distances are computed client-side (no PostGIS needed for the MVP).

alter table public.posts add column if not exists latitude double precision;
alter table public.posts add column if not exists longitude double precision;
alter table public.posts add column if not exists country text not null default '';
