# 01 – Localization

Use the same user-facing locale profile on both the host and the VM: an American-English Plasma
interface with German regional formats. It provides euro currency, metric measurements, A4 paper,
comma decimals, 24-hour time, and German date conventions without a German interface.

Run the system commands with `sudo`:

```bash
sudo locale-gen en_US.UTF-8 de_DE.UTF-8
sudo update-locale \
  LANG=en_US.UTF-8 \
  LC_ADDRESS=de_DE.UTF-8 \
  LC_MEASUREMENT=de_DE.UTF-8 \
  LC_MONETARY=de_DE.UTF-8 \
  LC_NAME=de_DE.UTF-8 \
  LC_NUMERIC=de_DE.UTF-8 \
  LC_PAPER=de_DE.UTF-8 \
  LC_TELEPHONE=de_DE.UTF-8 \
  LC_TIME=de_DE.UTF-8 \
  LANGUAGE=en_US
```

After cloning the repository, link the tracked Plasma profile. This replaces manual KDE System
Settings changes for language and regional formats:

```bash
mkdir -p ~/.config
ln -sfn ~/projects/agent-box-setup/user-home/plasma-localerc ~/.config/plasma-localerc
```

Log out and back in so Plasma and newly started applications read the updated environment. A system
reboot is not required.

## Verify

```bash
locale -a | grep -E '^(en_US|de_DE)\.(utf8|UTF-8)$'
locale
cat ~/.config/plasma-localerc
```

Expected values:

- `LANG=en_US.UTF-8` and `LANGUAGE=en_US`
- `LC_ADDRESS`, `LC_MEASUREMENT`, `LC_MONETARY`, `LC_NAME`, `LC_NUMERIC`, `LC_PAPER`,
  `LC_TELEPHONE`, and `LC_TIME` set to `de_DE.UTF-8`
- `~/.config/plasma-localerc` is a symlink to the tracked file

## Checklist

- [ ] `en_US.UTF-8` and `de_DE.UTF-8` are generated
- [ ] system locale categories use the agreed English UI and German formats
- [ ] Plasma reads the tracked locale profile after the next login
