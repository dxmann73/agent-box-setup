# 04 - Editor Setup

Cursor IDE is the primary editor. It's an AI-powered code editor built on VS
Code.

## Prerequisites

- Completed `02-core-tools.md`
- Completed `03-dev-environment.md`

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

## Verification Checklist

- [ ] Cursor IDE installed
- [ ] `cursor` command works from terminal

**Next:** Continue to `06-voice-tools.md`
