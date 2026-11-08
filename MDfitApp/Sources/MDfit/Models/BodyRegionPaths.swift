import SwiftUI

// MARK: - Body Region Path Data
// Exact coordinates from MD Fit web app (painmuscles.js)
// Canvas: 1182 × 1073, Front midpoint: 287, Back midpoint: 911.5

struct BodyRegionPathData {
    // Original canvas dimensions from web
    static let canvasWidth: CGFloat = 1182
    static let canvasHeight: CGFloat = 1073
    static let frontMidX: CGFloat = 287
    static let backMidX: CGFloat = 911.5

    // Front view bounding box (from painmuscles.js MAPS)
    static let frontBox = CGRect(x: 40, y: 0, width: 520, height: 1073)
    // Back view bounding box
    static let backBox = CGRect(x: 600, y: 0, width: 582, height: 1073)

    // MARK: - Region Definition

    struct Region: Identifiable {
        let id: String
        let view: BodyViewSide
        let isPaired: Bool
        let side: RegionSide
        let points: [CGPoint]
        let tracks: [String]

        enum RegionSide {
            case center
            case right
            case left
        }
    }

    enum BodyViewSide {
        case front
        case back
    }

    // MARK: - Front Regions (Right Side - Original Coordinates)

    static let frontRegionsRight: [Region] = [
        // Head/Neck - center (not paired)
        Region(
            id: "f-head",
            view: .front,
            isPaired: false,
            side: .center,
            points: [
                CGPoint(x: 287, y: 0), CGPoint(x: 330, y: 10), CGPoint(x: 348, y: 55),
                CGPoint(x: 340, y: 108), CGPoint(x: 322, y: 140), CGPoint(x: 330, y: 172),
                CGPoint(x: 342, y: 200), CGPoint(x: 287, y: 212), CGPoint(x: 232, y: 200),
                CGPoint(x: 244, y: 172), CGPoint(x: 252, y: 140), CGPoint(x: 234, y: 108),
                CGPoint(x: 226, y: 55), CGPoint(x: 244, y: 10)
            ],
            tracks: ["scalenes", "levator", "scalene-chest"]
        ),
        // Chest - right side
        Region(
            id: "f-chest-r",
            view: .front,
            isPaired: true,
            side: .right,
            points: [
                CGPoint(x: 287, y: 208), CGPoint(x: 240, y: 200), CGPoint(x: 200, y: 206),
                CGPoint(x: 190, y: 236), CGPoint(x: 188, y: 282), CGPoint(x: 192, y: 320),
                CGPoint(x: 200, y: 338), CGPoint(x: 250, y: 342), CGPoint(x: 287, y: 338)
            ],
            tracks: ["pec-major", "pec-minor-rib", "scalene-chest", "serratus"]
        ),
        // Abdomen - right side
        Region(
            id: "f-abdomen-r",
            view: .front,
            isPaired: true,
            side: .right,
            points: [
                CGPoint(x: 287, y: 338), CGPoint(x: 250, y: 342), CGPoint(x: 200, y: 338),
                CGPoint(x: 190, y: 372), CGPoint(x: 194, y: 410), CGPoint(x: 204, y: 430),
                CGPoint(x: 250, y: 432), CGPoint(x: 287, y: 428)
            ],
            tracks: ["external-oblique", "serratus", "psoas"]
        ),
        // Lower Abdomen - right side
        Region(
            id: "f-lower-abdomen-r",
            view: .front,
            isPaired: true,
            side: .right,
            points: [
                CGPoint(x: 287, y: 428), CGPoint(x: 250, y: 432), CGPoint(x: 204, y: 430),
                CGPoint(x: 194, y: 452), CGPoint(x: 202, y: 478), CGPoint(x: 232, y: 502),
                CGPoint(x: 258, y: 530), CGPoint(x: 287, y: 524)
            ],
            tracks: ["external-oblique", "iliacus", "psoas", "groin-rotational", "pectineus"]
        ),
        // Shoulder/Arm - right side
        Region(
            id: "f-shoulder-arm-r",
            view: .front,
            isPaired: true,
            side: .right,
            points: [
                CGPoint(x: 252, y: 160), CGPoint(x: 240, y: 186), CGPoint(x: 204, y: 200),
                CGPoint(x: 190, y: 232), CGPoint(x: 190, y: 282), CGPoint(x: 180, y: 322),
                CGPoint(x: 170, y: 362), CGPoint(x: 156, y: 394), CGPoint(x: 104, y: 398),
                CGPoint(x: 110, y: 350), CGPoint(x: 114, y: 300), CGPoint(x: 116, y: 252),
                CGPoint(x: 130, y: 214), CGPoint(x: 160, y: 196), CGPoint(x: 206, y: 180),
                CGPoint(x: 236, y: 156)
            ],
            tracks: ["anterior-deltoid", "pec-major", "scalenes", "supraspinatus", "infraspinatus", "subscapularis"]
        ),
        // Forearm/Hand - right side
        Region(
            id: "f-forearm-hand-r",
            view: .front,
            isPaired: true,
            side: .right,
            points: [
                CGPoint(x: 100, y: 392), CGPoint(x: 158, y: 394), CGPoint(x: 146, y: 440),
                CGPoint(x: 120, y: 482), CGPoint(x: 104, y: 512), CGPoint(x: 98, y: 588),
                CGPoint(x: 78, y: 644), CGPoint(x: 40, y: 656), CGPoint(x: 24, y: 604),
                CGPoint(x: 4, y: 568), CGPoint(x: 22, y: 534), CGPoint(x: 56, y: 506),
                CGPoint(x: 64, y: 460), CGPoint(x: 84, y: 418)
            ],
            tracks: ["medial-forearm", "radialis-general", "extensor-radialis", "scalenes"]
        ),
        // Thigh - right side
        Region(
            id: "f-thigh-r",
            view: .front,
            isPaired: true,
            side: .right,
            points: [
                CGPoint(x: 194, y: 468), CGPoint(x: 232, y: 500), CGPoint(x: 262, y: 534),
                CGPoint(x: 286, y: 566), CGPoint(x: 284, y: 630), CGPoint(x: 270, y: 690),
                CGPoint(x: 254, y: 712), CGPoint(x: 196, y: 714), CGPoint(x: 174, y: 690),
                CGPoint(x: 164, y: 620), CGPoint(x: 166, y: 540), CGPoint(x: 178, y: 490)
            ],
            tracks: ["iliacus", "groin-rotational", "pectineus", "glute-min", "hip-general", "knee"]
        ),
        // Knee - right side
        Region(
            id: "f-knee-r",
            view: .front,
            isPaired: true,
            side: .right,
            points: [
                CGPoint(x: 180, y: 708), CGPoint(x: 258, y: 706), CGPoint(x: 262, y: 754),
                CGPoint(x: 246, y: 800), CGPoint(x: 200, y: 802), CGPoint(x: 184, y: 760)
            ],
            tracks: ["knee", "groin-rotational", "glute-min"]
        ),
        // Lower Leg - right side
        Region(
            id: "f-leg-r",
            view: .front,
            isPaired: true,
            side: .right,
            points: [
                CGPoint(x: 186, y: 800), CGPoint(x: 248, y: 798), CGPoint(x: 242, y: 868),
                CGPoint(x: 232, y: 950), CGPoint(x: 240, y: 1032), CGPoint(x: 244, y: 1066),
                CGPoint(x: 200, y: 1072), CGPoint(x: 166, y: 1062), CGPoint(x: 180, y: 1020),
                CGPoint(x: 190, y: 960), CGPoint(x: 184, y: 880)
            ],
            tracks: ["knee", "calf-soleus", "foot", "glute-min"]
        )
    ]

