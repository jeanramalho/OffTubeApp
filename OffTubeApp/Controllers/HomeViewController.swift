//
//  HomeViewController.swift
//  OffTubeApp
//
//  Created by Jean Ramalho on 11/04/25.
//
import UIKit
import AVFoundation
import AVKit

/// Tela principal que exibe os vídeos baixados e permite baixar novos
class HomeViewController: UIViewController {
    
    private let mainView = HomeView() // View feita com ViewCode, contém TableView e botões
    private let viewModel: VideoListViewModel // ViewModel que gerencia os dados e lógica

    /// Inicializa o controlador com um ViewModel injetado (padrão MVVM)
    init(viewModel: VideoListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    /// Inicializador exigido pelo sistema (não usado no ViewCode, então marcamos como indisponível)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) não implementado")
    }

    /// Substitui a `view` padrão pela `HomeView` construída via código
    override func loadView() {
        view = mainView
    }

    /// Executado quando a view termina de carregar
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "OffTube"
        view.backgroundColor = .darkBackground // fundo escuro customizado

        // Customiza a Navigation Bar com uma pegada neon/tech
        navigationController?.navigationBar.barTintColor = .darkBackground
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.neonBlue,
            .font: UIFont.boldSystemFont(ofSize: 22)
        ]

        // Configura a TableView
        mainView.tableView.dataSource = self
        mainView.tableView.delegate = self
        mainView.tableView.register(VideoTableViewCell.self, forCellReuseIdentifier: VideoTableViewCell.reuseIdentifier)
        mainView.tableView.rowHeight = 90

        // Conecta ações dos botões aos métodos locais
        mainView.downloadButton.addTarget(self, action: #selector(downloadButtonTapped), for: .touchUpInside)
        mainView.playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
        mainView.nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        mainView.previousButton.addTarget(self, action: #selector(previousTapped), for: .touchUpInside)

        // Define os callbacks do ViewModel: sempre que ele atualizar os vídeos, atualizamos a tabela
        viewModel.onVideosUpdated = { [weak self] in
            DispatchQueue.main.async { // <----- ADICIONE AQUI
                self?.mainView.tableView.reloadData()
            }
        }

        // Callback em caso de erro no download
        viewModel.onDownloadError = { [weak self] errorMsg in
            print("[ERRO] \(errorMsg)")
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Erro ao baixar", message: errorMsg, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
        }
        
        NotificationCenter.default.addObserver(self,
                                                  selector: #selector(presentVideoPlayer),
                                                  name: Notification.Name("ReadyToPlayVideo"),
                                                  object: nil)

        // Permite que o áudio continue tocando com a tela bloqueada ou em segundo plano
        setupAudioSession()
    }

    /// Configura a sessão de áudio para permitir reprodução em background
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.allowAirPlay, .mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Erro ao configurar AVAudioSession: \(error)")
        }
    }
    
    @objc func presentVideoPlayer() {
        if let playerVC = viewModel.playerViewController {
            present(playerVC, animated: true)
        }
    }

    /// Acionado quando o botão de download é tocado
    @objc private func downloadButtonTapped() {
        guard let urlText = mainView.urlTextField.text, !urlText.isEmpty else {
            showAlert(title: "URL vazia", message: "Por favor, insira uma URL do YouTube válida")
            return
        }

        // Valida se a URL é de fato um link do YouTube
        guard urlText.contains("youtube.com") || urlText.contains("youtu.be") else {
            showAlert(title: "URL inválida", message: "Por favor, insira uma URL do YouTube válida")
            return
        }

        print("[DEBUG] Iniciando download para URL: \(urlText)")
        mainView.downloadButton.isEnabled = false
        mainView.activityIndicator.startAnimating()

        // Pede ao ViewModel para iniciar o download
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

    /// Alterna entre play e pause no vídeo atual
    @objc private func playPauseTapped() {
        if let player = viewModel.player, player.timeControlStatus == .playing {
            viewModel.pausePlayback()
            mainView.playPauseButton.setTitle("▶️", for: .normal)
        } else {
            viewModel.resumePlayback()
            mainView.playPauseButton.setTitle("⏸️", for: .normal)
        }
    }

    /// Avança para o próximo vídeo
    @objc private func nextTapped() {
        viewModel.nextVideo()
    }

    /// Volta para o vídeo anterior
    @objc private func previousTapped() {
        viewModel.previousVideo()
    }

    /// Exibe um alerta simples
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
    }
}

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    
    /// Informa à tabela quantos vídeos temos
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.videos.count
    }

    /// Cria e configura uma célula com as informações do vídeo
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: VideoTableViewCell.reuseIdentifier, for: indexPath) as? VideoTableViewCell else {
            return UITableViewCell()
        }

        let video = viewModel.videos[indexPath.row]
        cell.configure(with: video)
        return cell
    }

    /// Ao tocar num vídeo da lista, inicia a reprodução dele
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.currentIndex = indexPath.row
        viewModel.playCurrentVideo()
    }
}
