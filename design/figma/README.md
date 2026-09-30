# Figma assets

Design file: https://www.figma.com/design/gLuoHFbiiUGajAUpluWXOW

| Page | What's on it |
|---|---|
| Cover | Principles and the file map |
| Foundations | Colour tokens (Light + Dark side by side), type ramp with SwiftUI mappings |
| Components | Icons, system chrome, Button, Chip, Day version, Focus window card, Time ring, Now card, Timeline row, Tab bar, List row, Change row, Sheet header |
| iPhone — core loop | Today, Log dose, double-dose guard, Fix my day, Onboarding 2/3 |
| iPhone — recovery & learning | Welcome back, Low day / baseline, Learned, Lifestyle switch, Get support |
| Glanceables | Lock Screen (check-in + Live Activity), Dynamic Island, widgets, controls |
| Watch | Face, Now, Log, Check-in, Transition, Already-logged guard |
| Motion | A: dose logged → window draws in · B: time ring depletes → wrap-up · plugin test output |

## Fonts

Text styles are named after iOS text styles and ship as SF Pro / SF Compact through Dynamic Type.
The file uses **Inter** as a stand-in because SF fonts can't be rendered by Figma's cloud
renderer (and SF Pro Regular measures at 0 px wide in the MCP sandbox). Each style's description
holds `ships:<family>|<style>` and the exact SwiftUI font. To preview with SF locally, change the
22 text styles' family in the Figma desktop app — every text layer is bound to a style.

## Shader and plugin (not yet published)

Both Figma teams on the account have **View** seats, and `create_shader` /
`create_generative_plugin` return "You don't seem to have permission to do that". The sources are
complete and ready; publish them once an editor seat is assigned (you're admin of both Education
teams, so you can upgrade your own seat in the team's admin settings):

1. **Focus Window Band** — `shaders/focus-window-band/main.ts`, kind `fill`, not animated, no mouse.
   `create_shader` → `update_shader(files: [{ path: "main.ts", ... }])`.
2. **Focus Day Generator** — `plugins/focus-day-generator/{code.ts, ui.html}`.
   `create_generative_plugin` → `update_generative_plugin(files: [...])`.

The plugin's placement logic has been exercised in the design file through `use_figma`
(Motion page → "Plugin test — Focus Day Generator output"); the shader has not been compiled
because the build only runs on publish.
