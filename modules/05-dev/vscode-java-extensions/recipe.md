# vscode-java-extensions recipe

Run on the Dave catalog-ticked daily hosts after `vscode`. The three extensions are editor-wide;
project-specific extensions remain in each project's `.vscode/extensions.json`.

```bash
./apply.sh --target daily-host
./verify.sh --target daily-host
```
