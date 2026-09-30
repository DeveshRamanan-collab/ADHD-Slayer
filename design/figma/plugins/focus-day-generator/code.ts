// Focus Day Generator — Figma generative plugin (sandbox side).
// Builds a realistic Today timeline from a dose time, a focus window and a task list,
// using the same placement rules as the app's scheduler (docs/system-design.md §6):
// deep work longest-first inside best focus, medium/light in lighter focus, body tasks
// outside the window, a fill cap on flexible work, and 10-min transitions around fixed events.

const PANEL_WIDTH = 320

type TaskKind = 'deep' | 'medium' | 'light' | 'body'
type Task = { title: string; minutes: number; kind: TaskKind }
type Fixed = { title: string; start: number; minutes: number }
type Config = {
  dose: string
  startAfterMin: number
  lastsHours: number
  bestShare: number
  fillCap: number
  tasks: string
  fixed: string
}
type UiMessage = { type: 'resize'; height: number } | { type: 'generate'; config: Config }
type Block = { start: number; end: number; title: string; kind: TaskKind | 'fixed' | 'buffer'; zone: string }

figma.showUI(__html__, { width: PANEL_WIDTH, height: 560 })
figma.root.setRelaunchData({ open: 'Generate a focus day' })

const post = (text: string, tone: 'info' | 'error' | 'success' = 'info') => figma.ui.postMessage({ type: 'status', text, tone })

function parseClock(value: string): number | null {
  const m = value.trim().match(/^(\d{1,2})[:.](\d{2})$/)
  if (!m) return null
  const h = Number(m[1]), min = Number(m[2])
  if (h > 23 || min > 59) return null
  return h * 60 + min
}

function fmt(mins: number): string {
  const h = Math.floor(mins / 60), m = Math.round(mins % 60)
  const h12 = ((h + 11) % 12) + 1
  return `${h12}:${String(m).padStart(2, '0')}`
}

function parseTasks(text: string): Task[] {
  const out: Task[] = []
  for (const line of text.split('\n').slice(0, 30)) {
    const [title, mins, kind] = line.split(',').map(s => s.trim())
    if (!title) continue
    const minutes = Math.min(240, Math.max(5, Number(mins) || 30))
    const k = (['deep', 'medium', 'light', 'body'].includes(kind) ? kind : 'medium') as TaskKind
    out.push({ title, minutes, kind: k })
  }
  return out
}

function parseFixed(text: string): Fixed[] {
  const out: Fixed[] = []
  for (const line of text.split('\n').slice(0, 12)) {
    const [title, at, mins] = line.split(',').map(s => s.trim())
    const start = at ? parseClock(at) : null
    if (!title || start === null) continue
    out.push({ title, start, minutes: Math.min(480, Math.max(5, Number(mins) || 60)) })
  }
  return out
}

// Earliest gap of `len` minutes inside [from, to] that avoids every busy interval.
function fit(busy: Array<[number, number]>, from: number, to: number, len: number): number | null {
  let t = from
  const sorted = [...busy].sort((a, b) => a[0] - b[0])
  for (const [s, e] of sorted) {
    if (e <= t) continue
    if (s >= t + len) break
    t = Math.max(t, e)
  }
  return t + len <= to ? t : null
}

