# 04 - Editor Setup

Cursor IDE is the primary editor. It's an AI-powered code editor built on VS
Code.

## Prerequisites

- Completed `02-core-tools.md`

---

## 1. Install Cursor IDE

### Manual Installation Steps

1. Open the [Cursor download page](https://cursor.com/download)
2. Download the `.deb` package (it will save to your Downloads folder)
3. Open Downloads and right-click on the `cursor_*.deb` file
4. Select "Open With App Center"
5. Click "Install" and authenticate as needed

Verify:

```bash
cursor --version
```

The Cursor application should also appear in your applications menu. Tell your human to 'pin it to the Dash'.

---

## 2. Import current Settings into Profile

If you have an existing Cursor profile in `dave-cursor-default.code-profile`

Tell your human to import this manually.

**Note:** Extensions will be installed automatically based on per-repository
recommendations when you open projects.

---

## 3. Cursor Initial Tweaks

### Keybindings (Strg-M Strg-S, then "record keys")

- Remove the default `Strg-Shift-K` keybind, then reassign `Strg-Shift-K` to "Delete Line"
- Format document: add `Strg-Alt-L` binding
- Java: Go to test: `Strg-Shift-T`

### Settings

- Always show usage limits: Strg-Shift-J > Cursor Settings > Agents > Usage summary > "always"
- Markdown theme: Strg-, > Workbench > Appearance > set to "Dark Modern"
- Terminal scrollback: Settings > @feature:terminal scroll > Integrated scrollback > 9999
- Send keybindings to shell: enable `terminal.integrated.sendKeybindingsToShell`

### Keyboard shortcuts reference

```
Strg-I / Strg-L     Side Panel
Strg-E               Agent Mode
Strg-.               Mode (Agent, Plan, Ask)
Strg-#               Model
Strg-K / Strg-L      Inline edit / add to agent
Strg-Alt-B           AI Window
```

---

## 4. Java Extensions

If working with Java/Quarkus projects:

- Install the **Spring Boot Extension Pack**
- Install the [Quarkus extension](https://marketplace.cursorapi.com/items/?itemName=redhat.vscode-quarkus)
- Add Quarkus docs to Cursor @docs: Type @Docs > Add new doc > paste [https://quarkus.io/guides](https://quarkus.io/guides)

### Java settings

Add to workspace or user settings:

```json
{
  "java.maven.downloadSources": true,
  "java.diagnostic.filter": [
    "**/target/generated-sources/**/*"
  ],
  "java.completion.importOrder": [
    "*",
    "java",
    "javax"
  ],
  "java.compile.nullAnalysis.mode": "automatic"
}
```

---

## 5. Postprocessing

Export and save settings profile: Ctrl+Shift+P > "Preferences: Open Profiles (UI)"

---

## Verification Checklist

- [ ] Cursor IDE installed
- [ ] `cursor` command works from terminal
- [ ] Keybindings customized
- [ ] Java extensions installed (if applicable)
- [ ] Settings profile exported

**Next:** Continue to `05-voice-tools-a-faster-whisper.md`
