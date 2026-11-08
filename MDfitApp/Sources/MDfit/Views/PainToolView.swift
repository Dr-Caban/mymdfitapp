import SwiftUI

// MARK: - Pain Tool Main View

struct PainToolView: View {
    @State private var selectedView: BodyView = .front
    @State private var selectedRegions: [BodyRegion] = []
    @State private var selectedRegionIds: Set<String> = []  // For SVG region tracking
    @State private var showResults = false
    @State private var matchedPatterns: [PainPattern] = []
    @State private var showRedFlagWarning = false

    enum BodyView: String, CaseIterable {
        case front = "Front"
        case back = "Back"
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Background
                Color.mdCream
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Hero header
                        heroSection

                        // Content
                        VStack(spacing: 16) {
                            // Body map section
                            painMapSection

                            // Educational disclaimer
                            disclaimerNote

                            // Selected areas summary
                            if !selectedRegionIds.isEmpty {
                                selectedAreasSection
                            }

                            // Action button
                            if !selectedRegionIds.isEmpty {
                                actionButton
                            }

                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showResults) {
                PainResultsView(
                    selectedRegions: selectedRegions,
                    patterns: matchedPatterns
                )
            }
            .alert("Important Health Notice", isPresented: $showRedFlagWarning) {
                Button("I Understand", role: .cancel) {
                    showResults = true
                }
                Button("Call Doctor", role: .destructive) {
                    if let url = URL(string: "tel://9413130562") {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("Some selected areas may indicate symptoms that require professional evaluation. If you're experiencing severe pain, numbness, weakness, or other concerning symptoms, please consult a healthcare professional.")
            }
        }
    }

    // MARK: - Hero Section (Rounded card like web)

    private var heroSection: some View {
        ZStack {
            Color.mdInk
            RadialGradient(
                colors: [Color.mdInk3.opacity(0.5), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 300
            )
        }
        .frame(height: 130)
        .cornerRadius(16)
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .overlay(
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 0) {
                    Text("Pain ")
                        .font(.mdDisplay(28, weight: .bold))
                        .foregroundColor(.white)
                    Text("Tool")
                        .font(.mdDisplay(28, weight: .bold))
                        .italic()
                        .foregroundColor(.mdGold)
                }

                Text("TAP THE AREA THAT HURTS TO START\nYOUR PROTOCOL.")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 36)
            .padding(.bottom, 24)
            ,
            alignment: .bottomLeading
        )
    }

    // MARK: - Pain Map Section

    private var painMapSection: some View {
        VStack(spacing: 20) {
            // Front/Back toggle (gold filled for selected, outline for unselected)
            HStack(spacing: 12) {
                ForEach(BodyView.allCases, id: \.self) { view in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedView = view
                        }
                    } label: {
                        Text(view.rawValue)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(selectedView == view ? .mdInk : .mdInk)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedView == view ? Color.mdGold : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedView == view ? Color.mdGold : Color.mdLine, lineWidth: selectedView == view ? 0 : 1.5)
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // Anatomical body figure with tappable regions
            anatomicalBodyMap
        }
    }

    // MARK: - Anatomical Body Map