function plan(cfg: Config): { blocks: Block[]; unplaced: Task[]; window: [number, number, number]; dose: number } | string {
  const dose = parseClock(cfg.dose)
  if (dose === null) return 'Dose time should look like 8:10.'
  const wStart = dose + Math.min(180, Math.max(0, cfg.startAfterMin))
  const wEnd = wStart + Math.min(16, Math.max(1, cfg.lastsHours)) * 60
  const peakEnd = wStart + (wEnd - wStart) * Math.min(0.95, Math.max(0.3, cfg.bestShare / 100))
  const dayEnd = 22 * 60
  const tasks = parseTasks(cfg.tasks)
  const fixed = parseFixed(cfg.fixed)
  const TRANSITION = 10

  const busy: Array<[number, number]> = []
  const blocks: Block[] = []
  for (const f of fixed) {
    busy.push([f.start - TRANSITION, f.start + f.minutes + TRANSITION])
    blocks.push({ start: f.start, end: f.start + f.minutes, title: f.title, kind: 'fixed', zone: 'Calendar' })
  }
  // Fill cap: flexible work may use at most `fillCap` of the free window minutes.
  const windowFree = (wEnd - wStart) - fixed.reduce((acc, f) => acc + Math.max(0, Math.min(wEnd, f.start + f.minutes) - Math.max(wStart, f.start)), 0)
  let budget = windowFree * Math.min(0.9, Math.max(0.3, cfg.fillCap / 100))
  const unplaced: Task[] = []

  const place = (t: Task, from: number, to: number, zone: string, counts: boolean): boolean => {
    if (counts && t.minutes > budget) return false
    const s = fit(busy, from, to, t.minutes)
    if (s === null) return false
    busy.push([s, s + t.minutes + TRANSITION])
    blocks.push({ start: s, end: s + t.minutes, title: t.title, kind: t.kind, zone })
    if (counts) budget -= t.minutes
    return true
  }

  const deep = tasks.filter(t => t.kind === 'deep').sort((a, b) => b.minutes - a.minutes)
  const midLight = tasks.filter(t => t.kind === 'medium' || t.kind === 'light')
  const body = tasks.filter(t => t.kind === 'body')
  for (const t of deep) if (!place(t, wStart, peakEnd, 'Best focus', true) && !place(t, wStart, wEnd, 'Lighter focus', true)) unplaced.push(t)
  for (const t of midLight) if (!place(t, peakEnd, wEnd, 'Lighter focus', true) && !place(t, wStart, wEnd, 'Best focus', true)) unplaced.push(t)
  for (const t of body) {
    const isMeal = /lunch|meal|eat/i.test(t.title)
    const ok = isMeal
      ? place(t, dose + 300, dayEnd, 'Meal rule · 5 h after logging', false)
      : place(t, wEnd + 20, dayEnd, 'After focus window', false) || place(t, 7 * 60, dose, 'Before logging', false)
    if (!ok) unplaced.push(t)
  }
  blocks.sort((a, b) => a.start - b.start)
  return { blocks, unplaced, window: [wStart, peakEnd, wEnd], dose }
}

async function colorPaint(name: string, fallback: RGB): Promise<SolidPaint> {
  const vars = await figma.variables.getLocalVariablesAsync('COLOR')
  const v = vars.find(x => x.name === name)
  const base: SolidPaint = { type: 'SOLID', color: fallback }
  return v ? figma.variables.setBoundVariableForPaint(base, 'color', v) : base
}

