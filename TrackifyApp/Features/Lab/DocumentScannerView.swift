import SwiftUI
import VisionKit

struct DocumentScannerView: UIViewControllerRepresentable {
    var onCapture: ([String]) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> ScanContainerVC {
        ScanContainerVC(onCapture: onCapture, onCancel: onCancel)
    }

    func updateUIViewController(_ uiViewController: ScanContainerVC, context: Context) {}
    func makeCoordinator() -> Void {}
}

// MARK: - Container view controller

final class ScanContainerVC: UIViewController, DataScannerViewControllerDelegate {
    var onCapture: ([String]) -> Void
    var onCancel: () -> Void
    private var scanner: DataScannerViewController?
    private var allRecognized: [String] = []

    private let accentColor = UIColor(Color(Palette.accentLime))

    init(onCapture: @escaping ([String]) -> Void, onCancel: @escaping () -> Void) {
        self.onCapture = onCapture
        self.onCancel = onCancel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        guard DataScannerViewController.isSupported,
              DataScannerViewController.isAvailable else {
            showUnsupportedUI()
            return
        }

        let sc = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .accurate,
            isHighlightingEnabled: true
        )
        sc.delegate = self
        addChild(sc)
        view.addSubview(sc.view)
        sc.view.frame = view.bounds
        sc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sc.didMove(toParent: self)
        scanner = sc

        try? sc.startScanning()

        addOverlayButtons()
    }

    private func addOverlayButtons() {
        // Cancel top-left
        let cancelBtn = UIButton(type: .system)
        cancelBtn.setTitle("Abbrechen", for: .normal)
        cancelBtn.setTitleColor(.white, for: .normal)
        cancelBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        cancelBtn.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        view.addSubview(cancelBtn)
        cancelBtn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cancelBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
        ])

        // Capture bottom center
        let captureBtn = UIButton(type: .system)
        captureBtn.setTitle("Scannen", for: .normal)
        captureBtn.setTitleColor(.black, for: .normal)
        captureBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        captureBtn.backgroundColor = accentColor
        captureBtn.layer.cornerRadius = 28
        captureBtn.addTarget(self, action: #selector(didTapCapture), for: .touchUpInside)
        view.addSubview(captureBtn)
        captureBtn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            captureBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            captureBtn.widthAnchor.constraint(equalToConstant: 160),
            captureBtn.heightAnchor.constraint(equalToConstant: 56),
        ])

        // Hint label
        let hint = UILabel()
        hint.text = "Befund auf Kamera ausrichten"
        hint.textColor = UIColor.white.withAlphaComponent(0.7)
        hint.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        hint.textAlignment = .center
        view.addSubview(hint)
        hint.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hint.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hint.bottomAnchor.constraint(equalTo: captureBtn.topAnchor, constant: -12),
        ])
    }

    private func showUnsupportedUI() {
        let label = UILabel()
        label.text = "Kamera-Scanner nicht verfügbar\n(Simulator oder nicht unterstütztes Gerät)"
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 15)
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
        ])

        let closeBtn = UIButton(type: .system)
        closeBtn.setTitle("Schließen", for: .normal)
        closeBtn.setTitleColor(accentColor, for: .normal)
        closeBtn.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        view.addSubview(closeBtn)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            closeBtn.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 24),
        ])
    }

    @objc private func didTapCapture() {
        scanner?.stopScanning()
        onCapture(allRecognized)
    }

    @objc private func didTapCancel() {
        scanner?.stopScanning()
        onCancel()
    }

    // MARK: - DataScannerViewControllerDelegate

    func dataScanner(_ dataScanner: DataScannerViewController,
                     didAdd addedItems: [RecognizedItem],
                     allItems: [RecognizedItem]) {
        allRecognized = allItems.compactMap {
            if case .text(let t) = $0 { return t.transcript }
            return nil
        }
    }
}
