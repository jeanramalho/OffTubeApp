//
//  Video.swift
//  OffTubeApp
//
//  Created by Jean Ramalho on 11/04/25.
//
import Foundation

/// Representa um vídeo baixado ou disponível para download
struct Video: Codable {
    let id: String             // ID único do vídeo, geralmente retornado como "resourceId" pela API
    let title: String          // Nome do vídeo. Vem do campo "name" no JSON retornado
    let remoteURL: String      // URL direta para o arquivo de vídeo (ex: https://.../video.mp4)
    let thumbnailURL: String?  // URL da thumbnail (pode vir da API ou ser baixada separadamente)
    var localURL: URL?         // Caminho local após o vídeo ser baixado, usado para reprodução offline
}






