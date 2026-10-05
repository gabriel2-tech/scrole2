ALTER TABLE public.direct_conversation_members
  ADD COLUMN IF NOT EXISTS last_read_message_id uuid;

CREATE INDEX IF NOT EXISTS idx_direct_conversation_members_read_cursor
  ON public.direct_conversation_members (conversation_id, user_id, last_read_at);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication p
    JOIN pg_publication_rel pr ON pr.prpubid=p.oid
    JOIN pg_class c ON c.oid=pr.prrelid
    JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE p.pubname='supabase_realtime' AND n.nspname='public' AND c.relname='direct_conversation_members'
  ) THEN ALTER PUBLICATION supabase_realtime ADD TABLE public.direct_conversation_members; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication p
    JOIN pg_publication_rel pr ON pr.prpubid=p.oid
    JOIN pg_class c ON c.oid=pr.prrelid
    JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE p.pubname='supabase_realtime' AND n.nspname='public' AND c.relname='direct_message_hidden_for'
  ) THEN ALTER PUBLICATION supabase_realtime ADD TABLE public.direct_message_hidden_for; END IF;
END $$;

ALTER TABLE public.direct_conversation_members REPLICA IDENTITY FULL;
ALTER TABLE public.direct_message_hidden_for REPLICA IDENTITY FULL;

CREATE OR REPLACE FUNCTION public.mark_direct_conversation_read_cursor(
  p_conversation_id uuid,
  p_last_read_at timestamptz,
  p_last_read_message_id uuid
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
declare v_message_created_at timestamptz;
begin
  if auth.uid() is null then raise exception 'not_authenticated' using errcode='42501'; end if;
  if not public.direct_conversation_is_member(p_conversation_id) then raise exception 'not_conversation_member' using errcode='42501'; end if;
  if p_last_read_message_id is null or p_last_read_at is null then return; end if;
  select created_at into v_message_created_at
  from public.direct_messages
  where id=p_last_read_message_id and conversation_id=p_conversation_id and sender_id<>auth.uid() and deleted_at is null;
  if v_message_created_at is null then raise exception 'invalid_read_cursor' using errcode='22023'; end if;
  update public.direct_conversation_members
  set last_read_at=greatest(coalesce(last_read_at,to_timestamp(0)),v_message_created_at),
      last_read_message_id=case when last_read_at is null or v_message_created_at>=last_read_at then p_last_read_message_id else last_read_message_id end
  where conversation_id=p_conversation_id and user_id=auth.uid();
  insert into public.direct_message_receipts(message_id,user_id,delivered_at,read_at)
  select m.id,auth.uid(),now(),now()
  from public.direct_messages m
  where m.conversation_id=p_conversation_id and m.sender_id<>auth.uid() and m.deleted_at is null and m.created_at<=v_message_created_at
  on conflict(message_id,user_id) do update
    set delivered_at=coalesce(public.direct_message_receipts.delivered_at,excluded.delivered_at),
        read_at=coalesce(public.direct_message_receipts.read_at,excluded.read_at);
end;
$$;
REVOKE ALL ON FUNCTION public.mark_direct_conversation_read_cursor(uuid,timestamptz,uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.mark_direct_conversation_read_cursor(uuid,timestamptz,uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.mark_direct_message_read_visible(p_message_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
declare v_conversation_id uuid; v_sender_id uuid; v_message_created_at timestamptz; v_now timestamptz:=now();
begin
  if auth.uid() is null then raise exception 'not_authenticated' using errcode='42501'; end if;
  select m.conversation_id,m.sender_id,m.created_at into v_conversation_id,v_sender_id,v_message_created_at
  from public.direct_messages m where m.id=p_message_id and m.deleted_at is null;
  if v_conversation_id is null then return; end if;
  if not public.direct_conversation_is_member(v_conversation_id) then raise exception 'not_conversation_member' using errcode='42501'; end if;
  if v_sender_id=auth.uid() then return; end if;
  insert into public.direct_message_receipts(message_id,user_id,delivered_at,read_at)
  values(p_message_id,auth.uid(),v_now,v_now)
  on conflict(message_id,user_id) do update set delivered_at=coalesce(public.direct_message_receipts.delivered_at,excluded.delivered_at),read_at=coalesce(public.direct_message_receipts.read_at,excluded.read_at);
  update public.direct_conversation_members
  set last_read_at=greatest(coalesce(last_read_at,to_timestamp(0)),v_message_created_at),
      last_read_message_id=case when last_read_at is null or v_message_created_at>=last_read_at then p_message_id else last_read_message_id end
  where conversation_id=v_conversation_id and user_id=auth.uid();
end;
$$;
REVOKE ALL ON FUNCTION public.mark_direct_message_read_visible(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.mark_direct_message_read_visible(uuid) TO authenticated;
