-- Normalize per-game GitHub archive metadata and expose a stable project-root helper.
-- Applied to production on 2026-10-01.

update public.danbi_game_designs
set
  archive_repo = coalesce(archive_repo,'Queenrain9/danbi-game-office'),
  archive_path = case
    when archive_path ~ '^projects/[^/]+/' then
      (regexp_match(archive_path,'^(projects/[^/]+)'))[1] || '/game-design'
    else
      'projects/' || trim(both '-' from regexp_replace(lower(title),'[^a-z0-9]+','-','g')) || '/game-design'
  end,
  archived_at = coalesce(archived_at,now())
where source='chat_automation';

create or replace function public.danbi_project_root(p_design_id uuid)
returns text
language sql
stable
set search_path to 'public'
as $function$
  select case
    when d.archive_path ~ '^projects/[^/]+' then (regexp_match(d.archive_path,'^(projects/[^/]+)'))[1]
    else 'projects/' || trim(both '-' from regexp_replace(lower(d.title),'[^a-z0-9]+','-','g'))
  end
  from public.danbi_game_designs d
  where d.id=p_design_id
$function$;
