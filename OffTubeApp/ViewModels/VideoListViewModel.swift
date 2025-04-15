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

    // Informações da API do RapidAPI
    private let rapidAPIBaseURL = "https://youtube-quick-video-downloader-free-api-downlaod-all-video.p.rapidapi.com"
    private let rapidAPIKey = "e675e37fe3msh28737c9013eca79p1ed09cjsn7b8a4c446ef0"
    private let rapidAPIHost = "youtube-quick-video-downloader-free-api-downlaod-all-video.p.rapidapi.com"

    // Callbacks para atualizar UI ou exibir erro
    var onVideosUpdated: (() -> Void)?
    var onDownloadError: ((String) -> Void)?

    // Método principal para buscar o vídeo da URL fornecida via RapidAPI
    func downloadVideo(from videoURL: String, completion: @escaping (Bool) -> Void) {
        print("[DEBUG] Iniciando download para URL: \(videoURL)")

        // Codifica a URL para uso em query string
        guard let encodedVideoURL = videoURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("[ERRO] Falha ao codificar a URL do vídeo")
            completion(false)
            return
        }

        // Monta o endpoint com a URL codificada
        let endpoint = "\(rapidAPIBaseURL)/videodownload.php?url=\(encodedVideoURL)"
        guard let requestURL = URL(string: endpoint) else {
            print("[ERRO] URL da API RapidAPI inválida: \(endpoint)")
            completion(false)
            return
        }

        // Configura a requisição HTTP com os headers esperados pela RapidAPI
        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.setValue(rapidAPIKey, forHTTPHeaderField: "x-rapidapi-key")
        request.setValue(rapidAPIHost, forHTTPHeaderField: "x-rapidapi-host")
        request.timeoutInterval = 30

        // Inicia a requisição
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                // Tratamento de erro de rede
                if let error = error {
                    print("[ERRO] Erro na requisição RapidAPI: \(error.localizedDescription)")
                    self?.onDownloadError?("Erro na requisição RapidAPI: \(error.localizedDescription)")
                    completion(false)
                    return
                }

                // Verifica se veio algum dado
                guard let data = data else {
                    print("[ERRO] Resposta vazia da API RapidAPI.")
                    self?.onDownloadError?("Resposta vazia da API RapidAPI.")
                    completion(false)
                    return
                }

                do {
                    // Faz o parsing manual da resposta da RapidAPI
                    guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                          let firstItem = json.values.first as? [String: Any],
                          let resourceId = firstItem["resourceId"] as? String,
                          let urlsArray = firstItem["urls"] as? [[String: Any]] else {
                        print("[ERRO] Estrutura de resposta da API RapidAPI inválida.")
                        self?.onDownloadError?("Estrutura de resposta da API RapidAPI inválida.")
                        completion(false)
                        return
                    }

                    // Filtro para escolher o melhor vídeo com base na qualidade
                    var selectedVideo: VideoDownloadLink?
                    var bestMatchQuality = 0
                    var targetQuality = 720 // Qualidade preferida

                    for videoLink in urlsArray {
                        if let qualityString = videoLink["quality"] as? String,
                           let quality = Int(qualityString) {
                            if quality == targetQuality {
                                selectedVideo = VideoDownloadLink(url: videoLink["url"] as? String ?? "",
                                                                  name: videoLink["name"] as? String ?? "",
                                                                  subName: videoLink["subName"] as? String ?? "",
                                                                  extensionType: videoLink["extension"] as? String ?? "",
                                                                  quality: qualityString)
                                break
                            } else if quality < targetQuality && quality > bestMatchQuality {
                                bestMatchQuality = quality
                                selectedVideo = VideoDownloadLink(url: videoLink["url"] as? String ?? "",
                                                                  name: videoLink["name"] as? String ?? "",
                                                                  subName: videoLink["subName"] as? String ?? "",
                                                                  extensionType: videoLink["extension"] as? String ?? "",
                                                                  quality: qualityString)
                            } else if quality > targetQuality && (selectedVideo == nil || quality < bestMatchQuality) {
                                selectedVideo = VideoDownloadLink(url: videoLink["url"] as? String ?? "",
                                                                  name: videoLink["name"] as? String ?? "",
                                                                  subName: videoLink["subName"] as? String ?? "",
                                                                  extensionType: videoLink["extension"] as? String ?? "",
                                                                  quality: qualityString)
                            }
                        }
                    }

                    // Verifique se encontrou um vídeo selecionado
                    if let selectedVideo = selectedVideo {
                        let fullDownloadURL: String
                        if selectedVideo.url.hasPrefix("http") {
                            fullDownloadURL = selectedVideo.url
                        } else {
                            fullDownloadURL = "\(self?.rapidAPIBaseURL ?? "")\(selectedVideo.url)"
                        }

                        print("[DEBUG] Video selecionado: \(selectedVideo.name) - Qualidade: \(selectedVideo.quality)")
                        print("URL do download: \(fullDownloadURL)")

                        // Cria o objeto Video com os dados recebidos
                        let video = Video(
                            id: resourceId,
                            title: selectedVideo.name,
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
                        self?.onDownloadError?("Nenhuma qualidade de vídeo adequada encontrada.")
                        completion(false)
                    }

                } catch {
                    print("[ERRO] Falha ao decodificar a resposta da API RapidAPI: \(error.localizedDescription)")
                    self?.onDownloadError?("Erro ao decodificar resposta: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }.resume()
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
