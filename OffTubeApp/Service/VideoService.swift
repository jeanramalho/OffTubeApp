//
//  VideoService.swift
//  OffTubeApp
//
//  Created by Jean Ramalho on 15/04/25.
//
import Foundation

class VideoService {
    private let apiKey = "e675e37fe3msh28737c9013eca79p1ed09cjsn7b8a4c446ef0"
    private let host = "youtube-media-downloader.p.rapidapi.com"
    
    private lazy var downloadSession: URLSession = {
         let config = URLSessionConfiguration.default
         config.timeoutIntervalForRequest = 180.0  // 3 minutos
         config.timeoutIntervalForResource = 600.0 // 10 minutos
         return URLSession(configuration: config)
     }()

    func fetchVideoDetails(videoId: String, completion: @escaping (Result<VideoDetailsResponse, Error>) -> Void) {
        let urlString = "https://\(host)/v2/video/details?videoId=\(videoId)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")
        request.setValue(host, forHTTPHeaderField: "x-rapidapi-host")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0, userInfo: nil)))
                return
            }

            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(VideoDetailsResponse.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // Download do arquivo de vídeo com configuração otimizada
    func downloadVideoFile(from urlString: String, to destinationURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: [NSLocalizedDescriptionKey: "URL de download inválida"])))
            return
        }
        
        // Criar uma request para poder adicionar headers se necessário
        var request = URLRequest(url: url)
        request.timeoutInterval = 300.0 // 5 minutos
        
        // Adicionar headers úteis para downloads
        request.addValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        request.addValue("identity", forHTTPHeaderField: "Accept-Encoding")
        
        print("[DEBUG] Iniciando download de: \(urlString)")
        print("[DEBUG] Salvando em: \(destinationURL.path)")
        
        let task = downloadSession.downloadTask(with: request) { tempURL, response, error in
            if let error = error {
                print("[ERRO] Erro no download: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let tempURL = tempURL else {
                completion(.failure(NSError(domain: "Download failed", code: 0, userInfo: [NSLocalizedDescriptionKey: "Falha no download: nenhum arquivo temporário"])))
                return
            }
            
            do {
                // Criar pasta intermediária se necessário
                let directory = destinationURL.deletingLastPathComponent()
                if !FileManager.default.fileExists(atPath: directory.path) {
                    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                }
                
                // Se o arquivo já existe, remova-o
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                
                try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                print("[DEBUG] Download concluído: \(destinationURL.path)")
                completion(.success(destinationURL))
            } catch {
                print("[ERRO] Falha ao salvar arquivo: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    // Método para baixar thumbnail
    func downloadThumbnail(from urlString: String, to destinationURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: [NSLocalizedDescriptionKey: "URL de thumbnail inválida"])))
            return
        }
        
        let task = URLSession.shared.downloadTask(with: url) { tempURL, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let tempURL = tempURL else {
                completion(.failure(NSError(domain: "Download failed", code: 0, userInfo: [NSLocalizedDescriptionKey: "Falha no download da thumbnail"])))
                return
            }
            
            do {
                // Criar pasta intermediária se necessário
                let directory = destinationURL.deletingLastPathComponent()
                if !FileManager.default.fileExists(atPath: directory.path) {
                    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                }
                
                // Se o arquivo já existe, remova-o
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                
                try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                completion(.success(destinationURL))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
