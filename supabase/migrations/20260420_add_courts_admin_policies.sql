-- Enable RLS for courts and allow admin users to manage court rows.
-- Admin check is based on profiles.role = 'admin' for auth.uid().

ALTER TABLE public.courts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can read courts"
ON public.courts;
CREATE POLICY "Authenticated users can read courts"
ON public.courts
FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "Admins can insert courts"
ON public.courts;
CREATE POLICY "Admins can insert courts"
ON public.courts
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role = 'admin'
  )
);

DROP POLICY IF EXISTS "Admins can update courts"
ON public.courts;
CREATE POLICY "Admins can update courts"
ON public.courts
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role = 'admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role = 'admin'
  )
);

DROP POLICY IF EXISTS "Admins can delete courts"
ON public.courts;
CREATE POLICY "Admins can delete courts"
ON public.courts
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role = 'admin'
  )
);
