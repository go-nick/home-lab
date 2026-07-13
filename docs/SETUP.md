## OS Configuration

Using Fedora 43 Desktop because I already had this in my home-lab for another purpose.

Some required configuration before using for k8s home-lab study.

### Fedora Swap System
```
swapon --show
NAME       TYPE      SIZE USED PRIO
/dev/zram0 partition   8G   0B  100
```

Swap came on by default, disable it. 
TLDR: kubelet enforces memory limits....
a container that hits its memory limit might swap instead of getting OOM-killed.
this breaks the resource accounting kubelet relies on. 

```
sudo swapoff -a # Turn it off

sudo systemctl mask systemd-zram-setup@zram0.service # hard-disable systemd unit by symlinking
Created symlink '/etc/systemd/system/systemd-zram-setup@zram0.service' → '/dev/null'.
```

---

### SELinux check

```
getenforce
Permissive
```

Nothing to do here

--- 

### Firewalld - ports for k3s

- 6443/tcp -> kube-apiserver
- 8472/udp -> flannel -> still not sure if using flannel CNI but for stating it is fine
- 10250/tcp -> kubelet API 

```
sudo firewall-cmd --permanent --add-port=6443/tcp
sudo firewall-cmd --permanent --add-port=8472/udp
sudo firewall-cmd --permanent --add-port=10250/tcp

sudo firewall-cmd --permanent --remove-port=1025-65535/tcp
sudo firewall-cmd --permanent --remove-port=1025-65535/udp

sudo firewall-cmd --reload

sudo firewall-cmd --list-all
sudo firewall-cmd --list-services
sudo firewall-cmd --permanent --list-ports
sudo firewall-cmd --list-ports
```

Just some good hygiene on firewall 

---

### Kernel Modules + network forwarding

bridged network traffic came disabled by default
Pod networking won't work without this 

```
lsmod | grep -E 'br_netfilter|overlay' 

sudo modprobe br_netfilter overlay

lsmod | grep -E 'br_netfilter|overlay'
br_netfilter           36864  0
bridge                475136  1 br_netfilter
```

Alright, let's persist this. 
```
cat <<EOF | sudo tee /etc/modules-load.d/k3s.conf
br_netfilter
overlay
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k3s.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# check
sysctl net.bridge.bridge-nf-call-iptables net.ipv4.ip_forward
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
```

--- 

### cgroups

```
cat /sys/fs/cgroup/cgroup.controllers
cpuset cpu io memory hugetlb pids rdma misc dmem
```

cpu + io + memory this is v2, if it came v1 I would wash my hands from Fedora. 

--- 

### Disabling GUI

```
sudo systemctl set-default multi-user.target
sudo systemctl isolate multi-user.target
```

Switch-back:
```
sudo systemctl set-default graphical.target
sudo systemctl isolate graphical.target
```

check sshd enabled: 
```
sudo systemctl is-enabled sshd 
```


