# 04 - Editor Setup

Cursor IDE is the primary editor. It's an AI-powered code editor built on VS Code.

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

**Verify installation:**

```bash
cursor --version
```

Expected output: Version number like `2.x.x` along with commit hash

**Note:** The Cursor application should also appear in your applications menu. Tell your human to 'pin it to the Dash'.

---

## 2. Import current Settings into Profile

If you have an existing Cursor profile in `cursor-default.code-profile`

Tell your human to import this manually via Strg-Shift-P > Open Profiles (UI).

**Note:** Extensions will be installed automatically based on per-repository recommendations when you open projects.

---

## 3. Cursor Initial Tweaks

### Keybindings (Strg-M Strg-S, then "record keys")

- Remove the default `Strg-Shift-K` keybind, then reassign `Strg-Shift-K` to "Delete Line"
- Format document: Strg-Shift-P, Open keyboard Shortcuts, "format doc", add Strg-Alt-L
- Java: Go to test: `Strg-Shift-T`

### Settings

- Always show usage limits: Strg-Shift-J > Cursor Settings > Agents > Usage summary > "always"
- Markdown theme: Strg-, > Workbench > Appearance > set to "Dark Modern"
- Open terminal `Strg-ö`, choose Ubuntu WSL als default via the DDLB
- Terminal scrollback: Settings > @feature:terminal scroll > Integrated scrollback > 9999
- Send keybindings to shell: enable `terminal.integrated.sendKeybindingsToShell`

### Keyboard shortcuts reference

See also [Cursor keyboard shortcuts](https://cursor.com/docs/configuration/kbd#tab)

```text
Strg-I / Strg-L     Side Panel
Strg-E               Agent Mode
Strg-.               Mode (Agent, Plan, Ask)
Strg-#               Model
Strg-K / Strg-L      Inline edit / add to agent
Strg-Alt-B           AI Window
```

Since Cursor is based on VS Code, check the [VS Code keyboard shortcuts](./vs-code.md#keybinds)

---

## 4. Java Extensions

If working with Java/Quarkus projects:

- Install the **Spring Boot Extension** and the **Spring Boot Extension Pack**
- Install the [Quarkus extension](https://marketplace.cursorapi.com/items/?itemName=redhat.vscode-quarkus)
- Add Quarkus docs to Cursor @docs: Type @Docs > Add new doc > paste
  [https://quarkus.io/guides](https://quarkus.io/guides)

### Java settings

- Set Cursor to download sources: Open VS Code settings, search for `cursor://settings/java.maven.downloadSources`
- [Exclude warnings from generated-sources](https://stackoverflow.com/questions/57215534/java-ignore-warnings-on-directory-package-level/79781667#79781667)

This is accomplished by adding the following to workspace or user settings:

```json
{
  "java.maven.downloadSources": true,
  "java.diagnostic.filter": ["**/target/generated-sources/**/*"],
  "java.completion.importOrder": ["*", "java", "javax"],
  "java.compile.nullAnalysis.mode": "automatic"
}
```

### IntelliJ sync

- Export IntelliJ settings into xml in user home
- add to Users/dave/.cursor/settings.json

  ```json
    "settings": {
      "java.completion.importOrder": [
        "*",
        "java",
        "javax"
      ],
        "java.format.settings.url": "file:///Users/dave/.cursor/MHB-IntelliJ-Codestyle.xml",
        "java.format.settings.profile": "IntelliJ IDEA",
        "java.compile.nullAnalysis.mode": "automatic"
    }
  ```

---

## 5. Postprocessing

Export and save settings profile: Ctrl+Shift+P > "Preferences: Open Profiles (UI)"

---

---

## Complete Verification

Run verification command:

```bash
echo "=== Cursor IDE ===" && \
cursor --version && \
echo -e "\nCursor binary location: $(which cursor)" && \
echo "Cursor app installed: $(test -d /opt/Cursor && echo "✓ Yes" || echo "✗ No")"
```

## Verification Checklist

- [ ] Cursor IDE installed: `cursor --version` shows version
- [ ] `cursor` command works from terminal at `/usr/bin/cursor` or similar
- [ ] Cursor application appears in applications menu
- [ ] Keybindings customized (manual step)
- [ ] Java extensions installed if applicable (manual step)
- [ ] Settings profile exported (manual step)

**Next:** Continue to `05-voice-tools-a-faster-whisper.md`
