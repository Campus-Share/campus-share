# Campus Share

Campus Share is an initiative taken to create a large-scale repository of University of Toronto CMS resources to enable incoming students to access lectures, notes and slides, quizzes, solved midterms and solved final exams.

## 📦 Installation (Mac & Linux)

Follow these steps to install **Campus Share (`cshare.sh`)** so it can be run from anywhere on your system.

```bash
# Clone the repository
git clone https://github.com/Campus-Share/campus-share.git

# Enter the project folder
cd campus-share

# Move the script to a folder in your PATH
# /usr/local/bin is standard for system-wide executables
sudo mv ./cshare.sh /usr/local/bin/cshare

# Make the script executable
sudo chmod +x /usr/local/bin/cshare
```

Finally, add the appropriate export to your terminal configuration.

bash:
**Add /usr/local/bin to your PATH if it's not already included.**

For **zsh** users:

```bash
# Add /usr/local/bin to your PATH if not present
if ! echo $PATH | grep -q "/usr/local/bin"; then
  echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.zshrc
  source ~/.zshrc
fi
```

For **bash** users:

```bash
# Add /usr/local/bin to your PATH if not present
if ! echo $PATH | grep -q "/usr/local/bin"; then
  echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
  source ~/.bashrc
fi
```

> **Note:** Only add this line if `/usr/local/bin` is not already in your PATH. Reload your terminal or run `source ~/.zshrc` or `source ~/.bashrc` after making changes.

✅ **Done!** After you reload your terminal, you can now run the tool from anywhere by typing:

```bash
cshare
```

## Script Execution

There are two modes to executing this script.

- Splitting the contents of a source folder
- Merging the parts from a parts folder

### Splitting (for contributors)

`Coming soon!`

### Merging (for consumers)

Follow these instructions to convert a merge parts into a source folder

1. Run the script

```bash
chsare
```

2. Choose "Merge parts from parts folder"
3. Done! Open `./Source/` to access all files.