    private var anatomicalBodyMap: some View {
        GeometryReader { geometry in
            ZStack {
                // Anatomical body image (shows front or back half)
                AnatomicalBodyImage(selectedView: selectedView)

                // SVG-based anatomical region overlays (exact web paths)
                BodyRegionOverlay(
                    viewSide: selectedView == .front ? .front : .back,
                    selectedRegionIds: selectedRegionIds,
                    onRegionTap: { regionId in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            toggleRegionById(regionId)
                        }
                    }
                )
            }
        }
        .frame(height: 500)
        .background(Color.mdInk)
        .cornerRadius(16)
    }

    private func toggleRegion(_ region: BodyRegion) {
        withAnimation(.easeInOut(duration: 0.15)) {
            if selectedRegions.contains(region) {
                selectedRegions.removeAll { $0 == region }
            } else {
                selectedRegions.append(region)
            }
        }
    }

    private func toggleRegionById(_ regionId: String) {
        if selectedRegionIds.contains(regionId) {
            selectedRegionIds.remove(regionId)
        } else {
            selectedRegionIds.insert(regionId)
        }

        // Map region ID to BodyRegion for pattern matching
        if let bodyRegion = mapRegionIdToBodyRegion(regionId) {
            if selectedRegions.contains(bodyRegion) {
                // Only remove if no other related regions are selected
                let relatedIds = selectedRegionIds.filter { id in
                    mapRegionIdToBodyRegion(id) == bodyRegion
                }
                if relatedIds.isEmpty {
                    selectedRegions.removeAll { $0 == bodyRegion }
                }
            } else {
                selectedRegions.append(bodyRegion)
            }
        }
    }

    private func mapRegionIdToBodyRegion(_ regionId: String) -> BodyRegion? {
        // Map SVG region IDs to BodyRegion enum
        let baseId = regionId.replacingOccurrences(of: "-r", with: "").replacingOccurrences(of: "-l", with: "")

        switch baseId {
        case "f-head", "b-head": return .neck
        case "f-chest": return .chest
        case "f-abdomen", "f-lower-abdomen": return .core
        case "f-shoulder-arm", "b-shoulder-arm": return .shoulders
        case "f-forearm-hand", "b-forearm-hand": return .arms
        case "f-thigh": return .quadriceps
        case "f-knee", "b-knee": return .knees
        case "f-leg": return .calves
        case "b-blade": return .upperBack
        case "b-spine": return .upperBack
        case "b-low-back": return .lowerBack
        case "b-glute-ham": return .glutes
        case "b-calf-heel": return .calves
        default: return nil
        }
    }

    private func displayNameForRegionId(_ regionId: String) -> String {
        let baseId = regionId.replacingOccurrences(of: "-r", with: "").replacingOccurrences(of: "-l", with: "")
        let side = regionId.hasSuffix("-r") ? " (R)" : regionId.hasSuffix("-l") ? " (L)" : ""

        switch baseId {
        case "f-head": return "Head/Neck" + side
        case "b-head": return "Back of Head" + side
        case "f-chest": return "Chest" + side
        case "f-abdomen": return "Abdomen" + side
        case "f-lower-abdomen": return "Lower Abdomen" + side
        case "f-shoulder-arm": return "Shoulder/Arm" + side
        case "b-shoulder-arm": return "Back Shoulder/Arm" + side
        case "f-forearm-hand": return "Forearm/Hand" + side
        case "b-forearm-hand": return "Back Forearm/Hand" + side
        case "f-thigh": return "Thigh" + side
        case "f-knee": return "Knee (Front)" + side
        case "b-knee": return "Knee (Back)" + side
        case "f-leg": return "Shin/Ankle" + side
        case "b-blade": return "Shoulder Blade" + side
        case "b-spine": return "Spine"
        case "b-low-back": return "Lower Back"
        case "b-glute-ham": return "Glute/Hamstring" + side
        case "b-calf-heel": return "Calf/Heel" + side
        default: return regionId
        }
    }

    // MARK: - Disclaimer Note

    private var disclaimerNote: some View {
        Text("Educational only, not a diagnosis.")
            .font(.system(size: 13))
            .foregroundColor(.mdMuted)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 8)
    }

    // MARK: - Selected Areas Section

    private var selectedAreasSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("SELECTED AREAS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.mdAccentText)
                    .tracking(1.5)

                Spacer()

                Button {
                    withAnimation {
                        selectedRegions.removeAll()
                        selectedRegionIds.removeAll()
                    }
                } label: {
                    Text("Clear")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.mdAccentText)
                }
            }

            // Tags - show SVG region selections
            FlowLayout(spacing: 8) {
                ForEach(Array(selectedRegionIds).sorted(), id: \.self) { regionId in
                    HStack(spacing: 6) {
                        Text(displayNameForRegionId(regionId))
                            .font(.system(size: 13, weight: .medium))

                        Button {
                            withAnimation {
                                toggleRegionById(regionId)
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                        }
                    }
                    .foregroundColor(.mdInk)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.mdGold)
                    .cornerRadius(999)
                }
            }
        }
        .mdCardStyle()
    }

    // MARK: - Action Button

    private var actionButton: some View {
        VStack(spacing: 8) {
            Button {
                findPatterns()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Find Exercises")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.mdInk)
                .cornerRadius(12)
            }

            Text("We'll show exercises that may help with your selected areas")
                .font(.system(size: 12))
                .foregroundColor(.mdMuted)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Pattern Matching

    private func findPatterns() {
        matchedPatterns = PainPattern.samples.filter { pattern in
            selectedRegions.contains(pattern.bodyRegion) ||
            selectedRegions.contains(where: { pattern.referredAreas.contains($0) })
        }

        let hasRedFlagRegion = selectedRegions.contains { region in
            region == .neck || region == .chest || region == .lowerBack
        }

        if hasRedFlagRegion && selectedRegions.count >= 2 {
            showRedFlagWarning = true
        } else {
            showResults = true
        }
    }
}

// MARK: - Body Region Card

struct BodyRegionCard: View {
    let region: BodyRegion
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.mdAccent.opacity(0.2) : Color.mdPaper2)
                        .frame(width: 40, height: 40)

                    Image(systemName: region.icon)
                        .font(.system(size: 16))
                        .foregroundColor(isSelected ? .mdAccentText : .mdInk)
                }

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(region.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.mdInk)
                        .lineLimit(1)

                    Text(anatomicalSubtext(for: region))
                        .font(.system(size: 11))
                        .foregroundColor(.mdMuted)
                        .lineLimit(1)
                }

                Spacer()

                // Radio button
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.mdAccent : Color.mdLine, lineWidth: 2)
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(Color.mdAccent)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.mdGoldSoft : Color.mdPaper)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color.mdInk : Color.mdLine, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func anatomicalSubtext(for region: BodyRegion) -> String {
        switch region {
        case .neck: return "Cervical spine"
        case .shoulders: return "Deltoid, rotator cuff"
        case .chest: return "Pectoralis major/minor"
        case .arms: return "Biceps, triceps, forearm"
        case .core: return "Abdominals, obliques"
        case .upperBack: return "Thoracic spine, rhomboids"
        case .lowerBack: return "Lumbar spine, erectors"
        case .hips: return "Hip flexors, adductors"
        case .glutes: return "Gluteus max/med/min"
        case .quadriceps: return "Quad muscles"
        case .hamstrings: return "Hamstring group"
        case .knees: return "Patella, meniscus"
        case .calves: return "Gastrocnemius, soleus"
        case .ankles: return "Ankle joint complex"
        case .feet: return "Plantar fascia, toes"
        case .fullBody: return "Full body assessment"
        }
    }
}

