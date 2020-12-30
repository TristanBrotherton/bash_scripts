function upgrade_code_server () { 
    curl -fsSL https://code-server.dev/install.sh | sh
    systemctl daemon-reload
    sudo systemctl restart code-server@tristan
}
