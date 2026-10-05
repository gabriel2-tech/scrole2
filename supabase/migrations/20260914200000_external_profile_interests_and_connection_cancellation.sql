create or replace function public.cancel_connection(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_me uuid := auth.uid();
  v_row public.demande_connexion%rowtype;
  v_status text;
begin
  if v_me is null then raise exception 'not_authenticated'; end if;
  if p_user_id is null or p_user_id = v_me then raise exception 'invalid_user'; end if;

  select * into v_row
  from public.demande_connexion d
  where ((d.demandeur_id = v_me and d.destinataire_id = p_user_id)
      or (d.demandeur_id = p_user_id and d.destinataire_id = v_me))
    and d.statut in ('en_attente'::statut_connexion_enum, 'acceptee'::statut_connexion_enum)
  order by case when d.statut = 'en_attente'::statut_connexion_enum then 0 else 1 end, d.created_at desc
  limit 1;

  if not found then raise exception 'connection_not_found'; end if;

  if v_row.statut = 'en_attente'::statut_connexion_enum then
    if v_row.demandeur_id <> v_me then raise exception 'not_request_sender'; end if;
    v_status := 'demande_annulee';
  else
    v_status := 'connexion_supprimee';
  end if;

  delete from public.demande_connexion where id = v_row.id;
  return jsonb_build_object('request_id', v_row.id, 'status', v_status);
end;
$function$;

revoke all on function public.cancel_connection(uuid) from public;
revoke all on function public.cancel_connection(uuid) from anon;
grant execute on function public.cancel_connection(uuid) to authenticated;

create or replace function public.get_external_profile(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_me uuid := auth.uid();
  v_profile public.user_profiles%rowtype;
  v_priv public.user_privacy%rowtype;
  v_connected boolean := false;
  v_pending_out boolean := false;
  v_pending_in boolean := false;
  v_blocked boolean := false;
  v_following boolean := false;
  v_certified boolean := false;
  v_can_message boolean := false;
  v_friend_count integer := 0;
  v_country text;
  v_city text;
  v_interests jsonb := '[]'::jsonb;
begin
  if v_me is null then raise exception 'not_authenticated'; end if;
  if p_user_id is null or p_user_id = v_me then raise exception 'invalid_profile_user'; end if;

  select * into v_profile from public.user_profiles where user_id=p_user_id and deleted_at is null;
  if not found then raise exception 'profile_not_found'; end if;

  select * into v_priv from public.user_privacy where user_id=p_user_id;
  if not found then
    v_priv.profile_visibility:='public'; v_priv.allow_messages_from:='everyone';
    v_priv.afficher_pays:=true; v_priv.afficher_ville:=true;
  end if;

  select exists (select 1 from public.blocage_utilisateur b where b.statut
    and ((b.bloqueur_id=v_me and b.bloque_id=p_user_id) or (b.bloqueur_id=p_user_id and b.bloque_id=v_me))
    and (b.bloque_jusquau is null or b.bloque_jusquau>now())) into v_blocked;
  if v_blocked then return jsonb_build_object('user_id',p_user_id,'is_blocked',true,'is_private',true); end if;

  select exists (select 1 from public.demande_connexion d where d.statut='acceptee'::statut_connexion_enum
    and ((d.demandeur_id=v_me and d.destinataire_id=p_user_id) or (d.demandeur_id=p_user_id and d.destinataire_id=v_me))) into v_connected;
  select exists (select 1 from public.demande_connexion d where d.statut='en_attente'::statut_connexion_enum
    and d.demandeur_id=v_me and d.destinataire_id=p_user_id) into v_pending_out;
  select exists (select 1 from public.demande_connexion d where d.statut='en_attente'::statut_connexion_enum
    and d.demandeur_id=p_user_id and d.destinataire_id=v_me) into v_pending_in;
  select exists (select 1 from public.user_follows f where f.follower_id=v_me and f.followed_id=p_user_id) into v_following;
  select exists (select 1 from public.user_certifications c where c.user_id=p_user_id and c.status='active'::status_certification
    and c.issued_at<=now() and c.expires_at>=now()) into v_certified;
  select count(*)::int into v_friend_count from public.demande_connexion d where d.statut='acceptee'::statut_connexion_enum
    and (d.demandeur_id=p_user_id or d.destinataire_id=p_user_id);
  select c.nom into v_country from public.countries c where c.id=v_profile.country_id;
  select c.nom into v_city from public.cities c where c.id=v_profile.city_id;

  select coalesce(jsonb_agg(x.interest order by x.name), '[]'::jsonb) into v_interests
  from (
    select distinct i.name, jsonb_build_object('id',i.id,'name',i.name,'category',i.category,'icon_url',i.icon_url,'is_selected',true) as interest
    from public.user_interests ui join public.interests i on i.id=ui.interest_id
    where ui.user_id=p_user_id
  ) x;

  v_can_message := (v_connected or lower(coalesce(v_priv.allow_messages_from,'everyone')) in ('everyone','tous','tout_le_monde'));

  if lower(coalesce(v_priv.profile_visibility,'public')) in ('private','prive','privé') and not v_connected then
    return jsonb_build_object('user_id',p_user_id,'username',v_profile.username,'first_name',v_profile.first_name,'last_name',v_profile.last_name,
      'photo_url',v_profile.photo_url,'cover_url',v_profile.cover_url,'is_private',true,'is_connected',v_connected,
      'connection_request_sent',v_pending_out,'incoming_connection_request',v_pending_in,'is_following',v_following,
      'is_certified',v_certified,'can_message',v_can_message,'friend_count',v_friend_count,'interests','[]'::jsonb);
  end if;

  return jsonb_build_object('user_id',p_user_id,'username',v_profile.username,'first_name',v_profile.first_name,'last_name',v_profile.last_name,
    'birth_date',v_profile.birth_date,'bio',v_profile.bio,'slogan',v_profile.slogan,'photo_url',v_profile.photo_url,'cover_url',v_profile.cover_url,
    'country',case when v_priv.afficher_pays then v_country else null end,'city',case when v_priv.afficher_ville then v_city else null end,
    'is_private',false,'is_connected',v_connected,'connection_request_sent',v_pending_out,'incoming_connection_request',v_pending_in,
    'is_following',v_following,'is_certified',v_certified,'can_message',v_can_message,'friend_count',v_friend_count,'interests',v_interests);
end;
$function$;

revoke all on function public.get_external_profile(uuid) from public;
revoke all on function public.get_external_profile(uuid) from anon;
grant execute on function public.get_external_profile(uuid) to authenticated;
