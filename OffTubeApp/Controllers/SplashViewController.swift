//
//  SplashViewController.swift
//  OffTubeApp
//
//  Created by Jean Ramalho on 11/04/25.
//
import UIKit

class SplashViewController: UIViewController {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "OffTube"
        label.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        label.textColor = .neonBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .darkBackground
        view.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Transição para Home após 1.5 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            let viewModel = VideoListViewModel()
            let homeVC = HomeViewController(viewModel: viewModel)
            homeVC.modalTransitionStyle = .crossDissolve
            homeVC.modalPresentationStyle = .fullScreen
            self?.navigationController?.setViewControllers([homeVC], animated: true)
        }
    }
}
