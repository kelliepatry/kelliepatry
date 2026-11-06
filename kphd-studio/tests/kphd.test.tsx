import { expect, test } from 'claude-code/testing'

const SURFACES = ['terminal', 'desktop', 'vscode', 'mobile'] as const
const scroll = { offset: 0, bodyRows: 20 }

const engine = (on: any) => {
  on('command.register', (_: unknown, e: any) => ({ value: { command: e.name } }))
  on('tool.register', (_: unknown, e: any) => ({ value: { tool: `mcp__kphd-studio__${e.name}` } }))
  on('config.list', () => ({ value: [{ key: 'theme', value: 'custom:kphd-vermilion-light' }] }))
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('session.start', (_: unknown, e: any) => ({ cwd: e.cwd }))
}

test('the band, the palette and the zones draw on every surface', async ($, on) => {
  engine(on)
  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })

  for (const surface of SURFACES) {
    const band = await $.ui.mount({
      plugin: 'kphd-studio', component: 'AbovePrompt', surface,
      props: { hasSurvey: false, isWorking: false, maxRows: 10, bodyColumns: 60, scroll, view: {} },
    })
    expect((await band.find({ type: 'Text', text: /KPHD STUDIO/ }))?.text).toBe('KPHD STUDIO · operator-first design')
    await band.unmount()

    const pane = await $.ui.mount({
      plugin: 'kphd-studio', component: 'Pane', requestId: 'kphd', surface,
      props: { title: 'KPHD', isFocused: false, bodyColumns: 50, placement: 'dock', scroll, view: {} },
    })
    expect((await pane.find({ type: 'Text', text: /#C8361D/ }))?.text).toContain('#FF6B4A')
    expect((await pane.find({ type: 'Text', text: /Active:/ }))?.text).toContain('light')
    await pane.unmount()
  }
})

test('the brief tool files the six sections into the panel', async ($, on) => {
  engine(on)
  on('ui.toast', () => ({ value: undefined }))
  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })
  await $.tool.call({
    tool: 'mcp__kphd-studio__brief',
    objective: 'Reskin Claude', decisions: 'Vermilion accent', structure: 'Theme + mod',
    dependencies: 'Spec JSON', risks: 'Contrast', sequence: 'Theme, band, panel',
  } as any)
  const pane = await $.ui.mount({
    plugin: 'kphd-studio', component: 'Pane', requestId: 'kphd', surface: 'desktop',
    props: { title: 'KPHD', isFocused: false, bodyColumns: 50, placement: 'dock', scroll, view: {} },
  })
  expect((await pane.find({ type: 'Text', text: /Vermilion accent/ }))?.text).toBe('Vermilion accent')
  await pane.unmount()
})
