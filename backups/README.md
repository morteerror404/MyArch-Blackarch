Aqui está o `README.md` completo para o script `restore-backup.sh`, seguindo as melhores práticas de documentação:

```markdown
# Script de Restauração de Backup - HyprArch

![Backup Restoration](https://img.icons8.com/dusk/64/000000/backup.png)

## 📌 Visão Geral
Script para restaurar configurações do HyprArch a partir de backups automáticos. Compatível com sistemas que seguem o [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html).

## ✨ Funcionalidades
- ✅ Restauração segura com validação de integridade
- ✅ Interface interativa ou modo direto
- ✅ Preserva permissões de arquivos
- ✅ Log detalhado de operações
- ✅ Suporte a múltiplos backups com timestamp

## 📦 Pré-requisitos
- `tar` com suporte a gzip
- `rsync` (para cópia segura)
- Bash 5.0+

## 🛠️ Como Usar

### Método Interativo (Recomendado)
```bash
./restore-backup.sh
```
1. O script listará todos os backups disponíveis
2. Selecione pelo número correspondente
3. Confirme a operação

### Método Direto
```bash
./restore-backup.sh /caminho/do/backup.tar.gz
```

### Opções Avançadas
| Variável de Ambiente | Descrição | Padrão |
|----------------------|-----------|--------|
| `BACKUP_DIR` | Diretório de backups | `~/.local/share/hyprarch-backups` |
| `CONFIG_DIR` | Onde configs serão restauradas | `~/.config` |
| `LOG_LEVEL` | Verbosidade (1-3) | `2` |

## 📂 Estrutura de Backups
Os backups devem seguir o formato:
```
hyprarch-backups/
├── hypr-YYYYMMDD_HHMMSS.tar.gz
└── checksums.sha256
```

O arquivo compactado deve conter:
```
.
├── hypr/
│   ├── hyprland.conf
│   └── exec.conf
├── waybar/
│   ├── config.jsonc
│   └── style.css
└── rofi/
    └── config.rasi
```

## ⚠️ Limitações Conhecidas
1. Não restaura pacotes instalados
2. Não manipula arquivos fora de `~/.config`
3. Backups > 6 meses são ignorados (configurável)

## 🔧 Solução de Problemas
### Erro "Backup corrompido"
```bash
# Verificar integridade manualmente
tar -tzf backup.tar.gz && echo "Válido" || echo "Corrompido"
```

### Logs detalhados
```bash
tail -n 50 /tmp/hyprarch-restore.log
```

## 🤝 Contribuindo
1. Reporte bugs via [issues](https://github.com/morteerror404/MyArch-Blackarch/issues)
2. Envie melhorias via PRs
3. Padrão de código: [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)

## 📄 Licença
GPLv3 - Veja o arquivo [LICENSE](LICENSE) no repositório principal.

---

> 💡 **Dica**: Combine com `cron` para backups automáticos:
> ```bash
> 0 3 * * * /usr/bin/tar -czf ~/.local/share/hyprarch-backups/hypr-$(date +\%Y\%m\%d_\%H\%M\%S).tar.gz -C ~/.config {hypr,waybar,rofi}
> ```

![Backup Strategy](https://img.icons8.com/color/48/000000/backup--v1.png)  
*Backups são como capacetes - melhor ter e não precisar, do que precisar e não ter!*
