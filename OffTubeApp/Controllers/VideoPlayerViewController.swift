//
//  VideoPlayerViewController.swift
//  OffTubeApp
//
//  Created by Jean Ramalho on 13/04/25.
//
import AVFoundation
import AVKit

class VideoPlayerViewController: UIViewController {

    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var video: Video?
    private var pipController: AVPictureInPictureController?

    // Inicializador para receber o vídeo
    init(video: Video) {
        self.video = video
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPlayer()
        setupPictureInPicture()
        setupNotifications()
    }
    
    private func setupPlayer() {
        guard let videoURL = video?.localURL else {
            print("[ERRO] URL do vídeo inválida")
            return
        }
        
        print("[DEBUG] Iniciando player com URL: \(videoURL.path)")
        
        // Verificar se o arquivo existe
        if !FileManager.default.fileExists(atPath: videoURL.path) {
            print("[ERRO] Arquivo de vídeo não encontrado em: \(videoURL.path)")
            return
        }
        
        // Criar AVPlayerItem
        let playerItem = AVPlayerItem(url: videoURL)
        
        // Configurar AVPlayer
        player = AVPlayer(playerItem: playerItem)
        
        // Configurar AVPlayerLayer
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = view.bounds
        playerLayer?.videoGravity = .resizeAspect
        
        if let playerLayer = playerLayer {
            view.layer.addSublayer(playerLayer)
        }
        
        // Iniciar reprodução
        player?.play()
        
        // Configurar observadores
        setupPlayerObservers()
    }
    
    private func setupPictureInPicture() {
        guard let player = player,
              AVPictureInPictureController.isPictureInPictureSupported() else {
            return
        }
        
        pipController = AVPictureInPictureController(playerLayer: playerLayer!)
        pipController?.delegate = self
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    private func setupPlayerObservers() {
        // Observar status do player
        player?.currentItem?.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
        
        // Observar fim do vídeo
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if let status = player?.currentItem?.status {
                switch status {
                case .readyToPlay:
                    print("[DEBUG] Player pronto para reprodução")
                case .failed:
                    print("[ERRO] Falha na reprodução: \(player?.currentItem?.error?.localizedDescription ?? "Erro desconhecido")")
                case .unknown:
                    print("[AVISO] Status do player desconhecido")
                @unknown default:
                    break
                }
            }
        }
    }
    
    @objc private func playerDidFinishPlaying() {
        print("[DEBUG] Vídeo terminou de reproduzir")
        player?.seek(to: .zero)
        player?.play()
    }
    
    @objc private func applicationWillResignActive() {
        player?.pause()
    }
    
    @objc private func applicationDidBecomeActive() {
        player?.play()
    }
    
    deinit {
        player?.currentItem?.removeObserver(self, forKeyPath: "status")
        NotificationCenter.default.removeObserver(self)
    }
}

extension VideoPlayerViewController: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("[DEBUG] Iniciando Picture in Picture")
    }
    
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("[DEBUG] Parando Picture in Picture")
    }
} 
