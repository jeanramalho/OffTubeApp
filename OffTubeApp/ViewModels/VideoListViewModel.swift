//
//  VideoListViewModel.swift
//  OffTubeApp
//
//  Created by Jean Ramalho on 11/04/25.
//

import Foundation
import AVFoundation
import AVKit
import MediaPlayer

class VideoListViewModel: NSObject, AVPictureInPictureControllerDelegate {
    
    var downloadingVideoIds = Set<String>()
    
    // MARK: - Propriedades
    private(set) var videos: [Video] = []     // Lista de vídeos
    var player: AVPlayer?                     // Player para reprodução
    var playerViewController: AVPlayerViewController?
    var currentIndex: Int = 0                 // Índice do vídeo atual
    private let videoService = VideoService() // Serviço de API
    
    // Callbacks para atualizar a UI
    var onVideosUpdated: (() -> Void)?
    var onDownloadError: ((String) -> Void)?
    
    private var audioSessionConfigured = false
    private var playbackTimeObserver: Any?
    
    // MARK: - Inicialização
    override init() {
        super.init()
        loadLocalVideos() // Carrega vídeos salvos ao iniciar
        
        // Observa notificação de background
           NotificationCenter.default.addObserver(
               self,
               selector: #selector(handleAppDidEnterBackground),
               name: Notification.Name("AppDidEnterBackground"),
               object: nil
           )
    }
    
