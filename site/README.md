# AIPin website

Static site for AIPin. Plain HTML/CSS/JS in `src/`, assembled by `build.mjs` (no dependencies, Node 18+).

```sh
cd site
npm run build      # writes dist/
open dist/index.html
```

The build reads `../AIPin` so nothing is copied by hand:

- `AIPin.toc` → version shown on the download button
- `CHANGELOG.md` → the changelog section
- `media/icon-512.png` → logo and favicon (`dist/icon.png`)

If `../AIPin` is missing at build time, the script fetches those files from GitHub at the deployed commit (`VERCEL_GIT_COMMIT_SHA`, else `main`).

## Vercel

Create a project from this repo with **Root Directory** `site`. `vercel.json` sets everything else:

- Framework preset: Other
- Build command: `npm run build`
- Output directory: `dist`
