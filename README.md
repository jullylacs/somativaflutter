# 📘 Projeto: Somativa Flutter

## 🏷️ Descrição
O **este projeto** é um aplicativo desenvolvido em **Flutter** que permite o **registro de ponto eletrônico** com autenticação de usuários via **Firebase Authentication**, armazenamento de registros no **Cloud Firestore** e validação de **localização em tempo real** através do **Geolocator**.

O sistema garante que o colaborador só consiga registrar o ponto (entrada/saída) quando estiver dentro de um raio de 100 metros do local de trabalho autorizado.

---

## 🚀 Funcionalidades
- 🔐 **Login e autenticação** via Firebase  
- 🕓 **Registro de ponto (entrada e saída)** com hora e localização  
- 📍 **Validação de distância** com base na geolocalização do dispositivo  
- 📜 **Histórico de pontos** armazenado e exibido ao usuário  
- ⚙️ **Permissões automáticas** de localização e tratamento de erros  
- 🔄 **Reautenticação com senha** para garantir segurança no registro  

---

## 🧩 Tecnologias utilizadas
- **Flutter** (Dart)
- **Firebase Authentication**
- **Cloud Firestore**
- **Geolocator**
- **Material Design**

---

## ⚠️ Desafios e soluções

| Desafio | Solução Implementada |
|----------|----------------------|
| ❗ Manter o app fluido durante operações assíncronas (como autenticação e localização) | Foi adicionado um **indicador de carregamento (`CircularProgressIndicator`)** e o uso de `AnimatedSwitcher` para transições suaves. |
| ❗ Solicitação e tratamento de permissões de localização em diferentes cenários | Implementado fluxo completo com **tratamento de exceções** e mensagens personalizadas para cada caso (`negada`, `negada permanentemente`, `serviço desativado`). |
| ❗ Evitar travamentos ao iniciar o app sem permissões | Separado o processo de inicialização (`_inicializar`) em etapas assíncronas e não bloqueantes. |
| ❗ Garantir segurança no registro de ponto | Criado sistema de **reautenticação via senha** antes de registrar o ponto, prevenindo uso indevido do dispositivo. |
| ❗ Validar se o usuário está realmente no local de trabalho | Implementado cálculo de **distância geográfica com limite de 100 metros**, usando `Geolocator.distanceBetween`. |
| ❗ Garantir boa UX nas mensagens de erro | Criado método centralizado `_mostrarMensagem()` com **SnackBars flutuantes**, exibindo alertas rápidos e consistentes. |

---
  

## 📂 Estrutura do Projeto

- ib/
  - main.dart # Arquivo principal da aplicação
  - ponto_view.dart # Tela principal de registro de ponto
  - historico_view.dart # Tela de histórico de pontos
  - widgets/ # (opcional) componentes reutilizáveis

## 📱 Como usar

1. Crie uma conta e faça login.  
2. Permita o acesso à localização.  
3. Pressione **“Registrar Entrada”** quando chegar ao trabalho.  
4. Pressione **“Registrar Saída”** ao sair.  
5. Consulte seu **Histórico de Pontos** na tela correspondente.

---

## ⚠️ Tratamento de erros implementado

- ❌ **Falha na autenticação:** mensagem de erro amigável.  
- 📍 **Localização desativada:** alerta com instrução para ativar.  
- 🚫 **Permissão negada:** SnackBar com orientação.  
- 📏 **Tentativa fora do raio:** aviso de “fora do limite de 100m”.  
- 🔄 **Requisições assíncronas:** indicador de carregamento exibido durante o processo.

---

## 👩‍💻 Autora

**Jully Lacs**  
📍 Desenvolvido com Flutter
