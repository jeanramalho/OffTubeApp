//
//  Video.swift
//  OffTubeApp
//
//  Created by Jean Ramalho on 11/04/25.
//
import Foundation

/// Representa um vídeo baixado ou disponível para download
struct Video {
    let id: String             // ID único do vídeo, geralmente retornado como "resourceId" pela API
    let title: String          // Nome do vídeo. Vem do campo "name" no JSON retornado
    let remoteURL: String      // URL direta para o arquivo de vídeo (ex: https://.../video.mp4)
    let thumbnailURL: String?  // URL da thumbnail (pode vir da API ou ser baixada separadamente)
    let duration: Int          // Duração do vídeo em segundos (ainda não é retornado pela API atual)
    var localURL: URL?         // Caminho local após o vídeo ser baixado, usado para reprodução offline

    /// Retorna a duração formatada como "MM:SS"
    /// Mesmo que a duração esteja zerada (por falta de info da API), ainda formata como "00:00"
    var formattedDuration: String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}


