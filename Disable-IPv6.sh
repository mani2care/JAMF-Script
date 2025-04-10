#!/bin/zsh
#
# Turn off IPv6 addresses
LOG_DIR="/Library/Application Support/GiantEagle/logs"
LOG_FILE="${LOG_DIR}/DisableIPv6.log"

function create_log_directory ()
{
    # Ensure that the log directory and the log files exist. If they
    # do not then create them and set the permissions.
    #
    # RETURN: None

	# If the log directory doesnt exist - create it and set the permissions
	if [[ ! -d "${LOG_DIR}" ]]; then
		/bin/mkdir -p "${LOG_DIR}"
		/bin/chmod 755 "${LOG_DIR}"
	fi

	# If the log file does not exist - create it and set the permissions
	if [[ ! -f "${LOG_FILE}" ]]; then
		/usr/bin/touch "${LOG_FILE}"
		/bin/chmod 644 "${LOG_FILE}"
	fi
}

function logMe () 
{
    # Basic two pronged logging function that will log like this:
    #
    # 20231204 12:00:00: Some message here
    #
    # This function logs both to STDOUT/STDERR and a file
    # The log file is set by the $LOG_FILE variable.
    #
    # RETURN: None
    echo "${1}" 1>&2
    echo "$(/bin/date '+%Y%m%d %H:%M:%S'): ${1}\n" >> "${LOG_FILE}"
}

allports=$(/usr/sbin/networksetup -listallnetworkservices | grep -i -E 'Ethernet|Wi-Fi|USB')
for service in $allports
do
    /usr/sbin/networksetup -setv6off "$service"
    logMe "INFO: IPv6 disabled on port $service"
done
exit 0
