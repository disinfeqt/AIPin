#!/usr/bin/env node
// Builds the AIPin website into site/dist.
//
// The addon folder (../AIPin) is the single source of truth: the version
// comes from AIPin.toc, the changelog section is generated from
// CHANGELOG.md, media/icon-512.png is used as the logo and favicon, and
// AGENTS.md and INSTALL.md are published at the site root so the hero's
// agent prompt can point an AI assistant at them. No dependencies; needs Node 18+.

import { existsSync } from 'node:fs';
import { copyFile, mkdir, readdir, readFile, rm, writeFile } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const SITE_DIR = dirname(fileURLToPath(import.meta.url));
const SRC_DIR = join(SITE_DIR, 'src');
const OUT_DIR = join(SITE_DIR, 'dist');
const ADDON_DIR = resolve(SITE_DIR, '..', 'AIPin');

const REPO = 'disinfeqt/AIPin';
const REPO_URL = `https://github.com/${REPO}`;
// Public address of the site; the agent prompt in the hero links to INSTALL.md here.
const SITE_URL = (process.env.SITE_URL || 'https://wow.duxi.ao').replace(/\/+$/, '');

// ---------------------------------------------------------------------------
// Reading addon files
// ---------------------------------------------------------------------------

// A Vercel Git deployment clones the whole repository, so ../AIPin is normally
// on disk even when the project's Root Directory is `site`. If it isn't (for
// example "Include files outside the root directory" was turned off, or the
// site/ folder was deployed on its own), read the same commit from GitHub.
async function readAddonFile(rel, { binary = false } = {}) {
  const local = join(ADDON_DIR, rel);
  if (existsSync(local)) return readFile(local, binary ? undefined : 'utf8');

  const owner = process.env.VERCEL_GIT_REPO_OWNER;
  const slug = process.env.VERCEL_GIT_REPO_SLUG;
  const repo = owner && slug ? `${owner}/${slug}` : REPO;
  const ref = process.env.VERCEL_GIT_COMMIT_SHA || 'main';
  const url = `https://raw.githubusercontent.com/${repo}/${ref}/AIPin/${rel}`;
  console.warn(`! ${local} not found; fetching ${url}`);

  const res = await fetch(url);
  if (!res.ok) {
    throw new Error(`Cannot read AIPin/${rel}: not on disk, and ${url} returned HTTP ${res.status}`);
  }
  return binary ? Buffer.from(await res.arrayBuffer()) : res.text();
}

function tocField(toc, field) {
  const m = toc.match(new RegExp(`^##\\s*${field}:\\s*(.+?)\\s*$`, 'm'));
  return m ? m[1] : null;
}

// ---------------------------------------------------------------------------
// Changelog
// ---------------------------------------------------------------------------

const esc = (s) =>
  String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);

// Minimal inline Markdown: `code`, **bold**, [text](https://link).
function inline(md) {
  return md
    .split(/(`[^`]+`)/)
    .map((part) => {
      if (/^`[^`]+`$/.test(part)) return `<code>${esc(part.slice(1, -1))}</code>`;
      return esc(part)
        .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
        .replace(/\[([^\]]+)\]\((https?:\/\/[^)\s]+)\)/g, '<a href="$2">$1</a>');
    })
    .join('');
}

// "## 1.1.0", "## v1.1.0", "## [1.1.0] - 2026-11-05" -> { version, note }
function parseHeading(text) {
  const m = text.match(/v?(\d+\.\d+(?:\.\d+)?(?:-[0-9A-Za-z.-]+)?)/);
  if (!m) return { version: text, note: '' };
  const note = text.replace(m[0], '').replace(/^[\s\-–—:[\]()]+|[\s\-–—:[\]()]+$/g, '');
  return { version: m[1], note };
}

