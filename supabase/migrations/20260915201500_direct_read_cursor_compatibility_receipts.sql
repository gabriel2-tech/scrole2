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
  select created_at into v_message_created_at from public.direct_messages
  where id=p_last_read_message_id and conversation_id=p_conversation_id and sender_id<>auth.uid() and deleted_at is null;
  if v_message_created_at is null then raise exception 'invalid_read_cursor' using errcode='22023'; end if;
  update public.direct_conversation_members
  set last_read_at=greatest(coalesce(last_read_at,to_timestamp(0)),v_message_created_at),
      last_read_message_id=case when last_read_at is null or v_message_created_at>=last_read_at then p_last_read_message_id else last_read_message_id end
  where conversation_id=p_conversation_id and user_id=auth.uid();
  insert into public.direct_message_receipts(message_id,user_id,delivered_at,read_at)
  select m.id,auth.uid(),now(),now() from public.direct_messages m
  where m.conversation_id=p_conversation_id and m.sender_id<>auth.uid() and m.deleted_at is null and m.created_at<=v_message_created_at
  on conflict(message_id,user_id) do update
    set delivered_at=coalesce(public.direct_message_receipts.delivered_at,excluded.delivered_at),read_at=coalesce(public.direct_message_receipts.read_at,excluded.read_at);
end;
$$;
REVOKE ALL ON FUNCTION public.mark_direct_conversation_read_cursor(uuid,timestamptz,uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.mark_direct_conversation_read_cursor(uuid,timestamptz,uuid) TO authenticated;
