# Progm

Este projeto configura automaticamente o ambiente do **Wine** com os drivers gráficos modernos da **Intel/Mesa (com suporte 32-bits e Vulkan)** e ativa uma **trava global de segurança na aplicação Flask** usando a senha `2255`.

## 🚀 Como Instalar em uma Máquina Nova

Para baixar, extrair e rodar o instalador automaticamente, abra o terminal da máquina de destino e execute o comando abaixo:

```bash
cd ~/meu-instalador-seguro && cp ~/projeto-instalador/instalar.sh ./projeto-instalador/instalar.sh && tar -czf pacote.tar.gz projeto-instalador && git add . && git commit -m "Fix: Atualizado instalador com bloqueador de site definitivo" && BRANCH_ATUAL=$(git branch --show-current) && git push origin $BRANCH_ATUAL
