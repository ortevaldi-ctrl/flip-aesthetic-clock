import AppIntents

/// Stable identifiers keep each widget's selection across app updates.
enum WidgetBackgroundChoice: String, AppEnum {
    case minimalBlack
    case darkGradient
    case frostedGlass
    case monochromeAurora
    case liquidChrome
    case topographic
    case mountain
    case darkOcean
    case space
    case moon
    case nightCity
    case whiteNeon
    case technicalGrid
    case abstractMetal
    case particles
    case waves
    case brushedTitanium
    case carbonFiber
    case verticalSplit
    case outline
    case dotMatrix
    case retroFilm
    case earth
    case minimalLines
    case blackSilk
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Fondo"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .minimalBlack: "Minimal Black",
        .darkGradient: "Dark Gradient",
        .frostedGlass: "Frosted Glass",
        .monochromeAurora: "Monochrome Aurora",
        .liquidChrome: "Liquid Chrome",
        .topographic: "Topographic",
        .mountain: "Mountain",
        .darkOcean: "Dark Ocean",
        .space: "Space",
        .moon: "Moon",
        .nightCity: "Night City",
        .whiteNeon: "White Neon",
        .technicalGrid: "Technical Grid",
        .abstractMetal: "Abstract Metal",
        .particles: "Particles",
        .waves: "Waves",
        .brushedTitanium: "Brushed Titanium",
        .carbonFiber: "Carbon Fiber",
        .verticalSplit: "Vertical Split",
        .outline: "Outline",
        .dotMatrix: "Dot Matrix",
        .retroFilm: "Retro Film",
        .earth: "Earth",
        .minimalLines: "Minimal Lines",
        .blackSilk: "Black Silk"
    ]
    var clockStyle: ClockStyle {
        switch self {
        case .minimalBlack: return .minimalBlack
        case .darkGradient: return .darkGradient
        case .frostedGlass: return .frostedGlass
        case .monochromeAurora: return .monochromeAurora
        case .liquidChrome: return .liquidChrome
        case .topographic: return .topographic
        case .mountain: return .mountain
        case .darkOcean: return .darkOcean
        case .space: return .space
        case .moon: return .moon
        case .nightCity: return .nightCity
        case .whiteNeon: return .whiteNeon
        case .technicalGrid: return .technicalGrid
        case .abstractMetal: return .abstractMetal
        case .particles: return .particles
        case .waves: return .waves
        case .brushedTitanium: return .brushedTitanium
        case .carbonFiber: return .carbonFiber
        case .verticalSplit: return .verticalSplit
        case .outline: return .outline
        case .dotMatrix: return .dotMatrix
        case .retroFilm: return .retroFilm
        case .earth: return .earth
        case .minimalLines: return .minimalLines
        case .blackSilk: return .blackSilk
        }
    }
}

struct WidgetBackgroundIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Personalizar FLIP"
    static var description = IntentDescription("Elige el fondo de este widget.")
    @Parameter(title: "Fondo", default: .minimalBlack)
    var background: WidgetBackgroundChoice
    static var parameterSummary: some ParameterSummary {
        Summary("Fondo: \(\.$background)")
    }
}
