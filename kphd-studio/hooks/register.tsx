import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { Brief, View } from '../types'

// KPHD Monotone — Vermilion. Hex values from the studio's Set 1 / Set 2 spec.
const PLUGIN = 'kphd-studio'
const PANE = 'kphd'
const BRIEF_TOOL = 'mcp__kphd-studio__brief'
const BACKDROP = 'kphd-linen'

const isDark = atom({ plugin: 'kphd-studio', key: 'isDark' } as const, true)
const view = atom({ plugin: 'kphd-studio', key: 'view' } as const, 'palette' as View)
const brief = atom({ plugin: 'kphd-studio', key: 'brief' } as const, null, { shape: 'brief-1' })

const SURFACE = {
  band: { light: '#EBEBE9', dark: '#222222' },
  panel: { light: '#EEEEEC', dark: '#1F1F1F' },
  card: { light: '#EDEDEB', dark: '#202020' },
}

const TOAST = {
  save: 'Filed to the record.',
  draft: 'Draft ready for your review.',
  noSend: 'Saved — nothing was sent.',
  approval: 'Approval logged.',
  theme: 'Palette applied.',
}

// [slot, light, dark], grouped as the spec groups them.
const PALETTE: [string, [string, string, string][]][] = [
  ['Text', [
    ['text', '#1C1C1C', '#E9E9E7'],
    ['inverseText', '#FFFFFF', '#161616'],
    ['subtle', '#5E5E5C', '#B0B0AE'],
    ['inactive', '#6E6E6C', '#8F8F8D'],
    ['suggestion', '#3F6560', '#8FB8B0'],
    ['remember', '#74507A', '#C9A6CC'],
  ]],
  ['Brand', [['claude', '#C8361D', '#FF6B4A']]],
  ['Status', [
    ['success', '#47652A', '#9DC273'],
    ['warning', '#875500', '#E2B45C'],
    ['error', '#8E1530', '#FF9AAE'],
    ['merged', '#664A8C', '#B9A0DC'],
  ]],
  ['Prompt & modes', [
    ['promptBorder', '#8A8A88', '#6A6A68'],
    ['bashBorder', '#4A4A48', '#9A9A98'],
    ['permission', '#2D6683', '#82B9D2'],
    ['planMode', '#2B6A5C', '#72C3B0'],
    ['autoAccept', '#8C3D6C', '#DE90BC'],
    ['ide', '#465C88', '#97ABD8'],
  ]],
  ['Change tracking', [
    ['diffAdded', '#DCE8CF', '#2A3A22'],
    ['diffRemoved', '#F2D6CF', '#46251F'],
    ['diffAddedDimmed', '#EBF1E3', '#222C1D'],
    ['diffRemovedDimmed', '#F8E8E3', '#32201C'],
    ['diffAddedWord', '#B8D29D', '#41602F'],
    ['diffRemovedWord', '#E9B0A3', '#713428'],
  ]],
]

const ZONES: [string, string, string][] = [
  ['planMode', 'Plan', 'Claude proposes a plan and waits for your sign-off.'],
  ['autoAccept', 'Auto-accept', 'Edits go through without asking each time.'],
  ['bashBorder', 'Shell', 'You are typing a terminal command (prompt starts with !).'],
  ['permission', 'Permission', 'Claude is asking before it acts.'],
]

const BRIEF_SECTIONS: [keyof Brief, string][] = [
  ['objective', 'Objective'],
  ['decisions', 'Decisions'],
  ['structure', 'Structure'],
  ['dependencies', 'Dependencies'],
  ['risks', 'Risks'],
  ['sequence', 'Sequence'],
]

const TITLES: Record<View, string> = { palette: 'Palette', brief: 'Brief', zones: 'Zones' }

const tone = (dark: boolean, pair: { light: string; dark: string }) => (dark ? pair.dark : pair.light)

// The `target` half of the tool card's "◆ {Action} · {target}" label.
const targetOf = (input: unknown): string => {
  if (input === null || typeof input !== 'object') return ''
  const o = input as Record<string, unknown>
  for (const k of ['file_path', 'path', 'notebook_path', 'command', 'pattern', 'url', 'query', 'description', 'skill', 'prompt']) {
    const v = o[k]
    if (typeof v === 'string' && v.trim() !== '') {
      const one = v.trim().split('\n')[0] ?? ''
      return one.length > 60 ? `${one.slice(0, 57)}…` : one
    }
  }
  return ''
}

