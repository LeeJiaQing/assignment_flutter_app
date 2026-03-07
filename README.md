# assignment

CourtNow app (Flutter).

## Architecture

Current app structure follows **MVVM + Repository**:

- **View**: feature screens/widgets under `lib/features/**`.
- **ViewModel**: state + UI logic under `lib/features/**/viewmodels`.
- **Repository**: data access abstraction under `lib/core/repositories`.

For authentication role source, `SupabaseAuthRepository` is prepared as repository entry point and can be wired to real Supabase auth/profile data.
