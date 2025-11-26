#!/bin/bash
# =============================================
# Piggy Pro Manager - Version 1
# piggy pro manager by piggy team99
# =============================================

# ==============================================================================
SCRIPT_URL="https://raw.githubusercontent.com/piggyteam99/piggy-mirza/main/piggy.sh"
# ==============================================================================

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
PINK='\033[1;35m' # Piggy Color
CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

piggy_logo() {
    clear
    echo -e "${PINK}"
    cat << "EOF"
    ____  _                  
   / __ \(_)___  ____ ___  __        
  / /_/ / / __ \/ __ `/ / / /          
 / ____/ / /_/ / /_/ / /_/ /          
/_/    /_/\__, /\__, /\__, /          
        /____//____//____/            
      MANAGER SCRIPT V1
EOF
    echo -e "${NC}"
}

wait_for_apt() {
    while fuser /var/lib/dpkg/lock-frontend /var/lib/apt/lists/lock /var/cache/apt/archives/lock >/dev/null 2>&1; do
        echo -e "${YELLOW}Waiting for apt locks to be released... (10 seconds)${NC}"
        sleep 10
    done
}

fix_mirza_errors() {
    cd /var/www/mirza_pro || return
    echo -e "${CYAN}Applying fixes and adjustments...${NC}"

    [ ! -f version ] && echo "3.0" > version
    chown www-data:www-data version 2>/dev/null
    chmod 644 version 2>/dev/null

    for file in *.php; do
        [[ -f "$file" ]] || continue
        sed -i 's|define("index",.*);|if(!defined("index")) define("index", true);|g' "$file" 2>/dev/null
        sed -i 's|require_once("config.php");|if(!defined("index")) require_once("config.php");|g' "$file" 2>/dev/null
        sed -i 's|include("config.php");|if(!defined("index")) include("config.php");|g' "$file" 2>/dev/null
        sed -i 's|require("config.php");|if(!defined("index")) require("config.php");|g' "$file" 2>/dev/null
    done

    # Fix alireza_single.php
    if [ -f alireza_single.php ]; then
        echo -e "${CYAN}Renaming alireza_single.php -> alireza.php ...${NC}"
        mv alireza_single.php alireza.php 2>/dev/null
        sed -i "s|require_once __DIR__ . '/alireza_single.php';|require_once __DIR__ . '/alireza.php';|g" panels.php
    fi

    # Fix database tables
    if [ ! -f table.php ]; then
        curl -s -o table.php https://raw.githubusercontent.com/mahdiMGF2/mirza_pro/main/table.php
    fi

    if [ -f table.php ]; then
        sudo -u www-data php table.php >/dev/null 2>&1
        rm -f table.php
    fi

    chown -R www-data:www-data /var/www/mirza_pro 2>/dev/null
    chmod -R 755 /var/www/mirza_pro 2>/dev/null
    echo -e "${GREEN}All fixes applied successfully ✔${NC}"
}

install_piggy_command() {
    # This function installs the script as a global command AND switches to it if running from pipe
    local TARGET_PATH="/usr/local/bin/piggy"
    
    # 1. Check if running from a real file on disk (Local Run)
    if [ -f "$0" ]; then
        SCRIPT_PATH=$(realpath "$0")
        
        # If we are running the local file, but it doesn't match the global command
        if ! cmp -s "$SCRIPT_PATH" "$TARGET_PATH"; then
            echo -e "${CYAN}Updating global shortcut...${NC}"
            cp "$SCRIPT_PATH" "$TARGET_PATH"
            chmod +x "$TARGET_PATH"
        fi
        
    # 2. Check if running from Pipe/Web (One-Liner)
    else
        # We need to download the script to install it
        if [[ "$SCRIPT_URL" == http* ]]; then
             # Always try to download/update the global file when running from curl
             if curl -sL "$SCRIPT_URL" -o "$TARGET_PATH"; then
                 chmod +x "$TARGET_PATH"
                 
                 # === MAGIC FIX ===
                 # If we just downloaded the file and we are currently running from pipe (RAM),
                 # we immediately STOP this process and EXECUTE the file on disk.
                 # This ensures the user sees the latest version immediately.
                 echo -e "${GREEN} Latest version downloaded. Switching to installed version...${NC}"
                 sleep 1
                 exec bash "$TARGET_PATH"
             else
                 echo -e "${RED} Failed to download shortcut. Check SCRIPT_URL.${NC}"
             fi
        fi
    fi
}

self_update() {
    echo -e "${PINK}Checking for updates...${NC}"
    
    local GLOBAL_TARGET="/usr/local/bin/piggy"
    local TEMP_FILE="/tmp/piggy_update_tmp.sh"
    
    # GitHub Info for API (Instant Update)
    local REPO_OWNER="piggyteam99"
    local REPO_NAME="piggy-mirza"
    local FILE_PATH="piggy.sh"
    local BRANCH="main"
    
    # Method 1: Try GitHub API (Bypasses Raw CDN Delay)
    echo -e "${CYAN}Method 1: Fetching via GitHub API (Instant)...${NC}"
    local API_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents/$FILE_PATH?ref=$BRANCH"
    
    if curl -sL -H "Accept: application/vnd.github.v3.raw" "$API_URL" -o "$TEMP_FILE" && [ -s "$TEMP_FILE" ]; then
         echo -e "${GREEN}Download via API successful.${NC}"
    else
         # Method 2: Fallback to Raw URL with heavy cache busting
         echo -e "${YELLOW}API fetch failed/limited. Trying Raw URL fallback...${NC}"
         local ANTI_CACHE_URL="${SCRIPT_URL}?force_reload=$(date +%s)"
         if ! curl -sL "$ANTI_CACHE_URL" -o "$TEMP_FILE" || [ ! -s "$TEMP_FILE" ]; then
              echo -e "${RED}Update failed! Could not download script from any source.${NC}"
              rm -f "$TEMP_FILE"
              read -p "Press Enter..."
              return
         fi
    fi

    # Proceed if we have a file
    if [ -s "$TEMP_FILE" ]; then
        
        # Determine if running from file or pipe
        if [ -f "$0" ]; then
            local CURRENT_SCRIPT=$(realpath "$0")
            echo -e "${YELLOW}Updating current file: $CURRENT_SCRIPT${NC}"
            cat "$TEMP_FILE" > "$CURRENT_SCRIPT"
            chmod +x "$CURRENT_SCRIPT"

            if [ "$CURRENT_SCRIPT" != "$GLOBAL_TARGET" ]; then
                echo -e "${YELLOW}Updating global command: $GLOBAL_TARGET${NC}"
                cat "$TEMP_FILE" > "$GLOBAL_TARGET"
                chmod +x "$GLOBAL_TARGET"
            fi
            
            # Force write to disk and clear hash
            sync
            hash -r
            
            echo -e "${GREEN}Script updated successfully! Reloading...${NC}"
            rm -f "$TEMP_FILE"
            sleep 1
            exec bash "$CURRENT_SCRIPT"
        else
            echo -e "${YELLOW}Running from Pipe. Updating global install only...${NC}"
            mkdir -p $(dirname "$GLOBAL_TARGET")
            cat "$TEMP_FILE" > "$GLOBAL_TARGET"
            chmod +x "$GLOBAL_TARGET"
            
            sync
            hash -r
            
            echo -e "${GREEN}Global script updated! Switching to installed version...${NC}"
            rm -f "$TEMP_FILE"
            sleep 1
            exec bash "$GLOBAL_TARGET"
        fi
    fi
}

install_mirza() {
    piggy_logo
    echo -e "${PINK} >>> Starting Piggy Pro Installation (Fresh Mode)...${NC}\n"
    wait_for_apt

    # Pre-install clean up to ensure no conflict
    apt-get autoremove -y >/dev/null 2>&1

    [[ ! $(command -v openssl) ]] && apt-get install -y openssl
    if ! apt-cache search php8.2 | grep -q php8.2; then
        apt-get install -y software-properties-common gnupg
        add-apt-repository ppa:ondrej/php -y
        wait_for_apt
        apt-get update
    fi

    read -p "Domain (e.g., bot.example.com): " DOMAIN
    read -p "Bot Token: " BOT_TOKEN
    read -p "Admin ID: " ADMIN_ID
    read -p "Bot Username (without @, e.g., pigbot): " BOT_USERNAME
    read -p "Database Name (Enter = default: mirza_pro): " DB_NAME; DB_NAME=${DB_NAME:-mirza_pro}
    read -p "Database User (Enter = default: mirza_user): " DB_USER; DB_USER=${DB_USER:-mirza_user}
    
    DB_PASS=$(openssl rand -base64 32 | tr -d /=+ | cut -c -32)
    echo -e "${YELLOW}Auto-generated database password: $DB_PASS${NC}"

    echo "$DB_PASS" > /root/mirza_pass.txt

    wait_for_apt
    echo -e "${YELLOW}Installing/Reinstalling packages from scratch...${NC}"
    
    # Added --reinstall to force fresh config files
    apt-get install -y --reinstall apache2 mariadb-server git curl ufw phpmyadmin certbot python3-certbot-apache \
        php8.2 libapache2-mod-php8.2 php8.2-{mysql,curl,mbstring,xml,zip,gd,bcmath} 2>/dev/null

    # === FORCE ENABLE SERVICES ===
    # This fixes the issue where services stay disabled after removal
    echo -e "${YELLOW}Enabling services...${NC}"
    systemctl unmask apache2 >/dev/null 2>&1
    systemctl enable apache2 >/dev/null 2>&1
    systemctl start apache2 >/dev/null 2>&1
    
    systemctl unmask mariadb >/dev/null 2>&1
    systemctl enable mariadb >/dev/null 2>&1
    systemctl start mariadb >/dev/null 2>&1

    # === FIREWALL SAFETY (Non-Intrusive) ===
    echo -e "${YELLOW}Ensuring necessary ports are whitelisted...${NC}"
    ufw allow 22 >/dev/null 2>&1        # SSH
    ufw allow 80 >/dev/null 2>&1        # HTTP
    ufw allow 443 >/dev/null 2>&1       # HTTPS
    ufw allow 'Apache Full' >/dev/null 2>&1
    ufw reload >/dev/null 2>&1          
    # =======================================

    a2enmod rewrite >/dev/null 2>&1
    a2enmod ssl >/dev/null 2>&1
    a2enmod headers >/dev/null 2>&1

    # Database Creation
    echo -e "${YELLOW}Configuring Database...${NC}"
    mysql -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
    mysql -e "GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"

    echo -e "${YELLOW}Cloning source code...${NC}"
    rm -rf /var/www/mirza_pro
    if git clone https://github.com/mahdiMGF2/mirza_pro.git /var/www/mirza_pro; then
        chown -R www-data:www-data /var/www/mirza_pro
        chmod -R 755 /var/www/mirza_pro
    else
        echo -e "${RED}Failed to clone repository!${NC}"
        return 1
    fi

    # Config File
    cat > /var/www/mirza_pro/config.php <<EOF
<?php
if(!defined("index")) define("index", true);

\$dbname     = '$DB_NAME';
\$usernamedb = '$DB_USER';
\$passworddh = '$DB_PASS';

\$connect = mysqli_connect("localhost", \$usernamedb, \$passworddh, \$dbname);
if (!\$connect) die("Database connection failed!");

mysqli_set_charset(\$connect, "utf8mb4");

try {
    \$pdo = new PDO("mysql:host=localhost;dbname=$DB_NAME;charset=utf8mb4", \$usernamedb, \$passworddh, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
    ]);
} catch(Exception \$e) {
    die("PDO connection error");
}

\$APIKEY       = '$BOT_TOKEN';
\$adminnumber  = '$ADMIN_ID';
\$domainhosts  = 'https://$DOMAIN';
\$usernamebot  = '$BOT_USERNAME';
?>
EOF

    chown www-data:www-data /var/www/mirza_pro/config.php
    chmod 640 /var/www/mirza_pro/config.php

    cat > /etc/apache2/sites-available/mirza-pro.conf <<EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    DocumentRoot /var/www/mirza_pro
    <Directory /var/www/mirza_pro>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    Alias /phpmyadmin /usr/share/phpmyadmin
    ErrorLog \${APACHE_LOG_DIR}/mirza_error.log
    CustomLog \${APACHE_LOG_DIR}/mirza_access.log combined
</VirtualHost>
EOF

    a2ensite mirza-pro.conf >/dev/null 2>&1
    a2dissite 000-default.conf >/dev/null 2>&1
    
    # Restart Apache explicitly to apply config before certbot
    systemctl restart apache2

    fix_mirza_errors

    # === CERTIFICATE HANDLING ===
    echo -e "${YELLOW}Obtaining SSL Certificate...${NC}"
    
    # Check if cert exists to avoid duplicate/error, but try to force reinstall if files are missing
    if [ -d "/etc/letsencrypt/live/$DOMAIN" ]; then
          echo -e "${YELLOW}Existing certificate folder found.${NC}"
          echo -e "${CYAN}Attempting to reinstall existing cert...${NC}"
          certbot install --cert-name "$DOMAIN" --apache >/dev/null 2>&1
    else
          echo -e "${CYAN}Generating NEW certificate for $DOMAIN...${NC}"
          certbot --apache -d "$DOMAIN" --non-interactive --agree-tos --redirect -m admin@$DOMAIN >/dev/null 2>&1 || true
    fi
    # ============================
    
    # Set Webhook
    WEBHOOK_RES=$(curl -s "https://api.telegram.org/bot$BOT_TOKEN/setWebhook?url=https://$DOMAIN/index.php")
    
    systemctl restart apache2
    
    # Install command shortcut
    install_piggy_command

    echo -e "\n${GREEN} Installation Complete! 🐷${NC}"
    echo -e " Password saved in: /root/mirza_pass.txt"
    echo -e " Webhook Result: $WEBHOOK_RES"
}

delete_mirza() {
    echo -e "\n${RED}⚠️  WARNING: THIS IS A HARD RESET!${NC}"
    echo -e "${RED}This will remove the bot, DATABASE, SSL CERTS, and UNINSTALL APACHE/PHP.${NC}"
    echo -e "${RED}Use this only if you want a completely fresh start.${NC}"
    read -p "Are you sure? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then return; fi

    echo -e "${YELLOW}Stopping Services...${NC}"
    systemctl stop apache2 >/dev/null 2>&1
    
    # 1. Retrieve Domain and DB Info BEFORE deleting files
    DOMAIN=""
    if [ -f /etc/apache2/sites-available/mirza-pro.conf ]; then
        DOMAIN=$(grep "ServerName" /etc/apache2/sites-available/mirza-pro.conf | awk '{print $2}')
    fi

    if [ -f /var/www/mirza_pro/config.php ]; then
        DB_NAME=$(grep '$dbname' /var/www/mirza_pro/config.php | cut -d "'" -f 2)
        DB_USER=$(grep '$usernamedb' /var/www/mirza_pro/config.php | cut -d "'" -f 2)
        BOT_TOKEN=$(grep '$APIKEY' /var/www/mirza_pro/config.php | cut -d "'" -f 2)
        
        # Drop Database
        if [[ ! -z "$DB_NAME" ]]; then
            echo -e "${YELLOW}Dropping Database ($DB_NAME)...${NC}"
            mysql -e "DROP DATABASE IF EXISTS \`$DB_NAME\`;" 2>/dev/null
            mysql -e "DROP USER IF EXISTS '$DB_USER'@'localhost';" 2>/dev/null
        fi
        
        # Unset Webhook
        if [[ ! -z "$BOT_TOKEN" ]]; then
              echo -e "${YELLOW}Unsetting Webhook...${NC}"
              curl -s "https://api.telegram.org/bot$BOT_TOKEN/deleteWebhook" > /dev/null
        fi
    fi

    # 2. Delete SSL Certificates (Deep Clean)
    if [[ ! -z "$DOMAIN" ]]; then
        echo -e "${YELLOW}Removing SSL Certificates for $DOMAIN...${NC}"
        certbot delete --cert-name "$DOMAIN" --non-interactive >/dev/null 2>&1
        # Hard cleanup just in case
        rm -rf /etc/letsencrypt/live/"$DOMAIN"
        rm -rf /etc/letsencrypt/archive/"$DOMAIN"
        rm -rf /etc/letsencrypt/renewal/"$DOMAIN".conf
    fi

    # 3. Remove Files
    echo -e "${YELLOW}Removing website files...${NC}"
    rm -rf /var/www/mirza_pro
    rm -f /etc/apache2/sites-available/mirza-pro.conf
    rm -f /etc/apache2/sites-enabled/mirza-pro.conf
    rm -f /root/mirza_pass.txt
    rm -f /usr/local/bin/piggy
    
    # 4. PURGE PACKAGES (The "Fresh Start" Logic)
    # This ensures next install is actually fresh
    echo -e "${PINK}Purging Apache and PHP packages (Output visible)...${NC}"
    wait_for_apt
    # We do NOT purge mariadb-server completely to avoid losing OTHER databases if any exist.
    # But we purge Apache and PHP to reset their configs.
    # UPDATED: Removed redirection so user can see output/prompts
    apt-get purge -y --auto-remove apache2 libapache2-mod-php8.2 php8.2*
    
    # Clean up Apache config folder if it remains
    rm -rf /etc/apache2

    echo -e "${YELLOW}Ensuring ports (22, 80, 443) remain OPEN...${NC}"
    ufw allow 22 >/dev/null 2>&1
    ufw allow 80 >/dev/null 2>&1
    ufw allow 443 >/dev/null 2>&1
    ufw reload >/dev/null 2>&1

    echo -e "${GREEN}System has been wiped clean. Ready for a fresh install. 🗑️${NC}"
}

update_mirza() {
    echo -e "${PINK}Updating Piggy Pro Source...${NC}"
    
    if [ ! -d "/var/www/mirza_pro" ]; then
        echo -e "${RED}Installation not found!${NC}"
        return
    fi

    cd /var/www/mirza_pro || return
    git pull origin main
    
    # Re-apply fixes
    fix_mirza_errors
    
    # Ensure config permissions
    chown www-data:www-data config.php 2>/dev/null
    chmod 640 config.php 2>/dev/null
    
    # Re-install command in case of update
    install_piggy_command
    
    echo -e "${GREEN}Update Completed Successfully! 🚀${NC}"
}

show_pass() {
    echo -e "${PINK}--- Saved Database Password ---${NC}"
    if [ -f /root/mirza_pass.txt ]; then
        echo -e "${WHITE}Password: ${GREEN}$(cat /root/mirza_pass.txt)${NC}"
        echo -e "${CYAN}File Path: /root/mirza_pass.txt${NC}"
    else
        echo -e "${RED}Password file not found!${NC}"
    fi
    echo -e "${PINK}-------------------------------${NC}"
}

# ====================== Start Up Checks ======================

# Force create shortcut on first run if it doesn't exist
install_piggy_command

# ====================== Main Menu ======================
while true; do
    piggy_logo
    echo -e "${PINK}╔═════════════════════════════════════════════╗${NC}"
    echo -e "${PINK}║${WHITE} 1. Install Piggy Pro (Mirza)      🐷${PINK}        ║${NC}"
    echo -e "${PINK}║${WHITE} 2. Uninstall Completely (WIPE)    🗑️${PINK}       ║${NC}"
    echo -e "${PINK}║${WHITE} 3. Update & Fix Issues (Source)   🛠️${PINK}       ║${NC}"
    echo -e "${PINK}║${WHITE} 4. Edit config.php                📝${PINK}        ║${NC}"
    echo -e "${PINK}║${WHITE} 5. Webhook Status                 🔗${PINK}        ║${NC}"
    echo -e "${PINK}║${WHITE} 6. Show Database Password         🔑${PINK}        ║${NC}"
    echo -e "${PINK}║${CYAN} 7. Update Piggy Script (Menu)     🔃${PINK}        ║${NC}"
    echo -e "${PINK}║${RED} 8. Exit                           🚪${PINK}        ║${NC}"
    echo -e "${PINK}╚═════════════════════════════════════════════╝${NC}"
    echo -e ""
    read -p " Select an option (1-8): " choice

    case $choice in
        1) install_mirza ;;
        2) delete_mirza; sleep 3 ;;
        3) update_mirza; sleep 3 ;;
        4) nano /var/www/mirza_pro/config.php; systemctl restart apache2 ;;
        5) 
            TOKEN=$(grep -oE "[0-9]+:[A-Za-z0-9_-]{20,}" /var/www/mirza_pro/config.php 2>/dev/null)
            echo -e "${CYAN}Checking Webhook...${NC}"
            if [ -z "$TOKEN" ]; then
                echo -e "${RED}Token not found in config.php${NC}"
            else
                curl -s https://api.telegram.org/bot$TOKEN/getWebhookInfo | grep -E "(url|pending|last_error|has_custom_certificate)"
            fi
            echo -e "\n${YELLOW}Note: 'pending_update_count: 0' is GOOD. It means no messages are stuck.${NC}"
            read -p "Press Enter..." ;;
        6) show_pass; read -p "Press Enter..." ;;
        7) self_update ;;
        8) echo -e "${PINK}Goodbye! Oink Oink! 🐷${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid option!${NC}"; sleep 1 ;;
    esac
done
