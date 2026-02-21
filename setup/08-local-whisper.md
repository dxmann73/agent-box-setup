# Local whisper support

## Audio

On the fly encoding:

- [Whispr Flow](https://wisprflow.ai/)

Online services:

- [Notta - does not support aac](https://www.notta.ai)
- [Sally](https://www.sally.io)

Locally installed version:

[Sally Howto](https://www.sally.io/blog/installing-whisper-a-step-by-step-guide)
Installiert mit Python 3.14. FFMpeg herunter geladen und ins virtual environment nach `C:\Users\dave\whisper-env\Scripts` kopiert.

Usage (Windows), see also the [Whisper GitHub page](https://github.com/openai/whisper)

```cmd
python -m venv whisper-env
whisper-env\Scripts\activate.bat
whisper sample.aac
```

Just text, some other options (using `whisper --help`)

```bash
whisper --language de --output_format txt --threads 12 sample.aac
```

Check if pytorch is available and which device it is using: [Steps](https://stackoverflow.com/a/48152675/7998852)

Packaged versions:

- [transcribe anything](https://github.com/zackees/transcribe-anything)
- [Whisper Standalone](https://github.com/Purfview/whisper-standalone-win)

## Video

- Download using [yt-clip or yt-dlp](https://github.com/zackees/ytclip)
