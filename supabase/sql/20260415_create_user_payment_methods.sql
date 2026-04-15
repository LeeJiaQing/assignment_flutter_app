-- Persist per-user payment setup so details are reused across payment sessions.
create table if not exists public.user_payment_methods (
  user_id uuid primary key references auth.users(id) on delete cascade,
  tng_phone text,
  card_number text,
  bank_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.user_payment_methods enable row level security;

create policy if not exists "Users can view their payment setup"
on public.user_payment_methods
for select
to authenticated
using (auth.uid() = user_id);

create policy if not exists "Users can insert their payment setup"
on public.user_payment_methods
for insert
to authenticated
with check (auth.uid() = user_id);

create policy if not exists "Users can update their payment setup"
on public.user_payment_methods
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create or replace function public.set_user_payment_methods_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_user_payment_methods_updated_at on public.user_payment_methods;
create trigger trg_user_payment_methods_updated_at
before update on public.user_payment_methods
for each row
execute function public.set_user_payment_methods_updated_at();
