# 📡 Configuração de Rede no Arch Linux

## 🔌 Configuração Básica de Rede

### 1. Durante a Instalação (Arch ISO)
```bash
# Verificar interfaces de rede
ip link

# Para conexão via cabo (DHCP):
dhcpcd

# Para WiFi (usando iwd):
iwctl
[iwd]# station wlan0 scan
[iwd]# station wlan0 get-networks
[iwd]# station wlan0 connect SSID
[iwd]# exit
```

### 2. Pós-Instalação
Instale os pacotes necessários:
```bash
sudo pacman -S networkmanager iwd
```

Ative o serviço:
```bash
sudo systemctl enable --now NetworkManager
```

## 📶 Configuração de WiFi Persistente

1. Edite o arquivo de configuração do NetworkManager:
```bash
sudo nano /etc/NetworkManager/conf.d/wifi.conf
```

2. Adicione:
```ini
[device]
wifi.backend=iwd
```

3. Reinicie o serviço:
```bash
sudo systemctl restart NetworkManager
```

## 🌐 Configuração Manual de IP Estático

1. Crie um novo profile:
```bash
sudo nmcli con add con-name "Conexão-Estatica" ifname enp0s3 type ethernet ip4 192.168.1.100/24 gw4 192.168.1.1
```

2. Adicione DNS:
```bash
sudo nmcli con mod "Conexão-Estatica" ipv4.dns "8.8.8.8,8.8.4.4"
```

3. Ative a conexão:
```bash
sudo nmcli con up "Conexão-Estatica"
```

## 🔄 Troubleshooting

### Verificar Status:
```bash
nmcli device status
nmcli connection show
```

### Testar Conexão:
```bash
ping -c 4 archlinux.org
```

### Logs de Erros:
```bash
journalctl -u NetworkManager -b
```

## 📱 Configuração para USB Tethering

1. Conecte o dispositivo via USB
2. Verifique a interface:
```bash
ip a
```
3. Ative a conexão:
```bash
sudo nmcli con up interface-name
```

> 💡 Dica: Use `nmtui` para configuração via interface textual amigável!

## 📚 Referências
- [Arch Wiki - Network Configuration](https://wiki.archlinux.org/title/Network_configuration)
- [Video Tutorial](https://youtu.be/_nDqRToEtpo)

