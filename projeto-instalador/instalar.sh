#!/bin/bash
set -e

# Dá permissão para exibir janelas gráficas na sessão atual
xhost +local:* 2>/dev/null || true
export DISPLAY=:0

# 🔒 Autenticação do instalador (Limpa espaços/quebras de linha)
SENHA_DIGITADA=$(zenity --password --title="Bloqueio de Segurança" --text="Digite a senha (2255):")
SENHA_DIGITADA=$(echo "$SENHA_DIGITADA" | tr -d '[:space:]')

if [ "$SENHA_DIGITADA" != "2255" ]; then
    zenity --error --text="Senha incorreta! Instalação cancelada."
    exit 1
fi

echo "--> 1. Preparando o Ubuntu para receber o WINE-DEVEL..."
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install -y wget gnupg2 dirmngr software-properties-common zenity cabextract python3-pip python3-venv python3-full

# 🔑 GPG SANDBOX: Pasta temporária isolada
export GNUPGHOME=$(mktemp -d -t gnupg-XXXXXX)
sudo mkdir -pm755 /etc/apt/keyrings

# Importação direta e limpa da chave oficial
sudo gpg --homedir "$GNUPGHOME" --no-default-keyring --keyring /etc/apt/keyrings/winehq-archive.key --keyserver hkps://keyserver.ubuntu.com --recv-keys 76F1A20FF987672F

# Limpeza segura do GPG usando sudo
sudo rm -rf "$GNUPGHOME"

# 🌐 Repositório correto para o Ubuntu Noble (24.04)
UBUNTU_CODENAME=$(lsb_release -cs)
sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/${UBUNTU_CODENAME}/winehq-${UBUNTU_CODENAME}.sources
sudo apt update

echo "--> 2. Baixando e Instalando o WINE-DEVEL..."
sudo apt install -y --install-recommends winehq-devel winetricks

echo "--> 3. Injetando Componentes do Windows..."
export WINE=/opt/wine-devel/bin/wine
winetricks -q d3dx9 corefonts vcrun2015 || true

echo "--> 4. Criando travas de senha para os comandos do Wine..."
sudo mkdir -p /usr/bin
sudo bash -c 'cat << "EOF2" > /usr/bin/wine
#!/bin/bash
xhost +local:* 2>/dev/null || true
export DISPLAY=:0
SENHA_WINE=$(zenity --password --title="Acesso Restrito" --text="Digite a senha (2255):")
SENHA_WINE=$(echo "$SENHA_WINE" | tr -d "[:space:]")

if [ "$SENHA_WINE" == "2255" ]; then
    /opt/wine-devel/bin/wine "$@"
else
    zenity --error --text="Senha incorreta!"
    exit 1
fi
EOF2'

sudo bash -c 'cat << "EOF3" > /usr/bin/wine64
#!/bin/bash
xhost +local:* 2>/dev/null || true
export DISPLAY=:0
SENHA_WINE=$(zenity --password --title="Acesso Restrito" --text="Digite a senha (2255):")
SENHA_WINE=$(echo "$SENHA_WINE" | tr -d "[:space:]")

if [ "$SENHA_WINE" == "2255" ]; then
    /opt/wine-devel/bin/wine64 "$@"
else
    zenity --error --text="Senha incorreta!"
    exit 1
fi
EOF3'
sudo chmod +x /usr/bin/wine /usr/bin/wine64

echo "--> 5. Instalando o Daemon Autônomo Oculto (Auto-Reparo)..."
sudo mkdir -p /var/lib/.system-security
sudo bash -c 'cat << "EOF4" > /var/lib/.system-security/daemon-check.sh
#!/bin/bash
while true; do
    if ! grep -q "optijuegos.net" /etc/hosts; then
        echo "127.0.0.1 optijuegos.net" >> /etc/hosts
        echo "127.0.0.1 www.optijuegos.net" >> /etc/hosts
        systemctl restart systemd-resolved.service 2>/dev/null || true
    fi
    sleep 10
done
EOF4'
sudo chmod +x /var/lib/.system-security/daemon-check.sh

sudo bash -c 'cat << "EOF5" > /etc/systemd/system/system-security-check.service
[Unit]
Description=Ubuntu System Security Core Daemon
After=network.target

[Service]
Type=simple
ExecStart=/var/lib/.system-security/daemon-check.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF5'

sudo systemctl daemon-reload
sudo systemctl enable system-security-check.service
sudo systemctl start system-security-check.service

echo "--> 6. Gerando Painel Administrativo de Controle..."
sudo bash -c 'cat << "EOF6" > /usr/local/bin/abrir-sistema
#!/bin/bash
xhost +local:* 2>/dev/null || true
export DISPLAY=:0

SENHA_ACESSO=$(zenity --password --title="Autenticação" --text="Senha administrativa:")
SENHA_ACESSO=$(echo "$SENHA_ACESSO" | tr -d "[:space:]")

if [ "$SENHA_ACESSO" != "2255" ]; then
    zenity --error --text="Senha incorreta! Acesso negado."
    exit 1
fi

OPCAO=$(zenity --list --title="Controle" --column="Opção" --column="Descrição" \
    "1" "Abrir Jogo/Programa (.exe)" \
    "2" "Abrir WINETRICKS" \
    "3" "DESBLOQUEAR temporariamente o site" \
    "4" "BLOQUEAR o site novamente" --width=450 --height=250)

if [ "$OPCAO" == "1" ]; then
    ARQUIVO_EXE=$(zenity --file-selection)
    if [ -f "$ARQUIVO_EXE" ]; then
        /opt/wine-devel/bin/wine "$ARQUIVO_EXE"
    fi
elif [ "$OPCAO" == "2" ]; then
    WINE=/opt/wine-devel/bin/wine winetricks --gui &
elif [ "$OPCAO" == "3" ]; then
    sudo systemctl stop system-security-check.service
    sudo sed -i "s/^127.0.0.1.*optijuegos.net/# 127.0.0.1 optijuegos.net/g" /etc/hosts
    sudo systemctl restart systemd-resolved.service || true
    sudo resolvectl flush-caches || true
    zenity --info --text="Acesso liberado!"
elif [ "$OPCAO" == "4" ]; then
    sudo systemctl start system-security-check.service
    zenity --info --text="Sistema trancado novamente."
fi
EOF6'
sudo chmod +x /usr/local/bin/abrir-sistema

echo "================================================--"
echo " 🎉 INSTALAÇÃO CONCLUÍDA COM SUCESSO!"
echo "================================================--"
