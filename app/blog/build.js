// Blog builder: posts/*.md -> dist/<slug>.html + dist/index.html
// Docker build sırasında çalışır (bkz. app/Dockerfile, "blog-builder" stage).
// Hatalı bir yazı build'i durdurur; böylece bozuk bir site deploy edilmez.

import { mkdir, readdir, readFile, rm, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { marked } from "marked";

const root = path.dirname(fileURLToPath(import.meta.url));
const postsDir = path.join(root, "posts");
const outDir = path.join(root, "dist");

const HTML_ESCAPES = { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" };
const escapeHtml = (text) => text.replace(/[&<>"']/g, (char) => HTML_ESCAPES[char]);

const formatDate = (isoDate) =>
  new Date(`${isoDate}T00:00:00Z`).toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
    timeZone: "UTC",
  });

// Dosyanın başındaki "--- ... ---" bloğunu (title, date, summary) okur.
function parsePost(fileName, raw) {
  const slug = fileName.replace(/\.md$/, "");
  if (!/^[a-z0-9]+(-[a-z0-9]+)*$/.test(slug)) {
    throw new Error(`${fileName}: file name may only contain lowercase letters, digits and dashes`);
  }

  const match = raw.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n?([\s\S]*)$/);
  if (!match) {
    throw new Error(`${fileName}: must start with a front matter block (--- ... ---)`);
  }

  const meta = {};
  for (const line of match[1].split(/\r?\n/)) {
    if (!line.trim()) continue;
    const field = line.match(/^([A-Za-z_]+):\s*(.*)$/);
    if (!field) {
      throw new Error(`${fileName}: cannot read front matter line "${line}"`);
    }
    meta[field[1]] = field[2].trim().replace(/^(["'])(.*)\1$/, "$2");
  }

  if (!meta.title) {
    throw new Error(`${fileName}: front matter needs a "title"`);
  }
  if (!/^\d{4}-\d{2}-\d{2}$/.test(meta.date ?? "") || Number.isNaN(Date.parse(meta.date))) {
    throw new Error(`${fileName}: front matter needs a "date" in YYYY-MM-DD format`);
  }

  return {
    slug,
    title: meta.title,
    date: meta.date,
    summary: meta.summary ?? "",
    html: marked.parse(match[2]),
  };
}

// Tek geçişte değiştirir: yazı içeriğindeki "{{ ... }}" ifadelerine dokunmaz.
const render = (layout, values) =>
  layout.replace(/\{\{(\w+)\}\}/g, (placeholder, key) => values[key] ?? placeholder);

function postPage(post) {
  return `
      <a class="blog-back" href="/blog/">&larr; All posts</a>
      <article class="post">
        <header class="post-header">
          <h1 class="title">${escapeHtml(post.title)}</h1>
          <p class="post-date"><time datetime="${post.date}">${formatDate(post.date)}</time></p>
        </header>
        <div class="post-content">
${post.html}
        </div>
      </article>`;
}

function indexPage(posts) {
  const items = posts
    .map(
      (post) => `
        <li class="post-card">
          <a class="post-card__link" href="/blog/${post.slug}.html">
            <h2 class="post-card__title">${escapeHtml(post.title)}</h2>
          </a>
          <p class="post-date"><time datetime="${post.date}">${formatDate(post.date)}</time></p>
          ${post.summary ? `<p class="post-card__summary">${escapeHtml(post.summary)}</p>` : ""}
        </li>`
    )
    .join("");

  return `
      <p class="section__text__p1">Notes &amp; Write-ups</p>
      <h1 class="title">Blog</h1>
      ${posts.length ? `<ul class="post-list">${items}\n      </ul>` : '<p class="blog-empty">No posts yet.</p>'}`;
}

const layout = await readFile(path.join(root, "templates", "layout.html"), "utf8");
const fileNames = (await readdir(postsDir)).filter((name) => name.endsWith(".md")).sort();

const posts = [];
for (const fileName of fileNames) {
  posts.push(parsePost(fileName, await readFile(path.join(postsDir, fileName), "utf8")));
}
// En yeni yazı en üstte; aynı gündekiler dosya adına göre.
posts.sort((a, b) => b.date.localeCompare(a.date) || b.slug.localeCompare(a.slug));

await rm(outDir, { recursive: true, force: true });
await mkdir(outDir, { recursive: true });

for (const post of posts) {
  const page = render(layout, { title: escapeHtml(post.title), content: postPage(post) });
  await writeFile(path.join(outDir, `${post.slug}.html`), page);
}
await writeFile(path.join(outDir, "index.html"), render(layout, { title: "Blog", content: indexPage(posts) }));

console.log(`Blog built: ${posts.length} post(s) -> ${path.relative(process.cwd(), outDir) || "."}`);
