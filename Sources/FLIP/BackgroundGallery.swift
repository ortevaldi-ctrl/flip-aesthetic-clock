import SwiftUI

struct BackgroundGallery: View {
    @Binding var styleName: String
    @Binding var isPresented: Bool
    @StateObject private var favorites = FavoritesStore()
    @State private var onlyFavorites = false
    private var style: ClockStyle { ClockStyle(rawValue: styleName) ?? .minimalBlack }
    private var collection: [ClockStyle] { ClockStyle.allCases.filter { !onlyFavorites || favorites.contains($0) } }
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Colección · \(ClockStyle.allCases.count) fondos").font(.title2)
                Spacer()
                #if os(macOS)
                collectionPicker
                #endif
                Button("Cerrar") { isPresented = false }
            }
            #if os(iOS)
            collectionPicker
            #endif
            if collection.isEmpty {
                ContentUnavailableView("Aún no hay favoritos", systemImage: "star", description: Text("Marca tus fondos con la estrella para encontrarlos aquí."))
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 220))], spacing: 18) {
                        ForEach(collection) { item in
                            VStack(alignment: .leading, spacing: 10) {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.6)) { styleName = item.rawValue }
                                } label: {
                                    ZStack {
                                        ClockBackground(style: item, animated: false)
                                        HStack(spacing: 5) {
                                            ForEach(["10", "24", "08"], id: \.self) { value in
                                                Text(value).font(.system(size: 28, weight: .semibold, design: .rounded))
                                                    .padding(7).background(Color(white: 0.1), in: RoundedRectangle(cornerRadius: 5))
                                                    .overlay(Rectangle().fill(.black.opacity(0.8)).frame(height: 1))
                                            }
                                        }.accessibilityHidden(true)
                                    }.frame(height: 135).clipShape(RoundedRectangle(cornerRadius: 12))
                                }.buttonStyle(.plain).accessibilityLabel(item.rawValue).accessibilityAddTraits(style == item ? .isSelected : [])
                                HStack {
                                    Text(item.rawValue).font(.system(size: 12))
                                    Spacer()
                                    if style == item { Image(systemName: "checkmark.circle.fill").accessibilityLabel("Seleccionado") }
                                    Button { favorites.toggle(item) } label: { Image(systemName: favorites.contains(item) ? "star.fill" : "star") }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel((favorites.contains(item) ? "Quitar favorito: " : "Añadir favorito: ") + item.rawValue)
                                        .help(favorites.contains(item) ? "Quitar de favoritos" : "Añadir a favoritos")
                                }
                            }.padding(8).background(.white.opacity(style == item ? 0.12 : 0.03), in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
            }
        }.padding(25)
        #if os(macOS)
        .frame(width: 760, height: 550)
        #endif
        .preferredColorScheme(.dark)
    }
    private var collectionPicker: some View {
        Picker("Colección", selection: $onlyFavorites) {
            Text("Todos").tag(false)
            Text("Favoritos").tag(true)
        }.pickerStyle(.segmented)
        #if os(macOS)
        .frame(width: 190)
        #endif
    }
}