    // MARK: - Back Regions (Right Side - Original Coordinates)

    static let backRegionsRight: [Region] = [
        // Head - center (not paired)
        Region(
            id: "b-head",
            view: .back,
            isPaired: false,
            side: .center,
            points: [
                CGPoint(x: 911, y: 0), CGPoint(x: 949, y: 10), CGPoint(x: 965, y: 55),
                CGPoint(x: 955, y: 96), CGPoint(x: 911, y: 110), CGPoint(x: 867, y: 96),
                CGPoint(x: 857, y: 55), CGPoint(x: 873, y: 10)
            ],
            tracks: ["levator", "scalenes"]
        ),
        // Shoulder/Arm - right side
        Region(
            id: "b-shoulder-arm-r",
            view: .back,
            isPaired: true,
            side: .right,
            points: [
                CGPoint(x: 938, y: 140), CGPoint(x: 950, y: 165), CGPoint(x: 985, y: 192),
                CGPoint(x: 1030, y: 204), CGPoint(x: 1060, y: 222), CGPoint(x: 1082, y: 250),
                CGPoint(x: 1086, y: 292), CGPoint(x: 1094, y: 340), CGPoint(x: 1094, y: 385),
                CGPoint(x: 1070, y: 398), CGPoint(x: 1046, y: 388), CGPoint(x: 1034, y: 346),
                CGPoint(x: 1030, y: 300), CGPoint(x: 1040, y: 262), CGPoint(x: 1010, y: 236),
                CGPoint(x: 975, y: 226), CGPoint(x: 945, y: 212)
            ],
            tracks: ["supraspinatus", "infraspinatus", "subscapularis", "triceps", "levator", "scalenes"]
        ),
        // Shoulder Blade - right side
        Region(
            id: "b-blade-r",
            view: .back,
            isPaired: true,
            side: .right,
            points: [
                CGPoint(x: 952, y: 232), CGPoint(x: 985, y: 214), CGPoint(x: 1030, y: 222),
                CGPoint(x: 1058, y: 240), CGPoint(x: 1062, y: 280), CGPoint(x: 1040, y: 320),
                CGPoint(x: 1010, y: 350), CGPoint(x: 975, y: 355), CGPoint(x: 950, y: 330),
                CGPoint(x: 945, y: 280)
            ],
            tracks: ["infraspinatus", "levator", "scalenes", "serratus", "supraspinatus", "subscapularis"]
        ),
        // Spine - center (not paired)
        Region(
            id: "b-spine",
            view: .back,
            isPaired: false,
            side: .center,
            points: [
                CGPoint(x: 892, y: 100), CGPoint(x: 930, y: 100), CGPoint(x: 936, y: 150),
                CGPoint(x: 938, y: 220), CGPoint(x: 938, y: 300), CGPoint(x: 936, y: 350),
                CGPoint(x: 886, y: 350), CGPoint(x: 884, y: 300), CGPoint(x: 884, y: 220),
                CGPoint(x: 886, y: 150)
            ],
            tracks: ["levator", "scalenes", "infraspinatus", "serratus"]
        ),
        // Forearm/Hand - right side
        Region(
            id: "b-forearm-hand-r",
            view: .back,
            isPaired: true,
            side: .right,
            points: [
                CGPoint(x: 1062, y: 398), CGPoint(x: 1096, y: 390), CGPoint(x: 1112, y: 432),
                CGPoint(x: 1132, y: 480), CGPoint(x: 1142, y: 514), CGPoint(x: 1170, y: 548),
                CGPoint(x: 1182, y: 580), CGPoint(x: 1164, y: 622), CGPoint(x: 1132, y: 640),
                CGPoint(x: 1116, y: 600), CGPoint(x: 1106, y: 556), CGPoint(x: 1104, y: 516),
                CGPoint(x: 1090, y: 472), CGPoint(x: 1070, y: 432)
            ],
            tracks: ["extensor-radialis", "triceps", "radialis-general", "subscapularis", "scalenes"]
        ),
        // Glute/Hamstring - right side
        Region(
            id: "b-glute-ham-r",
            view: .back,
            isPaired: true,
            side: .right,
            points: [
                CGPoint(x: 922, y: 520), CGPoint(x: 967, y: 505), CGPoint(x: 1009, y: 496),
                CGPoint(x: 1037, y: 518), CGPoint(x: 1045, y: 575), CGPoint(x: 1050, y: 640),
                CGPoint(x: 1046, y: 700), CGPoint(x: 1032, y: 745), CGPoint(x: 985, y: 750),
                CGPoint(x: 945, y: 745), CGPoint(x: 932, y: 690), CGPoint(x: 927, y: 620),
                CGPoint(x: 915, y: 580)
            ],
            tracks: ["glute-min", "glute-max", "ql", "hip-general", "iliacus", "psoas"]
        ),
        // Lower Back - center (not paired)
        Region(
            id: "b-low-back",
            view: .back,
            isPaired: false,
            side: .center,
            points: [
                CGPoint(x: 880, y: 318), CGPoint(x: 942, y: 318), CGPoint(x: 952, y: 360),
                CGPoint(x: 962, y: 410), CGPoint(x: 976, y: 450), CGPoint(x: 980, y: 490),
                CGPoint(x: 960, y: 520), CGPoint(x: 940, y: 545), CGPoint(x: 922, y: 568),
                CGPoint(x: 900, y: 568), CGPoint(x: 882, y: 545), CGPoint(x: 862, y: 520),
                CGPoint(x: 842, y: 490), CGPoint(x: 846, y: 450), CGPoint(x: 860, y: 410),
                CGPoint(x: 870, y: 360)
            ],
            tracks: ["ql", "psoas", "iliacus", "glute-max", "glute-min"]
        ),
        // Knee - right side
        Region(
            id: "b-knee-r",
            view: .back,
            isPaired: true,
            side: .right,
            points: [
                CGPoint(x: 943, y: 728), CGPoint(x: 1019, y: 722), CGPoint(x: 1017, y: 770),
                CGPoint(x: 981, y: 782), CGPoint(x: 947, y: 772)
            ],
            tracks: ["calf-soleus", "knee"]
        ),
        // Calf/Heel - right side
        Region(
            id: "b-calf-heel-r",
            view: .back,
            isPaired: true,
            side: .right,
            points: [
                CGPoint(x: 943, y: 776), CGPoint(x: 1021, y: 772), CGPoint(x: 1027, y: 840),
                CGPoint(x: 1015, y: 905), CGPoint(x: 1008, y: 960), CGPoint(x: 1017, y: 1030),
                CGPoint(x: 999, y: 1070), CGPoint(x: 963, y: 1068), CGPoint(x: 957, y: 1010),
                CGPoint(x: 955, y: 940), CGPoint(x: 939, y: 860)
            ],
            tracks: ["calf-soleus", "foot", "glute-min"]
        )
    ]

