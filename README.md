# Mobile Forensic Setup

This project provides an automated setup script for mobile forensic tools on Arch Linux / CachyOS.

## Tools Included
- **UFADE**: Universal Forensic Apple Device Extractor
- **ALEX**: Android Logical Extraction
- **iLEAPP**: iOS Logs Events And Plists Parser
- **ALEAPP**: Android Logs Events And Plists Parser

## Installation

Run the following command to download and start the setup:

```bash
curl -sSL https://raw.githubusercontent.com/cybrcr/mobile-forensic-setup/master/setup-mobile-forensic.sh | bash
```

## Features
- Automated installation of system dependencies.
- Creation of Python virtual environments for each tool.
- Integration into the application menu (Mobile Forensic category).
- Automatic GUI scaling fix for iLEAPP and ALEAPP to ensure visibility on all screens.
- Global update script included.
