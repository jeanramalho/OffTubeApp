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
    private let viewModel = VideoListViewModel()
    
    override func loadView() {
        view = mainView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "OffTube"
        view.backgroundColor = .darkBackground
        
        // Configurar table view
        mainView.tableView.dataSource = self
        mainView.tableView.delegate = self
        mainView.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        // Ações dos botões
        mainView.downloadButton.addTarget(self, action: #selector(downloadButtonTapped), for: .touchUpInside)
        mainView.playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
        mainView.nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        mainView.previousButton.addTarget(self, action: #selector(previousTapped), for: .touchUpInside)
        
        // Callback para atualizar a table view quando a lista mudar
        viewModel.onVideosUpdated = { [weak self] in
            self?.mainView.tableView.reloadData()
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
        guard let urlText = mainView.urlTextField.text, !urlText.isEmpty else { return }
        viewModel.downloadVideo(from: urlText) { success in
            if success {
                // Opcional: limpar o textField
                self.mainView.urlTextField.text = ""
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

         let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
         // Exibe o título do vídeo ou a URL, se o título não estiver disponível
         cell.textLabel?.text = viewModel.videos[indexPath.row].title
         cell.backgroundColor = .darkBackground
         cell.textLabel?.textColor = .white
         return cell
    }
    
    // Ao selecionar um vídeo na lista, inicia a reprodução
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
         viewModel.currentIndex = indexPath.row
         viewModel.playCurrentVideo()
    }
}

