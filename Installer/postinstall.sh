#!/bin/sh

cp /Applications/OS-X-H3CClient.app/Contents/Resources/org.wireshark.ChmodBPF.plist /Library/LaunchDaemons
chown root:wheel /Library/LaunchDaemons/org.wireshark.ChmodBPF.plist

exit 0

