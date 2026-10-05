import Quickshell
import Quickshell.Io
import QtQuick

Scope {
  id: cm
  required property var cfg
  function run() { p.running = true }

  function hex(v) { return v.map(x => Math.round(Math.max(0, Math.min(255, x))).toString(16).padStart(2, "0")).join("") }
  function find(o) {
    if (typeof o === "string") return o
    if (o && typeof o === "object") return o.hex ?? o.color ?? find(Object.values(o)[0])
    return ""
  }
  function apply(txt) {
    const t = txt.trim()
    const i = t.indexOf("{")
    if (i >= 0) {
      let j
      try { j = JSON.parse(t.slice(i, t.lastIndexOf("}") + 1)) } catch (e) { return }
      const c = j.colors || j
      const get = (...names) => {
        for (const n of names) {
          const v = c.dark && c.dark[n] !== undefined ? c.dark[n] : (c[n] && c[n].dark !== undefined ? c[n].dark : undefined)
          const s = find(v)
          if (s) return s.slice(0, 7)
        }
        return ""
      }
      const a = get("primary")
      const b = get("surface", "background")
      const q = get("surface_container_high", "surface_container", "surface_variant")
      if (a) cfg.accent = a
      if (b) cfg.bg = b
      if (q) cfg.pill = q
    } else {
      const h = t.slice(0, 6)
      if (h.length < 6) return
      const c = [0, 2, 4].map(k => parseInt(h.slice(k, k + 2), 16))
      cfg.accent = "#" + hex(c.map(x => x * 0.4 + 153))
      cfg.bg = "#" + hex(c.map(x => x * 0.12 + 8))
      cfg.pill = "#" + hex(c.map(x => x * 0.26 + 18))
    }
  }

  Process {
    id: p
    command: ["sh", "-c", 'if command -v matugen >/dev/null 2>&1; then for a in "--json hex --dry-run image" "--json hex image"; do out=$(matugen $a "$1" -m dark 2>/dev/null); [ -n "$out" ] && break; done; [ -n "$out" ] || out=$(matugen image "$1" -m dark --json hex 2>/dev/null); printf %s "$out"; else m=$(command -v magick || echo convert); $m "$1" -resize 1x1 -format "%[hex:u]" info:; fi', "x", cm.cfg.wallpaper]
    stdout: StdioCollector { onStreamFinished: cm.apply(this.text) }
  }
}