    // MARK: - Persistencia de metadados
    // Caminho do arquivo de metadados
    private var metadataFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("metadata.json")
    }

    // Salvar metadados
    private func saveMetadata() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(videos)
            try data.write(to: metadataFileURL)
        } catch {
            print("Erro ao salvar metadados: \(error)")
        }
    }

    // Carregar metadados
    private func loadMetadata() {
        guard FileManager.default.fileExists(atPath: metadataFileURL.path) else { return }
           
           do {
               let data = try Data(contentsOf: metadataFileURL)
               let decoder = JSONDecoder()
               let decodedVideos = try decoder.decode([Video].self, from: data)
               videos = decodedVideos
           } catch {
               print("Erro ao carregar metadados: \(error)")
               videos = [] // Reset para evitar dados inválidos
           }
    }
    
    // MARK: - Carregar Vídeos Locais
    // Atualize o método loadLocalVideos
    private func loadLocalVideos() {
        loadMetadata() // Carrega metadados primeiro
        
        // Atualiza o localURL apenas se o arquivo existir
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        videos = videos.map { video in
            var updatedVideo = video
            let fileURL = documentsDir.appendingPathComponent("\(video.id).mp4")
            updatedVideo.localURL = FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
            return updatedVideo
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.onVideosUpdated?()
        }
    }
    
    // MARK: - Download de Vídeo
    func downloadVideo(from videoURL: String, completion: @escaping (Bool) -> Void) {
        guard let videoId = extractVideoId(from: videoURL) else {
            onDownloadError?("URL inválida")
            completion(false)
            return
        }
        
        videoService.fetchVideoDetails(videoId: videoId) { [weak self] result in
            switch result {
            case .success(let response):
                print("[DEBUG] Resposta da API: \(response)") // Log para verificar a resposta
                guard let bestVideo = self?.selectBestVideo(from: response.videos.items) else {
                    self?.onDownloadError?("Nenhum link de download disponível")
                    completion(false)
                    return
                }
                
                // Cria objeto Video com dados da API
                let thumbnailURL = response.thumbnails.first?.url
                let video = Video(
                    id: response.id,
                    title: response.title,
                    remoteURL: bestVideo.url,
                    thumbnailURL: thumbnailURL,
                    localURL: nil
                )
                
                // Adiciona à lista e inicia download
                self?.videos.insert(video, at: 0)
                self?.onVideosUpdated?()
                self?.downloadActualVideo(video: video, completion: completion)
                
            case .failure(let error):
                self?.onDownloadError?(error.localizedDescription)
                completion(false)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func extractVideoId(from url: String) -> String? {
        let pattern = "((?<=(v|V)/)|(?<=be/)|(?<=(\\?|\\&)v=)|(?<=embed/)|(?<=shorts/))([\\w-]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsString = url as NSString
        let results = regex.matches(in: url, range: NSRange(location: 0, length: nsString.length))
        return results.first.map { nsString.substring(with: $0.range) }
    }
    
    private func selectBestVideo(from videos: [VideoDownloadLink]) -> VideoDownloadLink? {
        // Prioriza 720p, depois a mais próxima
        let targetQuality = 720
        return videos.first(where: { $0.quality == "720" }) ??
        videos.min { abs(Int($0.quality) ?? 0 - targetQuality) < abs(Int($1.quality) ?? 0 - targetQuality) }
    }
    
    // MARK: - Lógica de Download
     private func downloadActualVideo(video: Video, completion: @escaping (Bool) -> Void) {
         downloadingVideoIds.insert(video.id)
         onVideosUpdated?()
         
         let localPath = getLocalVideoPath(for: video.id)
         
         videoService.downloadVideoFile(from: video.remoteURL, to: localPath) { [weak self] result in
             self?.downloadingVideoIds.remove(video.id)
             
             switch result {
             case .success(let savedURL):
                 DispatchQueue.main.async {
                     guard let self = self,
                           let index = self.videos.firstIndex(where: { $0.id == video.id }) else {
                         completion(false)
                         return
                     }
                     
                     // Atualiza URL local e salva metadados
                     self.videos[index].localURL = savedURL
                     self.saveMetadata()
                     
                     // Baixa thumbnail após sucesso no vídeo
                     if let thumbnailURL = self.videos[index].thumbnailURL {
                         self.downloadThumbnail(from: thumbnailURL, videoId: video.id) { _ in
                             self.saveMetadata() // Atualiza metadados novamente
                             self.onVideosUpdated?() // Atualiza UI para mostrar thumbnail
                         }
                     }
                     
                     completion(true)
                 }
                 
             case .failure(let error):
                 print("Erro no download: \(error.localizedDescription)")
                 self?.onDownloadError?("Erro ao baixar: \(error.localizedDescription)")
                 completion(false)
             }
         }
     }
    
    // MARK: - Thumbnails
    private func getLocalThumbnailPath(for videoId: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(videoId).jpg")
    }

    private func downloadThumbnail(from urlString: String, videoId: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        let destinationURL = getLocalThumbnailPath(for: videoId)
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                completion(false)
                return
            }
            
            do {
                try image.pngData()?.write(to: destinationURL)
                completion(true)
            } catch {
                completion(false)
            }
        }.resume()
    }
    
    // MARK: - Caminhos Locais
    private func getLocalVideoPath(for videoId: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(videoId).mp4")
    }
   
    
// MARK: - deleta Videos
    
    func removeVideo(at index: Int) {
        let video = videos[index]
        
        // Remove o arquivo de vídeo
        if let localURL = video.localURL {
            try? FileManager.default.removeItem(at: localURL)
        }
        
        // Remove a thumbnail
        let thumbnailURL = getLocalThumbnailPath(for: video.id)
        try? FileManager.default.removeItem(at: thumbnailURL)
        
        // Remove da lista
        videos.remove(at: index)
        saveMetadata()
        onVideosUpdated?()
    }
    
    // MARK: - Reprodução
    private var pipController: AVPictureInPictureController?
    
    private func configureAudioSession() {
        guard !audioSessionConfigured else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            audioSessionConfigured = true
        } catch {
            print("Erro ao configurar sessão de áudio: \(error)")
        }
        
        // Registra para notificações de interrupção
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }


    func playCurrentVideo() {
        guard currentIndex < videos.count else { return }
        let video = videos[currentIndex]
        
        // Configura sessão de áudio para permitir reprodução em segundo plano
        configureAudioSession()
        
        if let localURL = video.localURL, FileManager.default.fileExists(atPath: localURL.path) {
            print("[DEBUG] Usando vídeo local já baixado: \(localURL.path)")
            
            let player = AVPlayer(url: localURL)
            self.player = player
            
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            self.playerViewController = playerViewController
            
            // Configuração do PiP
            if AVPictureInPictureController.isPictureInPictureSupported(),
               let playerLayer = playerViewController.view.layer as? AVPlayerLayer {
                playerViewController.allowsPictureInPicturePlayback = true
                pipController = AVPictureInPictureController(playerLayer: playerLayer)
                pipController?.delegate = self
            }
            
            // Configura controles da tela bloqueada
            setupNowPlayingInfo(for: video)
            setupRemoteTransportControls()
            startPlaybackTimeObserver()
            
            NotificationCenter.default.post(name: Notification.Name("ReadyToPlayVideo"), object: self)
            player.play()
            
        } else {
            guard let downloadURL = URL(string: video.remoteURL) else {
                print("[ERRO] URL inválida para reprodução: \(video.remoteURL)")
                return
            }
            
            print("[DEBUG] Iniciando download para reprodução: \(downloadURL.absoluteString)")
            
            let task = URLSession.shared.downloadTask(with: downloadURL) { [weak self] tempLocalURL, _, error in
                guard let self = self else { return }
                
                // Tratamento de erro
                if let error = error {
                    print("Erro no download: \(error)")
                    DispatchQueue.main.async {
                        self.onDownloadError?("Erro ao baixar vídeo: \(error.localizedDescription)")
                    }
                    return
                }
                
                do {
                    let documentsDirectory = try FileManager.default.url(for: .documentDirectory,
                                                                         in: .userDomainMask,
                                                                         appropriateFor: nil,
                                                                         create: true)
                    let localURL = documentsDirectory.appendingPathComponent("\(video.id).mp4")
                    
                    if FileManager.default.fileExists(atPath: localURL.path) {
                        try FileManager.default.removeItem(at: localURL)
                    }
                    
                    try FileManager.default.moveItem(at: tempLocalURL!, to: localURL)
                    
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        
                        // Atualiza estado local
                        self.videos[self.currentIndex].localURL = localURL
                        self.saveMetadata()
                        
                        // Configura player
                        let player = AVPlayer(url: localURL)
                        self.player = player
                        
                        let playerViewController = AVPlayerViewController()
                        playerViewController.player = player
                        self.playerViewController = playerViewController
                        
                        // Configura controles
                        self.setupNowPlayingInfo(for: video)
                        self.setupRemoteTransportControls()
                        
                        // Habilita PiP
                        if AVPictureInPictureController.isPictureInPictureSupported(),
                           let playerLayer = playerViewController.view.layer as? AVPlayerLayer {
                            playerViewController.allowsPictureInPicturePlayback = true
                            self.pipController = AVPictureInPictureController(playerLayer: playerLayer)
                            self.pipController?.delegate = self
                        }
                        
                        NotificationCenter.default.post(name: Notification.Name("ReadyToPlayVideo"), object: self)
                        player.play()
                    }
                } catch {
                    print("Erro ao salvar vídeo: \(error)")
                    DispatchQueue.main.async {
                        self.onDownloadError?("Erro ao salvar vídeo: \(error.localizedDescription)")
                    }
                }
            }
            task.resume()
        }
    }
    
    // MARK: - Lock Screen Controls
    // Método completo para configurar informações de reprodução
    private func setupNowPlayingInfo(for video: Video) {
        guard let player = player else { return }
        
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo = [String: Any]()
        
        // Informações básicas sobre o vídeo
        nowPlayingInfo[MPMediaItemPropertyTitle] = video.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = "OffTubeApp"
        
        // Duração total do vídeo
        if let duration = player.currentItem?.asset.duration.seconds, duration.isFinite {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        }
        
        // Taxa de reprodução (1.0 = velocidade normal)
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        
        // Posição atual de reprodução
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime().seconds
        
        // Tenta adicionar uma imagem de capa (thumbnail)
        let thumbnailPath = getLocalThumbnailPath(for: video.id)
        if let thumbnailData = try? Data(contentsOf: thumbnailPath),
           let thumbnail = UIImage(data: thumbnailData) {
            let artwork = MPMediaItemArtwork(boundsSize: thumbnail.size) { _ in thumbnail }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        
        // Aplica as informações
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        
        // Ativa eventos de controle remoto
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }

    // Método para configurar controles remotos
    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Remove handlers anteriores para evitar duplicação
        [commandCenter.playCommand, commandCenter.pauseCommand,
         commandCenter.nextTrackCommand, commandCenter.previousTrackCommand,
         commandCenter.changePlaybackPositionCommand].forEach {
            $0.removeTarget(nil)
        }
        
        // Comando de reprodução
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.resumePlayback()
            return .success
        }
        
        // Comando de pausa
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.pausePlayback()
            return .success
        }
        
        // Próximo vídeo
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            guard let self = self, self.currentIndex + 1 < self.videos.count else {
                return .noSuchContent
            }
            self.nextVideo()
            return .success
        }
        
        // Vídeo anterior
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            guard let self = self, self.currentIndex > 0 else {
                return .noSuchContent
            }
            self.previousVideo()
            return .success
        }
        
        // Controle deslizante de progresso
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                  let player = self.player,
                  let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            
            let time = CMTime(seconds: positionEvent.positionTime, preferredTimescale: 600)
            player.seek(to: time)
            self.updateNowPlayingTimeInfo()
            return .success
        }
        
        // Habilita todos os comandos
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.nextTrackCommand.isEnabled = (currentIndex + 1 < videos.count)
        commandCenter.previousTrackCommand.isEnabled = (currentIndex > 0)
        commandCenter.changePlaybackPositionCommand.isEnabled = true
    }

    // Observador de tempo para atualizar a barra de progresso na tela bloqueada
    private func startPlaybackTimeObserver() {
        // Remove observador anterior se existir
        if let observer = playbackTimeObserver {
            player?.removeTimeObserver(observer)
            playbackTimeObserver = nil
        }
        
        // Cria novo observador que atualiza a cada 1 segundo
        playbackTimeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 1),
            queue: .main
        ) { [weak self] _ in
            self?.updateNowPlayingTimeInfo()
        }
    }

    // Método para atualizar informações de tempo na tela bloqueada
    private func updateNowPlayingTimeInfo() {
        guard let player = player,
              var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo else {
            return
        }
        
        // Atualiza tempo decorrido e taxa de reprodução
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime().seconds
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }


    // Atualiza o tempo decorrido periodicamente
    private func updatePlaybackProgress() {
        guard let player = player else { return }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] =
            player.currentTime().seconds
    }
    
    // Manipulador de interrupções de áudio (chamadas telefônicas, etc.)
    @objc private func handleAudioSessionInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // Interrupção começou - pausa o vídeo
            pausePlayback()
        case .ended:
            // Interrupção terminou - verifica se deve retomar a reprodução
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    resumePlayback()
                }
            }
        @unknown default:
            break
        }
    }


    
    // MARK: - Controles de Reprodução
    func pausePlayback() {
        player?.pause()
        updateNowPlayingTimeInfo()
    }

    func resumePlayback() {
        player?.play()
        updateNowPlayingTimeInfo()
    }

    func nextVideo() {
        guard currentIndex + 1 < videos.count else { return }
        currentIndex += 1
        playCurrentVideo()
    }

    func previousVideo() {
        guard currentIndex - 1 >= 0 else { return }
        currentIndex -= 1
        playCurrentVideo()
    }

    
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("PiP iniciado")
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("PiP finalizado")
    }
    
    private func setupNowPlayingInfo() {
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo = [String: Any]()
        
        // Configura informações básicas
        nowPlayingInfo[MPMediaItemPropertyTitle] = videos[currentIndex].title
        nowPlayingInfo[MPMediaItemPropertyArtist] = "OffTubeApp"
        
        // Configura tempo de reprodução
        let duration = player?.currentItem?.asset.duration.seconds ?? 0
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player?.currentTime().seconds
        
        // Atualiza a tela bloqueada
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }
    
    // Método para limpar recursos quando não estiver mais reproduzindo
    func stopPlayback() {
        // Remove o observador de tempo
        if let observer = playbackTimeObserver {
            player?.removeTimeObserver(observer)
            playbackTimeObserver = nil
        }
        
        // Para o player
        player?.pause()
        player = nil
        
        // Limpa informações da tela de bloqueio
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        
        // Desativa eventos de controle remoto
        UIApplication.shared.endReceivingRemoteControlEvents()
    }

    // método para detectar quando o app entra em background
    func applicationDidEnterBackground() {
        // Assegura que tudo está configurado para reprodução em background
        configureAudioSession()
        
        // Atualiza informações da tela bloqueada
        if let video = currentIndex < videos.count ? videos[currentIndex] : nil {
            setupNowPlayingInfo(for: video)
        }
    }
    
    // MARK: - desregistro do observador no deinit
    deinit {
        // Remove observadores de tempo
        if let observer = playbackTimeObserver {
            player?.removeTimeObserver(observer)
        }
        
        // Remove observadores de notificação
        NotificationCenter.default.removeObserver(self)
        
        // Desativa sessão de áudio se necessário
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Erro ao desativar sessão de áudio: \(error)")
        }
    }
    
    @objc private func handleAppDidEnterBackground() {
        applicationDidEnterBackground()
    }
    

}


