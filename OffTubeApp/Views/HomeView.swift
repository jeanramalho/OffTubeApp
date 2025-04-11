//
//  HomeView.swift
//  OffTubeApp
//
//  Created by Jean Ramalho on 11/04/25.
//
import UIKit

class HomeView: UIView {
    
    // Campo para inserir a URL
    let urlTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Cole a URL do vídeo"
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    // Botão para baixar o vídeo
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
    
    // TableView para listar vídeos
    let tableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    // Controles de reprodução
    let previousButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("◀️", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 30)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    let playPauseButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("⏯️", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 30)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    let nextButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("▶️", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 30)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        backgroundColor = .darkBackground
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(urlTextField)
        addSubview(downloadButton)
        addSubview(tableView)
        addSubview(previousButton)
        addSubview(playPauseButton)
        addSubview(nextButton)
        
        // Layout utilizando Auto Layout
        NSLayoutConstraint.activate([
            // URL field no topo
            urlTextField.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            urlTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            urlTextField.trailingAnchor.constraint(equalTo: downloadButton.leadingAnchor, constant: -8),
            urlTextField.heightAnchor.constraint(equalToConstant: 40),
            
            // Botão de download ao lado direito do textfield
            downloadButton.centerYAnchor.constraint(equalTo: urlTextField.centerYAnchor),
            downloadButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            downloadButton.widthAnchor.constraint(equalToConstant: 100),
            downloadButton.heightAnchor.constraint(equalToConstant: 40),
            
            // TableView para listar vídeos
            tableView.topAnchor.constraint(equalTo: urlTextField.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: previousButton.topAnchor, constant: -16),
            
            // Controles de reprodução na parte inferior
            playPauseButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            playPauseButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16),
            playPauseButton.widthAnchor.constraint(equalToConstant: 60),
            playPauseButton.heightAnchor.constraint(equalToConstant: 60),
            
            previousButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            previousButton.trailingAnchor.constraint(equalTo: playPauseButton.leadingAnchor, constant: -40),
            previousButton.widthAnchor.constraint(equalToConstant: 50),
            previousButton.heightAnchor.constraint(equalToConstant: 50),
            
            nextButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            nextButton.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 40),
            nextButton.widthAnchor.constraint(equalToConstant: 50),
            nextButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
}

