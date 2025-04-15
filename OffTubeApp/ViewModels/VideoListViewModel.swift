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
            DispatchQueue.main.async {
                switch result {
                case .success(let videoResponse):
                    print("[DEBUG] Resposta da API recebida com sucesso! ID: \(videoResponse.resourceId)")
                    
                    // Filtrar para encontrar o melhor vídeo com base na qualidade
                    var selectedVideo: VideoDownloadLink?
                    var bestMatchQuality = 0
                    let targetQuality = 720 // Qualidade preferida
                    
                    // Primeiro, tente encontrar exatamente 720p
                    selectedVideo = videoResponse.urls.first(where: { $0.quality == "720" })
                    
                    // Se não encontrou 720p, procure a melhor opção
                    if selectedVideo == nil {
                        for videoLink in videoResponse.urls {
                            if let quality = Int(videoLink.quality) {
                                // Preferência: qualidade mais próxima de 720p para baixo
                                if quality < targetQuality && quality > bestMatchQuality {
                                    bestMatchQuality = quality
                                    selectedVideo = videoLink
                                }
                                // Se não tiver nada abaixo de 720p, pegue a menor qualidade acima
                                else if quality > targetQuality && (selectedVideo == nil || Int(selectedVideo!.quality) ?? 0 > quality) {
                                    selectedVideo = videoLink
                                }
                            }
                        }
                    }
                    
                    // Se ainda não encontrou nada, pegue o primeiro disponível
                    if selectedVideo == nil && !videoResponse.urls.isEmpty {
                        selectedVideo = videoResponse.urls.first
                    }
                    
                    // Verifica se encontrou um vídeo selecionado
                    if let selected = selectedVideo {
                        let fullDownloadURL: String
                        if selected.url.hasPrefix("http") {
                            fullDownloadURL = selected.url
                        } else {
                            // Adiciona o host base se for uma URL relativa
                            fullDownloadURL = "https://youtube-quick-video-downloader-free-api-downlaod-all-video.p.rapidapi.com\(selected.url)"
                        }
                        
                        print("[DEBUG] Video selecionado: \(selected.name) - Qualidade: \(selected.quality)")
                        print("[DEBUG] URL do download: \(fullDownloadURL)")
                        
                        // Cria o objeto Video com os dados recebidos
                        let video = Video(
                            id: videoResponse.resourceId,
                            title: selected.name,
                            remoteURL: fullDownloadURL,
                            thumbnailURL: nil,
                            duration: 0,
                            localURL: nil
                        )
                        
                        // Insere o vídeo na lista e notifica UI
                        self?.videos.insert(video, at: 0)
                        self?.onVideosUpdated?()
                        completion(true)
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
