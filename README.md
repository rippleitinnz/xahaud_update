# Xahaud Update Script

This repository contains a setup script that installs a Xahaud auto-update script and sets up a cron job to run every 12 hours, including after power off or reboot.

## Installation

1. **Clone the Repository:**

    git clone https://github.com/rippleitinnz/xahaud_update.git

    cd xahaud_update

2. **Run the setup script:**

   sudo bash setup-xahaud-update.sh

This script will:

Install the Xahaud update script.
Set up a cron job to run the update script every 12 hours with a random 1 hour delay.
Restart the cron service to apply the changes.
If a new release is found, the script will download it, update and restart the Xahaud service, and log the activities to /opt/xahaud/log/update.log.

**Notes**

The sleep \$((RANDOM*3540/32768)) line in the cron file introduces a random delay to prevent all instances from running at the same time, which helps distribute the load more evenly.

This update script assumes the following:
You use the standard installation of Xahaud with standard directory structures
You download xahaud releases to /opt/xahaud/downloads

**DO NOT USE THIS SCRIPT IF YOU HAVE XAHAUD INSTALLED VIA DOCKER.**




