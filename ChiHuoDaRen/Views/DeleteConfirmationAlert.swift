import SwiftUI

#if canImport(UIKit)
import UIKit

struct DeleteConfirmationAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let onConfirm: () -> Void

    func body(content: Content) -> some View {
        content
            .background(
                DeleteConfirmationAlertPresenter(
                    isPresented: $isPresented,
                    onConfirm: onConfirm
                )
                .frame(width: 0, height: 0)
            )
    }
}

private struct DeleteConfirmationAlertPresenter: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onConfirm: () -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ viewController: UIViewController, context: Context) {
        guard isPresented, viewController.presentedViewController == nil else { return }

        let alert = UIAlertController(
            title: DeleteConfirmationPolicy.title,
            message: DeleteConfirmationPolicy.message,
            preferredStyle: .alert
        )
        alert.view.tintColor = .systemBlue
        alert.addAction(UIAlertAction(title: DeleteConfirmationPolicy.cancelButtonTitle, style: .cancel) { _ in
            isPresented = false
        })
        alert.addAction(UIAlertAction(title: DeleteConfirmationPolicy.confirmButtonTitle, style: .destructive) { _ in
            isPresented = false
            onConfirm()
        })

        DispatchQueue.main.async {
            guard viewController.presentedViewController == nil else { return }
            viewController.present(alert, animated: true)
        }
    }
}

extension View {
    func deleteConfirmationAlert(isPresented: Binding<Bool>, onConfirm: @escaping () -> Void) -> some View {
        modifier(DeleteConfirmationAlertModifier(isPresented: isPresented, onConfirm: onConfirm))
    }
}
#endif
