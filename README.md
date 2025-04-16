# 📱 OffTubeApp

![Swift](https://img.shields.io/badge/Swift-5.7-orange)
![Platform](https://img.shields.io/badge/Platform-iOS-blue)
![Architecture](https://img.shields.io/badge/Architecture-MVVM-purple)
![ViewCode](https://img.shields.io/badge/Layout-ViewCode-green)
![AVFoundation](https://img.shields.io/badge/Media-AVFoundation-red)
![MediaPlayer](https://img.shields.io/badge/Controls-MediaPlayer-yellow)

## 🌟 Visão Geral

O **OffTubeApp** é um aplicativo iOS nativo desenvolvido com foco na performance, experiência do usuário e boas práticas de arquitetura. Ele permite baixar vídeos do YouTube diretamente para o dispositivo, exibí-los em uma interface fluida baseada em UITableView, tocar áudio em segundo plano e manter a execução com a tela bloqueada. O app ainda oferece funcionalidades de compartilhamento e remoção de vídeos, com uma interface simples, direta e eficiente.

Um projeto pessoal desenvolvido de ponta a ponta para resolver um problema real: ouvir vídeos e podcasts do YouTube com liberdade, mesmo com a tela bloqueada, com foco em performance e experiência nativa.

- Download persistente de vídeos com gestão inteligente de recursos
- Player nativo integrado com recursos profissionais
- Arquitetura escalável para operações complexas de I/O
- Conformidade total com as diretrizes de mídia do iOS
- Controles completos na tela de bloqueio para uma experiência imersiva

<p align="center">
  <img src="https://github.com/user-attachments/assets/0978ce3a-b614-4287-a495-1e2c4fd2e82f" width="150" />
  <img src="https://github.com/user-attachments/assets/79973c8c-ce03-487d-abb6-e05edb9da947" width="150" />
  <img src="https://github.com/user-attachments/assets/894a6624-e334-4acf-bfbf-0610de5b1fbb" width="150" />
  <img src="https://github.com/user-attachments/assets/ccb5913d-1cdc-4ec5-be9d-b9a101a9fb2f" width="150" />
</p>

## 🚀 Funcionalidades Principais

### 🎬 Reprodutor Profissional
- Picture-in-Picture para multitarefa
- Reprodução contínua em segundo plano/tela bloqueada
- Controles precisos de playback (play/pause, próximo/anterior)
- Integração com sistema de áudio do iOS via `AVAudioSession`
- Controles completos na tela de bloqueio com scrubbing e navegação
- Tratamento inteligente de interrupções de áudio (chamadas telefônicas)
- Atualização dinâmica de metadata e artwork na Central de Controle

### 📥 Gestão de Conteúdo
- Download via URL do YouTube com seleção automática de qualidade (até 720p)
- Armazenamento seguro em sandbox com verificação de integridade
- Exclusão segura de arquivos e metadados associados
- Compartilhamento via AirDrop e apps de terceiros
- Persistência de metadados entre sessões usando `Codable`
- Gestão eficiente do armazenamento local

### ⚡ Performance Otimizada
- Listagem dinâmica com pré-carregamento de thumbnails
- Validação de URLs com expressões regulares nativas
- Serialização/deserialização eficiente de metadados
- Gerenciamento de memória para sessões prolongadas
- Observadores de tempo com otimização de bateria
- Limpeza automática de recursos para prevenir memory leaks

## 🛠 Stack Tecnológica

- **Swift 5.7**: Type-safety e recursos modernos
- **AVFoundation/AVKit**: Engine de mídia profissional
- **MediaPlayer Framework**: Integração nativa com controles do sistema
- **Grand Central Dispatch**: Concorrência otimizada
- **FileManager**: Gestão segura de arquivos locais
- **JSON Handling**: Serialização customizada com `Codable`
- **ViewCode**: Layouts programáticos e maintainables
- **Notification Center**: Comunicação desacoplada entre componentes

## 📂 Estrutura do Projeto

Organização profissional seguindo padrões de mercado:
```
OffTubeApp/
├── Controllers/ # Coordenação de fluxos e lifecycle
├── ViewModels/ # Lógica de negócios e estados reativos
├── Views/ # Componentes UI reutilizáveis
├── Models/ # Entidades de dados e DTOs
├── Service/ # Camada de rede e operações I/O
├── Managers/ # Serviços de infraestrutura e sistema
└── Resources/ # Assets e configurações locais
```

## 💡 Destaques Técnicos

### Engenharia de Mídia
- Implementação de `AVPlayerViewController` com suporte a PiP
- Configuração avançada de `AVAudioSession` para reprodução contínua
- Decodificação assíncrona de thumbnails usando `URLSession`
- Validação de formatos com `AVAsset`
- Integração com `MPNowPlayingInfoCenter` para metadados na tela bloqueada
- Controles precisos via `MPRemoteCommandCenter` para interação sem desbloqueio
- Monitoramento de progresso com `CMTime` e observadores otimizados

### Arquitetura
- Separação MVVM com bindings reativos
- Injeção de dependências para testabilidade
- Padrão Observer para atualizações em tempo real
- Tratamento granular de erros em todas as camadas
- Ciclo de vida gerenciado com `deinit` para liberação de recursos
- Notificações para comunicação entre camadas desacopladas

### Otimizações
- Priorização de threads com `DispatchQueue`
- Cache inteligente usando `NSCache`
- Sanitização de dados com `JSONEncoder/Decoder`
- Validação de URLs via `NSRegularExpression`
- Gestão eficiente de interrupções do sistema operacional
- Timeline precisa para atualização de controles da interface

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
