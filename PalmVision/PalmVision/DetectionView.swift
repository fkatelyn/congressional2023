//
//  DetectionView.swift
//  PalmVision
//
//  Inspired by: https://github.com/npna/CoreMLPlayer
//  Modified by Katelyn Fritz on 10/25/23.
//
import SwiftUI
import Vision


struct DetectionRect: View {
    @State private var isPresented = false
    let obj: Observation
    let drawingRect: CGRect
    
    var body: some View {
        Group {
            rectangle
            //objectLabel(drawingRect: drawingRect, object: obj)
        }
        .onTapGesture {
            isPresented = true
        }
    }
    
    var rectangle: some View {
        Rectangle()
            .stroke(ObjectLabel.from(observation: obj).color, lineWidth: borderWidth)
            .background(Color.clear)
            .frame(width: drawingRect.width, height: drawingRect.height)
            .offset(x: drawingRect.origin.x, y: drawingRect.origin.y)
    }
    
    let borderColor: Color = .red
    let borderWidth: Double = 2
    let labelWrap: Bool = true
    let labelBackgroundColor: Color = .red
    let labelTextColor: Color = .white
    let labelFontSize: Double = 13
    let labelMinFontScale: Double = 0.4
    let confidenceDisplayed: Bool = false
    
    
    func objectLabel(drawingRect: CGRect, object: Observation) -> some View {
        ZStack {
            let labelExtraHeight = 3.0 // In addition to font size
            let label = confidenceDisplayed ? "\(object.label) (\(object.confidence))" : "\(object.label)"
            VStack(alignment: .leading) {
                Text(label)
                    .font(.system(size: labelFontSize))
                    .foregroundColor(labelTextColor)
                    .lineLimit(1)
                    .padding(.horizontal, 2)
                    .minimumScaleFactor(labelWrap ? labelMinFontScale : 1)
                    .frame(height: labelFontSize + labelExtraHeight)
                    //.background(labelBackgroundColor)
                    .background(object.getColor())
            }
            .frame(width: drawingRect.width + borderWidth, height: drawingRect.height, alignment:.topLeading)
            .offset(x: drawingRect.origin.x - (borderWidth / 2), y: drawingRect.origin.y - (13.0 + (borderWidth / 2) + labelExtraHeight))
        }
    }
}


struct DetectionView: View {
    @State var selectedId: UUID?
    let detectedObjects: [Observation]
    var videoSize: CGSize?
    
    init(_ detectedObjects: [Observation], videoSize: CGSize? = nil) {
        self.detectedObjects = detectedObjects
        if let videoWidth = videoSize?.width, videoWidth > 10 {
            self.videoSize = videoSize
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            if let videoSize, let videoRect = getVideoRect(geometrySize: geometry.size, videoSize: videoSize) {
                ZStack {
                    VStack { EmptyView() }
                        .frame(width: videoRect.width, height: videoRect.height)
                        .offset(x: videoRect.origin.x, y: videoRect.origin.y)
                        .overlay {
                            GeometryReader { videoGeometry in
                                forEachBB(detectedObjects: detectedObjects, geometry: videoGeometry)
                            }
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                forEachBB(detectedObjects: detectedObjects, geometry: geometry)
            }
        }
    }
    
    func getVideoRect(geometrySize: CGSize, videoSize: CGSize) -> CGRect? {
        var offsetX = 0.0
        var offsetY = 0.0
        var width = geometrySize.width
        var height = geometrySize.height
        let cWidth = videoSize.width * (geometrySize.height / videoSize.height)
        let cHeight = videoSize.height * (geometrySize.width / videoSize.width)
        
        if cHeight < geometrySize.height {
            height = cHeight
            offsetY = (geometrySize.height - height) / 2
        } else {
            width = cWidth
            offsetX = (geometrySize.width - width) / 2
        }
        
        return CGRect(x: offsetX, y: offsetY, width: width, height: height)
    }
    
    func rectForNormalizedRect(normalizedRect: CGRect, width: Int, height: Int, geometry: GeometryProxy) -> CGRect {
        let rect = VNImageRectForNormalizedRect(normalizedRect, width, height)
        let cgRect = CGRect(x: rect.origin.x, y: (geometry.size.height - rect.origin.y - rect.size.height), width: rect.size.width, height: rect.size.height)
        return cgRect
        
        //let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -CGFloat(height))
        //return VNImageRectForNormalizedRect(normalizedRect, width, height).applying(transform)
    }
    func prepareObjectForSwiftUI(object: Observation, geometry: GeometryProxy) -> CGRect {
        let objectRect = CGRect(x: object.boundingBox.origin.x,
                                y: object.boundingBox.origin.y,
                                width: object.boundingBox.width,
                                height: object.boundingBox.height)
        
        return rectForNormalizedRect(normalizedRect: objectRect, width: Int(geometry.size.width), height: Int(geometry.size.height), geometry: geometry)
    }
    
    func forEachBB(detectedObjects: [Observation], geometry: GeometryProxy) -> some View {
        ForEach(detectedObjects) { obj in
            let confidence = Double(obj.confidence)
            let drawingRect = prepareObjectForSwiftUI(object: obj, geometry: geometry)
            DetectionRect(obj: obj, drawingRect: drawingRect)
        }
    }
}

