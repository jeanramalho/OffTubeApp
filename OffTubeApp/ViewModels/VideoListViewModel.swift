//
//  VideoListViewModel.swift
//  OffTubeApp
//
//  Created by Jean Ramalho on 11/04/25.
//

import Foundation
import AVFoundation
import AVKit

// ViewModel responsável por gerenciar a lista de vídeos, fazer o download e reprodução
class VideoListViewModel {
    // Lista de vídeos baixados ou em processo de download
    private(set) var videos: [Video] = []

    // Player para reproduzir os vídeos
    var player: AVPlayer?
    var playerViewController: AVPlayerViewController?

    // Índice do vídeo atualmente em reprodução
    var currentIndex: Int = 0

    // Serviço para fazer requisições à API
    private let videoService = VideoService()

    // Callbacks para atualizar UI ou exibir erro
    var onVideosUpdated: (() -> Void)?
    var onDownloadError: ((String) -> Void)?

    // Método principal para buscar o vídeo da URL fornecida via RapidAPI
    func downloadVideo(from videoURL: String, completion: @escaping (Bool) -> Void) {
        print("[DEBUG] Iniciando download para URL: \(videoURL)")

        videoService.fetchDownloadLinks(for: videoURL) { [weak self] result in
            switch result {
            case .success(let videoResponse):
                print("[DEBUG] Resposta da API recebida com sucesso! ID: \(videoResponse.resourceId)")
                
                // Lógica para seleção de qualidade e download...
                if let selectedVideo = self?.selectBestVideo(from: videoResponse.urls) {
                    // Criar objeto Video
                    let video = Video(
                        id: videoResponse.resourceId,
                        title: selectedVideo.name,
                        remoteURL: selectedVideo.url,
                        thumbnailURL: nil,
                        duration: 0,
                        localURL: nil
                    )
                    
                    // Baixar o vídeo
                    self?.downloadActualVideo(video: video) { success in
                        DispatchQueue.main.async {
                            if success {
                                // Adicionar à lista somente após o download bem-sucedido
                                self?.videos.insert(video, at: 0)
                                self?.onVideosUpdated?()
                            }
                            completion(success)
                        }
                    }
                } else {
                    print("[ERRO] Nenhuma qualidade de vídeo adequada encontrada.")
                    self?.onDownloadError?("Nenhuma qualidade de vídeo adequada encontrada.")
                    completion(false)
                }
                
            case .failure(let error):
                print("[ERRO] Falha na API: \(error.localizedDescription)")
                self?.onDownloadError?("Erro na solicitação: \(error.localizedDescription)")
                completion(false)
            }
        }
    }

    // Função auxiliar para selecionar o melhor vídeo
    private func selectBestVideo(from videos: [VideoDownloadLink]) -> VideoDownloadLink? {
        guard !videos.isEmpty else { return nil }
        
        // Primeiro tenta encontrar 720p
        if let video720p = videos.first(where: { $0.quality == "720" }) {
            return video720p
        }
        
        // Se não encontrar 720p, tenta encontrar a qualidade mais próxima
        let targetQuality = 720
        let sortedVideos = videos.compactMap { video -> (VideoDownloadLink, Int)? in
            guard let quality = Int(video.quality) else { return nil }
            return (video, abs(quality - targetQuality))
        }.sorted { $0.1 < $1.1 }
        
        return sortedVideos.first?.0 ?? videos.first
    }

    // Função para baixar o vídeo efetivamente
    private func downloadActualVideo(video: Video, completion: @escaping (Bool) -> Void) {
        guard let remoteURL = URL(string: video.remoteURL) else {
            completion(false)
            return
        }
        
        // Definir local path
        let localPath = getLocalVideoPath(for: video.id)
        
        videoService.downloadVideoFile(from: video.remoteURL, to: localPath) { result in
            switch result {
            case .success(let savedURL):
                print("[DEBUG] Vídeo baixado com sucesso para: \(savedURL.path)")
                
                // Atualizar o video com a URL local
                if let index = self.videos.firstIndex(where: { $0.id == video.id }) {
                    var updatedVideo = self.videos[index]
                    updatedVideo.localURL = savedURL
                    self.videos[index] = updatedVideo
                    self.onVideosUpdated?()
                }
                
                completion(true)
                
            case .failure(let error):
                print("[ERRO] Falha ao baixar vídeo: \(error.localizedDescription)")
                self.onDownloadError?("Erro ao baixar vídeo: \(error.localizedDescription)")
                completion(false)
            }
        }
    }

