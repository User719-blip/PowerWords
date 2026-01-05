# PowerWords

**PowerWords** is a cross-platform command launcher that wraps common tasks (like opening apps, searching the web, or finding files) in simple, memorable commands. It is designed to make your workflow faster and more accessible, using PowerShell on Windows and Bash on macOS/Linux.

---

## Features

- **Open Applications or URLs:**  
  Launch apps or open websites with a single command.

- **Web Search:**  
  Search the web using your default or a specified search engine.

- **Find Files:**  
  Search for files or folders by name and optionally open them.

- **System Status:**  
  View CPU, memory, and disk usage at a glance.

- **Git Sync:**  
  Add, commit, and push changes to your Git repository with one command.

- **Auto-Update (Windows):**  
  Checks for updates from GitHub and offers to install them.

---

## Installation

### **Windows (Recommended)**

1. **Using the Installer (Recommended)**
   - Download the latest `PowerWordsInstaller.exe` from the [Releases](https://github.com/User719-blip/PowerWords/releases) page .
   - or downlode the binary fine from installer folder and run it 'PowerWordsInstaller.exe' by clicking on it
   - Run the installer. It will:
     - Copy all necessary files to `C:\Program Files\PowerWords`
     - Add `launcher.exe` to your system PATH
     - Create Start Menu and Desktop shortcuts
     - Set up default configurations
     - Provide a clean uninstaller

2. **Manual Installation**
   - Clone this repository:
     ```sh
     git clone https://github.com/User719-blip/PowerWords.git
     ```
   - Build the launcher:
     ```sh
     cd PowerWords/src
     g++ launcher.cpp -o ../bin/launcher.exe
     ```
   - Add `PowerWords/bin` to your system PATH manually.

---

### **macOS/Linux (Experimental, Bash scripts untested)**

> ⚠️ **Bash scripts are untested and may require further enhancements.**

1. Clone the repository:
   ```sh
   git clone https://github.com/User719-blip/PowerWords.git
   ```
2. Make scripts executable:
   ```sh
   chmod +x scripts/mac/core.sh scripts/mac/add_app.sh
   ```
3. (Optional) Add an alias to your shell profile for easier access.

---

## Usage

- **Open an app or URL:**
  ```sh
  launcher.exe open vscode
  launcher.exe open "https://github.com"
  ```

- **Search the web:**
  ```sh
  launcher.exe search "how to write"
  launcher.exe search "how to write" -engine github
  ```

- **Find a file:**
  ```sh
  launcher.exe find document.pdf
  launcher.exe find -o doc.txt
  ```

- **System status:**
  ```sh
  launcher.exe sys-status
  ```

- **Git sync:**
  ```sh
  launcher.exe git-sync "commit message"
  ```

---

## Configuration

- **apps.json:**  
  Located in `config/app.json`. Maps app names to their executable paths.
  ```json
  {
    "chrome":  "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
    "firefox":  "C:\\Program Files\\Mozilla Firefox\\firefox.exe",
    "vscode":  "code",
    "sublime":  "C:\\Program Files\\Sublime Text\\sublime_text.exe"
  }
  ```
  Add new apps using:
  - Windows:  
    ```powershell
    .\scripts\win\add_app.ps1 -name "notepad" -path "C:\Windows\System32\notepad.exe"
    ```
  - macOS/Linux (untested):  
    ```sh
    ./scripts/mac/add_app.sh notepad /usr/bin/open -a TextEdit
    ```

- **search_engines.json:**  
  Configure search engines for the `search` command.

---

## Function Reference

- **open / Invoke-Open / open_app:**  
  Opens an app by name (from config), a file, or a URL.

- **search / Invoke-Search / search_web:**  
  Searches the web using a specified or default search engine.

- **find / Invoke-Find / find_file:**  
  Finds files/folders by pattern. Optionally opens the first result.

- **sys-status / Invoke-SysStatus / sys_status:**  
  Shows CPU, memory, and disk usage.

- **git-sync / Invoke-GitSync / git_sync:**  
  Adds, commits, and pushes changes to the current Git repo.

---

## Contributing

**Help Wanted!**

- Test and improve Bash scripts for macOS/Linux.
- Add support for more platforms and shells.
- Refactor code for better structure and maintainability.
- Suggest and implement new fun commands.
- Improve the installer and cross-platform experience.

To contribute:
1. Fork the repo and create a feature branch.
2. Make your changes and add tests if possible.
3. Open a pull request describing your changes.

---

## Known Issues & Future Enhancements

- Bash scripts are **untested** and may not work out-of-the-box.
- More robust error handling and cross-platform support needed.
- Add more commands and integrations as suggested by the community.

---

##
