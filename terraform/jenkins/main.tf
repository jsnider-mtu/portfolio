provider "digitalocean" {
}

resource "digitalocean_droplet" "jenky" {
    image       = "ubuntu-17-04-x64"
    name        = "jenky"
    region      = "ams3"
    size        = "1gb"
    user_data   = <<EOF
#!/bin/bash
# The basics
adduser --disabled-password josh
mkdir ~josh/.ssh
chmod 700 ~josh/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDQS2D3VxaOUszBhmLMw0owFwU/s23COfc6Y7NHI1Cwa+XZTqpIrc4xEl/gnteByFJrBRusRO1hFzFOy99761QXwJjllYpkQqnBPNqX5JoBKz94Jcpo5HwMEko4o8HegJXGMeougkocDfcEzHBm46I465RlWZpabTwm+OzpoOIWM6s0BmeXIEO9KAP2lRWYifALNzQAUV7/UMYrlhZc+or1KP/aTAf3wtMgWN0SvHDgDViLCXC9vQDEiD2lj6AEBKmuxkECSmWv1rkoI+qIIf+291SBV3v06sgPGYYijFuRQl/eoAlB883myxOR14T1nTRbxXpY6nwUdGehIDNh0Wxr" > ~josh/.ssh/authorized_keys
chown -R josh:josh ~josh/.ssh
sed -i 's/PermitRootLogin/#PermitRootLogin/;s/PasswordAuth/#PasswordAuth/' /etc/ssh/sshd_config
/etc/init.d/ssh restart
echo "josh ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/josh

# The Jenkins bit
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
echo "deb https://pkg.jenkins.io/debian-stable binary/" >> /etc/apt/sources.list
apt-get update
apt-get install -y jenkins
EOF
}

resource "digitalocean_droplet" "slave" {
    image       = "ubuntu-17-04-x64"
    name        = "slave"
    region      = "ams3"
    size        = "1gb"
    user_data   = <<EOF
#!/bin/bash
# The basics
adduser --disabled-password josh
mkdir ~josh/.ssh
chmod 700 ~josh/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDQS2D3VxaOUszBhmLMw0owFwU/s23COfc6Y7NHI1Cwa+XZTqpIrc4xEl/gnteByFJrBRusRO1hFzFOy99761QXwJjllYpkQqnBPNqX5JoBKz94Jcpo5HwMEko4o8HegJXGMeougkocDfcEzHBm46I465RlWZpabTwm+OzpoOIWM6s0BmeXIEO9KAP2lRWYifALNzQAUV7/UMYrlhZc+or1KP/aTAf3wtMgWN0SvHDgDViLCXC9vQDEiD2lj6AEBKmuxkECSmWv1rkoI+qIIf+291SBV3v06sgPGYYijFuRQl/eoAlB883myxOR14T1nTRbxXpY6nwUdGehIDNh0Wxr" > ~josh/.ssh/authorized_keys
chown -R josh:josh ~josh/.ssh
sed -i 's/PermitRootLogin/#PermitRootLogin/;s/PasswordAuth/#PasswordAuth/' /etc/ssh/sshd_config
/etc/init.d/ssh restart
echo "josh ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/josh

# The Jenkins bit
useradd -s /bin/bash -d /var/lib/jenkins jenkins
chown -R jenkins:jenkins /var/lib/jenkins
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDDwFxzTH2trGZKK+GkaTMUjgt0nt8kQXtIU7dvz1p5ZrQ6jvoibxe9LpyAYfN2rh6tkj9w27B2FFm4eUiD7/4j/hn+42Gg8oP3VujD++N2/JG3n+KZaEqcxZZtPeqVcXCirmHuRfyq0KReuIB3tBUO27D7pUr9PmrtDuvL3KYzOGZv6+lQ8iNGg1djDkonv2c7/fppgpX+LFY5wmbhEUCObDluU8JMJzjcu86f/rmhjf8UMTdRHkZF5TVEKkntE+ahm6YCEPwOSOZ96/93q5KTF6VtgoZzWa0wOQ6WuYPezCP8GmFiPr3pVCvVFeBTK3pCuiQ2hlocXMeDWA1brKyz" > /var/lib/jenkins/.ssh/authorized_keys
apt-get update && apt-get install -y openjdk-8-jre-headless
EOF
}
