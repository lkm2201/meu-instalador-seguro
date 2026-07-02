from flask import Flask, jsonify, request

app = Flask(__name__)

# Configuração central de segurança do seu ecossistema Flask
STATUS_SISTEMA = {
    "sistema_bloqueio": True,
    "senha_correta": "2255"
}

# 🔒 TRAVA GLOBAL: É executada ANTES de qualquer rota ou aplicação interna do Flask
@app.before_request
def verificar_trava_sistema():
    # Permite apenas acessar a página inicial ou a rota de liberação
    if request.endpoint in ['index', 'liberar_sistema']:
        return None
        
    # Se o sistema estiver travado, bloqueia QUALQUER outra rota/funcionalidade
    if STATUS_SISTEMA["sistema_bloqueio"]:
        return jsonify({
            "erro": "Acesso Negado",
            "mensagem": "Todas as aplicacoes Flask estao trancadas. Insira a senha de liberacao."
        }), 403

@app.route('/')
def index():
    return jsonify({
        "status": "Servidor Flask Operacional",
        "travado": STATUS_SISTEMA["sistema_bloqueio"]
    })

# Rota protegida para validar a senha e liberar todo o resto do app
@app.route('/liberar', methods=['POST'])
def liberar_sistema():
    dados = request.get_json()
    if dados and dados.get("senha") == STATUS_SISTEMA["senha_correta"]:
        STATUS_SISTEMA["sistema_bloqueio"] = False
        return jsonify({"sucesso": True, "mensagem": "Todas as aplicacoes Flask foram desbloqueadas!"})
    return jsonify({"sucesso": False, "mensagem": "Senha incorreta!"}), 401

# --- 🚀 EXEMPLOS DE OUTRAS APLICAÇÕES INTERNAS DO SEU FLASK ---
# Qualquer rota nova que você criar aqui embaixo já nasce automaticamente trancada!

@app.route('/api/dados')
def gerenciar_dados():
    return jsonify({"status": "Sucesso", "conteudo": "Dados sensíveis acessados!"})

@app.route('/dashboard')
def painel_controle():
    return jsonify({"status": "Sucesso", "conteudo": "Painel do administrador aberto!"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