// MARK: - Pain Results View

struct PainResultsView: View {
    @Environment(\.dismiss) var dismiss
    let selectedRegions: [BodyRegion]
    let patterns: [PainPattern]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    resultsHeader

                    // Matched patterns
                    if !patterns.isEmpty {
                        patternsSection
                    }

                    // Suggested exercises
                    suggestedExercisesSection

                    // Educational content
                    educationalSection

                    // Red flags
                    redFlagsSection

                    // Disclaimer
                    disclaimerSection

                    // CTA
                    ctaSection
                }
                .padding()
            }
            .background(Color.mdCream)
            .navigationTitle("Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Results Header

    private var resultsHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.mdOk)

            Text("Analysis Complete")
                .font(.mdDisplay(24, weight: .bold))
                .foregroundColor(.mdHeading)

            Text("Based on \(selectedRegions.count) selected area\(selectedRegions.count == 1 ? "" : "s")")
                .font(.system(size: 14))
                .foregroundColor(.mdMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .mdCardStyle()
    }

    // MARK: - Patterns Section

    private var patternsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("POSSIBLE PATTERNS")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.mdMuted)
                .tracking(1.5)

            ForEach(patterns) { pattern in
                PatternCard(pattern: pattern)
            }
        }
    }

    // MARK: - Suggested Exercises

    private var suggestedExercisesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("SUGGESTED EXERCISES")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.mdMuted)
                    .tracking(1.5)

                Spacer()

                Button("View All") {
                    // Navigate to video library
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.mdAccentText)
            }

            ForEach(Exercise.samples.prefix(3)) { exercise in
                ExerciseRow(exercise: exercise)
            }
        }
    }

    // MARK: - Educational Section

    private var educationalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Understanding Your Pain", systemImage: "book.fill")
                .font(.mdDisplay(16, weight: .bold))
                .foregroundColor(.mdHeading)

            if let pattern = patterns.first {
                Text(pattern.educationalContent)
                    .font(.system(size: 14))
                    .foregroundColor(.mdText)
            } else {
                Text("Pain in these areas can stem from various causes including muscle tension, posture, overuse, or referred pain from other regions. The exercises suggested focus on mobility, strengthening, and relief.")
                    .font(.system(size: 14))
                    .foregroundColor(.mdText)
            }
        }
        .mdCardStyle()
    }

    // MARK: - Red Flags Section

    private var redFlagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("When to Seek Help", systemImage: "exclamationmark.triangle.fill")
                .font(.mdDisplay(16, weight: .bold))
                .foregroundColor(.mdErr)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(redFlagIndicators, id: \.self) { flag in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundColor(.mdErr)
                            .font(.system(size: 14))
                        Text(flag)
                            .font(.system(size: 14))
                            .foregroundColor(.mdText)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.mdErr.opacity(0.1))
        .cornerRadius(MDTheme.radius)
    }

    private var redFlagIndicators: [String] {
        [
            "Severe pain that doesn't improve with rest",
            "Numbness, tingling, or weakness spreading",
            "Loss of bladder or bowel control",
            "Pain after a significant injury",
            "Unexplained weight loss with pain"
        ]
    }

    // MARK: - Disclaimer Section

    private var disclaimerSection: some View {
        Text(PainPattern.defaultDisclaimer)
            .font(.system(size: 12))
            .foregroundColor(.mdMuted)
            .multilineTextAlignment(.center)
            .padding()
    }

    // MARK: - CTA Section

    private var ctaSection: some View {
        VStack(spacing: 12) {
            Button {
                // Schedule consultation
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "calendar.badge.plus")
                    Text("Schedule In-Person Consultation")
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.mdInk)
                .cornerRadius(12)
            }

            Button {
                if let url = URL(string: "tel://9413130562") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "phone.fill")
                    Text("Call MD Fit: 941.313.0562")
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.mdInk)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.mdGold)
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Pattern Card

