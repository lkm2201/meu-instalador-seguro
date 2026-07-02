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

# --- INSTALAÇÃO DE DRIVERS DE VÍDEO PARA O WINE (UBUNTU NOBLE) ---
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
    cd /opt/minha_app_flask
    python3 -m venv venv || true
    ./venv/bin/pip install flask || true
    cd -
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

# Cria o comando de inicialização seguro que pede senha graficamente para abrir os apps
sudo bash -c 'cat << "EOF" > /usr/local/bin/abrir-sistema
#!/bin/bash

# Captura a senha de acesso graficamente usando Zenity
SENHA_ACESSO=$(zenity --password --title="Autenticação do Sistema" --text="Digite a senha para liberar os programas:")

if [ "$SENHA_ACESSO" != "2255" ]; then
    zenity --error --text="Senha incorreta! Acesso negado." --title="Erro"
    exit 1
fi

# Permite acesso ao X11 local para o Wine rodar sem erro de SHM
xhost +local:* 2>/dev/null

# Menu de Opções Gráfico
OPCAO=$(zenity --list --title="Menu do Sistema" --column="Opção" --column="Descrição" \
    "1" "Abrir Programa Windows (Wine)" \
    "2" "Iniciar Servidor Web (Flask)" --width=400 --height=200)

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
else
    zenity --info --text="Operação cancelada pelo usuário."
fi
EOF'

# Dá permissão para o comando de proteção rodar
sudo chmod +x /usr/local/bin/abrir-sistema

echo "=================================================="
echo " 🎉 Instalação concluída com sucesso no Ubuntu Noble!"
echo " Para rodar os apps com total segurança, use o comando: abrir-sistema"
echo "=================================================="
