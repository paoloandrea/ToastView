# Guida Liquid Glass per iOS/iPadOS/macOS
## Documentazione tecnica per sviluppatori SwiftUI e UIKit

---

## Indice

1. [Introduzione](#introduzione)
2. [Concetti Base](#concetti-base)
3. [Implementazione SwiftUI](#implementazione-swiftui)
4. [Implementazione UIKit](#implementazione-uikit)
5. [Pattern Architetturali](#pattern-architetturali)
6. [Best Practices](#best-practices)
7. [Esempi Pratici](#esempi-pratici)

---

## Introduzione

**Liquid Glass** è un effetto visivo di sistema introdotto da Apple che crea superfici semi-trasparenti con effetto vetro sfumato (blur). Questo effetto combina trasparenza, sfocatura e adattamento dinamico al contenuto sottostante per creare interfacce moderne e eleganti.

### Caratteristiche principali:
- Trasparenza dinamica che si adatta al contenuto sottostante
- Effetto blur multi-livello
- Animazioni fluide tra stati
- Supporto per dark mode e light mode
- Performance ottimizzate dal sistema

### Piattaforme supportate:
- iOS 18.0+
- iPadOS 18.0+
- macOS 15.0+

---

## Concetti Base

### 1. Material vs Glass Effect

**Material** (precedente approccio):
```swift
// Vecchio approccio con Material
.background(.ultraThinMaterial)
.background(.thinMaterial)
.background(.regularMaterial)
.background(.thickMaterial)
.background(.ultraThickMaterial)
```

**Glass Effect** (nuovo approccio):
```swift
// Nuovo approccio con Liquid Glass
.glassEffect(.ultraThin)
.glassEffect(.thin)
.glassEffect(.regular)
.glassEffect(.thick)
.glassEffect(.ultraThick)
```

### 2. Livelli di intensità

| Livello | Trasparenza | Blur | Uso consigliato |
|---------|-------------|------|------------------|
| `.ultraThin` | Massima | Minimo | Overlay leggeri, HUD temporanei |
| `.thin` | Alta | Basso | Badge, etichette fluttuanti |
| `.regular` | Media | Medio | Card, pannelli standard |
| `.thick` | Bassa | Alto | Modali, pannelli principali |
| `.ultraThick` | Minima | Massimo | Background, superfici opache |

### 3. Background Extension Effect

L'effetto `backgroundExtensionEffect()` estende visivamente l'immagine di sfondo oltre i suoi bordi naturali, creando un effetto di continuità visiva.

```swift
Image("background")
    .backgroundExtensionEffect()
```

**Quando usarlo:**
- Immagini hero in header
- Immagini full-screen con scrolling
- Featured content

---

## Implementazione SwiftUI

### 1. Glass Effect su Singoli Elementi

#### Badge con Liquid Glass
```swift
struct BadgeView: View {
    var badge: Badge

    var body: some View {
        Image(systemName: badge.symbolName)
            .foregroundStyle(.white)
            .font(.system(size: 24))
            .fontWeight(.medium)
            .frame(width: 52, height: 52)
            .background {
                Image(systemName: "hexagon.fill")
                    .foregroundStyle(badge.color)
                    .font(.system(size: 48))
            }
            .padding(12)
            // Applica Liquid Glass al badge
            .glassEffect(.regular, in: .rect(cornerRadius: 24))
    }
}
```

**Parametri chiave:**
- `.regular`: livello di intensità del glass effect
- `in: .rect(cornerRadius: 24)`: definisce la forma e il corner radius

#### Button con Glass Style
```swift
Button {
    // Action
} label: {
    Label("Show", systemImage: "hexagon.fill")
        .labelStyle(.iconOnly)
        .font(.system(size: 17))
        .fontWeight(.medium)
}
.buttonStyle(.glass)  // Applica lo stile glass al button
#if os(macOS)
.tint(.clear)  // Su macOS rimuove il tint di default
#endif
```

### 2. Glass Effect Container con Animazioni

Per animare elementi con glass effect, è necessario usare `GlassEffectContainer` e identificatori univoci.

```swift
struct AnimatedBadgesView: View {
    @State private var isExpanded: Bool = false
    @Namespace private var namespace

    var body: some View {
        GlassEffectContainer(spacing: 16) {
            VStack(alignment: .center, spacing: 20) {
                if isExpanded {
                    VStack(spacing: 14) {
                        ForEach(badges) { badge in
                            BadgeLabel(badge: badge)
                                .glassEffect(.regular, in: .rect(cornerRadius: 24))
                                // ID univoco per l'animazione
                                .glassEffectID(badge.id, in: namespace)
                        }
                    }
                }

                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    ToggleLabel(isExpanded: isExpanded)
                        .frame(width: 24, height: 32)
                }
                .buttonStyle(.glass)
                .glassEffectID("togglebutton", in: namespace)
            }
        }
    }
}
```

**Componenti essenziali:**
1. `GlassEffectContainer`: contenitore che coordina le animazioni
2. `@Namespace`: spazio dei nomi per identificare gli elementi
3. `glassEffectID(_:in:)`: assegna ID univoci per animazioni fluide
4. `withAnimation`: anima i cambiamenti di stato

### 3. Background Extension Effect per Immagini Hero

```swift
struct FeaturedItemView: View {
    let item: Item

    var body: some View {
        NavigationLink(value: item) {
            Image(item.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(minWidth: 0, maxWidth: .infinity,
                       minHeight: 0, maxHeight: .infinity)
                .clipped()
                // Estende l'immagine oltre i bordi
                .backgroundExtensionEffect()
                .overlay(alignment: .bottom) {
                    VStack {
                        Text("Featured")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .opacity(0.8)
                        Text(item.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.bottom, 40)
                }
        }
        .buttonStyle(.plain)
    }
}
```

### 4. Flexible Header con Scrolling

Sistema di header che si allunga quando si scrolla oltre il bordo superiore.

#### Step 1: Geometria Observable
```swift
@Observable private class FlexibleHeaderGeometry {
    var offset: CGFloat = 0
}
```

#### Step 2: Content Modifier
```swift
private struct FlexibleHeaderContentModifier: ViewModifier {
    @Environment(ModelData.self) private var modelData
    @Environment(FlexibleHeaderGeometry.self) private var geometry

    func body(content: Content) -> some View {
        let height = (modelData.windowSize.height / 2) - geometry.offset
        content
            .frame(height: height)
            .padding(.bottom, geometry.offset)
            .offset(y: geometry.offset)
    }
}
```

#### Step 3: ScrollView Modifier
```swift
private struct FlexibleHeaderScrollViewModifier: ViewModifier {
    @State private var geometry = FlexibleHeaderGeometry()

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                min(geometry.contentOffset.y + geometry.contentInsets.top, 0)
            } action: { _, offset in
                geometry.offset = offset
            }
            .environment(geometry)
    }
}
```

#### Step 4: View Extensions
```swift
extension ScrollView {
    func flexibleHeaderScrollView() -> some View {
        modifier(FlexibleHeaderScrollViewModifier())
    }
}

extension View {
    func flexibleHeaderContent() -> some View {
        modifier(FlexibleHeaderContentModifier())
    }
}
```

#### Step 5: Utilizzo
```swift
struct ContentView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 14) {
                // Header con effetto flexible
                FeaturedItemView(item: featuredItem)
                    .flexibleHeaderContent()

                // Resto del contenuto
                ForEach(items) { item in
                    ItemRow(item: item)
                }
            }
        }
        .flexibleHeaderScrollView()
        .ignoresSafeArea(edges: .top)
    }
}
```

### 5. Readability Gradient per Testo su Immagini

```swift
struct ReadabilityRoundedRectangle: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 15)
            .foregroundStyle(.clear)
            .background(
                LinearGradient(
                    colors: [.black.opacity(0.8), .clear],
                    startPoint: .bottom,
                    endPoint: .center
                )
            )
            .containerRelativeFrame(.vertical)
            .clipped()
    }
}
```

**Utilizzo:**
```swift
Image("thumbnail")
    .resizable()
    .aspectRatio(contentMode: .fill)
    .overlay {
        ReadabilityRoundedRectangle()
    }
    .overlay(alignment: .bottom) {
        Text("Title")
            .foregroundColor(.white)
            .padding()
    }
```

---

## Implementazione UIKit

### 1. UIVisualEffectView - Approccio Base

```swift
class GlassViewController: UIViewController {

    private lazy var glassView: UIVisualEffectView = {
        // Crea l'effetto blur
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let view = UIVisualEffectView(effect: blurEffect)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupGlassView()
    }

    private func setupGlassView() {
        view.addSubview(glassView)

        NSLayoutConstraint.activate([
            glassView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            glassView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            glassView.topAnchor.constraint(equalTo: view.topAnchor),
            glassView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Aggiungi contenuto al contentView
        addContentToGlassView()
    }

    private func addContentToGlassView() {
        let label = UILabel()
        label.text = "Glass Effect"
        label.textColor = .white
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false

        glassView.contentView.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: glassView.contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: glassView.contentView.centerYAnchor)
        ])
    }
}
```

### 2. Livelli di Material in UIKit

```swift
enum GlassMaterialLevel {
    case ultraThin
    case thin
    case regular
    case thick
    case ultraThick

    var blurStyle: UIBlurEffect.Style {
        switch self {
        case .ultraThin:
            return .systemUltraThinMaterial
        case .thin:
            return .systemThinMaterial
        case .regular:
            return .systemMaterial
        case .thick:
            return .systemThickMaterial
        case .ultraThick:
            return .systemChromeMaterial
        }
    }
}

class GlassView: UIView {

    private let level: GlassMaterialLevel
    private var effectView: UIVisualEffectView!

    init(level: GlassMaterialLevel, frame: CGRect = .zero) {
        self.level = level
        super.init(frame: frame)
        setupGlassEffect()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupGlassEffect() {
        let blur = UIBlurEffect(style: level.blurStyle)
        effectView = UIVisualEffectView(effect: blur)
        effectView.frame = bounds
        effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        insertSubview(effectView, at: 0)
    }

    var contentView: UIView {
        return effectView.contentView
    }
}
```

### 3. Glass Button (UIKit)

```swift
class GlassButton: UIButton {

    private let glassView: UIVisualEffectView
    private let vibrancyView: UIVisualEffectView

    override init(frame: CGRect) {
        // Setup blur effect
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        glassView = UIVisualEffectView(effect: blurEffect)

        // Setup vibrancy effect per il testo
        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect, style: .label)
        vibrancyView = UIVisualEffectView(effect: vibrancyEffect)

        super.init(frame: frame)

        setupGlassEffect()
        setupAppearance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupGlassEffect() {
        // Aggiungi glass view
        glassView.frame = bounds
        glassView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        glassView.isUserInteractionEnabled = false
        insertSubview(glassView, at: 0)

        // Aggiungi vibrancy view
        vibrancyView.frame = glassView.contentView.bounds
        vibrancyView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        vibrancyView.isUserInteractionEnabled = false
        glassView.contentView.addSubview(vibrancyView)

        // Corner radius
        layer.cornerRadius = 12
        layer.masksToBounds = true
    }

    private func setupAppearance() {
        if let titleLabel = titleLabel {
            vibrancyView.contentView.addSubview(titleLabel)
        }

        if let imageView = imageView {
            vibrancyView.contentView.addSubview(imageView)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        glassView.frame = bounds
        vibrancyView.frame = glassView.contentView.bounds
    }
}
```

### 4. Glass Container con Badge (UIKit)

```swift
class BadgeGlassContainer: UIView {

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private var badges: [BadgeView] = []
    private var isExpanded: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }

    func addBadge(_ badge: BadgeView) {
        badges.append(badge)
        badge.alpha = isExpanded ? 1 : 0
        badge.transform = isExpanded ? .identity : CGAffineTransform(scaleX: 0.1, y: 0.1)
        stackView.addArrangedSubview(badge)
    }

    @objc func toggleExpansion() {
        isExpanded.toggle()

        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.5,
            options: .curveEaseInOut
        ) {
            self.badges.forEach { badge in
                badge.alpha = self.isExpanded ? 1 : 0
                badge.transform = self.isExpanded ? .identity : CGAffineTransform(scaleX: 0.1, y: 0.1)
            }
            self.layoutIfNeeded()
        }
    }
}

class BadgeView: UIView {

    private let glassView: UIVisualEffectView
    private let iconImageView: UIImageView

    init(systemName: String, color: UIColor) {
        // Setup glass effect
        let blur = UIBlurEffect(style: .systemMaterial)
        glassView = UIVisualEffectView(effect: blur)

        // Setup icon
        iconImageView = UIImageView(image: UIImage(systemName: systemName))
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit

        super.init(frame: .zero)

        setupView(color: color)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView(color: UIColor) {
        // Glass background
        glassView.frame = bounds
        glassView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        glassView.layer.cornerRadius = 24
        glassView.layer.masksToBounds = true
        addSubview(glassView)

        // Background hexagon
        let hexagonView = UIImageView(image: UIImage(systemName: "hexagon.fill"))
        hexagonView.tintColor = color
        hexagonView.translatesAutoresizingMaskIntoConstraints = false
        glassView.contentView.addSubview(hexagonView)

        // Icon
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        glassView.contentView.addSubview(iconImageView)

        // Constraints
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 76),
            heightAnchor.constraint(equalToConstant: 76),

            hexagonView.centerXAnchor.constraint(equalTo: centerXAnchor),
            hexagonView.centerYAnchor.constraint(equalTo: centerYAnchor),
            hexagonView.widthAnchor.constraint(equalToConstant: 52),
            hexagonView.heightAnchor.constraint(equalToConstant: 52),

            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        glassView.frame = bounds
    }
}
```

### 5. Flexible Header ScrollView (UIKit)

```swift
class FlexibleHeaderScrollViewController: UIViewController {

    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()

    private let headerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private var headerHeightConstraint: NSLayoutConstraint!
    private var headerTopConstraint: NSLayoutConstraint!

    private let initialHeaderHeight: CGFloat = 300

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
    }

    private func setupViews() {
        view.addSubview(scrollView)
        view.addSubview(headerImageView)

        scrollView.delegate = self
        scrollView.contentInsetAdjustmentBehavior = .never
    }

    private func setupConstraints() {
        headerHeightConstraint = headerImageView.heightAnchor.constraint(
            equalToConstant: initialHeaderHeight
        )
        headerTopConstraint = headerImageView.topAnchor.constraint(
            equalTo: view.topAnchor
        )

        NSLayoutConstraint.activate([
            headerImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerTopConstraint,
            headerHeightConstraint,

            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension FlexibleHeaderScrollViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y

        // Stretch header quando si scrolla oltre il top
        if offsetY < 0 {
            headerHeightConstraint.constant = initialHeaderHeight - offsetY
            headerTopConstraint.constant = 0
        } else {
            // Mantieni l'altezza normale
            headerHeightConstraint.constant = initialHeaderHeight
            headerTopConstraint.constant = -offsetY
        }
    }
}
```

### 6. Background Extension Effect (UIKit)

```swift
class BackgroundExtensionImageView: UIImageView {

    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.1).cgColor,
            UIColor.black.withAlphaComponent(0.3).cgColor
        ]
        layer.locations = [0.0, 0.5, 1.0]
        return layer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupExtensionEffect()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupExtensionEffect()
    }

    private func setupExtensionEffect() {
        contentMode = .scaleAspectFill
        clipsToBounds = false

        // Aggiungi layer per l'estensione visiva
        layer.addSublayer(gradientLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Estendi il frame oltre i bordi
        let extendedBounds = bounds.insetBy(dx: -20, dy: -20)
        gradientLayer.frame = extendedBounds
    }
}
```

---

## Pattern Architetturali

### 1. Costanti Centralizzate

```swift
struct Constants {
    // Glass Effect
    static let cornerRadius: CGFloat = 15.0
    static let standardPadding: CGFloat = 14.0

    // Badge
    static let badgeSize: CGFloat = 52.0
    static let badgeGlassSpacing: CGFloat = 16.0
    static let badgeSpacing: CGFloat = 14.0
    static let badgeCornerRadius: CGFloat = 24.0
    static let badgeFrameWidth: CGFloat = 74.0

    // Material Style
    #if os(macOS)
    static let editingBackgroundStyle = WindowBackgroundShapeStyle.windowBackground
    #else
    static let editingBackgroundStyle = Material.ultraThickMaterial
    #endif
}
```

### 2. View Modifiers Riutilizzabili (SwiftUI)

```swift
struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = Constants.cornerRadius
    var level: Material = .regular

    func body(content: Content) -> some View {
        content
            .padding()
            .background(level, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    func glassCard(
        cornerRadius: CGFloat = Constants.cornerRadius,
        level: Material = .regular
    ) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, level: level))
    }
}

// Utilizzo
Text("Content")
    .glassCard()
```

### 3. Componenti Riutilizzabili (UIKit)

```swift
class GlassCard: UIView {

    private let effectView: UIVisualEffectView
    private let contentStackView: UIStackView

    var contentView: UIView {
        return contentStackView
    }

    init(level: GlassMaterialLevel = .regular, cornerRadius: CGFloat = 15) {
        let blur = UIBlurEffect(style: level.blurStyle)
        effectView = UIVisualEffectView(effect: blur)

        contentStackView = UIStackView()
        contentStackView.axis = .vertical
        contentStackView.spacing = 8

        super.init(frame: .zero)

        setupView(cornerRadius: cornerRadius)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView(cornerRadius: CGFloat) {
        effectView.frame = bounds
        effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        effectView.layer.cornerRadius = cornerRadius
        effectView.layer.masksToBounds = true
        addSubview(effectView)

        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        effectView.contentView.addSubview(contentStackView)

        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: effectView.contentView.topAnchor, constant: 16),
            contentStackView.leadingAnchor.constraint(equalTo: effectView.contentView.leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: effectView.contentView.trailingAnchor, constant: -16),
            contentStackView.bottomAnchor.constraint(equalTo: effectView.contentView.bottomAnchor, constant: -16)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        effectView.frame = bounds
    }
}
```

---

## Best Practices

### 1. Performance

#### SwiftUI
```swift
// ✅ BUONO: Lazy loading con glass effect
ScrollView {
    LazyVStack {
        ForEach(items) { item in
            ItemView(item: item)
                .glassEffect(.regular)
        }
    }
}

// ❌ EVITARE: Troppi effetti glass annidati
VStack {
    ForEach(items) { item in
        VStack {
            Text(item.title)
                .glassEffect(.thin)  // ❌ Eccessivo
        }
        .glassEffect(.regular)  // ❌ Annidamento non necessario
    }
    .glassEffect(.thick)  // ❌ Troppi livelli
}
```

#### UIKit
```swift
// ✅ BUONO: Riutilizza UIVisualEffectView
class OptimizedViewController: UIViewController {
    private lazy var glassView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(glassView)
        // Setup constraints una sola volta
    }
}

// ❌ EVITARE: Creare nuovi effect view continuamente
func addItem() {
    let glassView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    // ❌ Creare ogni volta è costoso
    view.addSubview(glassView)
}
```

### 2. Accessibilità

#### SwiftUI
```swift
BadgeView(badge: badge)
    .glassEffect(.regular, in: .rect(cornerRadius: 24))
    .accessibilityLabel(badge.name)
    .accessibilityHint("Double tap to view details")
```

#### UIKit
```swift
class AccessibleGlassButton: GlassButton {
    override init(frame: CGRect) {
        super.init(frame: frame)

        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = "Show Details"
        accessibilityHint = "Double tap to open details view"
    }
}
```

### 3. Dark Mode e Light Mode

#### SwiftUI
```swift
// Il sistema gestisce automaticamente, ma puoi personalizzare
struct AdaptiveGlassView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            Text("Content")
        }
        .glassEffect(colorScheme == .dark ? .thick : .regular)
    }
}
```

#### UIKit
```swift
class AdaptiveGlassView: UIView {
    private var effectView: UIVisualEffectView!

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateGlassEffect()
        }
    }

    private func updateGlassEffect() {
        let style: UIBlurEffect.Style = traitCollection.userInterfaceStyle == .dark
            ? .systemThickMaterial
            : .systemMaterial

        effectView.effect = UIBlurEffect(style: style)
    }
}
```

### 4. Animazioni Fluide

#### SwiftUI
```swift
struct AnimatedGlassCard: View {
    @State private var isExpanded = false

    var body: some View {
        VStack {
            Text("Content")
        }
        .frame(height: isExpanded ? 200 : 100)
        .glassEffect(.regular, in: .rect(cornerRadius: 15))
        .onTapGesture {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isExpanded.toggle()
            }
        }
    }
}
```

#### UIKit
```swift
func animateGlassExpansion() {
    UIView.animate(
        withDuration: 0.6,
        delay: 0,
        usingSpringWithDamping: 0.7,
        initialSpringVelocity: 0.5,
        options: .curveEaseInOut
    ) {
        self.glassView.frame.size.height = self.isExpanded ? 200 : 100
        self.view.layoutIfNeeded()
    }
}
```

---

## Esempi Pratici

### Esempio 1: Card List con Glass Effect

#### SwiftUI
```swift
struct GlassCardListView: View {
    let items: [Item]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(items) { item in
                    GlassCardRow(item: item)
                }
            }
            .padding()
        }
    }
}

struct GlassCardRow: View {
    let item: Item

    var body: some View {
        HStack {
            Image(systemName: item.icon)
                .font(.title)

            VStack(alignment: .leading) {
                Text(item.title)
                    .font(.headline)
                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 15))
    }
}
```

#### UIKit
```swift
class GlassCardListViewController: UIViewController {

    private let tableView: UITableView = {
        let table = UITableView()
        table.separatorStyle = .none
        table.backgroundColor = .clear
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(GlassCardCell.self, forCellReuseIdentifier: "GlassCard")

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

class GlassCardCell: UITableViewCell {

    private let cardView = GlassCard()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCell() {
        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(cardView)

        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.tintColor = .label

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = .secondaryLabel

        let stackView = UIStackView(arrangedSubviews: [iconImageView, titleLabel, subtitleLabel])
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.alignment = .center

        cardView.contentView.addArrangedSubview(stackView)

        cardView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 7),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -7)
        ])
    }

    func configure(with item: Item) {
        iconImageView.image = UIImage(systemName: item.icon)
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
    }
}
```

### Esempio 2: Modal con Glass Background

#### SwiftUI
```swift
struct GlassModalView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // Background scuro semi-trasparente
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Modal con glass effect
            VStack(spacing: 20) {
                Text("Modal Title")
                    .font(.title)
                    .fontWeight(.bold)

                Text("This is a modal with liquid glass effect")
                    .multilineTextAlignment(.center)

                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(30)
            .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 20))
            .padding(40)
        }
    }
}
```

#### UIKit
```swift
class GlassModalViewController: UIViewController {

    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var glassView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemUltraThickMaterial)
        let view = UIVisualEffectView(effect: blur)
        view.layer.cornerRadius = 20
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupModal()
        animateIn()
    }

    private func setupModal() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)

        view.addSubview(containerView)
        containerView.addSubview(glassView)

        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Modal Title"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Message
        let messageLabel = UILabel()
        messageLabel.text = "This is a modal with liquid glass effect"
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        // Close button
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Close", for: .normal)
        closeButton.addTarget(self, action: #selector(closeModal), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        glassView.contentView.addSubview(titleLabel)
        glassView.contentView.addSubview(messageLabel)
        glassView.contentView.addSubview(closeButton)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            glassView.topAnchor.constraint(equalTo: containerView.topAnchor),
            glassView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            glassView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            glassView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: glassView.contentView.topAnchor, constant: 30),
            titleLabel.centerXAnchor.constraint(equalTo: glassView.contentView.centerXAnchor),

            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            messageLabel.leadingAnchor.constraint(equalTo: glassView.contentView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: glassView.contentView.trailingAnchor, constant: -20),

            closeButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 30),
            closeButton.centerXAnchor.constraint(equalTo: glassView.contentView.centerXAnchor),
            closeButton.bottomAnchor.constraint(equalTo: glassView.contentView.bottomAnchor, constant: -30)
        ])

        // Tap gesture per chiudere
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(closeModal))
        view.addGestureRecognizer(tapGesture)
    }

    private func animateIn() {
        containerView.alpha = 0
        containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)

        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.5
        ) {
            self.containerView.alpha = 1
            self.containerView.transform = .identity
        }
    }

    @objc private func closeModal() {
        UIView.animate(withDuration: 0.3) {
            self.containerView.alpha = 0
            self.containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            self.view.alpha = 0
        } completion: { _ in
            self.dismiss(animated: false)
        }
    }
}
```

### Esempio 3: Floating Action Button con Glass

#### SwiftUI
```swift
struct FloatingGlassButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
        }
        .buttonStyle(.glass)
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

// Utilizzo
struct ContentView: View {
    var body: some View {
        ZStack {
            // Contenuto principale
            ScrollView {
                // ...
            }

            // FAB
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingGlassButton {
                        print("FAB tapped")
                    }
                    .padding(20)
                }
            }
        }
    }
}
```

#### UIKit
```swift
class FloatingGlassButton: UIButton {

    private let glassView: UIVisualEffectView

    override init(frame: CGRect) {
        let blur = UIBlurEffect(style: .systemMaterial)
        glassView = UIVisualEffectView(effect: blur)

        super.init(frame: frame)

        setupButton()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupButton() {
        // Glass background
        glassView.frame = bounds
        glassView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        glassView.layer.cornerRadius = 28
        glassView.layer.masksToBounds = true
        glassView.isUserInteractionEnabled = false
        insertSubview(glassView, at: 0)

        // Icon
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        tintColor = .white

        // Shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0, height: 5)
        layer.shadowRadius = 10

        // Size
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 56),
            heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        glassView.frame = bounds
        glassView.layer.cornerRadius = bounds.height / 2
    }
}

// Utilizzo in ViewController
class MainViewController: UIViewController {

    private lazy var fab: FloatingGlassButton = {
        let button = FloatingGlassButton()
        button.addTarget(self, action: #selector(fabTapped), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(fab)

        NSLayoutConstraint.activate([
            fab.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            fab.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    @objc private func fabTapped() {
        print("FAB tapped")
    }
}
```

---

## Riferimenti e Risorse

### Documentazione Apple
- [Human Interface Guidelines - Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- [SwiftUI Material](https://developer.apple.com/documentation/swiftui/material)
- [UIVisualEffectView](https://developer.apple.com/documentation/uikit/uivisualeffectview)
- [UIBlurEffect](https://developer.apple.com/documentation/uikit/uiblureffect)

### Sample Project
- [Landmarks: Building an app with Liquid Glass](https://developer.apple.com/documentation/swiftui/landmarks-building-an-app-with-liquid-glass)

### File di Riferimento nel Progetto
- [`FlexibleHeader.swift`](Landmarks/Landmarks/Views/Landmarks/FlexibleHeader.swift) - Header elastico con scroll
- [`BadgesView.swift`](Landmarks/Landmarks/Views/Badges/BadgesView.swift) - Badge animati con glass effect
- [`LandmarkFeaturedItemView.swift`](Landmarks/Landmarks/Views/Landmarks/Landmarks%20View/LandmarkFeaturedItemView.swift) - Background extension effect
- [`ReadabilityRoundedRectangle.swift`](Landmarks/Landmarks/Views/Landmarks/Landmarks%20View/ReadabilityRoundedRectangle.swift) - Gradient per leggibilità
- [`Constants.swift`](Landmarks/Landmarks/Model/Constants.swift) - Costanti centralizzate

---

## Note sulla Compatibilità

### Requisiti Minimi
- **SwiftUI Liquid Glass**: iOS 18.0+, iPadOS 18.0+, macOS 15.0+
- **UIKit Material**: iOS 13.0+, iPadOS 13.0+, macOS 10.15+

### Fallback per Versioni Precedenti

#### SwiftUI
```swift
struct AdaptiveGlassView: View {
    var body: some View {
        VStack {
            Text("Content")
        }
        .background {
            if #available(iOS 18.0, *) {
                // Nuovo glass effect
                RoundedRectangle(cornerRadius: 15)
                    .glassEffect(.regular)
            } else {
                // Fallback con Material
                RoundedRectangle(cornerRadius: 15)
                    .fill(.regularMaterial)
            }
        }
    }
}
```

#### UIKit
```swift
func createGlassEffect() -> UIVisualEffectView {
    if #available(iOS 13.0, *) {
        return UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    } else {
        // Fallback per iOS < 13
        return UIVisualEffectView(effect: UIBlurEffect(style: .light))
    }
}
```

---

## Conclusione

Questa guida fornisce una panoramica completa dell'implementazione del Liquid Glass Effect sia in SwiftUI che in UIKit. Gli esempi sono basati sul progetto ufficiale Apple "Landmarks" e coprono:

- ✅ Concetti base e differenze tra Material e Glass Effect
- ✅ Implementazioni complete per SwiftUI
- ✅ Implementazioni complete per UIKit
- ✅ Pattern architetturali e best practices
- ✅ Esempi pratici pronti all'uso
- ✅ Gestione accessibilità e performance
- ✅ Compatibilità e fallback

Utilizza questa documentazione come riferimento durante lo sviluppo di interfacce moderne con effetto Liquid Glass.
