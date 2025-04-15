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
    
    // Inicializador personalizado para lidar com diferentes formatos de resposta
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Tentar decodificar resourceId diretamente
        do {
            resourceId = try container.decode(String.self, forKey: .resourceId)
        } catch {
            // Caso não encontre, usar algum valor padrão ou gerar um ID
            resourceId = UUID().uuidString
            print("[DEBUG] resourceId não encontrado, gerando UUID")
        }
        
        // Tentar decodificar urls
        do {
            urls = try container.decode([VideoDownloadLink].self, forKey: .urls)
        } catch {
            // Se não encontrar, inicializar como array vazio
            urls = []
            print("[DEBUG] urls não encontrado ou tem formato diferente: \(error)")
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case resourceId, urls
    }
}

class VideoService {
    private let apiKey = "e675e37fe3msh28737c9013eca79p1ed09cjsn7b8a4c446ef0"
    private let host = "youtube-quick-video-downloader-free-api-downlaod-all-video.p.rapidapi.com"
    
    // Sessão de download com timeout maior
    private lazy var downloadSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 180.0  // 3 minutos para iniciar a resposta
        config.timeoutIntervalForResource = 600.0 // 10 minutos para conclusão total
        return URLSession(configuration: config)
    }()

    func fetchDownloadLinks(for videoURL: String, completion: @escaping (Result<VideoResponse, Error>) -> Void) {
        // Construir a URL corretamente com parâmetros de consulta
        var components = URLComponents(string: "https://\(host)/videodownload.php")
        components?.queryItems = [URLQueryItem(name: "url", value: videoURL)]
        
        guard let url = components?.url else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: [NSLocalizedDescriptionKey: "Não foi possível construir a URL da API"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")
        request.setValue(host, forHTTPHeaderField: "x-rapidapi-host")
        request.timeoutInterval = 60 // Aumentar timeout para 60 segundos

        print("[DEBUG] Enviando requisição para: \(url.absoluteString)")

        URLSession.shared.dataTask(with: request) { data, response, error in
            // Verificar erro de rede
            if let error = error {
                print("[ERRO] Erro de rede: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            // Verificar código de resposta HTTP
            if let httpResponse = response as? HTTPURLResponse {
                print("[DEBUG] Código de status HTTP: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    let error = NSError(domain: "HTTPError",
                                       code: httpResponse.statusCode,
                                       userInfo: [NSLocalizedDescriptionKey: "Erro HTTP \(httpResponse.statusCode)"])
                    completion(.failure(error))
                    return
                }
            }

            // Verificar se recebemos dados
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0, userInfo: [NSLocalizedDescriptionKey: "Resposta vazia da API"])))
                return
            }

            // Debug: Imprimir resposta bruta
            if let responseString = String(data: data, encoding: .utf8) {
                print("[DEBUG] Resposta bruta da API: \(responseString)")
            }

            do {
                // Primeiro verificar o formato da resposta
                let jsonObject = try JSONSerialization.jsonObject(with: data)
                
                // Verificar se é um array
                if let jsonArray = jsonObject as? [[String: Any]], let first = jsonArray.first {
                    let jsonData = try JSONSerialization.data(withJSONObject: first)
                    let result = try JSONDecoder().decode(VideoResponse.self, from: jsonData)
                    completion(.success(result))
                }
                // Se não for um array, tenta como um objeto único
                else if let jsonDict = jsonObject as? [String: Any] {
                    // Verificar se temos mensagem de erro da API
                    if let errorMessage = jsonDict["message"] as? String {
                        print("[ERRO] Mensagem de erro da API: \(errorMessage)")
                        completion(.failure(NSError(domain: "APIError", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                        return
                    }
                    
                    let jsonData = try JSONSerialization.data(withJSONObject: jsonDict)
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
