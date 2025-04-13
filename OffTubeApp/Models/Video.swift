//
//  Video.swift
//  OffTubeApp
//
//  Created by Jean Ramalho on 11/04/25.
//
import Foundation

struct Video {
    let id: String           // ID único do vídeo
    let title: String        // Título do vídeo
    let remoteURL: String    // URL fornecida pela API (ex: "/videos/arquivo.mp4")
    let thumbnailURL: String? // URL da thumbnail do vídeo
    let duration: Int        // Duração em segundos
    var localURL: URL?       // Após baixar o arquivo para o dispositivo, atualiza com o caminho local
    
    // Retorna a duração formatada como "MM:SS"
    var formattedDuration: String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

