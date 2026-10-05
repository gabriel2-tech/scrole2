-- Messaging v2: server-authoritative five-minute mutation window and
-- certification snapshot at deletion time.
ALTER TABLE public.direct_messages ADD COLUMN IF NOT EXISTS sender_is_certified_at_deletion boolean;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication p JOIN pg_publication_rel pr ON pr.prpubid=p.oid JOIN pg_class c ON c.oid=pr.prrelid JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE p.pubname='supabase_realtime' AND n.nspname='public' AND c.relname='direct_messages'
  ) THEN ALTER PUBLICATION supabase_realtime ADD TABLE public.direct_messages; END IF;
END $$;
ALTER TABLE public.direct_messages REPLICA IDENTITY FULL;
ALTER TABLE public.direct_messages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS direct_messages_sender_update_5m ON public.direct_messages;
CREATE POLICY direct_messages_sender_update_5m ON public.direct_messages FOR UPDATE TO authenticated
USING (sender_id=auth.uid() AND created_at > now() - interval '5 minutes')
WITH CHECK (sender_id=auth.uid() AND created_at > now() - interval '5 minutes');
-- RPCs are the only supported mutation path from the client.
REVOKE UPDATE ON public.direct_messages FROM authenticated;

CREATE OR REPLACE FUNCTION public.edit_direct_message(p_message_id uuid, p_text text)
RETURNS public.direct_messages LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
DECLARE v_message public.direct_messages;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'not_authenticated' USING errcode='42501'; END IF;
  UPDATE public.direct_messages SET text=nullif(trim(p_text),''), edited_at=now()
  WHERE id=p_message_id AND sender_id=auth.uid() AND created_at > now()-interval '5 minutes' AND deleted_at IS NULL
  RETURNING * INTO v_message;
  IF v_message.id IS NULL THEN RAISE EXCEPTION 'edit_window_expired_or_forbidden' USING errcode='42501'; END IF;
  RETURN v_message;
END;
$$;

CREATE OR REPLACE FUNCTION public.delete_direct_message(p_message_id uuid)
RETURNS public.direct_messages LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
DECLARE v_message public.direct_messages; v_certified boolean:=false;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'not_authenticated' USING errcode='42501'; END IF;
  SELECT coalesce((account_status='active' AND is_verified=true),false) INTO v_certified FROM public.user_profiles WHERE id=auth.uid();
  UPDATE public.direct_messages SET deleted_at=now(), text=NULL, media_urls='{}', audio_url=NULL, sender_is_certified_at_deletion=v_certified
  WHERE id=p_message_id AND sender_id=auth.uid() AND created_at > now()-interval '5 minutes' AND deleted_at IS NULL
  RETURNING * INTO v_message;
  IF v_message.id IS NULL THEN RAISE EXCEPTION 'delete_window_expired_or_forbidden' USING errcode='42501'; END IF;
  RETURN v_message;
END;
$$;

REVOKE ALL ON FUNCTION public.edit_direct_message(uuid,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.edit_direct_message(uuid,text) TO authenticated;
REVOKE ALL ON FUNCTION public.delete_direct_message(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_direct_message(uuid) TO authenticated;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname='pg_cron') THEN
    PERFORM cron.unschedule(jobid) FROM cron.job WHERE jobname='scrole-purge-deleted-direct-message-content';
    PERFORM cron.schedule('scrole-purge-deleted-direct-message-content','*/5 * * * *',$job$UPDATE public.direct_messages SET text=NULL,media_urls='{}',audio_url=NULL WHERE deleted_at IS NOT NULL AND deleted_at < now()-interval '5 minutes'$job$);
  END IF;
END $$;
