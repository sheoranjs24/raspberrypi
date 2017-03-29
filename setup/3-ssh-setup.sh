# SSH Setup

## Delete pi user
sudo deluser --remove-all-files pi

## Fixed IP
sudo touch /etc/network/interfaces
echo "
auto eth0
iface eth0 inet static
       address 192.168.1.101
       gateway 192.168.1.1
       netmask 255.255.255.0
       network 192.168.1.0
       broadcast 192.168.1.255
" >> /etc/network/interfaces
sudo /etc/init.d/networking restart 

## SSH Config
scp ~/.ssh/id_rsa.pub $USERNAME@$HOSTNAME:
ssh $USERNAME@$HOSTNAME
sudo mkdir .ssh
mv id_rsa.pub .ssh/authorized_keys
sudo chown -R example_user:example_user .ssh
sudo chmod 700 .ssh
sudo chmod 600 .ssh/authorized_keys
#todo: Change /etc/ssh/sshd_config  PasswordAuthentication no PermitRootLogin no
sudo service ssh restart