struct PatternCard: View {
    let pattern: PainPattern
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pattern.bodyRegion.displayName)
                            .font(.mdDisplay(16, weight: .bold))
                            .foregroundColor(.mdHeading)

                        if !pattern.referredAreas.isEmpty {
                            Text("May refer to: \(pattern.referredAreas.map(\.displayName).joined(separator: ", "))")
                                .font(.system(size: 12))
                                .foregroundColor(.mdMuted)
                        }
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.mdMuted)
                }
            }

            if isExpanded {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Common Causes:")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.mdHeading)

                    ForEach(pattern.commonCauses, id: \.self) { cause in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.mdAccentText)
                                .frame(width: 4, height: 4)
                            Text(cause)
                                .font(.system(size: 13))
                                .foregroundColor(.mdText)
                        }
                    }
                }
            }
        }
        .mdCardStyle()
    }
}

// MARK: - Exercise Row

struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            RoundedRectangle(cornerRadius: 9)
                .fill(Color.mdInk3)
                .frame(width: 80, height: 60)
                .overlay(
                    Circle()
                        .fill(Color.mdAccent.opacity(0.95))
                        .frame(width: 26, height: 26)
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.mdInk)
                                .offset(x: 1)
                        )
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.mdInk)
                    .lineLimit(1)

                Text(exercise.category.displayName)
                    .font(.system(size: 13))
                    .foregroundColor(.mdMuted)

                HStack(spacing: 4) {
                    MDTagBadge(text: exercise.level.displayName, color: .mdAccentText)
                    MDTagBadge(text: exercise.bodyRegion.displayName, color: .mdGold)
                }
            }

            Spacer()

            Button {
                // Play video
            } label: {
                Circle()
                    .fill(Color.mdInk)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "play.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .offset(x: 1)
                    )
            }
        }
        .mdCardStyle()
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }

    struct FlowResult {
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                sizes.append(size)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }

            size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

// MARK: - Anatomical Body Image (Real image from web app)

struct AnatomicalBodyImage: View {
    let selectedView: PainToolView.BodyView

