import SwiftUI
#if os(iOS)
import UIKit

struct CardPrintView: UIViewControllerRepresentable {
    let data: Data
    let finished: () -> Void
    func makeUIViewController(context: Context) -> PrintController { PrintController(data: data, finished: finished) }
    func updateUIViewController(_ controller: PrintController, context: Context) { }

    final class PrintController: UIViewController {
        let data: Data
        let finished: () -> Void
        private var presented = false
        init(data: Data, finished: @escaping () -> Void) {
            self.data = data; self.finished = finished
            super.init(nibName: nil, bundle: nil)
        }
        required init?(coder: NSCoder) { return nil }
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            guard !presented else { return }
            presented = true
            let printer = UIPrintInteractionController.shared
            let info = UIPrintInfo(dictionary: nil)
            info.jobName = "My Funny Valentine"
            info.outputType = .general
            printer.printInfo = info
            printer.printingItem = data
            printer.present(from: view.bounds, in: view, animated: true) { _, _, _ in self.finished() }
        }
    }
}
#elseif os(macOS)
import AppKit
import PDFKit

struct CardPrintView: NSViewRepresentable {
    let data: Data
    let finished: () -> Void
    func makeNSView(context: Context) -> PrintAnchor { PrintAnchor(data: data, finished: finished) }
    func updateNSView(_ view: PrintAnchor, context: Context) { }

    final class PrintAnchor: NSView {
        let data: Data
        let finished: () -> Void
        private var presented = false
        init(data: Data, finished: @escaping () -> Void) {
            self.data = data; self.finished = finished
            super.init(frame: .zero)
        }
        required init?(coder: NSCoder) { return nil }
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard window != nil, !presented else { return }
            presented = true
            DispatchQueue.main.async { [weak self] in
                guard let self,
                      let document = PDFDocument(data: self.data),
                      let info = NSPrintInfo.shared.copy() as? NSPrintInfo,
                      let operation = document.printOperation(for: info, scalingMode: .pageScaleDownToFit, autoRotate: true)
                else { self?.finished(); return }
                operation.run()
                self.finished()
            }
        }
    }
}
#endif