const actionOf = (tool: string) =>
  tool.startsWith('mcp__') ? (tool.split('__').slice(-1)[0] ?? tool).replace(/[_-]+/g, ' ') : tool

async function syncTheme($: EngineInterface) {
  const row = (await $.config.list()).find(r => r.key === 'theme')
  const value = String(row?.value ?? 'dark')
  await update($, isDark, () => !/light/i.test(value))
}

async function openPane($: EngineInterface, which: View) {
  await update($, view, () => which)
  const opened = await $.ui.open({ id: PANE, title: `KPHD · ${TITLES[which]}` })
  return opened.isPlaced
}

// Full-screen studio backdrop for the desktop app and the iPhone / iPad app.
async function setBackdrop($: EngineInterface) {
  const dark = await read($, isDark)
  // Surfaces that draw no backdrop (the terminal) just decline; never block startup.
  await $.ui.backdrop({
    id: BACKDROP,
    glass: { tint: dark ? '#1F1F1F' : '#EEEEEC', opacity: 0.55, blur: 12 },
    colorScheme: dark ? 'dark' : 'light',
  }).catch(() => undefined)
}

function backdropSvg(dark: boolean) {
  const ground = dark ? '#1A1A1A' : '#EEEEEC'
  const weave = dark ? '#262626' : '#E4E4E1'
  const accent = dark ? '#FF6B4A' : '#C8361D'
  const mark = dark ? '#2E2E2E' : '#DCDCD9'
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 1200" preserveAspectRatio="xMidYMid slice">
<defs><pattern id="kphd-linen-${dark ? 'd' : 'l'}" width="6" height="6" patternUnits="userSpaceOnUse">
<rect width="6" height="6" fill="${ground}"/><path d="M0 0.5H6M0.5 0V6" stroke="${weave}" stroke-width="1"/></pattern></defs>
<rect width="1200" height="1200" fill="url(#kphd-linen-${dark ? 'd' : 'l'})"/>
<rect x="0" y="0" width="1200" height="6" fill="${accent}"/>
<rect x="0" y="12" width="1200" height="2" fill="${accent}"/>
<text x="600" y="1130" text-anchor="middle" font-family="Helvetica, Arial, sans-serif" font-size="44" font-weight="700" letter-spacing="14" fill="${mark}">KPHD STUDIO</text>
</svg>`
}

function paletteText(dark: boolean) {
  const lines = ['**KPHD Monotone — Vermilion**', `Active: ${dark ? 'dark' : 'light'} · light / dark`, '']
  for (const [group, slots] of PALETTE) {
    lines.push(`**${group}**`)
    for (const [slot, l, d] of slots) lines.push(`- \`${slot}\` ${l} / ${d}`)
    lines.push('')
  }
  return lines.join('\n').trim()
}

function zonesText() {
  return ['**Zones** — each mode reads as its own room', '', ...ZONES.map(([slot, name, what]) => {
    const pair = PALETTE.flatMap(([, s]) => s).find(([k]) => k === slot)
    return `- **${name}** (${pair ? `${pair[1]} / ${pair[2]}` : slot}): ${what}`
  })].join('\n')
}

