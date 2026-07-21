# Backend Deployment Runbook (Vercel)

The backend is a set of Vercel serverless functions (`api/`) with shared code
in `lib/`. It exists **only as a fallback** for devices without Apple
Intelligence — the app is fully functional without it. Deploying is optional
for 1.0, but doing it means older devices get real AI sayings and artwork.

Verified state before deploying: `npm run type-check` clean, `npm test`
26/26 passing, `npm audit --omit=dev` reports 0 vulnerabilities.

## 1. Prerequisites

- A Vercel account and the Vercel CLI (`npm i -g vercel`), or use the Vercel
  dashboard's GitHub integration on this repo.
- An OpenAI API key with access to the models named in `lib/openai.ts`.
- ⚠️ **Verify the model IDs in `lib/openai.ts` against OpenAI's current model
  list before deploying.** A wrong model name type-checks fine and fails every
  request at runtime.

## 2. Create the KV store

The backend uses Vercel KV (Upstash Redis) for caching, rate limits, and
image bytes.

1. Vercel dashboard → Storage → Create → **KV**.
2. Attach it to the project. This auto-populates `KV_REST_API_URL` and
   `KV_REST_API_TOKEN` in the project's environment.

## 3. Environment variables

Set in Vercel → Project → Settings → Environment Variables (Production):

| Variable | Required | Value |
|---|---|---|
| `OPENAI_API_KEY` | ✅ | Your OpenAI key |
| `KV_REST_API_URL` / `KV_REST_API_TOKEN` | ✅ | Auto-set by attaching KV |
| `API_BASE_URL` | recommended | The deployed origin, e.g. `https://mfv-api.vercel.app` — used to build the public image URLs served by `api/image/[key].ts` |
| `OPENAI_MODEL` / `OPENAI_FALLBACK_MODEL` / `OPENAI_IMAGE_MODEL` | optional | Model overrides |
| `APPLE_ROOT_CERTS` | not needed for 1.0 | Only if the subscription is ever re-enabled (see `app-store/SUBMISSION.md` §5) |

## 4. Deploy

```bash
npm install
vercel           # preview deploy, sanity-check it
vercel --prod    # production
```

Or push to the connected Git branch and let Vercel build automatically.

## 5. Post-deploy smoke tests

Replace `$HOST` with your deployment URL:

```bash
# Sayings — expect 200 with a 10-item array
curl -s -X POST "$HOST/api/generate-sayings" \
  -H 'Content-Type: application/json' \
  -d '{"inspiration":"coffee","userId":"smoke-test-1"}' | head -c 400

# Rate limit — 4th request from the same userId should be 429
for i in 1 2 3 4; do curl -s -o /dev/null -w "%{http_code}\n" \
  -X POST "$HOST/api/generate-sayings" \
  -H 'Content-Type: application/json' \
  -d "{\"inspiration\":\"word-$i\",\"userId\":\"smoke-rl\"}"; done

# Image — expect 200 with an imageUrl on this host
curl -s -X POST "$HOST/api/generate-image" \
  -H 'Content-Type: application/json' \
  -d '{"description":"two cats cuddling","userId":"smoke-test-1","style":"valentine"}'

# The returned imageUrl should serve actual image bytes
curl -s -o /dev/null -w "%{http_code} %{content_type}\n" "<imageUrl from above>"
```

Expected limits: sayings 3/day per `userId`, images 3/day per `userId`
(`DAILY_IMAGE_LIMIT` in `lib/subscription.ts`). Identical prompts are served
from cache without consuming an OpenAI call.

## 6. Point the app at it

Add the deployment origin to the iOS app's `Info.plist`:

```xml
<key>APIBaseURL</key>
<string>https://your-deployment.vercel.app</string>
```

Without this key the app never calls the backend and generates everything on
device (or from built-in templates). With it, devices lacking Apple
Intelligence use the backend as their fallback.

> ⚠️ Shipping a build with `APIBaseURL` set changes the App Store privacy
> answers: the app then sends the typed prompt plus an anonymous install UUID
> to your server. `app-store/SUBMISSION.md` §4 and the published privacy policy
> (https://nathanfennel.com/my-funny-valentine/privacy) already describe this
> fallback, so no policy rewrite is needed — just answer the App Privacy
> questionnaire accordingly.

## 7. Cost guardrails

Spend is bounded by design:

- Per-install daily caps (3 sayings requests, 3 images).
- Prompt-keyed caching (7 days sayings, 30 days images) — repeat prompts are
  free.
- `maxDuration: 30` in `vercel.json` bounds function runtime.

There is no unbounded path: every OpenAI call requires a request that passed
the rate limiter.
