//
//  VideoListViewModel.swift
//  OffTubeApp
//
//  Created by Jean Ramalho on 11/04/25.
//
import Foundation
import AVFoundation

class VideoListViewModel {
    private(set) var videos: [Video] = []
    var player: AVPlayer?
    var currentIndex: Int = 0
    
    // URL base da API
    private let baseURL = "https://backend-offtube.onrender.com"
    
    // Callback para atualizar a UI
    var onVideosUpdated: (() -> Void)?
    var onDownloadError: ((String) -> Void)?
    
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
            onDownloadError?("Erro ao serializar a requisição.")
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.onDownloadError?(error.localizedDescription)
                    completion(false)
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let videoPath = json["url"] as? String else {
                    self?.onDownloadError?("Resposta inválida da API.")
                    completion(false)
                    return
                }
                
                // Assume que o título será o mesmo da URL de YouTube (pode melhorar usando outra rota da API)
                let video = Video(title: videoURL, remoteURL: videoPath, localURL: nil)
                self?.videos.insert(video, at: 0) // Último no topo
                self?.onVideosUpdated?()
                completion(true)
            }
        }.resume()
    }
    
    // Método para iniciar a reprodução de um vídeo a partir do índice atual
    func playCurrentVideo() {
        guard currentIndex < videos.count else { return }
        
        // Baixe localmente o arquivo do vídeo usando URLSessionDownloadTask e salve em Document Directory
        let video = videos[currentIndex]
        guard let downloadURL = URL(string: baseURL + video.remoteURL) else { return }
        
        let task = URLSession.shared.downloadTask(with: downloadURL) { [weak self] tempLocalURL, response, error in
            if let error = error {
                print("Erro no download do vídeo: \(error)")
                return
            }
            guard let tempLocalURL = tempLocalURL else { return }
            do {
                let documentsDirectory = try FileManager.default.url(for: .documentDirectory,
                                                                     in: .userDomainMask,
                                                                     appropriateFor: nil,
                                                                     create: true)
                let localURL = documentsDirectory.appendingPathComponent("\(UUID().uuidString).mp4")
                try FileManager.default.moveItem(at: tempLocalURL, to: localURL)
                // Atualize o vídeo com o localURL e inicie a reprodução
                DispatchQueue.main.async {
                    self?.videos[self!.currentIndex].localURL = localURL
                    self?.player = AVPlayer(url: localURL)
                    self?.player?.play()
                }
            } catch {
                print("Erro ao salvar vídeo localmente: \(error)")
            }
        }
        task.resume()
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

