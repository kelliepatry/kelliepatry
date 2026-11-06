export type Brief = {
  objective: string
  decisions: string
  structure: string
  dependencies: string
  risks: string
  sequence: string
}
export type View = 'palette' | 'brief' | 'zones'

declare module 'claude-code' {
  interface PluginState {
    'kphd-studio': { isDark: boolean; view: View; brief: Shaped<Brief | null> }
  }
}
