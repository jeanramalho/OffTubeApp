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
    
    // Activity Indicator para indicar o download
    let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .large)
        ai.color = .neonBlue
        ai.translatesAutoresizingMaskIntoConstraints = false
        ai.hidesWhenStopped = true
        return ai
    }()
    
    // TableView para listar os vídeos baixados
    let tableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .darkBackground
        return tv
    }()
    
    // Botões de controle – aumentados
    let previousButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("◀️", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 40)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitleColor(.neonBlue, for: .normal)
        return btn
    }()
    
    let playPauseButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("⏯️", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 50)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitleColor(.neonBlue, for: .normal)
        return btn
    }()
    
    let nextButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("▶️", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 40)
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
        fatalError("init(coder:) has not been implementado")
    }
    
    private func setupViews() {
        addSubview(urlTextField)
        addSubview(downloadButton)
        addSubview(activityIndicator)
        addSubview(tableView)
        addSubview(previousButton)
        addSubview(playPauseButton)
        addSubview(nextButton)
        
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
            
            // Activity indicator centralizado sobre o botão (opcional)
            activityIndicator.centerXAnchor.constraint(equalTo: downloadButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: downloadButton.centerYAnchor),
            
            // TableView abaixo do text field
            tableView.topAnchor.constraint(equalTo: urlTextField.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: previousButton.topAnchor, constant: -16),
            
            // Botões de controle na parte inferior
            playPauseButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            playPauseButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16),
            playPauseButton.widthAnchor.constraint(equalToConstant: 90),
            playPauseButton.heightAnchor.constraint(equalToConstant: 90),
            
            previousButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            previousButton.trailingAnchor.constraint(equalTo: playPauseButton.leadingAnchor, constant: -40),
            previousButton.widthAnchor.constraint(equalToConstant: 80),
            previousButton.heightAnchor.constraint(equalToConstant: 80),
            
            nextButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor),
            nextButton.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 40),
            nextButton.widthAnchor.constraint(equalToConstant: 80),
            nextButton.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
}