    // Faz download real do arquivo de vídeo (de uma URL direta)
    private func downloadVideoFile(from urlString: String, videoId: String, completion: @escaping (Bool) -> Void) {
        print("Iniciando download do arquivo de vídeo de: \(urlString)")
        guard let url = URL(string: urlString) else {
            print("[ERRO] URL inválida para o arquivo de vídeo")
            completion(false)
            return
        }

        let task = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, _, error in
            if let error = error {
                print("[ERRO] Erro no download do arquivo de vídeo: \(error)")
                completion(false)
                return
            }
            guard let tempURL = tempURL else {
                print("[ERRO] URL temporária inválida para o arquivo de vídeo")
                completion(false)
                return
            }

            // Caminho local de destino para o vídeo
            let fileManager = FileManager.default
            let destinationURL = self?.getLocalVideoPath(for: videoId) ?? URL(fileURLWithPath: "")

            do {
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                try fileManager.moveItem(at: tempURL, to: destinationURL)
                print("Arquivo de vídeo salvo localmente em: \(destinationURL.path)")
                completion(true)
            } catch {
                print("[ERRO] Erro ao salvar o arquivo de vídeo: \(error)")
                completion(false)
            }
        }
        task.resume()
    }

    // Retorna o caminho local para salvar o vídeo
    private func getLocalVideoPath(for videoId: String) -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("\(videoId).mp4")
    }

    // Retorna o caminho local para salvar a thumbnail
    private func getLocalThumbnailPath(for videoId: String) -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("\(videoId).jpg")
    }

    // Faz download da imagem de thumbnail e salva localmente
    func downloadThumbnail(from urlString: String, videoId: String, completion: @escaping (Bool) -> Void) {
        print("Iniciando download da thumbnail de: \(urlString)")
        guard let url = URL(string: urlString) else {
            print("[ERRO] URL inválida para thumbnail")
            completion(false)
            return
        }

        let task = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, _, error in
            if let error = error {
                print("[ERRO] Erro no download da thumbnail: \(error)")
                completion(false)
                return
            }
            guard let tempURL = tempURL else {
                print("[ERRO] URL temporária inválida para thumbnail")
                completion(false)
                return
            }

            let fileManager = FileManager.default
            let destinationURL = self?.getLocalThumbnailPath(for: videoId) ?? URL(fileURLWithPath: "")

            do {
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
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

    // Inicia reprodução do vídeo atual da lista
    func playCurrentVideo() {
        guard currentIndex < videos.count else { return }
        let video = videos[currentIndex]
        guard let downloadURL = URL(string: video.remoteURL) else {
            print("URL inválida para reprodução: \(video.remoteURL)")
            return
        }

        print("Iniciando download do arquivo para reprodução: \(downloadURL.absoluteString)")
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
                let fileName = "\(video.id)_\(UUID().uuidString).mp4"
                let localURL = documentsDirectory.appendingPathComponent(fileName)

                if FileManager.default.fileExists(atPath: localURL.path) {
                    try FileManager.default.removeItem(at: localURL)
                }

                try FileManager.default.moveItem(at: tempLocalURL, to: localURL)
                print("Vídeo para reprodução salvo localmente em: \(localURL.path)")

                DispatchQueue.main.async {
                    // Atualiza vídeo com URL local salva
                    var updatedVideo = self?.videos[self!.currentIndex]
                    updatedVideo?.localURL = localURL
                    if let updatedVideo = updatedVideo {
                        self?.videos[self!.currentIndex] = updatedVideo
                    }

                    // Configura o player e inicia a reprodução
                    let player = AVPlayer(url: localURL)
                    self?.player = player

                    let playerViewController = AVPlayerViewController()
                    playerViewController.player = player
                    self?.playerViewController = playerViewController

                    if AVPictureInPictureController.isPictureInPictureSupported() {
                        playerViewController.allowsPictureInPicturePlayback = true
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

    // Pausa o player
    func pausePlayback() {
        player?.pause()
    }

    // Retoma reprodução
    func resumePlayback() {
        player?.play()
    }

    // Avança para o próximo vídeo
    func nextVideo() {
        guard currentIndex + 1 < videos.count else { return }
        currentIndex += 1
        playCurrentVideo()
    }

    // Retorna para o vídeo anterior
    func previousVideo() {
        guard currentIndex - 1 >= 0 else { return }
        currentIndex -= 1
        playCurrentVideo()
    }
}
