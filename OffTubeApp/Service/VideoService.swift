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
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
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
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }

            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                   let first = jsonArray.first {
                    let jsonData = try JSONSerialization.data(withJSONObject: first)
                    let result = try JSONDecoder().decode(VideoResponse.self, from: jsonData)
                    completion(.success(result))
                } else {
                    completion(.failure(NSError(domain: "Invalid response format", code: 0)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

