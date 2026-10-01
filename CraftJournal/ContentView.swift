import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(
                keyPath: \CraftEntry.date,
                ascending: false
            )
        ],
        animation: .default
    )
    private var entries: FetchedResults<CraftEntry>

    @State private var showingAddEntry = false

    @State private var searchText = ""   // C2

    var body: some View {
        NavigationStack {

            VStack(alignment: .leading, spacing: 0) {

                // Entry count
                Text("\(entries.count) \(entries.count == 1 ? "entry" : "entries")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 8)

                if entries.isEmpty {

                    // C2: if the user is searching, show "no results"
                    // instead of the "no entries" message
                    if searchText.isEmpty {
                        ContentUnavailableView(
                            "No Craft Entries",
                            systemImage: "book.closed",
                            description: Text(
                                "Add your first Zorig Chusum craft entry."
                            )
                        )
                    } else {
                        ContentUnavailableView.search(text: searchText)
                    }

                } else {

                    List {
                        ForEach(entries) { entry in
                            NavigationLink {
                                EntryDetailView(entry: entry)
                            } label: {
                                EntryRow(entry: entry)
                            }
                        }
                        .onDelete(perform: deleteEntries)
                    }
                }
            }
            .navigationTitle("Craft Journal")
            // C2: search box in the navigation bar
            .searchable(text: $searchText, prompt: "Search by title")
            // C2: re-run the fetch with a filter whenever the text changes
            .onChange(of: searchText) { _, newValue in
                entries.nsPredicate = newValue.isEmpty
                    ? nil
                    : NSPredicate(format: "title CONTAINS[cd] %@", newValue)
            }
            .toolbar {

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddEntry = true
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }

                // C5: open the summary screen
                ToolbarItem(placement: .bottomBar) {
                    NavigationLink {
                        SummaryView()
                    } label: {
                        Label("Summary", systemImage: "chart.bar")
                    }
                }
            }
            .sheet(isPresented: $showingAddEntry) {
                AddEntryView()
                    .environment(
                        \.managedObjectContext,
                        viewContext
                    )
            }
        }
    }

    // Delete entries
    private func deleteEntries(offsets: IndexSet) {
        offsets
            .map { entries[$0] }
            .forEach(viewContext.delete)

        do {
            try viewContext.save()
        } catch {
            print("Could not delete: \(error)")
        }
    }
}


// MARK: - Entry Row

struct EntryRow: View {
    @ObservedObject var entry: CraftEntry

    var body: some View {
        HStack(spacing: 12) {

            // Photo thumbnail
            if let data = entry.photo,
               let uiImage = UIImage(data: data) {

                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 8)
                    )

            } else {

                Image(systemName: "photo")
                    .frame(width: 60, height: 60)
                    .foregroundStyle(.secondary)
            }

            // Entry information
            VStack(alignment: .leading, spacing: 4) {

                Text(entry.title ?? "Untitled")
                    .font(.headline)

                Text(entry.craftType ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(entry.artisanName ?? "Unknown artisan")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}


// MARK: - C5 Summary Screen

struct SummaryView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CraftEntry.date, ascending: false)])
    private var entries: FetchedResults<CraftEntry>

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Total entries")
                        .bold()
                    Spacer()
                    Text("\(entries.count)")
                        .bold()
                }
            }

            Section("By craft") {
                ForEach(crafts, id: \.self) { craft in
                    HStack {
                        Text(craft)
                        Spacer()
                        Text("\(count(for: craft))")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Summary")
    }

    // count the entries whose craftType matches
    private func count(for craft: String) -> Int {
        entries.filter { $0.craftType == craft }.count
    }
}


// MARK: - Preview

#Preview {
    ContentView()
        .environment(
            \.managedObjectContext,
            PersistenceController.preview.container.viewContext
        )
}
