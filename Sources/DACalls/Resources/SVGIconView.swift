import SVGKit
import SwiftUI

struct SVGIconView: UIViewRepresentable {
    let svgData: Data

    func makeUIView(context _: Context) -> SVGKFastImageView {
        let svgImage = SVGKImage(data: svgData)
        let imageView = SVGKFastImageView(svgkImage: svgImage)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }

    func updateUIView(_: SVGKFastImageView, context _: Context) {}
}
