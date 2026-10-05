CREATE OR REPLACE FUNCTION public.get_direct_messages_after(
  p_conversation_id uuid,
  p_after timestamptz,
  p_limit integer DEFAULT 100
) RETURNS SETOF public.direct_messages
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'not_authenticated' USING errcode='42501'; END IF;
  IF NOT public.direct_conversation_is_member(p_conversation_id) THEN RAISE EXCEPTION 'not_conversation_member' USING errcode='42501'; END IF;
  RETURN QUERY
  SELECT * FROM public.direct_messages
  WHERE conversation_id=p_conversation_id
    AND created_at > coalesce(p_after, to_timestamp(0))
  ORDER BY created_at ASC
  LIMIT least(greatest(coalesce(p_limit,100),1),500);
END;
$$;

REVOKE ALL ON FUNCTION public.get_direct_messages_after(uuid,timestamptz,integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_direct_messages_after(uuid,timestamptz,integer) TO authenticated;