    // MARK: - Mirror Function (for left side)

    static func mirrorPoints(_ points: [CGPoint], midX: CGFloat) -> [CGPoint] {
        points.map { CGPoint(x: 2 * midX - $0.x, y: $0.y) }
    }

    // MARK: - Generate All Regions (with mirrored left sides)

    static func allFrontRegions() -> [Region] {
        var regions: [Region] = []

        for region in frontRegionsRight {
            if region.isPaired {
                // Add right side
                regions.append(region)
                // Add mirrored left side
                let leftPoints = mirrorPoints(region.points, midX: frontMidX)
                regions.append(Region(
                    id: region.id.replacingOccurrences(of: "-r", with: "-l"),
                    view: .front,
                    isPaired: true,
                    side: .left,
                    points: leftPoints,
                    tracks: region.tracks
                ))
            } else {
                // Center region, no mirroring needed
                regions.append(region)
            }
        }

        return regions
    }

    static func allBackRegions() -> [Region] {
        var regions: [Region] = []

        for region in backRegionsRight {
            if region.isPaired {
                // Add right side
                regions.append(region)
                // Add mirrored left side
                let leftPoints = mirrorPoints(region.points, midX: backMidX)
                regions.append(Region(
                    id: region.id.replacingOccurrences(of: "-r", with: "-l"),
                    view: .back,
                    isPaired: true,
                    side: .left,
                    points: leftPoints,
                    tracks: region.tracks
                ))
            } else {
                // Center region, no mirroring needed
                regions.append(region)
            }
        }

        return regions
    }
}

