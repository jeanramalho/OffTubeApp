//
//  VideoTableViewCell.swift
//  OffTubeApp
//
//  Created by Jean Ramalho on 13/04/25.
//
import UIKit

class VideoTableViewCell: UITableViewCell {
    static let reuseIdentifier = "VideoTableViewCell"
    
    // Thumbnail do vídeo
    private let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .darkGray
        imageView.layer.cornerRadius = 6
        return imageView
    }()
    
    // Título do vídeo
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .neonBlue
        label.numberOfLines = 2
        return label
    }()
    
    // Duração do vídeo
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .lightGray
        return label
    }()
    
    // Status do download
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .systemGreen
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .darkBackground
        selectionStyle = .none
        
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(durationLabel)
        contentView.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            // Thumbnail à esquerda
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            thumbnailImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            thumbnailImageView.widthAnchor.constraint(equalTo: thumbnailImageView.heightAnchor, multiplier: 16/9),
            
            // Título à direita do thumbnail
            titleLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            
            // Duração abaixo do título
            durationLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            durationLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            
            // Status à direita da duração
            statusLabel.leadingAnchor.constraint(equalTo: durationLabel.trailingAnchor, constant: 12),
            statusLabel.centerYAnchor.constraint(equalTo: durationLabel.centerYAnchor)
        ])
    }
    
    func configure(with video: Video) {
        titleLabel.text = video.title
        durationLabel.text = video.formattedDuration
        
        // Status baseado na disponibilidade local
        if video.localURL != nil {
            statusLabel.text = "✓ Disponível offline"
            statusLabel.textColor = .systemGreen
        } else {
            statusLabel.text = "⬇️ Baixando..."
            statusLabel.textColor = .systemOrange
        }
        
        // Limpa imagem antiga
        thumbnailImageView.image = nil
        
        // Define placeholder enquanto carrega
        thumbnailImageView.backgroundColor = .darkGray
    }
    
    func setThumbnail(_ image: UIImage?) {
        thumbnailImageView.backgroundColor = image == nil ? .darkGray : .clear
        thumbnailImageView.image = image
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.image = nil
        thumbnailImageView.backgroundColor = .darkGray
        titleLabel.text = nil
        durationLabel.text = nil
        statusLabel.text = nil
    }
}
