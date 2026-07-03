#!/bin/bash
set -e

# ==================================================
#       📦 INSTALADOR AUTOMÁTICO - UBUNTU NOBLE     
# ==================================================

# 🔒 Captura a senha inicial usando o Zenity (sem sudo para não quebrar a tela)
SENHA_DIGITADA=$(zenity --password --title="Bloqueio de Segurança" --text="Digite a senha padrão (2255) para iniciar a instalação:")

if [ "$SENHA_DIGITADA" != "2255" ]; then
    zenity --error --text="Senha incorreta! Instalação cancelada." --title="Erro"
    exit 1
fi

echo "--> 1. Instalando drivers gráficos modernos e suporte 32-bits..."
sudo add-apt-repository -y universe
sudo add-apt-repository -y multiverse
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install -y libgl1-mesa-dri:i386 mesa-vulkan-drivers mesa-vulkan-drivers:i386 libglx-mesa0:i386 libgl1:i386

echo "--> 2. Instalando Wine, Python e dependências do sistema..."
sudo apt install -y wine wine32 wine64 libwine libwine:i386 python3-pip python3-venv python3-full zenity

echo "--------------------------------------------------"
echo "--> 3. Configurando pastas e copiando arquivos para /opt..."

# Configura a pasta do Flask
if [ -d "flask_app" ]; then
    sudo mkdir -p /opt/minha_app_flask
    sudo cp -r flask_app/* /opt/minha_app_flask/
    sudo python3 -m venv /opt/minha_app_flask/venv || true
    sudo /opt/minha_app_flask/venv/bin/pip install flask || true
fi

# Configura a pasta do Wine
if [ -f "seu_app_windows.exe" ]; then
    sudo mkdir -p /opt/meu_app_wine
    sudo cp seu_app_windows.exe /opt/meu_app_wine/
fi

# Tranca as pastas para usuários comuns não mexerem
sudo chmod 700 /opt/meu_app_wine || true
sudo chmod 700 /opt/minha_app_flask || true

echo "--------------------------------------------------"
echo "--> 4. Criando o Bloqueador Gráfico nos Apps (abrir-sistema)..."

# Cria o comando de inicialização seguro que pede senha graficamente para abrir os apps ou bloquear o site
sudo bash -c 'cat << "EOF2" > /usr/local/bin/abrir-sistema
#!/bin/bash

# Captura a senha de acesso graficamente usando Zenity
SENHA_ACESSO=$(zenity --password --title="Autenticação do Sistema" --text="Digite a senha para liberar os programas:")

if [ "$SENHA_ACESSO" != "2255" ]; then
    zenity --error --text="Senha incorreta! Acesso negado." --title="Erro"
    exit 1
fi

# Permite acesso ao X11 local para o Wine rodar sem erro de SHM
xhost +local:* 2>/dev/null

# Menu de Opções Gráfico Atualizado com a função de Bloqueio
OPCAO=$(zenity --list --title="Menu do Sistema" --column="Opção" --column="Descrição" \
    "1" "Abrir Programa Windows (Wine)" \
    "2" "Iniciar Servidor Web (Flask)" \
    "3" "Bloquear o Site Optijuegos (Segurança)" --width=400 --height=230)

if [ "$OPCAO" == "1" ]; then
    if [ -f "/opt/meu_app_wine/seu_app_windows.exe" ]; then
        wine /opt/meu_app_wine/seu_app_windows.exe
    else
        zenity --error --text="Aplicativo Windows não encontrado em /opt/meu_app_wine/"
    fi
elif [ "$OPCAO" == "2" ]; then
    if [ -d "/opt/minha_app_flask" ]; then
        source /opt/minha_app_flask/venv/bin/activate
        python3 /opt/minha_app_flask/app.py
    else
        zenity --error --text="Aplicação Flask não encontrada em /opt/minha_app_flask/"
    fi
elif [ "$OPCAO" == "3" ]; then
    if grep -q "optijuegos.net" /etc/hosts; then
        zenity --info --text="O site optijuegos.net já está na lista de bloqueados!" --title="Aviso"
    else
        sudo bash -c "echo '\''127.0.0.1 optijuegos.net'\'' >> /etc/hosts"
        sudo bash -c "echo '\''127.0.0.1 www.optijuegos.net'\'' >> /etc/hosts"
        sudo systemctl restart systemd-resolved.service || true
        zenity --info --text="Sucesso! O site https://optijuegos.net/ foi totalmente bloqueado nesta máquina." --title="Bloqueado"
    fi
else
    zenity --info --text="Operação cancelada pelo usuário."
fi
EOF2'

sudo chmod +x /usr/local/bin/abrir-sistema

echo "=================================================="
echo " 🎉 Instalação concluída com sucesso no Ubuntu Noble!"
echo " Para gerenciar os apps e bloqueios, use o comando: abrir-sistema"
echo "=================================================="
