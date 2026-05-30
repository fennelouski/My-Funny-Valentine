# Deploying the Marketing Website to Vercel

## Option A: Deploy website as its own Vercel project (recommended)

1. Go to [vercel.com](https://vercel.com) and sign in.
2. Click **Add New** → **Project**.
3. Import your Git repository.
4. Configure the project:
   - **Root Directory**: Click **Edit** and set to `website`.
   - **Framework Preset**: Next.js (auto-detected).
   - **Build Command**: `npm run build` (default).
   - **Output Directory**: `out` (for static export).
5. Click **Deploy**.

After deployment, add your production URL to:
- `website/public/robots.txt` → `Sitemap:` line
- `website/app/sitemap.ts` → `url` in the returned array

## Option B: Same repo as API (monorepo)

To serve both the API and the website from one Vercel project:

1. In the **root** of the repo (not in `website`), add a `vercel.json` that:
   - Keeps `api/` routes for the backend.
   - Serves the static website from `website/out` for all other routes.

2. Use a single build that:
   - Builds the API (TypeScript).
   - Runs `cd website && npm install && npm run build`.

This requires a root `package.json` with a build script that runs both. Prefer **Option A** if you want the site and API as separate URLs (e.g. `myapp.vercel.app` for site and `api.myapp.vercel.app` for API).

## Post-deploy checklist

- [ ] Replace `[APP_ID]` in `components/Hero.tsx` and `components/Footer.tsx` with your App Store app ID.
- [ ] Update `website/public/robots.txt` and `website/app/sitemap.ts` with your production domain.
- [ ] Add real screenshots under `website/public/screenshots/` and wire them in `components/Screenshots.tsx`.
- [ ] (Optional) Add a real `favicon.ico` to `website/public/`.
- [ ] Enable Vercel Analytics in the Vercel project dashboard if desired.
