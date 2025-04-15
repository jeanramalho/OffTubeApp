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
        tf.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        tf.textColor = .white
        return tf
    }()
    
    // Botão para iniciar o download
    let downloadButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Baixar", for: .normal)
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = .neonBlue
        btn.layer.cornerRadius = 8
        return btn
    }()
    
    // Activity Indicator para feedback do download
    let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .large)
        ai.color = .neonBlue
        ai.translatesAutoresizingMaskIntoConstraints = false
        ai.hidesWhenStopped = true
        return ai
    }()
    
    // TableView para exibir vídeos baixados
    let tableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .darkBackground
        tv.separatorStyle = .none
        return tv
    }()
    
    // Botões de controle – maiores
    let previousButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("◀️", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 45)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitleColor(.neonBlue, for: .normal)
        return btn
    }()
    
    let playPauseButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("⏯️", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 60)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitleColor(.neonBlue, for: .normal)
        return btn
    }()
    
    let nextButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("▶️", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 45)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitleColor(.neonBlue, for: .normal)
        return btn
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .darkBackground
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) não implementado")
    }
    
    private func setupViews() {
        addSubview(urlTextField)
        addSubview(downloadButton)
        addSubview(activityIndicator)
        addSubview(tableView)
        addSubview(previousButton)
        addSubview(playPauseButton)
        addSubview(nextButton)
        
        NSLayoutConstraint.activate([
            // URL TextField no topo
            urlTextField.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            urlTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            urlTextField.trailingAnchor.constraint(equalTo: downloadButton.leadingAnchor, constant: -8),
            urlTextField.heightAnchor.constraint(equalToConstant: 45),
            
            // Botão de download à direita
            downloadButton.centerYAnchor.constraint(equalTo: urlTextField.centerYAnchor),
            downloadButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            downloadButton.widthAnchor.constraint(equalToConstant: 120),
            downloadButton.heightAnchor.constraint(equalToConstant: 45),
            
            // Activity Indicator centralizado no download button
            activityIndicator.centerXAnchor.constraint(equalTo: downloadButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: downloadButton.centerYAnchor),
            
            // TableView abaixo do textField
            tableView.topAnchor.constraint(equalTo: urlTextField.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: previousButton.topAnchor, constant: -16),
            
            // Botões de controle na parte inferior
            playPauseButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            playPauseButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16),
            playPauseButton.widthAnchor.constraint(equalToConstant: 100),
            playPauseButton.heightAnchor.constraint(equalToConstant: 100),
            
            previousButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            previousButton.trailingAnchor.constraint(equalTo: playPauseButton.leadingAnchor, constant: -40),
            previousButton.widthAnchor.constraint(equalToConstant: 90),
            previousButton.heightAnchor.constraint(equalToConstant: 90),
            
            nextButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            nextButton.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 40),
            nextButton.widthAnchor.constraint(equalToConstant: 90),
            nextButton.heightAnchor.constraint(equalToConstant: 90)
        ])
    }
}
