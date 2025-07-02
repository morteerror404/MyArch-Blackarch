if ! sha256sum -c "$BACKUP_DIR/checksums.sha256"; then
    echo -e "${RED}ERRO: Backup corrompido!${NC}"
    exit 1
fi