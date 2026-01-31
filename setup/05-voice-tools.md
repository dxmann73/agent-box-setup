# 05 - Voice Tools

Set up Wispr Flow for voice input.

## Prerequisites

- Completed core setup (01-04)
- Microphone connected and working

---

## 1. Install Wispr Flow

### Windows

Download from: https://wispr.com/flow

Or via winget (if available):
```powershell
winget install Wispr.Flow
```

### macOS

```bash
brew install --cask wispr-flow
```

Or download from: https://wispr.com/flow

### Linux

Wispr Flow may not be available for Linux. Alternatives:
- **Talon Voice** - https://talonvoice.com/
- **Nerd Dictation** - https://github.com/ideasman42/nerd-dictation

---

## 2. Initial Setup

1. Launch Wispr Flow
2. Grant microphone permissions when prompted
3. Complete the onboarding tutorial
4. Set your preferred activation hotkey

---

## 3. Recommended Settings

### Activation Mode
- **Push-to-talk** is recommended for coding to avoid accidental dictation
- Set a comfortable hotkey (e.g., `Ctrl+Shift+Space` or a mouse button)

### Language Model
- Enable the enhanced/cloud model for better accuracy if available

### Application-Specific Settings
- Enable in VS Code
- Enable in terminal applications
- Consider disabling in password fields

---

## 4. Integration with Claude

Wispr Flow works seamlessly with Claude Code:

1. Have Claude running in terminal
2. Use voice to dictate your requests
3. Wispr transcribes directly into the terminal

Tips:
- Speak naturally, including punctuation ("period", "comma", "new line")
- Use "scratch that" to undo
- Say command names clearly

---

## 5. Custom Commands (Optional)

Wispr Flow supports custom voice commands. Consider adding:
- "run tests" → `npm test`
- "git status" → `git status`
- "commit changes" → Opens commit dialog

---

## Verification Checklist

- [ ] Wispr Flow installed and running
- [ ] Microphone working
- [ ] Hotkey configured
- [ ] Test dictation in a text editor
- [ ] Test dictation in terminal with Claude

**Next:** Continue to `06-optional.md`
