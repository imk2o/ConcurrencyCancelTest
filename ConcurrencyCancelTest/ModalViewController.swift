//
//  ModalViewController.swift
//  ConcurrencyCancelTest
//
//  Created by k2o on 2022/04/29.
//

import UIKit
import Combine

class ModalViewController: UIViewController {

    private var presenter: ModalPresenter!
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter = ModalPresenter()
        bind()
    }
    
    @IBAction func echo(_ sender: Any) {
        presenter.echo("ECHO")
    }
    
    @IBAction func echoCancellable(_ sender: Any) {
        presenter.echoCancellable("ECHO(C)")
    }

    private func bind() {
        presenter.$echoBack
            .compactMap { $0 }
            .sink { [unowned self] in
                presentAlert(message: $0)
            }
            .store(in: &cancellables)
    }
    
    private func presentAlert(title: String? = nil, message: String? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(alert, animated: true)
    }
}

@MainActor
final class ModalPresenter {

    private var tasks: [Task<Void, Never>] = []
    
    @Published private(set) var echoBack: String? {
        didSet { print("echoBack: \(echoBack ?? "nil")")}
    }
    
    deinit {
        print("deinit presenter")
        tasks.forEach { $0.cancel() }
    }

    func echo(_ string: String) {
        tasks.append(Task { [unowned self] in
            do {
                // 以下の書き方だと、[unowned self]でもキャプチャされてしまう？
                // echoBack = try await EchoService.shared.echo(string)
                let result = try await EchoService.shared.echo(string)
                // エコーバック前にモーダルを閉じてしまうと、以下でクラッシュする
                echoBack = result
            } catch {
                guard !Task.isCancelled else {
                    print("Task cancelled")
                    return
                }
                dump(error)
            }
        })
    }
    
    func echoCancellable(_ string: String) {
        tasks.append(Task { [unowned self] in
            do {
                // 以下の書き方だと、[unowned self]でもキャプチャされてしまう？
                // echoBack = try await EchoService.shared.echoCancellable(string)
                let result = try await EchoService.shared.echoCancellable(string)
                // エコーバック前にモーダルを閉じても、キャンセルがスローされるので以下に到達しない
                echoBack = result
            } catch {
                guard !Task.isCancelled else {
                    print("Task cancelled")
                    return
                }
                dump(error)
            }
        })
    }
}
