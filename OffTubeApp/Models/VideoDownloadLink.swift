//
//  VideoDownloadLink.swift
//  OffTubeApp
//
//  Created by Jean Ramalho on 15/04/25.
//
struct VideoDownloadLink: Decodable {
    let url: String
    let quality: String
    let `extension`: String
    let sizeText: String?
}
