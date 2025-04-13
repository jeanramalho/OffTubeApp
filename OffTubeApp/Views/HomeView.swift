//
//  HomeView.swift
//  OffTubeApp
//
//  Created by Jean Ramalho on 11/04/25.
//
import UIKit

class HomeView: UIView {
    
    // TextField para inserir a URL do vídeo
    let urlTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Cole a URL do vídeo"
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.backgroundColor = .white.withAlphaComponent(0.1)
        tf.textColor = .white
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .none
        tf.keyboardType = .URL
        tf.clearButtonMode = .whileEditing
        return tf
    }()
    
    // Botão de download
    let downloadButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Baixar", for: .normal)
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .neonBlue
        btn.layer.cornerRadius = 8
        return btn
    }()
    
    // Progress View para o download
    let downloadProgressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .bar)
        pv.trackTintColor = .darkGray
        pv.progressTintColor = .neonBlue
        pv.translatesAutoresizingMaskIntoConstraints = false
        pv.isHidden = true
        return pv
    }()
    
    // Container para exibição do vídeo atual (Picture-in-Picture)
    let videoContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        view.clipsToBounds = true
        view.layer.cornerRadius = 8
        return view
    }()
    
    // Progress View para o progresso do vídeo
    let progressView: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .bar)
        pv.trackTintColor = .darkGray
        pv.progressTintColor = .neonBlue
        pv.translatesAutoresizingMaskIntoConstraints = false
        return pv
    }()
    
    // TableView para listar os vídeos baixados
    let tableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .darkBackground
        tv.separatorStyle = .singleLine
        tv.separatorColor = .neonBlue.withAlphaComponent(0.3)
        tv.rowHeight = 80
        return tv
    }()
    
    // Container para os controles de reprodução
    let controlsContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .darkBackground
        view.isHidden = true
        return view
    }()
    
    // Botões de controle
    let previousButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("⏮", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 40)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitleColor(.neonBlue, for: .normal)
        return btn
    }()
    
    let playPauseButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("▶️", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 50)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitleColor(.neonBlue, for: .normal)
        return btn
    }()
    
    let nextButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("⏭", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 40)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitleColor(.neonBlue, for: .normal)
        return btn
    }()
    
    // Activity Indicator para mostrar o progresso do download
    let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .neonBlue
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .darkBackground
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implementado")
    }
    
    private func setupViews() {
        addSubview(urlTextField)
        addSubview(downloadButton)
        addSubview(downloadProgressView)
        addSubview(videoContainerView)
        addSubview(progressView)
        addSubview(tableView)
        addSubview(activityIndicator)
        
        controlsContainerView.addSubview(previousButton)
        controlsContainerView.addSubview(playPauseButton)
        controlsContainerView.addSubview(nextButton)
        addSubview(controlsContainerView)
        
        // Layout utilizando AutoLayout
        NSLayoutConstraint.activate([
            // URL TextField no topo
            urlTextField.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            urlTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            urlTextField.trailingAnchor.constraint(equalTo: downloadButton.leadingAnchor, constant: -8),
            urlTextField.heightAnchor.constraint(equalToConstant: 40),
            
            // Botão de download ao lado direito
            downloadButton.centerYAnchor.constraint(equalTo: urlTextField.centerYAnchor),
            downloadButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            downloadButton.widthAnchor.constraint(equalToConstant: 100),
            downloadButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Progress bar de download abaixo da text field
            downloadProgressView.topAnchor.constraint(equalTo: urlTextField.bottomAnchor, constant: 8),
            downloadProgressView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            downloadProgressView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            downloadProgressView.heightAnchor.constraint(equalToConstant: 4),
            
            // Container do vídeo atual
            videoContainerView.topAnchor.constraint(equalTo: downloadProgressView.bottomAnchor, constant: 16),
            videoContainerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            videoContainerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            videoContainerView.heightAnchor.constraint(equalToConstant: 200),
            
            // Progress bar do vídeo
            progressView.topAnchor.constraint(equalTo: videoContainerView.bottomAnchor, constant: 4),
            progressView.leadingAnchor.constraint(equalTo: videoContainerView.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: videoContainerView.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 4),
            
            // TableView abaixo do player
            tableView.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: controlsContainerView.topAnchor, constant: -16),
            
            // Container de controles
            controlsContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            controlsContainerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            controlsContainerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            controlsContainerView.heightAnchor.constraint(equalToConstant: 80),
            
            // Botões de controle na parte inferior
            playPauseButton.centerXAnchor.constraint(equalTo: controlsContainerView.centerXAnchor),
            playPauseButton.centerYAnchor.constraint(equalTo: controlsContainerView.centerYAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: 90),
            playPauseButton.heightAnchor.constraint(equalToConstant: 90),
            
            previousButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            previousButton.trailingAnchor.constraint(equalTo: playPauseButton.leadingAnchor, constant: -40),
            previousButton.widthAnchor.constraint(equalToConstant: 80),
            previousButton.heightAnchor.constraint(equalToConstant: 80),
            
            nextButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            nextButton.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 40),
            nextButton.widthAnchor.constraint(equalToConstant: 80),
            nextButton.heightAnchor.constraint(equalToConstant: 80),
            
            // Activity Indicator no centro da tela
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}
