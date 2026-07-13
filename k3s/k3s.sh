#!/bin/bash

# --- Configuration ---
# skip k3s's built-in Helm controller addon.
INSTALL_K3S_EXEC="--disable=helm-controller"
# --- End Configuration ---

usage() {
    echo "Usage: $0 {install | uninstall | status}"
    echo ""
    echo "  install   : Installs K3s (course setup: ${INSTALL_K3S_EXEC})."
    echo "  uninstall : Uninstalls K3s using the bundled script."
    echo "  status    : Shows k3s.service status." 
    echo "  setup     : run only once before everything"
    exit 1
}

if [ -z "$1" ]; then
    usage
fi

k3s_install() {
    echo "Starting K3s installation..."
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="$INSTALL_K3S_EXEC" INSTALL_K3S_SKIP_SELINUX_RPM=true sh

    echo "Setting up Kubernetes configuration..."
    sudo rm -f ~/.kube/config || true
    sudo mkdir -p ~/.kube
    sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
    sudo chmod 600 ~/.kube/config
    sudo chown "$(id -u)":"$(id -g)" ~/.kube/config
    # echo 'export KUBECONFIG=$HOME/.kube/config' >> ~/.bashrc
    echo "K3s installation complete. Kubeconfig at ~/.kube/config"
}

k3s_uninstall() {
    echo "Starting K3s uninstallation..."

    if [ -f "/usr/local/bin/k3s-uninstall.sh" ]; then
        /usr/local/bin/k3s-uninstall.sh
        echo "K3s uninstallation complete."
    else
        echo "K3s uninstall script not found at /usr/local/bin/k3s-uninstall.sh."
        exit 1
    fi
}

k3s_status() {
    sudo systemctl status k3s.service
}

initial_setup() {
    echo "Set-up kube dir" 
    sudo mkdir -p ~/.kube 
    sudo chown "$(id -u)":"$(id -g)" ~/.kube
    sudo chmod 700 ~/.kube 
    echo "ls -lah ~/.kube" 
    ls -lah ~/.kube 
}

case "$1" in
    setup)
        initial_setup
        ;;
    install)
        k3s_install
        ;;
    uninstall)
        k3s_uninstall
        ;;
    status)
        k3s_status
        ;;
    *)
        usage
        ;;
esac
