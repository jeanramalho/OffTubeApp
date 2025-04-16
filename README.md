# 📱 OffTubeApp

![Swift](https://img.shields.io/badge/Swift-5.7-orange)
![Platform](https://img.shields.io/badge/Platform-iOS-blue)
![Architecture](https://img.shields.io/badge/Architecture-MVVM-purple)
![ViewCode](https://img.shields.io/badge/Layout-ViewCode-green)
![AVFoundation](https://img.shields.io/badge/Media-AVFoundation-red)

## 🌟 Visão Geral

**OffTubeApp** é uma solução profissional para gerenciamento de conteúdo multimídia offline, desenvolvida para demonstrar expertise em desenvolvimento iOS de alto nível. Combina técnicas avançadas de engenharia de software com uma experiência de usuário premium, oferecendo:

- Download persistente de vídeos com gestão inteligente de recursos
- Player nativo integrado com recursos profissionais
- Arquitetura escalável para operações complexas de I/O
- Conformidade total com as diretrizes de mídia do iOS

<p align="center">
  <img src="https://via.placeholder.com/150x320/008080/FFFFFF?text=Lista+de+V%C3%ADdeos" width="150" />
  <img src="https://via.placeholder.com/150x320/008080/FFFFFF?text=Player+PiP" width="150" />
  <img src="https://via.placeholder.com/150x320/008080/FFFFFF?text=Gerenciamento" width="150" />
</p>

## 🚀 Funcionalidades Principais

### 🎬 Reprodutor Profissional
- Picture-in-Picture para multitarefa
- Reprodução contínua em segundo plano/tela bloqueada
- Controles precisos de playback (play/pause, próximo/anterior)
- Integração com sistema de áudio do iOS via `AVAudioSession`

### 📥 Gestão de Conteúdo
- Download via URL do YouTube com seleção automática de qualidade (até 720p)
- Armazenamento seguro em sandbox com verificação de integridade
- Exclusão segura de arquivos e metadados associados
- Compartilhamento via AirDrop e apps de terceiros

### ⚡ Performance Otimizada
- Listagem dinâmica com pré-carregamento de thumbnails
- Validação de URLs com expressões regulares nativas
- Serialização/deserialização eficiente de metadados
- Gerenciamento de memória para sessões prolongadas

## 🛠 Stack Tecnológica

- **Swift 5.7**: Type-safety e recursos modernos
- **AVFoundation/AVKit**: Engine de mídia profissional
- **Grand Central Dispatch**: Concorrência otimizada
- **FileManager**: Gestão segura de arquivos locais
- **JSON Handling**: Serialização customizada com `Codable`
- **ViewCode**: Layouts programáticos e maintainables

## 📂 Estrutura do Projeto

Organização profissional seguindo padrões de mercado:

OffTubeApp/
├── Controllers/ # Coordenação de fluxos e lifecycle
├── ViewModels/ # Lógica de negócios e estados reativos
├── Views/ # Componentes UI reutilizáveis
├── Models/ # Entidades de dados e DTOs
├── Service/ # Camada de rede e operações I/O
└── Resources/ # Assets e configurações locais


## 💡 Destaques Técnicos

### Engenharia de Mídia
- Implementação de `AVPlayerViewController` com suporte a PiP
- Configuração de `AVAudioSession` para background playback
- Decodificação assíncrona de thumbnails usando `URLSession`
- Validação de formatos com `AVAsset`

### Arquitetura
- Separação MVVM com bindings reativos
- Injeção de dependências para testabilidade
- Padrão Observer para atualizações em tempo real
- Tratamento granular de erros em todas as camadas

### Otimizações
- Priorização de threads com `DispatchQueue`
- Cache inteligente usando `NSCache`
- Sanitização de dados com `JSONEncoder/Decoder`
- Validação de URLs via `NSRegularExpression`

## ⚙️ Configuração

1. Clone o repositório
```bash
git clone https://github.com/jeanramalho/OffTubeApp.git
```

2. Abra o projeto no Xcode 14+
```bash
open OffTubeApp.xcodeproj
```
3. Habilite as capabilities necessárias:
// Target > Signing & Capabilities
- Background Modes: Audio, AirPlay, Picture in Picture
- App Sandbox: File Access > User Selected File

## 📞 Contato

Estou disponível para discutir detalhes técnicos, arquiteturais ou oportunidades profissionais:

- LinkedIn: [Jean Ramalho](https://www.linkedin.com/in/jean-ramalho/)
- Email: jeanramalho.dev@gmail.com

---

⭐️ Desenvolvido por Jean Ramalho | Desenvolvedor iOS | Swift & UIKit

"Any fool can write code that a computer can understand. Good programmers write code that humans can understand."
― Martin Fowler
