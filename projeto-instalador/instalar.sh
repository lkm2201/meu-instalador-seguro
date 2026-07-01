#!/bin/bash
set -e

echo "=================================================="
echo "    📦 INSTALADOR AUTOMÁTICO - UBUNTU NOBLE    "
echo "=================================================="

echo "--> 1. Atualizando listas e adicionando arquitetura 32-bits..."
sudo dpkg --add-architecture i386
sudo apt update

echo "--> 2. Instalando Wine Completo, Python e Zenity (Interface Gráfica)..."
sudo apt install -y wine wine32 wine64 libwine libwine:i386 python3-pip python3-venv python3-full zenity

echo "--------------------------------------------------"
echo "--> 3. Configurando pastas do sistema..."

if [ -d "flask_app" ]; then
    sudo mkdir -p /opt/minha_app_flask
    sudo cp -r flask_app/* /opt/minha_app_flask/
    cd /opt/minha_app_flask
    python3 -m venv venv || true
    cd -
fi

if [ -f "seu_app_windows.exe" ]; then
    sudo mkdir -p /opt/meu_app_wine
    sudo cp seu_app_windows.exe /opt/meu_app_wine/
fi

# Tranca as pastas para usuários comuns
sudo chmod 700 /opt/meu_app_wine || true
sudo chmod 700 /opt/minha_app_flask || true

echo "--------------------------------------------------"
echo "--> 4. Criando as Travas Globais de Senha (2255)..."

# Cria o validador central com a senha 2255
sudo bash -c 'cat << "EOF" > /usr/local/bin/valida-acesso-sistema
#!/bin/bash
SENHA_DIGITADA=$(zenity --password --title="Autenticação do Sistema" --text="Acesso restrito ao Wine. Digite a senha para liberar:")
if [ "$SENHA_DIGITADA" != "2255" ]; then
    zenity --error --text="Senha incorreta! Acesso negado." --title="Erro"
    exit 1
fi
exit 0
EOF'
sudo chmod +x /usr/local/bin/valida-acesso-sistema

# Cria wrappers do Wine
sudo bash -c 'cat << "EOF" > /usr/local/bin/wine
#!/bin/bash
/usr/local/bin/valida-acesso-sistema && /usr/bin/wine "$@"
EOF'

sudo bash -c 'cat << "EOF" > /usr/local/bin/wine64
#!/bin/bash
/usr/local/bin/valida-acesso-sistema && /usr/bin/wine64 "$@"
EOF'

sudo bash -c 'cat << "EOF" > /usr/local/bin/wineserver
#!/bin/bash
/usr/local/bin/valida-acesso-sistema && /usr/bin/wineserver "$@"
EOF'

sudo chmod +x /usr/local/bin/wine /usr/local/bin/wine64 /usr/local/bin/wineserver

# Aplica os aliases no .bashrc do usuário atual
sed -i '/alias wine=/d' ~/.bashrc
sed -i '/alias wine64=/d' ~/.bashrc
echo "alias wine='/usr/local/bin/valida-acesso-sistema && /usr/bin/wine'" >> ~/.bashrc
echo "alias wine64='/usr/local/bin/valida-acesso-sistema && /usr/bin/wine64'" >> ~/.bashrc

echo "=================================================="
echo " 🎉 Configuração salva no script com sucesso!"
echo "=================================================="#!/bin/bash
set -e

# --- COLOQUE A SENHA DOS PROGRAMAS AQUI ---
SENHA_DOS_PROGRAMAS="2255"

echo "=================================================="
echo "    📦 INSTALADOR AUTOMÁTICO - UBUNTU NOBLE    "
echo "=================================================="

echo "--> 1. Atualizando listas do sistema..."
sudo apt update

echo "--> 2. Instalando Wine, Python e dependências..."
sudo apt install -y wine64 python3-pip python3-venv python3-full

echo "--------------------------------------------------"

echo "--> 3. Copiando arquivos para o sistema (/opt)..."
# Configura a pasta do Flask
if [ -d "flask_app" ]; then
    sudo mkdir -p /opt/minha_app_flask
    sudo cp -r flask_app/* /opt/minha_app_flask/
    cd /opt/minha_app_flask
    python3 -m venv venv
    ./venv/bin/pip install flask
    cd -
fi

# Configura a pasta do Wine
if [ -f "seu_app_windows.exe" ]; then
    sudo mkdir -p /opt/meu_app_wine
    sudo cp seu_app_windows.exe /opt/meu_app_wine/
fi

echo "--------------------------------------------------"
echo "--> 4. Criando o Bloqueador de Senha nos Apps..."

# Cria o comando de inicialização seguro que pede senha para abrir os apps
sudo bash -c "cat << 'EOF' > /usr/local/bin/abrir-sistema
#!/bin/bash

# Senha definida no instalador
SENHA_CORRETA=\"$SENHA_DOS_PROGRAMAS\"

echo \"=== SISTEMA PROTEGIDO ===\"
read -s -p \"Digite a senha de acesso para liberar os programas: \" SENHA_DIGITADA
echo \"\"

if [ \"\$SENHA_DIGITADA\" != \"\$SENHA_CORRETA\" ]; then
    echo \"❌ Senha incorreta! Acesso negado.\"
    exit 1
fi

echo \"✅ Acesso liberado!\"
echo \"1) Abrir Programa (Wine)\"
echo \"2) Iniciar Servidor (Flask)\"
read -p \"Escolha o que deseja rodar (1 ou 2): \" OPCAO

if [ \"\$OPCAO\" == \"1\" ]; then
    echo \"Iniciando aplicativo no Wine...\"
    wine /opt/meu_app_wine/seu_app_windows.exe
elif [ \"\$OPCAO\" == \"2\" ]; then
    echo \"Iniciando servidor Flask...\"
    source /opt/minha_app_flask/venv/bin/activate
    python /opt/minha_app_flask/app.py
else
    echo \"Opção inválida.\"
fi
EOF"

# Dá permissão para o comando seguro funcionar
sudo chmod +x /usr/local/bin/abrir-sistema

echo "=================================================="
echo " 🎉 Instalação concluída sem erros!"
echo " Para o usuário abrir os apps com senha, ele usará o comando: abrir-sistema"
echo "=================================================="
