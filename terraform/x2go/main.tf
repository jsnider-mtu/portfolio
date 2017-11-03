provider "digitalocean" {
# USE DIGITALOCEAN_TOKEN env var
}

resource "digitalocean_droplet" "x2go" {
    image       = "ubuntu-17-04-x64"
    name        = "x2go"
    region      = "ams3"
    size        = "1gb"
    ipv6        = 1
    user_data   = <<EOF
#!/bin/bash
apt-add-repository ppa:x2go/stable
apt-get update
apt-get install -y x2goserver x2goserver-xsession xfce4
adduser --disabled-password josh
mkdir /home/josh/.ssh
chmod 700 /home/josh/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDQS2D3VxaOUszBhmLMw0owFwU/s23COfc6Y7NHI1Cwa+XZTqpIrc4xEl/gnteByFJrBRusRO1hFzFOy99761QXwJjllYpkQqnBPNqX5JoBKz94Jcpo5HwMEko4o8HegJXGMeougkocDfcEzHBm46I465RlWZpabTwm+OzpoOIWM6s0BmeXIEO9KAP2lRWYifALNzQAUV7/UMYrlhZc+or1KP/aTAf3wtMgWN0SvHDgDViLCXC9vQDEiD2lj6AEBKmuxkECSmWv1rkoI+qIIf+291SBV3v06sgPGYYijFuRQl/eoAlB883myxOR14T1nTRbxXpY6nwUdGehIDNh0Wxr" > /home/josh/.ssh/authorized_keys
chown -R josh:josh /home/josh/.ssh
sed -i 's/PermitRootLogin/#PermitRootLogin/;s/PasswordAuth/#PasswordAuth/' /etc/ssh/sshd_config
/etc/init.d/ssh restart
echo "josh ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/josh
EOF
}
