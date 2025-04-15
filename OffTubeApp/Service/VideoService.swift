//
//  VideoService.swift
//  OffTubeApp
//
//  Created by Jean Ramalho on 15/04/25.
//
import Foundation

struct VideoDownloadLink: Decodable {
    let url: String
    let name: String
    let subName: String
    let extensionType: String
    let quality: String

    private enum CodingKeys: String, CodingKey {
        case url, name, subName, quality
        case extensionType = "extension"
    }
}

struct VideoResponse: Decodable {
    let resourceId: String
    let urls: [VideoDownloadLink]
}

class VideoService {
    private let apiKey = "e675e37fe3msh28737c9013eca79p1ed09cjsn7b8a4c446ef0"
    private let host = "youtube-quick-video-downloader-free-api-downlaod-all-video.p.rapidapi.com"

    func fetchDownloadLinks(for videoURL: String, completion: @escaping (Result<VideoResponse, Error>) -> Void) {
        guard let encodedURL = videoURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://\(host)/videodownload.php?url=\(encodedURL)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: [NSLocalizedDescriptionKey: "Não foi possível codificar a URL do vídeo"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")
        request.setValue(host, forHTTPHeaderField: "x-rapidapi-host")
        request.timeoutInterval = 30

        print("[DEBUG] Enviando requisição para: \(url.absoluteString)")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0, userInfo: [NSLocalizedDescriptionKey: "Resposta vazia da API"])))
                return
            }

            // Debug: Imprimir resposta bruta
            if let responseString = String(data: data, encoding: .utf8) {
                print("[DEBUG] Resposta bruta da API: \(responseString)")
            }

            do {
                // Primeiro tenta como array (o formato que você mostrou no exemplo)
                if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                   let first = jsonArray.first {
                    let jsonData = try JSONSerialization.data(withJSONObject: first)
                    let result = try JSONDecoder().decode(VideoResponse.self, from: jsonData)
                    completion(.success(result))
                }
                // Se não for um array, tenta como um objeto único
                else if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let jsonData = try JSONSerialization.data(withJSONObject: jsonObject)
                    let result = try JSONDecoder().decode(VideoResponse.self, from: jsonData)
                    completion(.success(result))
                } else {
                    completion(.failure(NSError(domain: "Invalid response format", code: 0, userInfo: [NSLocalizedDescriptionKey: "Formato de resposta inválido"])))
                }
            } catch {
                print("[DEBUG] Erro ao decodificar JSON: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }

    // Para download real do arquivo de vídeo (opcional, se quiser usar)
    func downloadVideoFile(from urlString: String, to destinationURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: [NSLocalizedDescriptionKey: "URL de download inválida"])))
            return
        }
        
        let task = URLSession.shared.downloadTask(with: url) { tempURL, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let tempURL = tempURL else {
                completion(.failure(NSError(domain: "Download failed", code: 0, userInfo: [NSLocalizedDescriptionKey: "Falha no download: nenhum arquivo temporário"])))
                return
            }
            
            do {
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
