-- Direct-message RPCs are authenticated-only. SECURITY DEFINER remains intentional
-- for business rules, but anonymous callers must not be able to invoke them.
REVOKE EXECUTE ON FUNCTION public.insert_direct_message(uuid,uuid,text,text,text,text[],uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.send_direct_message(uuid,text,text,text,text[],uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_direct_messages(uuid,integer,timestamptz) FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_my_direct_conversations() FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_or_create_direct_conversation(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.get_direct_unread_state(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.mark_direct_conversation_read(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.mark_direct_message_delivered(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.mark_direct_message_read(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.delete_direct_message(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.delete_direct_message_for_me(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.edit_direct_message(uuid,text) FROM anon;
