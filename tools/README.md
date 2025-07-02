# 🛠️ Ferramentas do HyprArch

## network-scanner.sh
**Descrição**: Scanner completo de rede que verifica:
- Interfaces de rede
- Conexões ativas
- Tabela ARP
- Teste de ping

**Uso**:
```bash
./network-scanner.sh
```

**Saída**: Relatório salvo em `~/.cache/hyprarch-scans/`

## system-monitor.sh
**Descrição**: Monitor de recursos em tempo real que mostra:
- Uso de CPU/Memória
- Espaço em disco
- Temperatura da CPU

**Uso**:
```bash
./system-monitor.sh
```
**Atalho**: Pressione `Ctrl+C` para sair

## 📌 Dicas
1. Torne os scripts executáveis:
```bash
chmod +x *.sh
```

2. Para acesso rápido, crie aliases no seu `.bashrc`:
```bash
alias scan='~/tools/network-scanner.sh'
alias monitor='~/tools/system-monitor.sh'
```

3. Os scripts não requerem privilégios root para funcionamento básico