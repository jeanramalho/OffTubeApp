//
//  VideoListViewModel.swift
//  OffTubeApp
//
//  Created by Jean Ramalho on 11/04/25.
//
import Foundation
import AVFoundation
import AVKit

class VideoListViewModel {
    private(set) var videos: [Video] = []
    var player: AVPlayer?
    var playerViewController: AVPlayerViewController?
    var currentIndex: Int = 0
    
    // URL base da API
    private let baseURL = "https://backend-offtube.onrender.com"
    
    // Callback para atualizar a UI
    var onVideosUpdated: (() -> Void)?
    var onDownloadError: ((String) -> Void)?
    
    // Inicializador
    init() {
        // Verificar status da API no início para garantir que está funcionando
        checkAPIStatus()
    }
    
    // Verifica se a API está funcionando
    private func checkAPIStatus() {
        guard let url = URL(string: "\(baseURL)/status") else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("Erro ao verificar status da API: \(error.localizedDescription)")
                return
            }
            
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let status = json["status"] as? String,
               let cookiesConfigured = json["cookies_configured"] as? Bool {
                print("Status da API: \(status)")
                print("Cookies configurados: \(cookiesConfigured)")
                
                if !cookiesConfigured {
                    DispatchQueue.main.async {
                        self?.onDownloadError?("API não tem cookies do YouTube configurados.")
                    }
                }
            }
        }.resume()
    }
    
    // Baixa o vídeo através da API
    func downloadVideo(from videoURL: String, completion: @escaping (Bool) -> Void) {
        print("[DEBUG] Iniciando download para URL: \(videoURL)")
        
        // Validar URL do YouTube
        guard let url = URL(string: videoURL),
              url.host?.contains("youtube.com") == true || url.host?.contains("youtu.be") == true else {
            print("[ERRO] URL inválida")
            completion(false)
            return
        }
        
        // Criar payload
        let payload = ["url": videoURL]
        print("Enviando requisição para \(baseURL)/download com payload: \(payload)")
        
        // Criar URLRequest
        guard let requestURL = URL(string: "\(baseURL)/download") else {
            print("[ERRO] URL inválida")
            completion(false)
            return
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120 // Aumentar timeout para 120 segundos
        
        // Configurar cache e política de rede
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.networkServiceType = .responsiveData
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            print("[ERRO] Erro ao criar payload: \(error)")
            completion(false)
            return
        }
        
        // Configurar sessão com timeout maior e configurações específicas
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 120
        config.waitsForConnectivity = true
        config.allowsCellularAccess = true
        config.allowsConstrainedNetworkAccess = true
        config.allowsExpensiveNetworkAccess = true
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.connectionProxyDictionary = nil
        config.tlsMinimumSupportedProtocol = .tlsProtocol12
        
        let session = URLSession(configuration: config)
        
        // Implementar sistema de retry
        var retryCount = 0
        let maxRetries = 3
        let retryDelay: TimeInterval = 2.0
        
        func attemptDownload() {
            let task = session.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("[ERRO] Erro na requisição: \(error)")
                    
                    // Tentar novamente se ainda houver tentativas
                    if retryCount < maxRetries {
                        retryCount += 1
                        print("[INFO] Tentativa \(retryCount) de \(maxRetries)")
                        DispatchQueue.global().asyncAfter(deadline: .now() + retryDelay) {
                            attemptDownload()
                        }
                        return
                    }
                    
                    completion(false)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("[ERRO] Resposta inválida")
                    completion(false)
                    return
                }
                
                print("Status HTTP: \(httpResponse.statusCode)")
                
                guard httpResponse.statusCode == 200,
                      let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let videoURL = json["url"] as? String,
                      let videoId = json["id"] as? String,
                      let title = json["title"] as? String,
                      let thumbnailURL = json["thumbnail"] as? String,
                      let duration = json["duration"] as? Int else {
                    print("[ERRO] Resposta inválida da API")
                    completion(false)
                    return
                }
                
                print("Resposta da API: \(json)")
                
                // Baixar vídeo
                self.downloadVideoFile(from: "\(self.baseURL)\(videoURL)", videoId: videoId) { success in
                    if success {
                        // Baixar thumbnail
                        self.downloadThumbnail(from: "\(self.baseURL)\(thumbnailURL)", videoId: videoId) { thumbnailSuccess in
                            if thumbnailSuccess {
                                // Adicionar vídeo à lista
                                let video = Video(
                                    id: videoId,
                                    title: title,
                                    remoteURL: videoURL,
                                    thumbnailURL: "\(self.baseURL)\(thumbnailURL)",
                                    duration: duration,
                                    localURL: self.getLocalVideoPath(for: videoId)
                                )
                                
                                DispatchQueue.main.async {
                                    self.videos.append(video)
                                    completion(true)
                                }
                            } else {
                                completion(false)
                            }
                        }
                    } else {
                        completion(false)
                    }
                }
            }
            
            task.resume()
        }
        
        // Iniciar primeira tentativa
        attemptDownload()
    }
    
    private func downloadVideoFile(from urlString: String, videoId: String, completion: @escaping (Bool) -> Void) {
        print("Iniciando download do vídeo de: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("[ERRO] URL inválida")
            completion(false)
            return
        }
        
        let task = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("[ERRO] Erro ao baixar vídeo: \(error)")
                completion(false)
                return
            }
            
            guard let tempURL = tempURL else {
                print("[ERRO] URL temporária inválida")
                completion(false)
                return
            }
            
            let fileManager = FileManager.default
            let destinationURL = self.getLocalVideoPath(for: videoId)
            
            do {
                // Remover arquivo existente se houver
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                
                // Mover arquivo para destino
                try fileManager.moveItem(at: tempURL, to: destinationURL)
                print("Vídeo salvo localmente em: \(destinationURL.path)")
                completion(true)
            } catch {
                print("[ERRO] Erro ao salvar vídeo: \(error)")
                completion(false)
            }
        }
        
        task.resume()
    }
    
    private func getLocalVideoPath(for videoId: String) -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("\(videoId).mp4")
    }
    
    private func getLocalThumbnailPath(for videoId: String) -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("\(videoId).jpg")
    }
    
    // Função auxiliar para validar URLs do YouTube
    private func isValidYouTubeURL(_ urlString: String) -> Bool {
        let youtubeRegex = "^(https?://)?(www\\.)?(youtube\\.com|youtu\\.be)/.+$"
        let youtubeTest = NSPredicate(format:"SELF MATCHES %@", youtubeRegex)
        return youtubeTest.evaluate(with: urlString)
    }
    
    // Método para baixar a thumbnail se disponível
    func downloadThumbnail(from urlString: String, videoId: String, completion: @escaping (Bool) -> Void) {
        print("Iniciando download da thumbnail de: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("[ERRO] URL inválida")
            completion(false)
            return
        }
        
        let task = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("[ERRO] Erro ao baixar thumbnail: \(error)")
                completion(false)
                return
            }
            
            guard let tempURL = tempURL else {
                print("[ERRO] URL temporária inválida")
                completion(false)
                return
            }
            
            let fileManager = FileManager.default
            let destinationURL = self.getLocalThumbnailPath(for: videoId)
            
            do {
                // Remover arquivo existente se houver
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                
                // Mover arquivo para destino
                try fileManager.moveItem(at: tempURL, to: destinationURL)
                print("Thumbnail salva localmente em: \(destinationURL.path)")
                completion(true)
            } catch {
                print("[ERRO] Erro ao salvar thumbnail: \(error)")
                completion(false)
            }
        }
        
        task.resume()
    }
    
    // Método para iniciar a reprodução de um vídeo a partir do índice atual
    func playCurrentVideo() {
        guard currentIndex < videos.count else { return }
        
        // Baixe localmente o arquivo do vídeo usando URLSessionDownloadTask e salve em Document Directory
        let video = videos[currentIndex]
        guard let downloadURL = URL(string: baseURL + video.remoteURL) else {
            print("URL inválida: \(baseURL + video.remoteURL)")
            return
        }
        
        print("Iniciando download do vídeo de: \(downloadURL.absoluteString)")
        
        let task = URLSession.shared.downloadTask(with: downloadURL) { [weak self] tempLocalURL, response, error in
            if let error = error {
                print("Erro no download do vídeo: \(error)")
                DispatchQueue.main.async {
                    self?.onDownloadError?("Erro ao baixar vídeo: \(error.localizedDescription)")
                }
                return
            }
            
            guard let tempLocalURL = tempLocalURL else {
                print("URL temporária inválida")
                return
            }
            
            do {
                let documentsDirectory = try FileManager.default.url(for: .documentDirectory,
                                                                  in: .userDomainMask,
                                                                  appropriateFor: nil,
                                                                  create: true)
                let fileName = "\(video.id)_\(UUID().uuidString).mp4"
                let localURL = documentsDirectory.appendingPathComponent(fileName)
                
                // Remove arquivo existente se houver
                if FileManager.default.fileExists(atPath: localURL.path) {
                    try FileManager.default.removeItem(at: localURL)
                }
                
                try FileManager.default.moveItem(at: tempLocalURL, to: localURL)
                print("Vídeo salvo localmente em: \(localURL.path)")
                
                // Exclui o vídeo do servidor depois de baixar localmente
                self?.deleteVideoFromServer(video)
                
                // Atualiza o vídeo com o localURL e inicia a reprodução
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    // Atualiza o URL local no modelo
                    var updatedVideo = self.videos[self.currentIndex]
                    updatedVideo.localURL = localURL
                    self.videos[self.currentIndex] = updatedVideo
                    
                    // Cria o player e inicia reprodução
                    let player = AVPlayer(url: localURL)
                    self.player = player
                    
                    // Configura o playerViewController para Picture-in-Picture
                    let playerViewController = AVPlayerViewController()
                    playerViewController.player = player
                    self.playerViewController = playerViewController
                    
                    // Ativa o modo PiP se disponível
                    if AVPictureInPictureController.isPictureInPictureSupported() {
                        playerViewController.allowsPictureInPicturePlayback = true
                    }
                    
                    // Notifica que podemos apresentar o player
                    NotificationCenter.default.post(name: Notification.Name("ReadyToPlayVideo"), object: self)
                    
                    player.play()
                }
            } catch {
                print("Erro ao salvar vídeo localmente: \(error)")
                DispatchQueue.main.async {
                    self?.onDownloadError?("Erro ao salvar vídeo: \(error.localizedDescription)")
                }
            }
        }
        task.resume()
    }
    
    // Remove vídeo do servidor depois de baixado
    private func deleteVideoFromServer(_ video: Video) {
        // Extrai o nome do arquivo da URL
        let urlComponents = video.remoteURL.components(separatedBy: "/")
        guard let fileName = urlComponents.last else { return }
        
        guard let deleteURL = URL(string: "\(baseURL)/videos/\(fileName)") else { return }
        
        var request = URLRequest(url: deleteURL)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("Erro ao excluir vídeo do servidor: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("Vídeo excluído com sucesso do servidor")
                } else {
                    print("Erro ao excluir vídeo. Status: \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
    
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
}
