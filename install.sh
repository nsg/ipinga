#!/bin/bash

echo "Installing Ipinga on $HOSTNAME"

cat <<EOF > /etc/systemd/system/ipinga-root.service
[Unit]
Description = "Ipinga Passive Checks"

[Service]
ExecStart=/opt/ipinga/ipinga.sh
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF > /etc/systemd/system/ipinga-user.service
[Unit]
Description = "Ipinga Passive Checks"

[Service]
LoadCredential=ipinga.conf:/etc/ipinga.conf
ExecStart=/opt/ipinga/ipinga.sh
DynamicUser=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

if [ ! -e /etc/ipinga.conf ]; then
    echo "Creating /etc/ipinga.conf"
    cat <<EOF > /etc/ipinga.conf
icinga-host     https://icinga.example.com:5665
api-user        my-username
api-pass        my-password
check-hostname  $HOSTNAME
EOF
chmod 0600 /etc/ipinga.conf
chown 0:0 /etc/ipinga.conf
else
    echo "/etc/ipinga.conf already there"
fi

echo "Deploy files"
mkdir -p /opt/ipinga
cp -vr scripts/*.sh /opt/ipinga
cp -vr scripts/checks /opt/ipinga

echo "Restart services"
systemctl restart ipinga-root
systemctl restart ipinga-user
