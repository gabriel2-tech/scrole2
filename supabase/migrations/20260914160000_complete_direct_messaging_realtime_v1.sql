-- Direct messaging realtime contract: stable client IDs + Postgres Changes.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication p
    JOIN pg_publication_rel pr ON pr.prpubid=p.oid
    JOIN pg_class c ON c.oid=pr.prrelid
    JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE p.pubname='supabase_realtime' AND n.nspname='public' AND c.relname='direct_messages'
  ) THEN ALTER PUBLICATION supabase_realtime ADD TABLE public.direct_messages; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication p
    JOIN pg_publication_rel pr ON pr.prpubid=p.oid
    JOIN pg_class c ON c.oid=pr.prrelid
    JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE p.pubname='supabase_realtime' AND n.nspname='public' AND c.relname='direct_message_receipts'
  ) THEN ALTER PUBLICATION supabase_realtime ADD TABLE public.direct_message_receipts; END IF;
END $$;
ALTER TABLE public.direct_messages REPLICA IDENTITY FULL;
ALTER TABLE public.direct_message_receipts REPLICA IDENTITY FULL;

CREATE OR REPLACE FUNCTION public.insert_direct_message(
  p_message_id uuid,
  p_conversation_id uuid,
  p_text text DEFAULT NULL,
  p_type text DEFAULT 'text',
  p_audio_url text DEFAULT NULL,
  p_media_urls text[] DEFAULT '{}',
  p_replied_to_id uuid DEFAULT NULL
) RETURNS public.direct_messages
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
declare v_message public.direct_messages;
begin
  if auth.uid() is null then raise exception 'not_authenticated' using errcode='42501'; end if;
  if not public.direct_conversation_is_member(p_conversation_id) then raise exception 'not_conversation_member' using errcode='42501'; end if;
  insert into public.direct_messages(id,conversation_id,sender_id,text,type,audio_url,media_urls,replied_to_id)
  values(p_message_id,p_conversation_id,auth.uid(),nullif(trim(p_text),''),p_type,p_audio_url,coalesce(p_media_urls,'{}'),p_replied_to_id)
  on conflict(id) do update set id=public.direct_messages.id
  returning * into v_message;
  update public.direct_conversations set last_message_at=greatest(coalesce(last_message_at,v_message.created_at),v_message.created_at),updated_at=now() where id=p_conversation_id;
  return v_message;
end;
$function$;
REVOKE ALL ON FUNCTION public.insert_direct_message(uuid,uuid,text,text,text,text[],uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.insert_direct_message(uuid,uuid,text,text,text,text[],uuid) TO authenticated;
