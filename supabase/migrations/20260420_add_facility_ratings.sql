-- Add average rating column to facilities
ALTER TABLE public.facilities
ADD COLUMN IF NOT EXISTS average_rating numeric(3,2) NOT NULL DEFAULT 0;

-- Facility rating table (1-5 stars + optional comment)
CREATE TABLE IF NOT EXISTS public.facility_ratings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id uuid NOT NULL REFERENCES public.facilities(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rating integer NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (facility_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_facility_ratings_facility_id
  ON public.facility_ratings(facility_id);

-- Keep facilities.average_rating in sync automatically
CREATE OR REPLACE FUNCTION public.refresh_facility_average_rating(p_facility_id uuid)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.facilities
  SET average_rating = COALESCE((
      SELECT ROUND(AVG(fr.rating)::numeric, 2)
      FROM public.facility_ratings fr
      WHERE fr.facility_id = p_facility_id
    ), 0)
  WHERE id = p_facility_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.trigger_refresh_facility_average_rating()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  PERFORM public.refresh_facility_average_rating(
    COALESCE(NEW.facility_id, OLD.facility_id)
  );
  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_refresh_facility_average_rating
ON public.facility_ratings;

CREATE TRIGGER trg_refresh_facility_average_rating
AFTER INSERT OR UPDATE OR DELETE ON public.facility_ratings
FOR EACH ROW
EXECUTE FUNCTION public.trigger_refresh_facility_average_rating();

ALTER TABLE public.facility_ratings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read facility ratings"
ON public.facility_ratings
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Users can insert their own facility ratings"
ON public.facility_ratings
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own facility ratings"
ON public.facility_ratings
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);
