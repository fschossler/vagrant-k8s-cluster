## Vagrant Files

Project created to store and test my Vagrant environments.

## Prerequisites 💻

### Software

- kubectl: https://kubernetes.io/docs/tasks/tools/#kubectl
- Vagrant: https://www.vagrantup.com/docs/installation
- VirtualBox: https://www.virtualbox.org/wiki/Downloads
- Install disk resize plugin: `vagrant plugin install vagrant-disksize`

### Hardware

- 8GB RAM or more
- 6 vCPU (ideally)
- Disk: Boot of the 3 instances according to the desired environment + size of VM installation/usage

## Installation 🚀

Just enter the `kubeadm-flannel` folder and run:

```shell
vagrant up
```

## Usage 🤩

1. Create a directory called `.kube` in your home: `mkdir -p ~/.kube`
2. After starting the cluster, run: `scp vagrant@192.168.56.50:/home/vagrant/.kube/config ~/.kube/vagrant-config`
   * The password is: `vagrant`
3. Open your Shell configuration file (in my case ZSH): `vim ~/.zshrc`
4. Add this new configuration file to KUBECONFIG within the configuration file: `export KUBECONFIG=$KUBECONFIG:~/.kube/vagrant-config`
5. Rename the context to vagrant: `kubectl config rename-context kubernetes-admin@kubernetes vagrant`
6. Close your editor and restart your terminal

## Useful commands to use with Vagrant

- `vagrant suspend`: suspends the current VMs and saves their state to the hard drive, useful to avoid killing all VMs and thus free up RAM
- `vagrant resume`: resumes the previous suspension and brings the VMs and your cluster back to life
- `vagrant destroy -f`: deletes all VMs and your entire cluster
- `vagrant ssh vmname`: accesses the VM via SSH with its respective name
