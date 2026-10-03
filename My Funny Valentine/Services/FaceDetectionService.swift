import Foundation
import CoreGraphics
import Vision
import CoreImage

/// Vision requests run on this actor, away from the editor's main actor.
actor FaceDetectionService {
    static let shared = FaceDetectionService()
    private let imageContext = CIContext()
    private init() {}

    func detectFaces(in image: PlatformImage) async throws -> [DetectedFace] {
        guard let cgImage = Self.normalizedCGImage(from: image) else {
            throw FaceDetectionError.invalidImage
        }
        let request = VNDetectFaceRectanglesRequest()
        #if targetEnvironment(simulator)
        try Self.configureSimulatorCPU(request)
        #endif
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        // Synchronous requests have one throwing path, avoiding a double-resumed continuation.
        try handler.perform([request])
        let faces = request.results ?? []
        guard !faces.isEmpty else { return [] }
        let foreground = foregroundImage(from: cgImage, handler: handler)
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)

        return faces.compactMap { observation in
            guard let rect = Self.paddedFaceBounds(observation.boundingBox, imageSize: imageSize),
                  let photoCrop = cgImage.cropping(to: rect) else { return nil }
            let maskedCrop = foreground?.cropping(to: rect)
            let hasMask = maskedCrop.map { Self.hasVisiblePixels($0) } ?? false
            let crop = hasMask ? (maskedCrop ?? photoCrop) : photoCrop
            let faceImage = PlatformGraphics.makeImage(
                from: crop, size: CGSize(width: crop.width, height: crop.height)
            )
            guard let data = PlatformImageUtils.pngData(from: faceImage) else { return nil }
            return DetectedFace(id: UUID(), imageData: data, boundingBox: rect,
                                confidence: observation.confidence, hasForegroundMask: hasMask)
        }
    }

    private func foregroundImage(from image: CGImage, handler: VNImageRequestHandler) -> CGImage? {
        if #available(iOS 17, macOS 14, *) {
            let request = VNGenerateForegroundInstanceMaskRequest()
            do {
                #if targetEnvironment(simulator)
                try Self.configureSimulatorCPU(request)
                #endif
                try handler.perform([request])
                guard let observation = request.results?.first,
                      !observation.allInstances.isEmpty else { return nil }
                // ponytail: all foreground instances share the matte; touching people may remain
                // in one padded crop. Select individual mask instances if that becomes a real problem.
                let buffer = try observation.generateMaskedImage(
                    ofInstances: observation.allInstances, from: handler, croppedToInstancesExtent: false
                )
                let masked = CIImage(cvPixelBuffer: buffer)
                guard masked.extent.width == CGFloat(image.width),
                      masked.extent.height == CGFloat(image.height) else { return nil }
                return imageContext.createCGImage(masked, from: masked.extent)
            } catch {
                // Unsupported hardware/model or segmentation failure keeps a usable photo crop.
                return nil
            }
        }
        return nil
    }

    #if targetEnvironment(simulator)
    private nonisolated static func configureSimulatorCPU(_ request: VNRequest) throws {
        // The Simulator can fail to create GPU/Neural Engine inference contexts.
        // Use only CPU devices that this exact request/revision advertises.
        if #available(iOS 17, *) {
            let stages = try request.supportedComputeStageDevices
            guard stages[.main]?.contains(where: { if case .cpu = $0 { return true }; return false }) == true else {
                throw FaceDetectionError.simulatorCPUUnavailable
            }
            for (stage, devices) in stages {
                if let cpu = devices.first(where: { if case .cpu = $0 { return true }; return false }) {
                    request.setComputeDevice(cpu, for: stage)
                }
            }
        }
    }
    #endif

    /// Normalize camera/Photos orientation before both Vision requests and pixel cropping.
    nonisolated static func normalizedCGImage(from image: PlatformImage) -> CGImage? {
        let maximumDimension: CGFloat = 2048
        guard let source = PlatformGraphics.cgImage(from: image) else { return nil }
        let ratio = min(1, maximumDimension / CGFloat(max(source.width, source.height)))
        guard ratio < 1 else { return source }
        let size = CGSize(width: max(1, floor(CGFloat(source.width) * ratio)),
                          height: max(1, floor(CGFloat(source.height) * ratio)))
        let upright = PlatformGraphics.makeImage(from: source, size: CGSize(width: source.width, height: source.height))
        return PlatformImageUtils.resized(upright, to: size).flatMap { PlatformGraphics.cgImage(from: $0) }
    }

    nonisolated static func paddedFaceBounds(_ box: CGRect, imageSize: CGSize) -> CGRect? {
        guard box.origin.x.isFinite, box.origin.y.isFinite,
              box.width.isFinite, box.height.isFinite, box.width > 0, box.height > 0,
              imageSize.width.isFinite, imageSize.height.isFinite,
              imageSize.width > 0, imageSize.height > 0 else { return nil }
        let face = CGRect(x: box.minX * imageSize.width, y: (1 - box.maxY) * imageSize.height,
                          width: box.width * imageSize.width, height: box.height * imageSize.height)
        let image = CGRect(origin: .zero, size: imageSize)
        let crop = face.insetBy(dx: -face.width * 0.3, dy: -face.height * 0.3).intersection(image)
        guard !crop.isNull, !crop.isEmpty else { return nil }
        return crop.integral.intersection(image)
    }

    private nonisolated static func hasVisiblePixels(_ image: CGImage) -> Bool {
        var pixels = [UInt8](repeating: 0, count: 8 * 8 * 4)
        return pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(data: buffer.baseAddress, width: 8, height: 8,
                                          bitsPerComponent: 8, bytesPerRow: 32,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: 8, height: 8))
            return stride(from: 3, to: buffer.count, by: 4).contains { buffer[$0] > 10 }
        }
    }
}

nonisolated struct DetectedFace: Identifiable, Sendable {
    let id: UUID
    let imageData: Data
    let boundingBox: CGRect
    let confidence: Float
    var hasForegroundMask: Bool = false
}

nonisolated enum FaceDetectionError: LocalizedError {
    case invalidImage
    case noFacesDetected
    #if targetEnvironment(simulator)
    case simulatorCPUUnavailable
    #endif

    var errorDescription: String? {
        switch self {
        case .invalidImage: return "Could not process image."
        case .noFacesDetected: return "No faces were detected in the image."
        #if targetEnvironment(simulator)
        case .simulatorCPUUnavailable: return "Vision does not provide CPU face detection in this Simulator."
        #endif
        }
    }
}
