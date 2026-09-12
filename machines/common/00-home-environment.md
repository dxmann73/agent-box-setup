# 00 – Home environment

Run this after cloning the repository. Back up the Kubuntu-created dotfiles, then replace them with
the repository-managed symlinks.

## 1. Back up existing files

```bash
mkdir -p ~/.agent-box-setup-backup
mv ~/.bashrc ~/.profile ~/.gitconfig ~/.agent-box-setup-backup/
```

Move `.bash_aliases` too when it already exists:

```bash
test ! -e ~/.bash_aliases || mv ~/.bash_aliases ~/.agent-box-setup-backup/
mkdir -p ~/.config
test ! -e ~/.config/plasma-localerc || \
  mv ~/.config/plasma-localerc ~/.agent-box-setup-backup/
```

## 2. Create symlinks

```bash
cd ~/projects/agent-box-setup
ln -sf "$PWD/user-home/.bashrc" ~/.bashrc
ln -sf "$PWD/user-home/.bash_aliases" ~/.bash_aliases
ln -sf "$PWD/user-home/.profile" ~/.profile
ln -sf "$PWD/user-home/.gitconfig" ~/.gitconfig
ln -sf "$PWD/user-home/ua.sh" ~/ua.sh
ln -sf "$PWD/user-home/update-tools.sh" ~/update-tools.sh
mkdir -p ~/.config
ln -sf "$PWD/user-home/plasma-localerc" ~/.config/plasma-localerc
ln -sf "$PWD/.markdownlint.json" ~/projects/.markdownlint.json
```

## 3. Create the secrets file

```bash
cd ~/projects/agent-box-setup
cp user-home/.bash_secrets.CHANGE-ME user-home/.bash_secrets
nano user-home/.bash_secrets
ln -sf "$PWD/user-home/.bash_secrets" ~/.bash_secrets
source ~/.bashrc
```

## 4. Verify

```bash
ls -l ~/.bashrc ~/.bash_aliases ~/.profile ~/.gitconfig ~/.bash_secrets ~/ua.sh ~/update-tools.sh
ls -l ~/.config/plasma-localerc
ls -l ~/projects/.markdownlint.json
git config --global --list
```

## 5. Checklist

- [ ] existing dotfiles are backed up
- [ ] managed dotfiles and scripts are symlinked
- [ ] Plasma locale profile is symlinked
- [ ] `~/.bash_secrets` is created from the template and symlinked
- [ ] shell configuration and Git configuration load

Next: [02-core-tools.md](02-core-tools.md)
