#!/bin/bash

# Variables for paths
UPDATE_SCRIPT_NAME="xahaud-silent-update.sh"
UPDATE_SCRIPT_PATH="/usr/local/bin/$UPDATE_SCRIPT_NAME"
CRON_FILE_PATH="/etc/cron.d/xahaud-silent-update"
LOG_DIR="/opt/xahaud/log"
LOG_FILE="$LOG_DIR/update.log"
USER="root"  # Change this if a different user should run the cron job

# Ensure the log directory exists
mkdir -p "$LOG_DIR"

# Copy the provided update script to /usr/local/bin
cat << 'EOF' > "$UPDATE_SCRIPT_PATH"
#!/bin/bash
# Copy this file to /usr/local/bin as root
# make it executable - chmod +x /usr/local/bin/root
# add the cron file

VERSION="latest"
SCREEN_OUTPUT=false

# Parse command-line options
while getopts "v:s" opt; do
  case $opt in
    v) VERSION=$OPTARG ;;
    s) SCREEN_OUTPUT=true ;;
  esac
done

RELEASE_TYPE="release"
URL="https://build.xahau.tech/"
BASE_DIR=/opt/xahaud
USER=xahaud
PROGRAM=xahaud
BIN_DIR=$BASE_DIR/bin
DL_DIR=$BASE_DIR/downloads
LOG_DIR=$BASE_DIR/log
SCRIPT_LOG_FILE=$LOG_DIR/update.log
SERVICE_NAME="$PROGRAM.service"

log() {
  local message="$1"
  echo "$(date +"%Y-%m-%d %H:%M:%S") $message" >> "$SCRIPT_LOG_FILE"
  if [ "$SCREEN_OUTPUT" = true ]; then
    echo "$message"
  fi
}

# Ensure the script runs as root
[[ $EUID -ne 0 ]] && exit 1

# Fetch available versions
filenames=$(curl --silent "${URL}" | grep -Eo '>[^<]+<' | sed -e 's/^>//' -e 's/<$//' | grep -E '^\S+\+[0-9]{2,3}$' | grep -E $RELEASE_TYPE)

if [[ "$VERSION" == "latest" ]]; then
  version_filter="release"
else
  version_filter=$VERSION
fi

version_file=$(echo "$filenames" | grep "$version_filter" | sort -t'B' -k2n -n | tail -n 1)

if [[ -z "$version_file" ]]; then
  log "No update found."
  exit 0
fi

log "New Update: $version_file"

if [[ ! -f "$DL_DIR/$version_file" ]]; then
  curl --silent --fail "${URL}${version_file}" -o "$DL_DIR/$version_file"
  chmod +x "$DL_DIR/$version_file"
  chown $USER:$USER "$DL_DIR/$version_file"
  log "Downloaded $version_file"
fi

current_file=$(readlink "$BIN_DIR/$PROGRAM")
if [[ "$current_file" != "$DL_DIR/$version_file" ]]; then
  ln -snf "$DL_DIR/$version_file" "$BIN_DIR/$PROGRAM"
  log "Symlink updated to $version_file"

  # Restart the service using systemctl
  log "Restarting $SERVICE_NAME"
  systemctl restart $SERVICE_NAME

  log "Update available: Yes"
else
  log "Update available: No"
fi
EOF

# Make the update script executable
chmod +x "$UPDATE_SCRIPT_PATH"

# Create the cron job file
cat << EOF > "$CRON_FILE_PATH"
# Cron job to run xahaud-silent-update.sh with random delay up to 59 mins
SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin

# Run the script every 12 hours with a random delay every hour
*/5 * * * * root sleep $((RANDOM * 300 / 32768)) && $UPDATE_SCRIPT_PATH >> $LOG_FILE 2>&1
EOF

# Set appropriate permissions for the cron file
chmod 644 "$CRON_FILE_PATH"

# Restart cron service to ensure the cron job is picked up
systemctl restart cron

echo "Update script and cron job have been set up successfully."
