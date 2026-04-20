-- Migrate legacy public.reviews rows into public.facility_ratings
-- and remove the old table once data is copied.

DO $$
BEGIN
  IF to_regclass('public.reviews') IS NOT NULL THEN
    INSERT INTO public.facility_ratings (facility_id, user_id, rating, review, created_at)
    SELECT
      r.facility_id,
      r.user_id,
      r.rating,
      r.comment,
      r.created_at
    FROM public.reviews r
    ON CONFLICT (facility_id, user_id)
    DO UPDATE SET
      rating = EXCLUDED.rating,
      review = EXCLUDED.review,
      created_at = EXCLUDED.created_at;

    DROP TABLE public.reviews;
  END IF;
END
$$;

-- Backfill facilities.average_rating after migration.
UPDATE public.facilities f
SET average_rating = COALESCE(avg_rows.avg_rating, 0)
FROM (
  SELECT
    fr.facility_id,
    ROUND(AVG(fr.rating)::numeric, 2) AS avg_rating
  FROM public.facility_ratings fr
  GROUP BY fr.facility_id
) AS avg_rows
WHERE f.id = avg_rows.facility_id;

UPDATE public.facilities
SET average_rating = 0
WHERE id NOT IN (
  SELECT DISTINCT facility_id
  FROM public.facility_ratings
);
