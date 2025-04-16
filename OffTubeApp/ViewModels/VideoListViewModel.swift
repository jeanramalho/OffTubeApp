//
//  VideoListViewModel.swift
//  OffTubeApp
//
//  Created by Jean Ramalho on 11/04/25.
//

import Foundation
import AVFoundation
import AVKit

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
    
    // MARK: - Inicialização
    override init() {
        super.init()
        loadLocalVideos() // Carrega vídeos salvos ao iniciar
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

    func playCurrentVideo() {
        guard currentIndex < videos.count else { return }
        let video = videos[currentIndex]
        
        // Verifica se já existe URL local
        if let localURL = video.localURL, FileManager.default.fileExists(atPath: localURL.path) {
            print("[DEBUG] Usando vídeo local já baixado: \(localURL.path)")
            
            // Configura o player e inicia a reprodução
            let player = AVPlayer(url: localURL)
            self.player = player
            
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            self.playerViewController = playerViewController
            
            // Configura o PiP se suportado
            if AVPictureInPictureController.isPictureInPictureSupported(),
               let playerLayer = playerViewController.view.layer as? AVPlayerLayer { // Correção aqui
                playerViewController.allowsPictureInPicturePlayback = true
                pipController = AVPictureInPictureController(playerLayer: playerLayer)
                pipController?.delegate = self
            }
            
            NotificationCenter.default.post(name: Notification.Name("ReadyToPlayVideo"), object: self)
            player.play()
            
        } else {
            // Se não existe local, faz o download
            guard let downloadURL = URL(string: video.remoteURL) else {
                print("[ERRO] URL inválida para reprodução: \(video.remoteURL)")
                return
            }
            
            print("[DEBUG] Iniciando download do arquivo para reprodução: \(downloadURL.absoluteString)")
            
            let task = URLSession.shared.downloadTask(with: downloadURL) { [weak self] tempLocalURL, _, error in
                if let error = error {
                    print("Erro no download do vídeo para reprodução: \(error)")
                    DispatchQueue.main.async {
                        self?.onDownloadError?("Erro ao baixar vídeo: \(error.localizedDescription)")
                    }
                    return
                }
                
                guard let tempLocalURL = tempLocalURL else {
                    print("URL temporária inválida para reprodução")
                    return
                }
                
                do {
                    // Salva vídeo no diretório local antes de tocar
                    let documentsDirectory = try FileManager.default.url(for: .documentDirectory,
                                                                         in: .userDomainMask,
                                                                         appropriateFor: nil,
                                                                         create: true)
                    let fileName = "\(video.id).mp4" // Nome fixo para evitar duplicatas
                    let localURL = documentsDirectory.appendingPathComponent(fileName)
                    
                    if FileManager.default.fileExists(atPath: localURL.path) {
                        try FileManager.default.removeItem(at: localURL)
                    }
                    
                    try FileManager.default.moveItem(at: tempLocalURL, to: localURL)
                    print("Vídeo para reprodução salvo localmente em: \(localURL.path)")
                    
                    DispatchQueue.main.async { [weak self] in // Adicione [weak self] in
                        guard let self = self else { return }
                        self.videos[self.currentIndex].localURL = localURL
                        self.saveMetadata()
                        
                        let player = AVPlayer(url: localURL)
                        self.player = player
                        
                        let playerViewController = AVPlayerViewController()
                        playerViewController.player = player
                        self.playerViewController = playerViewController
                        
                        // Configura o PiP se suportado
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
                    print("Erro ao salvar vídeo localmente para reprodução: \(error)")
                    DispatchQueue.main.async {
                        self?.onDownloadError?("Erro ao salvar vídeo: \(error.localizedDescription)")
                    }
                }
            }
            task.resume()
        }
    }

    
    // MARK: - Controles de Reprodução
    func pausePlayback() {
        player?.pause()
    }

    func resumePlayback() {
        player?.play()
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

}