function briefText(b: Brief) {
  return BRIEF_SECTIONS.map(([k, label]) => `**${label.toUpperCase()}**\n${b[k] || '—'}`).join('\n\n')
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await syncTheme($)
    await setBackdrop($)
    $.ui.status('KPHD Studio — Los Angeles')
    await $.command.register({ name: 'palette', description: 'KPHD: all 23 slots as swatches, light and dark hex' })
    await $.command.register({ name: 'kphd-brief', description: 'KPHD: session brief — Objective, Decisions, Structure, Dependencies, Risks, Sequence' })
    await $.command.register({ name: 'zones', description: 'KPHD: mode legend — plan, auto-accept, shell, permission' })
    await $.tool.register({
      name: 'brief',
      description:
        'Files the KPHD session brief shown in the /kphd-brief panel. Each field is a short plain-language summary (a few lines) of this session so far.',
      inputSchema: {
        type: 'object',
        properties: Object.fromEntries(BRIEF_SECTIONS.map(([k, label]) => [k, { type: 'string', description: label }])),
        required: BRIEF_SECTIONS.map(([k]) => k),
      },
      isDeferred: false,
    })
    return next(e)
  })

  // Theme changes: keep the band/panel/card surfaces in step and confirm.
  on('config.set', { key: 'theme' }, async ($, e, next) => {
    const done = await next(e)
    if (!('deny' in done && done.deny)) {
      await syncTheme($)
      await setBackdrop($)
      if (/kphd/i.test(String(e.value))) $.ui.toast(TOAST.theme)
    }
    return done
  }).catch(($, e, next) => next(e))

  // From a phone or tablet (Remote Control) or where no panel can show,
  // the commands answer in the conversation instead.
  on('command.run', { command: 'palette' }, async ($, e) => {
    const placed = await openPane($, 'palette')
    const inline = e.origin?.kind === 'bridge' || !placed
    return { text: inline ? paletteText(await read($, isDark)) : 'KPHD palette opened.' }
  })

  on('command.run', { command: 'zones' }, async ($, e) => {
    const placed = await openPane($, 'zones')
    const inline = e.origin?.kind === 'bridge' || !placed
    return { text: inline ? zonesText() : 'KPHD zones opened.' }
  })

  on('command.run', { command: 'kphd-brief' }, async ($, e) => {
    const placed = await openPane($, 'brief')
    const inline = e.origin?.kind === 'bridge' || !placed
    const reply = inline
      ? 'Then reply with the brief itself: the six section names in bold capitals (OBJECTIVE, DECISIONS, STRUCTURE, DEPENDENCIES, RISKS, SEQUENCE), each followed by its lines.'
      : 'Then reply with one line saying the brief is filed.'
    return {
      text: inline ? 'KPHD brief — writing it now.' : 'KPHD brief opened.',
      context: [
        `Write the KPHD session brief now: call the ${BRIEF_TOOL} tool once with objective, decisions, structure, dependencies, risks and sequence, each a few short plain-language lines drawn from this session. ${reply}`,
      ],
    }
  }).catch(($, e, next) => next(e))

  on('tool.call', { tool: 'mcp__kphd-studio__brief' }, async ($, e) => {
    const input = (e as unknown as { input?: Record<string, unknown> }).input ?? (e as unknown as Record<string, unknown>)
    const filed = Object.fromEntries(
      BRIEF_SECTIONS.map(([k]) => [k, typeof input[k] === 'string' ? (input[k] as string) : '']),
    ) as Brief
    await update($, brief, () => filed)
    await openPane($, 'brief')
    $.ui.toast(TOAST.save)
    return { result: `Brief filed to the KPHD panel.\n\n${briefText(filed)}` }
  }).catch(($, e, next) => next(e))

  // Toasts on real outcomes.
  on('tool.call', async ($, e, next) => {
    const done = await next(e)
    if ('deny' in done && done.deny) return done
    if (done.isError) return done
    const tool = String(e.tool)
    if (tool === 'Write' || tool === 'Edit' || tool === 'NotebookEdit') $.ui.toast(TOAST.save)
    else if (/draft/i.test(tool)) $.ui.toast(TOAST.draft)
    else if (tool === 'ExitPlanMode') $.ui.toast(TOAST.approval)
    return done
  }).catch(($, e, next) => next(e))

  // The backdrop drawing (desktop app, iPhone / iPad app).
  on('ui.render', { component: 'Backdrop' }, async ($, e, next) => {
    if (e.props.plugin !== 'kphd-studio' || e.props.id !== BACKDROP) return next(e)
    if (e.surface !== 'desktop' && e.surface !== 'mobile') return next(e)
    const { Svg } = $.ui.resolve(e)
    const dark = e.props.colorScheme ? e.props.colorScheme === 'dark' : await read($, isDark)
    return <Svg source={backdropSvg(dark)} alt="KPHD Studio linen backdrop with a vermilion rule" />
  })

  // Band above the prompt: double vermilion rules top and bottom.
  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    if (e.props.hasSurvey || e.props.maxRows < 4) return next(e)
    const { Box, Text } = $.ui.resolve(e)
    const dark = await read($, isDark)
    const width = Math.max(10, e.props.bodyColumns)
    const rule = '═'.repeat(width)
    return (
      <Box flexDirection="column" backgroundColor={tone(dark, SURFACE.band)} width={width}>
        <Text color="claude" wrap="truncate">{rule}</Text>
        <Box paddingX={1}>
          <Text color="text" bold wrap="truncate">KPHD STUDIO · operator-first design</Text>
        </Box>
        <Text color="claude" wrap="truncate">{rule}</Text>
      </Box>
    )
  })

  // Tool card: soft surface, rounded promptBorder edge, "◆ Action · target" label.
  on('ui.render', { component: 'ToolUse' }, async ($, e, next) => {
    const row = await next(e)
    if (e.props.isExpanded) return row
    const { Box, Text } = $.ui.resolve(e)
    const dark = await read($, isDark)
    const target = targetOf(e.props.input)
    const label = `◆ ${actionOf(e.props.tool)}${target ? ` · ${target}` : ''}`
    return (
      <Box flexDirection="column" borderStyle="round" borderColor="promptBorder" backgroundColor={tone(dark, SURFACE.card)} paddingX={1}>
        <Text color="subtle" bold wrap="truncate">{label}</Text>
        {row}
      </Box>
    )
  })

  // The side panel: /palette, /brief, /zones share one pane.
  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Text, Button } = $.ui.resolve(e)
    const dark = await read($, isDark)
    const which = await read($, view)
    const filed = await read($, brief)
    const width = Math.max(10, e.props.bodyColumns - 2)
    const divider = <Text color="promptBorder" wrap="truncate">{'─'.repeat(width)}</Text>
    const heading = (t: string) => <Text color="claude" bold>{t.toUpperCase()}</Text>

    const tabs = (
      <Box flexDirection="row" gap="xs">
        {(['palette', 'brief', 'zones'] as View[]).map(v => (
          <Button
            key={`tab-${v}`}
            label={TITLES[v]}
            variant={v === which ? 'primary' : 'secondary'}
            onPress={() => openPane($, v)}
          />
        ))}
      </Box>
    )

    let body
    if (which === 'palette') {
      body = (
        <Box flexDirection="column">
          {heading('KPHD Monotone — Vermilion')}
          <Text color="subtle">Active: {dark ? 'dark' : 'light'} · ■ = live swatch · light / dark hex</Text>
          {PALETTE.map(([group, slots]) => (
            <Box flexDirection="column" marginTop={1}>
              <Text color="text" bold>{group}</Text>
              {slots.map(([slot, l, d]) => (
                <Box flexDirection="row">
                  <Text color={dark ? d : l}>■■ </Text>
                  <Text color="text">{slot.padEnd(18)}</Text>
                  <Text color="subtle">{l} / {d}</Text>
                </Box>
              ))}
            </Box>
          ))}
        </Box>
      )
    } else if (which === 'zones') {
      body = (
        <Box flexDirection="column">
          {heading('Zones')}
          <Text color="subtle">Each mode reads as its own room.</Text>
          {ZONES.map(([slot, name, what]) => (
            <Box flexDirection="column" marginTop={1}>
              <Box flexDirection="row">
                <Text color={slot}>██ </Text>
                <Text color={slot} bold>{name}</Text>
              </Box>
              <Text color="text">{what}</Text>
            </Box>
          ))}
        </Box>
      )
    } else {
      body = (
        <Box flexDirection="column">
          {heading('Session brief')}
          {filed === null ? (
            <Text color="subtle">Not filed yet. Run /kphd-brief and Claude will write it from this session.</Text>
          ) : (
            BRIEF_SECTIONS.map(([k, label]) => (
              <Box flexDirection="column" marginTop={1}>
                <Text color="claude" bold>{label.toUpperCase()}</Text>
                <Text color="text">{filed[k] || '—'}</Text>
              </Box>
            ))
          )}
          <Box marginTop={1}>
            <Button
              key="refile"
              label="Refresh brief"
              variant="secondary"
              onPress={async () => {
                await $.command.run({ command: 'kphd-brief', args: '' })
              }}
            />
          </Box>
        </Box>
      )
    }

    return (
      <Box flexDirection="column" backgroundColor={tone(dark, SURFACE.panel)} paddingX={1}>
        {tabs}
        {divider}
        {body}
      </Box>
    )
  })
}
