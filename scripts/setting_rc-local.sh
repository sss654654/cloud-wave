#!/bin/bash
# Configuration to restart streamlit application 
touch /etc/rc.d/rc.local
cat <<EOT >> /etc/rc.d/rc.local
#!/bin/bash
streamlit run /root/streamlit-project/main.py --server.port 80
EOT

ln -s /etc/rc.d/rc.local /etc/rc.local
chmod 755 /etc/rc.d/rc.local

# Configuration System demon 
echo " " >> /lib/systemd/system/rc-local.service 
echo "[Install]" >> /lib/systemd/system/rc-local.service 
echo "WantedBy=multi-user.target" >> /lib/systemd/system/rc-local.service 

# Install Code-Deploy Agent
systemctl daemon-reload
systemctl enable rc-local

yum install ruby -y
cd /home/ec2-user
wget https://aws-codedeploy-ap-northeast-2.s3.ap-northeast-2.amazonaws.com/latest/install
chmod +x install
./install auto
service codedeploy-agent status