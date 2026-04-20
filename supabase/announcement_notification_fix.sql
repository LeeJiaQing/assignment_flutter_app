-- ============================================================
-- Announcement + notification consistency patch (Supabase)
-- Run in Supabase SQL Editor
-- Date: 2026-04-20
-- ============================================================

BEGIN;

-- 1) Track edits on announcements.
ALTER TABLE public.announcements
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS edit_count INT NOT NULL DEFAULT 0;

-- 2) One-time cleanup of broken legacy rows.
-- 2.1 remove malformed announcement notifications without announcement_id.
DELETE FROM public.user_notifications un
WHERE un.type = 'announcement'
  AND COALESCE(un.data->>'announcement_id', '') = '';

-- 2.2 remove orphan notifications (announcement was deleted already).
DELETE FROM public.user_notifications un
WHERE un.type = 'announcement'
  AND NOT EXISTS (
    SELECT 1
    FROM public.announcements a
    WHERE a.id::text = un.data->>'announcement_id'
  );

-- 2.3 dedupe: keep latest notification per (user_id, announcement_id).
WITH ranked AS (
  SELECT
    id,
    ROW_NUMBER() OVER (
      PARTITION BY user_id, (data->>'announcement_id')
      ORDER BY created_at DESC, id DESC
    ) AS rn
  FROM public.user_notifications
  WHERE type = 'announcement'
)
DELETE FROM public.user_notifications un
USING ranked r
WHERE un.id = r.id
  AND r.rn > 1;

-- 3) Keep user_notifications in sync when an announcement is edited.
CREATE OR REPLACE FUNCTION public.reset_announcement_notifications()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF OLD.title IS DISTINCT FROM NEW.title
     OR OLD.body IS DISTINCT FROM NEW.body THEN

    UPDATE public.user_notifications
    SET is_read = false,
        title = NEW.title,
        body = NEW.body
    WHERE type = 'announcement'
      AND (data->>'announcement_id') = OLD.id::text;

    NEW.edit_count := COALESCE(OLD.edit_count, 0) + 1;
    NEW.updated_at := now();
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_announcement_edited ON public.announcements;
CREATE TRIGGER on_announcement_edited
BEFORE UPDATE ON public.announcements
FOR EACH ROW
EXECUTE FUNCTION public.reset_announcement_notifications();

-- 4) Remove announcement notifications immediately on delete.
CREATE OR REPLACE FUNCTION public.cleanup_deleted_announcement_notifications()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM public.user_notifications
  WHERE type = 'announcement'
    AND (data->>'announcement_id') = OLD.id::text;
  RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS on_announcement_deleted ON public.announcements;
CREATE TRIGGER on_announcement_deleted
AFTER DELETE ON public.announcements
FOR EACH ROW
EXECUTE FUNCTION public.cleanup_deleted_announcement_notifications();

-- 5) Replace sender and no-duplicate behavior for new announcements.
CREATE OR REPLACE FUNCTION public.notify_announcement_targets(announcement_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  ann RECORD;
  uid UUID;
BEGIN
  SELECT * INTO ann FROM public.announcements WHERE id = announcement_id;
  IF NOT FOUND THEN
    RETURN;
  END IF;

  IF ann.target_type = 'all' THEN
    INSERT INTO public.user_notifications (user_id, type, title, body, data)
    SELECT
      p.id,
      'announcement',
      ann.title,
      ann.body,
      jsonb_build_object('announcement_id', ann.id::text)
    FROM public.profiles p
    WHERE p.id <> ann.created_by
      AND NOT EXISTS (
        SELECT 1
        FROM public.user_notifications un
        WHERE un.user_id = p.id
          AND un.type = 'announcement'
          AND (un.data->>'announcement_id') = ann.id::text
      );
  ELSE
    FOREACH uid IN ARRAY ann.target_user_ids LOOP
      CONTINUE WHEN uid = ann.created_by;

      INSERT INTO public.user_notifications (user_id, type, title, body, data)
      SELECT
        uid,
        'announcement',
        ann.title,
        ann.body,
        jsonb_build_object('announcement_id', ann.id::text)
      WHERE NOT EXISTS (
        SELECT 1
        FROM public.user_notifications un
        WHERE un.user_id = uid
          AND un.type = 'announcement'
          AND (un.data->>'announcement_id') = ann.id::text
      );
    END LOOP;
  END IF;

  UPDATE public.announcements
  SET notification_sent = true
  WHERE id = announcement_id;
END;
$$;

COMMIT;
