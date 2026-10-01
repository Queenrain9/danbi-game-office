-- Front Design Pipeline v0.4.1
-- pgcrypto is installed in the extensions schema on Supabase.
-- The v0.4 SECURITY DEFINER helper used search_path=public, so unqualified digest() was not visible.

create or replace function public.danbi_front_json_hash(p_value jsonb)
returns text
language sql immutable
set search_path=public,extensions
as $$
  select encode(extensions.digest(convert_to(coalesce(p_value, 'null'::jsonb)::text, 'UTF8'), 'sha256'), 'hex');
$$;
