//
//  SplashViewController.swift
//  OffTubeApp
//
//  Created by Jean Ramalho on 11/04/25.
//
import UIKit

class SplashViewController: UIViewController {
    
    private let logoImageView: UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.contentMode = .scaleAspectFit
        image.image = UIImage(named: "logo")
        image.clipsToBounds = true
        return image
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .darkBackground
        view.addSubview(logoImageView)
        
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logoImageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.2),
        ])
        
        // Transição para Home após 1,5 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            let viewModel = VideoListViewModel()
            let homeVC = HomeViewController(viewModel: viewModel)
            // Substituir a pilha de view controllers para evitar voltar à splash
            self?.navigationController?.setViewControllers([homeVC], animated: true)
        }
    }
}
