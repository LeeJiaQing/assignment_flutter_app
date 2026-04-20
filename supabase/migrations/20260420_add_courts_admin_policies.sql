-- Enable RLS for courts and allow authenticated users to manage court rows.
-- Access to this flow is controlled by app routing (admin screens).

ALTER TABLE public.courts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can read courts"
ON public.courts;
CREATE POLICY "Authenticated users can read courts"
ON public.courts
FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert courts"
ON public.courts;
CREATE POLICY "Authenticated users can insert courts"
ON public.courts
FOR INSERT
TO authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated users can update courts"
ON public.courts;
CREATE POLICY "Authenticated users can update courts"
ON public.courts
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated users can delete courts"
ON public.courts;
CREATE POLICY "Authenticated users can delete courts"
ON public.courts
FOR DELETE
TO authenticated
USING (true);
