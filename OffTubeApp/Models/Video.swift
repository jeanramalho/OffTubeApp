//
//  Video.swift
//  OffTubeApp
//
//  Created by Jean Ramalho on 11/04/25.
//
import Foundation

struct Video {
    let title: String
    let remoteURL: String    // URL fornecida pela API (ex: "/videos/arquivo.mp4")
    var localURL: URL?       // Após baixar o arquivo para o dispositivo, atualiza com o caminho local
}