// MARK: - Path Smoothing (Catmull-Rom to Cubic Bezier)
// Converts polygon points to smooth curves matching the web's smooth() function

extension Array where Element == CGPoint {
    /// Converts polygon points to a smooth SwiftUI Path using Catmull-Rom spline interpolation
    func toSmoothPath() -> Path {
        guard count >= 3 else {
            return Path { path in
                guard let first = self.first else { return }
                path.move(to: first)
                for point in self.dropFirst() {
                    path.addLine(to: point)
                }
                path.closeSubpath()
            }
        }

        return Path { path in
            // Catmull-Rom to cubic Bezier conversion (matching web's smooth function)
            for i in 0..<count {
                let p0 = self[(i - 1 + count) % count]
                let p1 = self[i]
                let p2 = self[(i + 1) % count]
                let p3 = self[(i + 2) % count]

                // Control points
                let c1 = CGPoint(
                    x: p1.x + (p2.x - p0.x) / 6,
                    y: p1.y + (p2.y - p0.y) / 6
                )
                let c2 = CGPoint(
                    x: p2.x - (p3.x - p1.x) / 6,
                    y: p2.y - (p3.y - p1.y) / 6
                )

                if i == 0 {
                    path.move(to: p1)
                }
                path.addCurve(to: p2, control1: c1, control2: c2)
            }
            path.closeSubpath()
        }
    }

