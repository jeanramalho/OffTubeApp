//
//  HomeViewController.swift
//  OffTubeApp
//
//  Created by Jean Ramalho on 11/04/25.
//
import UIKit
import AVFoundation

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
        
        // Configurar TableView
        mainView.tableView.dataSource = self
        mainView.tableView.delegate = self
        
        // Configurar ações dos botões
        mainView.downloadButton.addTarget(self, action: #selector(downloadButtonTapped), for: .touchUpInside)
        mainView.playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
        mainView.nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        mainView.previousButton.addTarget(self, action: #selector(previousTapped), for: .touchUpInside)
        
        // Callbacks do ViewModel para atualizar a UI
        viewModel.onVideosUpdated = { [weak self] in
            self?.mainView.tableView.reloadData()
        }
        viewModel.onDownloadError = { errorMsg in
            print("[ERRO] \(errorMsg)")
        }
        
        // Configurar sessão de áudio para permitir reprodução em background
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Erro ao configurar AVAudioSession: \(error)")
        }
    }
    
    @objc private func downloadButtonTapped() {
        guard let urlText = mainView.urlTextField.text, !urlText.isEmpty else {
            print("[DEBUG] URL vazia")
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
    
    @objc private func playPauseTapped() {
        if let player = viewModel.player, player.timeControlStatus == .playing {
            viewModel.pausePlayback()
            mainView.playPauseButton.setTitle("⏸️", for: .normal)
        } else {
            viewModel.resumePlayback()
            mainView.playPauseButton.setTitle("▶️", for: .normal)
        }
    }
    
    @objc private func nextTapped() {
        viewModel.nextVideo()
    }
    
    @objc private func previousTapped() {
        viewModel.previousVideo()
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         return viewModel.videos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

         let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ??
            UITableViewCell(style: .default, reuseIdentifier: "Cell")
         
         // Configurar a célula com tema escuro e texto neon
         cell.textLabel?.text = viewModel.videos[indexPath.row].title
         cell.backgroundColor = .darkBackground
         cell.textLabel?.textColor = .neonBlue
         return cell
    }
    
    // Ao selecionar uma célula, inicia a reprodução do vídeo
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
         viewModel.currentIndex = indexPath.row
         viewModel.playCurrentVideo()
    }
}
