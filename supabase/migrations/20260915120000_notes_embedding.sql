-- Ricerca semantica: embedding per nota + funzione di similarità (coseno).
-- L'estensione vector è già installata nello schema extensions.
create extension if not exists vector with schema extensions;

alter table public.notes
  add column if not exists embedding extensions.vector(512);

-- Note dell'utente corrente ordinate per similarità coseno decrescente.
-- security invoker: gira con i permessi del chiamante, quindi sotto RLS.
create or replace function public.match_notes(
  query_embedding extensions.vector(512),
  match_count int default 10,
  min_similarity float default 0.4
)
returns table (id uuid, similarity float)
language sql
stable
security invoker
set search_path = public, extensions
as $$
  select n.id,
         1 - (n.embedding <=> query_embedding) as similarity
  from public.notes n
  where n.user_id = auth.uid()
    and n.embedding is not null
    and 1 - (n.embedding <=> query_embedding) >= min_similarity
  order by n.embedding <=> query_embedding
  limit match_count;
$$;
