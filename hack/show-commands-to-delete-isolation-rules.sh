#!/bin/bash
set -eu -o pipefail
iptables-save -t filter | grep -- '--comment "CNI isolation plugin rules"' | sed -e 's/^-[A-Z]/-D/g' | xargs -L1 echo iptables
echo "# Run the above commands to delete all iptables rules created by CNI isolation plugin"
echo "# The above commands are not executed yet. Copy-paste to terminal or use '|sh' for actual execution."
