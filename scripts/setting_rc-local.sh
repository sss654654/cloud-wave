#!/bin/bash
# Configuration to restart streamlit application 
sudo touch /etc/rc.d/rc.local
sudo echo '#!/bin/bash
streamlit run /home/ec2-user/streamlit-project/main.py --server.port 8080 --server.enableCORS false --server.enableXsrfProtection false --server.enableWebsocketCompression=false' | sudo tee /etc/rc.d/rc.local

sudo ln -s /etc/rc.d/rc.local /etc/rc.local
sudo chmod 755 /etc/rc.d/rc.local

# Configuration Systemd Service
sudo bash -c 'echo "Restart=always" >> /lib/systemd/system/rc-local.service'
sudo bash -c 'echo "User=ec2-user" >> /lib/systemd/system/rc-local.service'
sudo bash -c 'echo " " >> /lib/systemd/system/rc-local.service'
sudo bash -c 'echo "[Install]" >> /lib/systemd/system/rc-local.service '
sudo bash -c 'echo "WantedBy=multi-user.target" >> /lib/systemd/system/rc-local.service '

# Service enable
sudo systemctl daemon-reload
sudo systemctl enable rc-local