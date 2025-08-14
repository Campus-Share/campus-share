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
sudo mv cshare.sh /usr/local/bin/cshare.sh

# Make the script executable
sudo chmod +x /usr/local/bin/cshare.sh
```

✅ **Done!** After you reload your terminal, you can now run the tool from anywhere by typing:

```bash
cshare.sh
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
