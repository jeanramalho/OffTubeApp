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
        guard let url = URL(string: "\(baseURL)/download") else {
            onDownloadError?("URL da API inválida.")
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let bodyDict = ["url": videoURL]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: bodyDict, options: [])
        } catch {
            onDownloadError?("Erro ao serializar a requisição: \(error.localizedDescription)")
            completion(false)
            return
        }
        
        print("Enviando requisição para \(url.absoluteString) com payload: \(bodyDict)")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Erro na rede: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.onDownloadError?("Erro de conexão: \(error.localizedDescription)")
                    completion(false)
                }
                return
            }
            
            // Verifica o status HTTP da resposta
            if let httpResponse = response as? HTTPURLResponse {
                print("Status HTTP: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode >= 400 {
                    DispatchQueue.main.async {
                        self?.onDownloadError?("Erro HTTP \(httpResponse.statusCode)")
                        completion(false)
                    }
                    return
                }
            }
            
            // Tenta decodificar a resposta para debug
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Resposta da API: \(responseString)")
            }
            
            // Processa a resposta JSON
            guard let data = data else {
                DispatchQueue.main.async {
                    self?.onDownloadError?("Nenhum dado recebido da API")
                    completion(false)
                }
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                // Verifica se há mensagem de erro
                if let errorMsg = json?["error"] as? String {
                    DispatchQueue.main.async {
                        self?.onDownloadError?("Erro da API: \(errorMsg)")
                        completion(false)
                    }
                    return
                }
                
                // Extrai informações do vídeo
                guard let videoPath = json?["url"] as? String,
                      let id = json?["id"] as? String,
                      let title = json?["title"] as? String else {
                    DispatchQueue.main.async {
                        self?.onDownloadError?("Resposta inválida da API")
                        completion(false)
                    }
                    return
                }
                
                // Cria o objeto de vídeo
                let thumbnailURL = json?["thumbnail"] as? String
                let duration = json?["duration"] as? Int ?? 0
                
                let video = Video(
                    id: id,
                    title: title,
                    remoteURL: videoPath,
                    thumbnailURL: thumbnailURL != nil ? "\(self?.baseURL ?? "")\(thumbnailURL!)" : nil,
                    duration: duration,
                    localURL: nil
                )
                
                DispatchQueue.main.async {
                    self?.videos.insert(video, at: 0) // Último no topo
                    self?.onVideosUpdated?()
                    completion(true)
                }
            } catch {
                print("Erro ao processar JSON: \(error)")
                DispatchQueue.main.async {
                    self?.onDownloadError?("Erro ao processar resposta: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }.resume()
    }
    
    // Método para baixar a thumbnail se disponível
    func downloadThumbnail(for video: Video, completion: @escaping (UIImage?) -> Void) {
        guard let thumbnailURLString = video.thumbnailURL,
              let thumbnailURL = URL(string: thumbnailURLString) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: thumbnailURL) { data, _, error in
            if let error = error {
                print("Erro ao baixar thumbnail: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    completion(image)
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
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
