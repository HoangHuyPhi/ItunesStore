import Foundation

class ResultArray:Codable {
  var resultCount = 0
  var results = [SearchResult]()
}

private let typeForKind = [
  "album": NSLocalizedString("Album", comment: "Localized kind: Album"),
  "audiobook": NSLocalizedString("Audio Book", comment: "Localized kind: Audio Book"),
  "book": NSLocalizedString("Book", comment: "Localized kind: Book"),
  "ebook": NSLocalizedString("E-Book", comment: "Localized kind: E-Book"),
  "feature-movie": NSLocalizedString("Movie", comment: "Localized kind: Feature Movie"),
  "music-video": NSLocalizedString("Music Video", comment: "Localized kind: Music Video"),
  "podcast": NSLocalizedString("Podcast", comment: "Localized kind: Podcast"),
  "software": NSLocalizedString("App", comment: "Localized kind: Software"),
  "song": NSLocalizedString("Song", comment: "Localized kind: Song"),
  "tv-episode": NSLocalizedString("TV Episode", comment: "Localized kind: TV Episode"),
]

class SearchResult:Codable, CustomStringConvertible {
  var kind:String?
  var artistName = ""
  var trackName:String?
  var trackPrice:Double?
  var trackViewUrl:String?
  var collectionName:String?
  var collectionViewUrl:String?
  var collectionPrice:Double?
  var itemPrice:Double?
  var itemGenre:String?
  var bookGenre:[String]?
  var currency = ""
  var imageSmall = ""
  var imageLarge = ""
  
  enum CodingKeys: String, CodingKey {
    case imageSmall = "artworkUrl60"
    case imageLarge = "artworkUrl100"
    case itemGenre = "primaryGenreName"
    case bookGenre = "genres"
    case itemPrice = "price"
    case kind, artistName, currency
    case trackName, trackPrice, trackViewUrl
    case collectionName, collectionViewUrl, collectionPrice
  }
  
  var name:String {
    return trackName ?? collectionName ?? ""
  }
  
  var storeURL:String {
    return trackViewUrl ?? collectionViewUrl ?? ""
  }
  
  var price:Double {
    return trackPrice ?? collectionPrice ?? 0.0
  }
  
  var genre:String {
    if let genre = itemGenre {
      return genre
    } else if let genres = bookGenre {
      return genres.joined(separator: ", ")
    }
    return ""
  }
  
  var type: String {
    let kind = self.kind ?? "audiobook"
    return typeForKind[kind] ?? kind
  }
  
  var description:String {
    return "Kind: \(kind ?? ""), Name: \(name), Artist Name: \(artistName)\n"
  }
}

func < (lhs: SearchResult, rhs: SearchResult) -> Bool {
  return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
}
