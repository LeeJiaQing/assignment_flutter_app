-- Atomic court replacement helper used by admin facility create/edit flow.
-- SECURITY DEFINER allows trusted DB-side execution even when client RLS
-- policies are restrictive or inconsistent.

CREATE OR REPLACE FUNCTION public.set_facility_courts(
  p_facility_id uuid,
  p_court_names text[]
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM public.courts
  WHERE facility_id = p_facility_id;

  IF p_court_names IS NULL OR array_length(p_court_names, 1) IS NULL THEN
    RETURN;
  END IF;

  INSERT INTO public.courts (facility_id, name)
  SELECT
    p_facility_id,
    trim(court_name)
  FROM unnest(p_court_names) AS court_name
  WHERE trim(court_name) <> '';
END;
$$;

REVOKE ALL ON FUNCTION public.set_facility_courts(uuid, text[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_facility_courts(uuid, text[]) TO authenticated;
