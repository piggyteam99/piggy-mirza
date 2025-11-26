🐷 Piggy Pro Manager (Mirza Pro)

Piggy Pro Manager is an advanced and automated bash script designed to install, manage, and update the Mirza Pro Telegram bot source code on Ubuntu servers. This script handles all dependencies including Apache, PHP 8.2, MariaDB, and SSL Certificates.

🚀 Quick Installation

Copy and paste the following command into your terminal to start the manager:
```bash
bash <(curl -s https://raw.githubusercontent.com/piggyteam99/piggy-mirza/main/piggy.sh)```


✨ Features

Automated Installation: Installs all required packages (PHP, Apache, SQL, etc.) automatically.

SSL Configuration: Auto-generates free SSL certificates via Certbot.

Database Management: Creates database and user automatically.

Bot Management: Sets and deletes Telegram Webhook easily.

Update System: Updates both the Mirza Pro source code and the Piggy Manager script itself.

Fixer: Automatically fixes common bugs in the source code.

📋 Menu Options

Install Piggy Pro: install bot

Uninstall Completely: Removes all files, databases, and certificates (Wipe).

Update & Fix Issues: Updates the bot source code and applies fixes.

Edit config.php: Opens the configuration file editor.

Webhook Status: Checks if the bot is connected to Telegram.

Show Database Password: Displays the saved database credentials.

Update Piggy Script: Updates this manager script to the latest version.

