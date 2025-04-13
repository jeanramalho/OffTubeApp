//
//  HomeViewController.swift
//  OffTubeApp
//
//  Created by Jean Ramalho on 11/04/25.
//
import UIKit
import AVFoundation
import AVKit

class HomeViewController: UIViewController {
    
    private let mainView = HomeView()
    private let viewModel: VideoListViewModel
    
    // Injeção do ViewModel
    init(viewModel: VideoListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) não implementado")
    }
    
    override func loadView() {
        view = mainView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "OffTube"
        navigationController?.navigationBar.barTintColor = .darkBackground
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.neonBlue,
            .font: UIFont.boldSystemFont(ofSize: 20)
        ]
        view.backgroundColor = .darkBackground
        
        // Registrar célula personalizada para a tableView
        mainView.tableView.register(VideoTableViewCell.self, forCellReuseIdentifier: VideoTableViewCell.reuseIdentifier)
        
        // Configurar TableView
        mainView.tableView.dataSource = self
        mainView.tableView.delegate = self
        mainView.tableView.rowHeight = 80
        
        // Configurar ações dos botões
        mainView.downloadButton.addTarget(self, action: #selector(downloadButtonTapped), for: .touchUpInside)
        mainView.playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
        mainView.nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        mainView.previousButton.addTarget(self, action: #selector(previousTapped), for: .touchUpInside)
        
        // Callbacks do ViewModel para atualizar a UI
        viewModel.onVideosUpdated = { [weak self] in
            self?.mainView.tableView.reloadData()
        }
        viewModel.onDownloadError = { [weak self] errorMsg in
            print("[ERRO] \(errorMsg)")
            
            // Mostrar alerta de erro
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Erro", message: errorMsg, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
        }
        
        // Observar notificação de vídeo pronto para reprodução
        NotificationCenter.default.addObserver(self, selector: #selector(videoReadyToPlay), name: Notification.Name("ReadyToPlayVideo"), object: nil)
        
        // Configurar sessão de áudio para permitir reprodução em background
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay, .mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Erro ao configurar AVAudioSession: \(error)")
        }
    }
    
    @objc private func downloadButtonTapped() {
        guard let urlText = mainView.urlTextField.text, !urlText.isEmpty else {
            let alert = UIAlertController(title: "URL vazia", message: "Por favor, insira uma URL do YouTube válida", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // Verifica se a URL é do YouTube
        guard urlText.contains("youtube.com") || urlText.contains("youtu.be") else {
            let alert = UIAlertController(title: "URL inválida", message: "Por favor, insira uma URL do YouTube válida", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        print("[DEBUG] Iniciando download para URL: \(urlText)")
        mainView.downloadButton.isEnabled = false
        mainView.activityIndicator.startAnimating()
        
        viewModel.downloadVideo(from: urlText) { [weak self] success in
            DispatchQueue.main.async {
                self?.mainView.downloadButton.isEnabled = true
                self?.mainView.activityIndicator.stopAnimating()
                if success {
                    self?.mainView.urlTextField.text = ""
                    print("[DEBUG] Download concluído com sucesso")
                } else {
                    print("[DEBUG] Download falhou")
                }
            }
        }
    }
    
    @objc private func videoReadyToPlay() {
        // Apresenta o AVPlayerViewController quando o vídeo estiver pronto
        if let playerViewController = viewModel.playerViewController {
            present(playerViewController, animated: true) {
                playerViewController.player?.play()
            }
        }
    }
    
    @objc private func playPauseTapped() {
        if let player = viewModel.player, player.timeControlStatus == .playing {
            viewModel.pausePlayback()
            mainView.playPauseButton.setTitle("▶️", for: .normal)
        } else {
            viewModel.resumePlayback()
            mainView.playPauseButton.setTitle("⏸️", for: .normal)
        }
    }
    
    @objc private func nextTapped() {
        viewModel.nextVideo()
    }
    
    @objc private func previousTapped() {
        viewModel.previousVideo()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         return viewModel.videos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: VideoTableViewCell.reuseIdentifier, for: indexPath) as? VideoTableViewCell else {
            return UITableViewCell()
        }
        
        let video = viewModel.videos[indexPath.row]
        cell.configure(with: video)
        
        // Carregar thumbnail
        viewModel.downloadThumbnail(for: video) { image in
            // Verifica se a célula ainda está visível/válida
            if let visibleCell = tableView.cellForRow(at: indexPath) as? VideoTableViewCell {
                visibleCell.setThumbnail(image)
            }
        }
        
        return cell
    }
    
    // Altura dinâmica para as células
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    // Ao selecionar uma célula, inicia a reprodução do vídeo
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.currentIndex = indexPath.row
        viewModel.playCurrentVideo()
    }
}