    var body: some View {
        GeometryReader { geometry in
            croppedBodyImage
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var croppedBodyImage: some View {
        if let croppedImage = getCroppedImage() {
            Image(uiImage: croppedImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else if let fallbackImage = getFallbackImage() {
            Image(uiImage: fallbackImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            placeholderView
        }
    }

    private func getCroppedImage() -> UIImage? {
        guard let uiImage = UIImage(named: "BodyFigures"),
              let cgImage = uiImage.cgImage else { return nil }

        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)

        // Crop to front (left half) or back (right half)
        let cropRect: CGRect
        if selectedView == .front {
            cropRect = CGRect(x: 0, y: 0, width: imageWidth * 0.5, height: imageHeight)
        } else {
            cropRect = CGRect(x: imageWidth * 0.5, y: 0, width: imageWidth * 0.5, height: imageHeight)
        }

        guard let croppedCG = cgImage.cropping(to: cropRect) else { return nil }
        return UIImage(cgImage: croppedCG)
    }

    private func getFallbackImage() -> UIImage? {
        let imageName = selectedView == .front ? "BodyFront" : "BodyBack"
        return UIImage(named: imageName)
    }

    private var placeholderView: some View {
        ZStack {
            Color.mdInk
            VStack(spacing: 12) {
                Image(systemName: "figure.stand")
                    .font(.system(size: 100))
                    .foregroundColor(.mdGold.opacity(0.3))
                Text(selectedView.rawValue.uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(2)
            }
        }
    }
}

// MARK: - Body Silhouette View (Fallback with gold outlines)

struct BodySilhouetteView: View {
    let view: PainToolView.BodyView
    let selectedRegions: [BodyRegion]
    let onRegionTap: (BodyRegion) -> Void

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let centerX = width / 2
            let scale = min(width / 300, height / 500)

            ZStack {
                // Body silhouette with muscle texture appearance
                Canvas { context, size in
                    drawAnatomicalBody(context: context, size: size, scale: scale, centerX: centerX)
                }

                // Gold outline regions
                bodyOutlineRegions(scale: scale, centerX: centerX, height: height)
            }
        }
    }

    private func drawAnatomicalBody(context: GraphicsContext, size: CGSize, scale: CGFloat, centerX: CGFloat) {
        let bodyColor = Color(red: 0.76, green: 0.45, blue: 0.35) // Muscle tone color

        // Head
        let headPath = Path(ellipseIn: CGRect(x: centerX - 35 * scale, y: 10 * scale, width: 70 * scale, height: 80 * scale))
        context.fill(headPath, with: .color(bodyColor))

        // Neck
        let neckPath = Path(CGRect(x: centerX - 20 * scale, y: 80 * scale, width: 40 * scale, height: 30 * scale))
        context.fill(neckPath, with: .color(bodyColor))

        // Torso
        var torsoPath = Path()
        torsoPath.move(to: CGPoint(x: centerX - 70 * scale, y: 110 * scale))
        torsoPath.addLine(to: CGPoint(x: centerX - 80 * scale, y: 130 * scale))
        torsoPath.addLine(to: CGPoint(x: centerX - 75 * scale, y: 250 * scale))
        torsoPath.addLine(to: CGPoint(x: centerX - 50 * scale, y: 280 * scale))
        torsoPath.addLine(to: CGPoint(x: centerX, y: 290 * scale))
        torsoPath.addLine(to: CGPoint(x: centerX + 50 * scale, y: 280 * scale))
        torsoPath.addLine(to: CGPoint(x: centerX + 75 * scale, y: 250 * scale))
        torsoPath.addLine(to: CGPoint(x: centerX + 80 * scale, y: 130 * scale))
        torsoPath.addLine(to: CGPoint(x: centerX + 70 * scale, y: 110 * scale))
        torsoPath.closeSubpath()
        context.fill(torsoPath, with: .color(bodyColor))

        // Left arm
        var leftArmPath = Path()
        leftArmPath.move(to: CGPoint(x: centerX - 80 * scale, y: 115 * scale))
        leftArmPath.addLine(to: CGPoint(x: centerX - 130 * scale, y: 200 * scale))
        leftArmPath.addLine(to: CGPoint(x: centerX - 140 * scale, y: 300 * scale))
        leftArmPath.addLine(to: CGPoint(x: centerX - 120 * scale, y: 300 * scale))
        leftArmPath.addLine(to: CGPoint(x: centerX - 110 * scale, y: 210 * scale))
        leftArmPath.addLine(to: CGPoint(x: centerX - 70 * scale, y: 130 * scale))
        leftArmPath.closeSubpath()
        context.fill(leftArmPath, with: .color(bodyColor))

        // Right arm
        var rightArmPath = Path()
        rightArmPath.move(to: CGPoint(x: centerX + 80 * scale, y: 115 * scale))
        rightArmPath.addLine(to: CGPoint(x: centerX + 130 * scale, y: 200 * scale))
        rightArmPath.addLine(to: CGPoint(x: centerX + 140 * scale, y: 300 * scale))
        rightArmPath.addLine(to: CGPoint(x: centerX + 120 * scale, y: 300 * scale))
        rightArmPath.addLine(to: CGPoint(x: centerX + 110 * scale, y: 210 * scale))
        rightArmPath.addLine(to: CGPoint(x: centerX + 70 * scale, y: 130 * scale))
        rightArmPath.closeSubpath()
        context.fill(rightArmPath, with: .color(bodyColor))

        // Left leg
        var leftLegPath = Path()
        leftLegPath.move(to: CGPoint(x: centerX - 50 * scale, y: 280 * scale))
        leftLegPath.addLine(to: CGPoint(x: centerX - 55 * scale, y: 380 * scale))
        leftLegPath.addLine(to: CGPoint(x: centerX - 50 * scale, y: 470 * scale))
        leftLegPath.addLine(to: CGPoint(x: centerX - 30 * scale, y: 470 * scale))
        leftLegPath.addLine(to: CGPoint(x: centerX - 25 * scale, y: 380 * scale))
        leftLegPath.addLine(to: CGPoint(x: centerX - 10 * scale, y: 290 * scale))
        leftLegPath.closeSubpath()
        context.fill(leftLegPath, with: .color(bodyColor))

        // Right leg
        var rightLegPath = Path()
        rightLegPath.move(to: CGPoint(x: centerX + 50 * scale, y: 280 * scale))
        rightLegPath.addLine(to: CGPoint(x: centerX + 55 * scale, y: 380 * scale))
        rightLegPath.addLine(to: CGPoint(x: centerX + 50 * scale, y: 470 * scale))
        rightLegPath.addLine(to: CGPoint(x: centerX + 30 * scale, y: 470 * scale))
        rightLegPath.addLine(to: CGPoint(x: centerX + 25 * scale, y: 380 * scale))
        rightLegPath.addLine(to: CGPoint(x: centerX + 10 * scale, y: 290 * scale))
        rightLegPath.closeSubpath()
        context.fill(rightLegPath, with: .color(bodyColor))
    }

    private func bodyOutlineRegions(scale: CGFloat, centerX: CGFloat, height: CGFloat) -> some View {
        let goldColor = Color.mdGold

        return ZStack {
            Group {
                // Neck outline
                regionOutline(
                    points: [
                        CGPoint(x: centerX - 25 * scale, y: 75 * scale),
                        CGPoint(x: centerX + 25 * scale, y: 75 * scale),
                        CGPoint(x: centerX + 25 * scale, y: 110 * scale),
                        CGPoint(x: centerX - 25 * scale, y: 110 * scale)
                    ],
                    color: goldColor
                )

                // Shoulders outline
                regionOutline(
                    points: [
                        CGPoint(x: centerX - 85 * scale, y: 105 * scale),
                        CGPoint(x: centerX + 85 * scale, y: 105 * scale),
                        CGPoint(x: centerX + 80 * scale, y: 135 * scale),
                        CGPoint(x: centerX - 80 * scale, y: 135 * scale)
                    ],
                    color: goldColor
                )

                // Chest outline
                regionOutline(
                    points: [
                        CGPoint(x: centerX - 75 * scale, y: 135 * scale),
                        CGPoint(x: centerX + 75 * scale, y: 135 * scale),
                        CGPoint(x: centerX + 70 * scale, y: 195 * scale),
                        CGPoint(x: centerX - 70 * scale, y: 195 * scale)
                    ],
                    color: goldColor
                )

                // Core/abs outline
                regionOutline(
                    points: [
                        CGPoint(x: centerX - 55 * scale, y: 195 * scale),
                        CGPoint(x: centerX + 55 * scale, y: 195 * scale),
                        CGPoint(x: centerX + 50 * scale, y: 270 * scale),
                        CGPoint(x: centerX - 50 * scale, y: 270 * scale)
                    ],
                    color: goldColor
                )

                // Left arm outline
                regionOutline(
                    points: [
                        CGPoint(x: centerX - 130 * scale, y: 140 * scale),
                        CGPoint(x: centerX - 85 * scale, y: 115 * scale),
                        CGPoint(x: centerX - 75 * scale, y: 200 * scale),
                        CGPoint(x: centerX - 115 * scale, y: 220 * scale)
                    ],
                    color: goldColor
                )

                // Right arm outline
                regionOutline(
                    points: [
                        CGPoint(x: centerX + 130 * scale, y: 140 * scale),
                        CGPoint(x: centerX + 85 * scale, y: 115 * scale),
                        CGPoint(x: centerX + 75 * scale, y: 200 * scale),
                        CGPoint(x: centerX + 115 * scale, y: 220 * scale)
                    ],
                    color: goldColor
                )
            }

            Group {
                // Hips outline
                regionOutline(
                    points: [
                        CGPoint(x: centerX - 55 * scale, y: 270 * scale),
                        CGPoint(x: centerX + 55 * scale, y: 270 * scale),
                        CGPoint(x: centerX + 50 * scale, y: 300 * scale),
                        CGPoint(x: centerX - 50 * scale, y: 300 * scale)
                    ],
                    color: goldColor
                )

                // Left quad outline
                regionOutline(
                    points: [
                        CGPoint(x: centerX - 55 * scale, y: 300 * scale),
                        CGPoint(x: centerX - 10 * scale, y: 300 * scale),
                        CGPoint(x: centerX - 25 * scale, y: 380 * scale),
                        CGPoint(x: centerX - 55 * scale, y: 380 * scale)
                    ],
                    color: goldColor
                )

                // Right quad outline
                regionOutline(
                    points: [
                        CGPoint(x: centerX + 55 * scale, y: 300 * scale),
                        CGPoint(x: centerX + 10 * scale, y: 300 * scale),
                        CGPoint(x: centerX + 25 * scale, y: 380 * scale),
                        CGPoint(x: centerX + 55 * scale, y: 380 * scale)
                    ],
                    color: goldColor
                )

                // Knees outline
                regionOutline(
                    points: [
                        CGPoint(x: centerX - 55 * scale, y: 380 * scale),
                        CGPoint(x: centerX + 55 * scale, y: 380 * scale),
                        CGPoint(x: centerX + 50 * scale, y: 410 * scale),
                        CGPoint(x: centerX - 50 * scale, y: 410 * scale)
                    ],
                    color: goldColor
                )

                // Calves outline
                regionOutline(
                    points: [
                        CGPoint(x: centerX - 50 * scale, y: 410 * scale),
                        CGPoint(x: centerX + 50 * scale, y: 410 * scale),
                        CGPoint(x: centerX + 45 * scale, y: 460 * scale),
                        CGPoint(x: centerX - 45 * scale, y: 460 * scale)
                    ],
                    color: goldColor
                )

                // Feet outline
                regionOutline(
                    points: [
                        CGPoint(x: centerX - 50 * scale, y: 460 * scale),
                        CGPoint(x: centerX + 50 * scale, y: 460 * scale),
                        CGPoint(x: centerX + 45 * scale, y: 485 * scale),
                        CGPoint(x: centerX - 45 * scale, y: 485 * scale)
                    ],
                    color: goldColor
                )
            }
        }
    }

    private func regionOutline(points: [CGPoint], color: Color) -> some View {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: first)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
            path.closeSubpath()
        }
        .stroke(color, lineWidth: 1.5)
    }
}

// MARK: - Legacy Support

struct InteractiveBodyMap: View {
    enum LegacyBodyView {
        case front, back
    }
    let view: LegacyBodyView
    @Binding var selectedRegions: [BodyRegion]

    var body: some View {
        EmptyView()
    }
}

struct AnatomicalRegionCard: View {
    let region: BodyRegion
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        BodyRegionCard(region: region, isSelected: isSelected, action: action)
    }
}

struct BodyRegionButton: View {
    let region: BodyRegion
    let isSelected: Bool
    let frame: CGRect
    let action: () -> Void

    var body: some View {
        EmptyView()
    }
}

struct PainToolResultsView: View {
    let selectedRegions: [BodyRegion]
    let patterns: [PainPattern]

    var body: some View {
        PainResultsView(selectedRegions: selectedRegions, patterns: patterns)
    }
}

struct PainPatternCard: View {
    let pattern: PainPattern

    var body: some View {
        PatternCard(pattern: pattern)
    }
}

struct ExerciseResultRow: View {
    let exercise: Exercise

    var body: some View {
        ExerciseRow(exercise: exercise)
    }
}

// MARK: - Preview

struct PainToolView_Previews: PreviewProvider {
    static var previews: some View {
        PainToolView()
    }
}