async function render(result: Exclude<ReturnType<typeof plan>, string>): Promise<FrameNode> {
  const font: FontName = { family: 'Inter', style: 'Regular' }
  const fontBold: FontName = { family: 'Inter', style: 'Semi Bold' }
  await Promise.all([figma.loadFontAsync(font), figma.loadFontAsync(fontBold)])
  const kindColor: Record<string, [string, RGB]> = {
    deep: ['focus/strong', { r: 0.169, g: 0.431, b: 0.408 }],
    medium: ['focus/mid', { r: 0.498, g: 0.698, b: 0.675 }],
    light: ['focus/soft', { r: 0.835, g: 0.906, b: 0.89 }],
    body: ['body/strong', { r: 0.627, g: 0.384, b: 0.247 }],
    fixed: ['fixed/strong', { r: 0.373, g: 0.392, b: 0.533 }],
    buffer: ['ink/tertiary', { r: 0.541, g: 0.557, b: 0.541 }],
  }
  const ink = await colorPaint('ink/primary', { r: 0.106, g: 0.114, b: 0.11 })
  const inkSecondary = await colorPaint('ink/secondary', { r: 0.353, g: 0.373, b: 0.361 })
  const surface = await colorPaint('bg/surface', { r: 1, g: 1, b: 1 })

  const frame = figma.createFrame()
  frame.name = `Generated day · logged ${fmt(result.dose)}`
  frame.layoutMode = 'VERTICAL'
  frame.primaryAxisSizingMode = 'AUTO'
  frame.counterAxisSizingMode = 'FIXED'
  frame.resize(354, 100)
  frame.paddingTop = frame.paddingBottom = 12
  frame.paddingLeft = frame.paddingRight = 12
  frame.itemSpacing = 4
  frame.cornerRadius = 26
  frame.fills = [surface]

  const header = figma.createText()
  header.fontName = fontBold
  header.fontSize = 13
  header.characters = `Focus window ${fmt(result.window[0])} – ${fmt(result.window[2])} · best focus to ${fmt(result.window[1])}`
  header.fills = [inkSecondary]
  frame.appendChild(header)

  for (const b of result.blocks) {
    const row = figma.createFrame()
    row.name = b.title
    row.layoutMode = 'HORIZONTAL'
    row.counterAxisAlignItems = 'CENTER'
    row.itemSpacing = 12
    row.paddingTop = row.paddingBottom = 8
    row.fills = []
    frame.appendChild(row)
    row.layoutSizingHorizontal = 'FILL'
    row.layoutSizingVertical = 'HUG'

    const time = figma.createText()
    time.fontName = fontBold
    time.fontSize = 15
    time.characters = fmt(b.start)
    time.fills = [ink]
    time.textAlignHorizontal = 'RIGHT'
    row.appendChild(time)
    time.resize(44, time.height)

    const bar = figma.createRectangle()
    const [varName, fallback] = kindColor[b.kind]
    bar.fills = [await colorPaint(varName, fallback)]
    bar.cornerRadius = 2
    bar.resize(4, 36)
    row.appendChild(bar)

    const col = figma.createFrame()
    col.layoutMode = 'VERTICAL'
    col.fills = []
    col.itemSpacing = 2
    row.appendChild(col)
    col.layoutSizingHorizontal = 'FILL'
    col.layoutSizingVertical = 'HUG'
    const title = figma.createText()
    title.fontName = fontBold
    title.fontSize = 15
    title.characters = b.title
    title.fills = [ink]
    col.appendChild(title)
    const meta = figma.createText()
    meta.fontName = font
    meta.fontSize = 13
    meta.characters = `${Math.round(b.end - b.start)} min · ${b.zone}`
    meta.fills = [inkSecondary]
    col.appendChild(meta)
  }

  if (result.unplaced.length) {
    const note = figma.createText()
    note.fontName = font
    note.fontSize = 13
    note.characters = `Didn’t fit without over-packing: ${result.unplaced.map(t => t.title).join(', ')}. The app would ask you: split, move to tomorrow, or use your baseline day.`
    note.fills = [await colorPaint('attention/strong', { r: 0.541, g: 0.369, b: 0 })]
    frame.appendChild(note)
    note.layoutSizingHorizontal = 'FILL'
    note.textAutoResize = 'HEIGHT'
  }

  frame.x = Math.round(figma.viewport.center.x - frame.width / 2)
  frame.y = Math.round(figma.viewport.center.y - frame.height / 2)
  frame.setRelaunchData({ open: 'Regenerate this focus day' })
  return frame
}

figma.ui.onmessage = async (message: UiMessage) => {
  if (message.type === 'resize') {
    figma.ui.resize(PANEL_WIDTH, Math.max(200, Math.min(900, Math.round(message.height))))
    return
  }
  if (message.type === 'generate') {
    const result = plan(message.config)
    if (typeof result === 'string') {
      post(result, 'error')
      return
    }
    try {
      const frame = await render(result)
      figma.currentPage.selection = [frame]
      figma.viewport.scrollAndZoomIntoView([frame])
      const extra = result.unplaced.length ? ` · ${result.unplaced.length} didn’t fit` : ''
      post(`Created a day with ${result.blocks.length} blocks${extra}.`, 'success')
    } catch (e) {
      post(`Couldn’t create the layer: ${(e as Error).message}`, 'error')
    }
  }
}
