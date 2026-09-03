# 🟩 GitHub Contribution Widget for macOS

A lightweight macOS menu bar and desktop widget that visualizes your GitHub contribution graph, annual counts, current & longest streaks, and today's commit count.

---

## 🌟 Features

- 🐙 **GitHub Contribution Heatmap**: View your 52-week calendar grid directly from your menu bar.
- 📊 **Live Streak & Metric Cards**: See your total contributions, current active streak (🔥), longest streak (🏆), and today's commits (⚡).
- 🎛 **Customizable Menu Bar**: Choose to show your Current Streak, Longest Streak, or Today's Commits right in your macOS menu bar.
- 🎨 **Color Themes**: Personalize the widget with 7 built-in themes including GitHub Green, Dracula Purple, Cyberpunk Neon, and more.
- 🖥 **Desktop Mode**: Pin the widget to your desktop for a floating overview.
- 🔄 **Automatic Refresh**: The widget updates in the background automatically to keep your stats current.

---

## 🚀 Quick Start & Installation

### 1. Install & Launch

You can easily install the widget using npm (Recommended):

```bash
npm install -g git-contribution-widget-macos
git-contribution-widget
```

Alternatively, you can run the installation script directly:

```bash
sh install.sh
```

### 2. Set your GitHub ID
- Click the new **GitHub icon** in your macOS menu bar.
  
  <img src="assets/manu_bar.png" width="300" alt="Menu Bar Icon">

- The widget popover will appear showing your contribution graph.
  
  <img src="assets/manu_bar_click.png" width="300" alt="Widget Popover">

- Open **Settings (⚙️)**, enter your **GitHub ID** and press Enter.
  
  <img src="assets/setting.png" width="300" alt="Settings">

### 3. Done! 🎉
Your widget is now active and will refresh automatically in the background.

---

## 🛠 Advanced Options

You can manage the widget using the command line options:

```bash
# If using npm:
git-contribution-widget --login      # Automatically start the widget when you log in
git-contribution-widget --uninstall  # Completely remove the widget and its settings
git-contribution-widget --help       # Show all options

# If using install.sh:
sh install.sh --login
sh install.sh --uninstall
sh install.sh --help
```

---

## 📄 License
MIT License