    /// Scales and translates points to fit within a target frame
    func scaled(from sourceRect: CGRect, to targetRect: CGRect) -> [CGPoint] {
        let scaleX = targetRect.width / sourceRect.width
        let scaleY = targetRect.height / sourceRect.height

        return map { point in
            CGPoint(
                x: targetRect.minX + (point.x - sourceRect.minX) * scaleX,
                y: targetRect.minY + (point.y - sourceRect.minY) * scaleY
            )
        }
    }
}

// MARK: - SwiftUI Shape for Body Regions

struct BodyRegionShape: Shape {
    let points: [CGPoint]
    let viewSide: BodyRegionPathData.BodyViewSide

    func path(in rect: CGRect) -> Path {
        // Web canvas: 1182×1073, we crop and show half at a time
        // Front half: x=0 to 591 (width=591), centered body at x=287
        // Back half: x=591 to 1182 (width=591), centered body at x=911.5

        let canvasWidth: CGFloat = 1182
        let canvasHeight: CGFloat = 1073
        let halfWidth: CGFloat = canvasWidth / 2  // 591

        // For cropped view, adjust x coordinates
        let xOffset: CGFloat = viewSide == .front ? 0 : halfWidth

        // The cropped portion dimensions
        let croppedWidth: CGFloat = halfWidth
        let croppedHeight: CGFloat = canvasHeight

        // Scale to fit the view (aspect fit)
        let scaleX = rect.width / croppedWidth
        let scaleY = rect.height / croppedHeight
        let scale = min(scaleX, scaleY)

        // Calculate centering offset (to center the scaled image in the view)
        let scaledWidth = croppedWidth * scale
        let scaledHeight = croppedHeight * scale
        let offsetX = (rect.width - scaledWidth) / 2
        let offsetY = (rect.height - scaledHeight) / 2

        // Transform points
        let transformedPoints = points.map { point -> CGPoint in
            // Adjust x for which half we're showing
            let adjustedX = point.x - xOffset

            // Scale and translate
            let scaledX = adjustedX * scale + offsetX
            let scaledY = point.y * scale + offsetY

            return CGPoint(x: scaledX, y: scaledY)
        }

        return transformedPoints.toSmoothPath()
    }
}

// MARK: - Body Region Overlay View

struct BodyRegionOverlay: View {
    let viewSide: BodyRegionPathData.BodyViewSide
    let selectedRegionIds: Set<String>
    let onRegionTap: (String) -> Void

    private var regions: [BodyRegionPathData.Region] {
        viewSide == .front ? BodyRegionPathData.allFrontRegions() : BodyRegionPathData.allBackRegions()
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(regions) { region in
                    let isSelected = selectedRegionIds.contains(region.id)

                    Button {
                        onRegionTap(region.id)
                    } label: {
                        // Regions are INVISIBLE until tapped (matching web)
                        // Only show gold fill with glow when selected
                        BodyRegionShape(points: region.points, viewSide: viewSide)
                            .fill(isSelected ? Color.mdGold.opacity(0.5) : Color.clear)
                            .shadow(
                                color: isSelected ? Color.mdGold.opacity(0.7) : Color.clear,
                                radius: isSelected ? 12 : 0
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
