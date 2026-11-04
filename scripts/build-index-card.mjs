// Rebuilds assets/kphd-index-card.svg from the live KPHD Index (kelliepatry.com/index).
// Projects and Field Notes are counted from the published page; if the fetch fails or
// looks wrong, the last good counts in assets/index-card.json are kept.
import { readFileSync, writeFileSync, existsSync } from "node:fs"

const SRC = "https://kelliepatry.com/index"
const STATE = "assets/index-card.json"
const OUT = "assets/kphd-index-card.svg"
const STAGES = ["Discovery", "Design", "Documents + permits", "Build", "Opening"]
const TYPES = ["Coffee", "Bar", "Restaurant", "Hotel", "Retail + salon", "Kitchen + workplace"]

const prev = existsSync(STATE) ? JSON.parse(readFileSync(STATE, "utf8")) : { projects: 17, notes: 14 }
let projects = prev.projects, notes = prev.notes, source = "cached"
try {
    const res = await fetch(SRC, { headers: { "user-agent": "kphd-index-card" } })
    if (!res.ok) throw new Error("HTTP " + res.status)
    const html = await res.text()
    const uniq = (re) => new Set([...html.matchAll(re)].map((m) => m[1])).size
    const p = uniq(/\/projects\/([a-z0-9-]+)/g)
    const n = uniq(/\/notes\/([a-z0-9-]+)/g)
    if (p >= 5 && n >= 3) { projects = p; notes = n; source = "live" }
    else console.warn(`implausible counts p=${p} n=${n}; keeping previous`)
} catch (e) { console.warn("fetch failed:", e.message, "— keeping previous counts") }

const pad = (x) => String(x).padStart(2, "0")
const stamp = new Date().toLocaleDateString("en-CA", { timeZone: "America/Los_Angeles" })
const changed = projects !== prev.projects || notes !== prev.notes
const updated = changed || !prev.updated ? stamp : prev.updated
writeFileSync(STATE, JSON.stringify({ projects, notes, updated }, null, 2) + "\n")

const CYCLE = STAGES.length * 3 // seconds; each stage holds 3s
const stageRows = STAGES.map((s, i) => {
    const y = 140 + i * 50
    const d = `${i * 3}s`
    return `    <circle cx="880" cy="${y}" r="5" class="dot" style="animation-delay:${d}"/>
    <text x="900" y="${y + 4}" class="stg" style="animation-delay:${d}">${s.toUpperCase().replace("+", "&#43;")}</text>`
}).join("\n")

const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="440" viewBox="0 0 1200 440" role="img" aria-labelledby="t d">
  <title id="t">KPHD Index</title>
  <desc id="d">The KPHD Index: ${projects} projects, ${TYPES.length} place types, ${STAGES.length} stages, ${notes} Field Notes. Live at kelliepatry.com/index. Updated ${updated}.</desc>
  <style>
    .m{font-family:'Space Mono','SFMono-Regular',Consolas,'Liberation Mono',monospace}
    .scan{animation:scan 3.2s cubic-bezier(.6,0,.3,1) infinite}
    @keyframes scan{0%{transform:translateX(-260px)}100%{transform:translateX(560px)}}
    .live{animation:pulse 2s ease-in-out infinite}
    @keyframes pulse{0%,100%{opacity:1}50%{opacity:.2}}
    .dot{fill:#161615;stroke:#A6A6A3;stroke-width:1;animation:dot ${CYCLE}s steps(1,end) infinite}
    @keyframes dot{0%{fill:#F4F4F2;stroke:#F4F4F2}${(100 / STAGES.length).toFixed(2)}%,100%{fill:#161615;stroke:#A6A6A3}}
    .stg{font-family:'Space Mono','SFMono-Regular',Consolas,monospace;font-size:12px;letter-spacing:2px;fill:#7C7C79;animation:stg ${CYCLE}s steps(1,end) infinite}
    @keyframes stg{0%{fill:#F4F4F2}${(100 / STAGES.length).toFixed(2)}%,100%{fill:#7C7C79}}
    @media (prefers-reduced-motion:reduce){.scan,.live,.dot,.stg{animation:none}}
  </style>
  <rect width="1200" height="440" fill="#161615"/>
  <rect x="48" y="40" width="1104" height="360" fill="none" stroke="#3A3A38"/>
  <line x1="48" y1="88" x2="1152" y2="88" stroke="#3A3A38"/>
  <text x="72" y="71" class="m" font-size="15" letter-spacing="3.2" fill="#A6A6A3">SHEET IX — KPHD INDEX</text>
  <circle cx="772" cy="66" r="4" fill="#F4F4F2" class="live"/>
  <text x="1128" y="71" text-anchor="end" class="m" font-size="15" letter-spacing="3.2" fill="#7C7C79">LIVE · KELLIEPATRY.COM/INDEX</text>

  <text x="72" y="168" class="m" font-size="54" font-weight="700" letter-spacing="-1.5" fill="#F4F4F2">Every room. Every phase.</text>
  <text x="72" y="222" class="m" font-size="54" font-weight="700" letter-spacing="-1.5" fill="#7C7C79">Every note behind it.</text>

  <svg x="72" y="246" width="520" height="3" overflow="hidden">
    <rect width="520" height="3" fill="#3A3A38"/>
    <rect width="260" height="3" fill="#F4F4F2" class="scan"/>
  </svg>

  <g class="m">
    <text x="72"  y="312" font-size="44" font-weight="700" fill="#F4F4F2">${pad(projects)}</text>
    <text x="72"  y="338" font-size="13" letter-spacing="2.6" fill="#A6A6A3">PROJECTS</text>
    <text x="272" y="312" font-size="44" font-weight="700" fill="#F4F4F2">${pad(TYPES.length)}</text>
    <text x="272" y="338" font-size="13" letter-spacing="2.6" fill="#A6A6A3">PLACE TYPES</text>
    <text x="472" y="312" font-size="44" font-weight="700" fill="#F4F4F2">${pad(STAGES.length)}</text>
    <text x="472" y="338" font-size="13" letter-spacing="2.6" fill="#A6A6A3">STAGES</text>
    <text x="672" y="312" font-size="44" font-weight="700" fill="#F4F4F2">${pad(notes)}</text>
    <text x="672" y="338" font-size="13" letter-spacing="2.6" fill="#A6A6A3">FIELD NOTES</text>
  </g>
  <text x="72" y="380" class="m" font-size="11" letter-spacing="2.2" fill="#7C7C79">UPDATED ${updated} · RECOUNTED DAILY FROM THE LIVE INDEX</text>

  <line x1="880" y1="128" x2="880" y2="352" stroke="#3A3A38"/>
${stageRows}

  <text x="48" y="428" class="m" font-size="13" letter-spacing="2.6" fill="#7C7C79">${TYPES.map((t) => t.toUpperCase()).join(" · ")}</text>
  <text x="1152" y="428" text-anchor="end" class="m" font-size="15" letter-spacing="3.2" fill="#F4F4F2">OPEN THE INDEX  →</text>
</svg>
`
writeFileSync(OUT, svg)
console.log(`card: ${projects} projects, ${notes} notes (${source}), updated ${updated}`)