function parseChangelog(md) {
  const releases = [];
  let current = null;
  for (const raw of md.split(/\r?\n/)) {
    const heading = raw.match(/^##\s+(.+?)\s*$/);
    if (heading) {
      current = { ...parseHeading(heading[1]), items: [] };
      releases.push(current);
      continue;
    }
    if (!current) continue;
    const item = raw.match(/^\s*[-*+]\s+(.*)$/);
    if (item) current.items.push(item[1].trim());
    else if (raw.trim() && current.items.length && /^\s{2,}\S/.test(raw)) {
      current.items[current.items.length - 1] += ' ' + raw.trim(); // wrapped bullet
    }
  }
  return releases;
}

// CHANGELOG.md lists each change in Chinese and in English. Sort bullets by
// language so the site's language toggle can show one set at a time.
function bulletLang(text) {
  const plain = text.replace(/`[^`]*`/g, ' ');
  const han = (plain.match(/\p{Script=Han}/gu) || []).length;
  const words = (plain.match(/[A-Za-z]+/g) || []).length;
  return han > 0 && han >= words ? 'zh' : 'en';
}

function renderChangelog(md) {
  const releases = parseChangelog(md);
  if (!releases.length) throw new Error('CHANGELOG.md has no "## <version>" sections');

  const list = (items, lang) =>
    `<ul${lang ? ` lang="${lang}"` : ''}>\n${items.map((t) => `          <li>${inline(t)}</li>`).join('\n')}\n        </ul>`;

  const html = releases
    .map((r) => {
      const zh = r.items.filter((t) => bulletLang(t) === 'zh');
      const en = r.items.filter((t) => bulletLang(t) === 'en');
      // If a release is written in only one language, show it in both modes.
      const body = zh.length && en.length ? `${list(zh, 'zh-CN')}\n        ${list(en, 'en')}` : list(r.items);
      const id = `v${r.version.replace(/[^0-9A-Za-z]+/g, '-')}`;
      const note = r.note ? `<span class="release-note">${esc(r.note)}</span>` : '';
      return `<article class="release" id="${id}">
        <header class="release-head"><h3>v${esc(r.version)}</h3>${note}</header>
        ${body}
      </article>`;
    })
    .join('\n      ');

  return { html, releases };
}

// ---------------------------------------------------------------------------
// Build
// ---------------------------------------------------------------------------

async function build() {
  const [toc, changelog, icon, agents, install] = await Promise.all([
    readAddonFile('AIPin.toc'),
    readAddonFile('CHANGELOG.md'),
    readAddonFile('media/icon-512.png', { binary: true }),
    readAddonFile('AGENTS.md'),
    readAddonFile('INSTALL.md'),
  ]);

  const version = tocField(toc, 'Version');
  if (!version) throw new Error('AIPin.toc has no "## Version:" line');

  const { html: changelogHtml, releases } = renderChangelog(changelog);
  if (releases[0].version !== version) {
    console.warn(`! AIPin.toc says ${version} but the newest CHANGELOG.md entry is ${releases[0].version}`);
  }

  const vars = {
    VERSION: esc(version),
    REPO_URL,
    DOWNLOAD_URL: `${REPO_URL}/releases/latest/download/AIPin.zip`,
    AGENTS_URL: `${REPO_URL}/blob/main/AIPin/AGENTS.md`,
    INSTALL_PROMPT_URL: `${SITE_URL}/INSTALL.md`,
    ICON_URL: `https://raw.githubusercontent.com/${REPO}/main/AIPin/media/icon-512.png`,
    CHANGELOG: changelogHtml,
  };

  const template = await readFile(join(SRC_DIR, 'index.html'), 'utf8');
  const page = template.replace(/\{\{(\w+)\}\}/g, (match, key) => {
    if (!(key in vars)) throw new Error(`Unknown placeholder ${match} in src/index.html`);
    return vars[key];
  });

  await rm(OUT_DIR, { recursive: true, force: true });
  await mkdir(OUT_DIR, { recursive: true });
  await writeFile(join(OUT_DIR, 'index.html'), page);
  await writeFile(join(OUT_DIR, 'icon.png'), icon);
  await writeFile(join(OUT_DIR, 'AGENTS.md'), agents);
  await writeFile(join(OUT_DIR, 'INSTALL.md'), install);
  for (const entry of await readdir(SRC_DIR, { withFileTypes: true })) {
    if (entry.isFile() && entry.name !== 'index.html') {
      await copyFile(join(SRC_DIR, entry.name), join(OUT_DIR, entry.name));
    }
  }

  console.log(`Built ${OUT_DIR}: AIPin v${version}, ${releases.length} changelog entries`);
}

build().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
