# 00 – Home environment

Run this after cloning the repository. Back up the Kubuntu-created dotfiles, then replace them with
the repository-managed symlinks.

## 1. Back up existing files

```bash
mkdir -p ~/.agent-box-setup-backup
for file in ~/.bashrc ~/.profile ~/.bash_aliases; do
  test ! -e "$file" || mv "$file" ~/.agent-box-setup-backup/
done
```

## 2. Create symlinks

```bash
cd ~/projects/agent-box-setup
ln -sf "$PWD/user-home/.bashrc" ~/.bashrc
ln -sf "$PWD/user-home/.bash_aliases" ~/.bash_aliases
ln -sf "$PWD/user-home/.profile" ~/.profile
ln -sf "$PWD/user-home/ua.sh" ~/ua.sh
ln -sf "$PWD/user-home/update-tools.sh" ~/update-tools.sh
ln -sf "$PWD/.markdownlint.json" ~/projects/.markdownlint.json
```

## 3. Verify

```bash
ls -l ~/.bashrc ~/.bash_aliases ~/.profile ~/ua.sh ~/update-tools.sh
ls -l ~/projects/.markdownlint.json
```

## 4. Checklist

- [ ] existing dotfiles are backed up
- [ ] managed dotfiles and scripts are symlinked
- [ ] shell configuration loads

Next: [02-core-tools.md](02-core-tools.md)
