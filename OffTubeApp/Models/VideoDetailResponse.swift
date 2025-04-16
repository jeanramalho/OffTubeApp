//
//  VideoDetailResponse.swift
//  OffTubeApp
//
//  Created by Jean Ramalho on 15/04/25.
//
struct VideoDetailsResponse: Decodable {
    let id: String
    let title: String
    let thumbnails: [Thumbnail]
    let videos: VideoItems

    private enum CodingKeys: String, CodingKey {
        case id, title, thumbnails, videos
    }
}
