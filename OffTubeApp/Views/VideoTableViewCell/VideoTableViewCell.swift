//
//  VideoTableViewCell.swift
//  OffTubeApp
//
//  Created by Jean Ramalho on 13/04/25.
//
import UIKit

class VideoTableViewCell: UITableViewCell {
    static let reuseIdentifier = "VideoCell"
    
    private let thumbnailImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.layer.cornerRadius = 8
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = .neonBlue
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let activityIndicator: UIActivityIndicatorView = {
           let ai = UIActivityIndicatorView(style: .medium)
           ai.color = .neonBlue
           ai.translatesAutoresizingMaskIntoConstraints = false
           ai.hidesWhenStopped = true
           return ai
       }()
    
    
    // Configurar a célula com dados do modelo
    func configure(with video: Video, isDownloading: Bool) {
        titleLabel.text = video.title
        
        // Carrega thumbnail local se existir
        let thumbnailURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(video.id).jpg")
        
        if FileManager.default.fileExists(atPath: thumbnailURL.path) {
            thumbnailImageView.image = UIImage(contentsOfFile: thumbnailURL.path)
        } else {
            thumbnailImageView.image = UIImage(systemName: "film")
        }
        
        // Mostra/Esconde o loading
        isDownloading ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .darkBackground
        contentView.backgroundColor = .darkBackground
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) não implementado")
    }
    
    private func setupViews() {
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            thumbnailImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 80),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 60),
            
            titleLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            
            activityIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            activityIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
        ])
    }
}
