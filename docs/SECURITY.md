# Políticas de Segurança do HyprArch

## Boas Práticas de Instalação

1. **Verificação de Integridade**
   - Sempre valide checksums de downloads
   ```sh
   sha256sum hyprarch-installer.sh
   ```

2. **Controle de Acesso**
   - Execute apenas como root durante instalação
   - Revogue permissões após instalação:
   ```sh
   chmod 750 /usr/local/bin/hyprarch-*
   ```

3. **Gerenciamento de Pacotes**
   - Atualize regularmente:
   ```sh
   pacman -Syu
   ```
   - Verifique pacotes do BlackArch:
   ```sh
   pacman -Qi blackarch-<tool>
   ```

## Configurações Seguras Recomendadas

### Para Hyprland
```conf
# Em ~/.config/hypr/hyprland.conf
exec-once = swaylock --daemonize
bind = $mainMod, L, exec, swaylock
```

### Para Sistema
1. Ativar firewall:
   ```sh
   sudo systemctl enable --now nftables
   ```
2. Configurar sudo:
   ```sh
   visudo
   ```

## Avisos Importantes

⚠️ **Ferramentas do BlackArch**
- Use apenas em ambientes controlados
- Mantenha registro de atividades
- Não use para testes não autorizados

⚠️ **Configurações Padrão**
- Altere todas as senhas padrão
- Desative serviços desnecessários

## Reportando Vulnerabilidades
Encontrou um problema? Abra uma issue em:
[github.com/seu-repo/security](https://github.com/seu-repo/security)
```
