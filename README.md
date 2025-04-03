## Vagrant Files

Projeto criado para armazenar e testar meus ambientes em Vagrant.

## Pré-requisitos 💻

### Software

- kubectl: https://kubernetes.io/docs/tasks/tools/#kubectl
- Vagrant: https://www.vagrantup.com/docs/installation
- VirtualBox: https://www.virtualbox.org/wiki/Downloads
- Instalar plugin para resize do disco: `vagrant plugin install vagrant-disksize`

### Hardware

- 8GB RAM ou mais
- 6 vCPU (idealmente)
- Disco: Boot das 3 instâncias de acordo com o ambiente desejado + tamanho da instalação/utilização das VMs

## Instalação 🚀

Basta entrar no folder `kubeadm-flannel` e executar:

```
vagrant up
```

## Utilização 🤩

1. Crie um diretório chamado `.kube` na sua home: `mkdir -p ~/.kube`
2. Após subir o cluster execute: `scp vagrant@192.168.56.50:/home/vagrant/.kube/config ~/.kube/vagrant-config`
   * A senha é: `vagrant`
3. Entre dentro do arquivo de configuração do seu Shell (no meu caso ZSH): `vim ~/.zshrc`
4. Adicione esse novo arquivo de configuração no KUBECONFIG dentro do arquivo de configuração: `export KUBECONFIG=$KUBECONFIG:~/.kube/vagrant-config`
5. Renomeie o contexto para vagrant: `kubectl config rename-context kubernetes-admin@kubernetes vagrant`
6. Feche seu editor e reinicie seu terminal

## Comandos úteis para usar no Vagrant

- `vagrant suspend`: suspende as VMs atualmente e salva no HD o tamanho delas, útil para não precisar matar todas as VMS e assim liberar a RAM
- `vagrant resume`: resume a suspensão anterior e trás as VMs e seu cluster e volta a vida
- `vagrant destroy -f`: exclui todas as VMs e seu cluster inteiro
- `vagrant ssh nomedavm`: acessa via SSH a VM com seu respectivo nome
