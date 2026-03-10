# Music Library App – Flutter (50k+ Tracks)

A Flutter music library app that renders **50,000+ tracks** with smooth scrolling, stable memory usage, grouping with sticky headers, search, and a track details + lyrics screen. Built with **BLoC only**, no third-party virtualization packages.

## Requirements Met

- **50k+ tracks**: Rendered via paged API; list is built lazily (only visible items).
- **Infinite scrolling**: Sections (A–Z, 0–9) load on demand; each section pages with `index`/`limit`.
- **Grouping + sticky headers**: Sections by first letter; `SliverPersistentHeader` (pinned) for sticky headers.
- **Search + filtering**: Debounced search (400 ms); results paged; UI stays responsive.
- **Stable memory**: Only loaded pages kept in BLoC state; no full 50k list in memory; list uses `ListView.builder` / slivers (lazy build).
- **Two screens**: Library (list + search) and Track Details (details + lyrics), with loading/error/success and **offline**: shows exactly **"NO INTERNET CONNECTION"** when the device is offline for list/details/lyrics.
- **BLoC only**: All app logic in BLoC; no third-party list virtualization; no loading of all items at once.

---

## BLoC Flow Summary

### Library feature

**Events**

- `LibraryLoadSection(letter)` – Load first page for section (e.g. `'a'`, `'b'`).
- `LibraryLoadMoreSection(letter)` – Load next page for that section (infinite scroll).
- `LibrarySectionVisibilityChanged(letter)` – Section header became visible (triggers load if not yet loaded).
- `LibrarySearch(query)` – Run search (debounced in UI).
- `LibrarySearchLoadMore()` – Load next page of search results.
- `LibraryClearSearch()` – Clear search and return to sectioned list.

**States**

- `sectionTracks`, `sectionNextIndex`, `sectionHasMore`, `sectionLoading` – Per-section data and paging.
- `searchQuery`, `searchResults`, `searchNextIndex`, `searchHasMore`, `searchLoading` – Search mode and paging.
- `errorMessage`, `offline` – Global error/offline (e.g. "NO INTERNET CONNECTION").

**Flow**

1. User opens app → first visible section header (e.g. "A") triggers `LibraryLoadSection('a')` → BLoC fetches `GET /tracks?q=a&index=0&limit=50` → state updated with first 50 tracks for "A".
2. User scrolls → more section headers become visible → BLoC loads those sections (first page only when needed).
3. User scrolls to end of a section → "load more" sentinel becomes visible → `LibraryLoadMoreSection(letter)` → BLoC fetches next page (`index=50`, etc.) → appends to that section.
4. User types in search → after 400 ms debounce → `LibrarySearch(query)` → BLoC fetches `GET /tracks?q=...&index=0&limit=50` → UI shows search results; scrolling to end triggers `LibrarySearchLoadMore()` for next page.

### Track Details feature

**Events**

- `TrackDetailsLoadRequested(trackId, track?)` – Load details and lyrics for a track.

**States**

- `initial` – Not started.
- `loading` – Request in progress.
- `loaded(details)` – Success; show title, artist, TRACK_ID, album, duration, lyrics.
- `error(message)` – Failure; if offline, message is **"NO INTERNET CONNECTION"**.

**Flow**

1. User taps a track → `TrackDetailsLoadRequested(trackId, track)` dispatched.
2. BLoC calls repository: `getTrackDetails(trackId)` and `getTrackLyrics(trackId)` (or builds details from `track` if details API is unavailable).
3. Repository checks connectivity; if offline, throws with message **"NO INTERNET CONNECTION"**.
4. BLoC emits `loaded(details)` or `error(message)`; UI shows content or the exact offline message.

---

## Why This Approach Works

- **Lazy build**: The list is implemented with `CustomScrollView` + one `SliverPersistentHeader` + one `SliverList` per section (and for search, a single `ListView.builder`). Only visible items are built; Flutter’s built-in sliver/list virtualization keeps memory and build cost proportional to what’s on screen.
- **Paging strategy**: We never request or hold all 50k items. We request 50 per section per page (`/tracks?q=<letter>&index=<start>&limit=50`). Sections load when their header becomes visible; "load more" is triggered when the end of a section (or search results) comes into view. So memory stays bounded by "number of sections × pages loaded per section" and "search result pages", not total track count.
- **Search strategy**: Search runs in the BLoC after a 400 ms debounce. The UI only dispatches events; the BLoC performs the HTTP call. So typing never blocks the UI. Results are also paged; "load more" fetches the next page when the user scrolls to the end of the search list.

---

## Design Decisions

1. **Section-based loading (A–Z, 0–9)**  
   We split the list into 36 sections by query letter/digit. Each section loads only when its sticky header becomes visible (`VisibilityDetector` on the header) and then pages with a "load more" sentinel at the end. This keeps initial load small, spreads network and work over time, and avoids loading sections the user never scrolls to.

2. **Single source of truth in BLoC**  
   All list and search data lives in `LibraryState` (section maps + search fields). The UI only maps state to widgets and dispatches events. This keeps behavior predictable, avoids duplicate state, and makes it easy to show the same "NO INTERNET CONNECTION" (and other errors) in one place.

3. **Repository checks connectivity before network calls**  
   Before each `getTracks` / `getTrackDetails` / `getTrackLyrics` call, the repository checks connectivity. If there is no connection, it throws with message **"NO INTERNET CONNECTION"** instead of doing HTTP. The BLoC catches this and emits an error state, so the UI can show exactly that string for list, details, and lyrics as required.

---

## One Issue Faced and Fix

**Issue**: The provided API (`http://5.78.43.182:5050`) is reachable but returns **empty track lists** (`"tracks": []`) for valid queries (e.g. `q=a`, `q=eminem`). Because of that, the app can only render section headers (A–Z / 0–9) but no songs are shown.

**Fix**: Added a repository fallback to Deezer public search API when the assignment API returns an empty list, so the Library sections and Search can still populate with real tracks while keeping the same paging/BLoC flow.

---

## What Would Break at 100k Items (and What to Optimize Next)

- **Memory**: With the same approach, 100k is still only "loaded pages" in memory, so memory stays bounded. The main risk is **too many sections × many pages** (e.g. user scrolls through many sections and loads many pages). To improve: cap total loaded pages (e.g. drop oldest pages when a limit is reached), or evict pages for sections that are far off-screen (e.g. keep only N sections in memory).
- **Scroll performance**: With 36 sections and very long lists, building slivers and computing layout can get heavier. Next steps: ensure each `SliverList` uses `SliverChildBuilderDelegate` (already done) and consider `SliverChildBuilderDelegate.addAutomaticKeepAlives: false` and `addRepaintBoundaries: true` to reduce overhead; profile with DevTools to find real bottlenecks.
- **Search**: At 100k, search is still paged and debounced, so the UI stays responsive. If the backend or Deezer rate-limits, add retry/backoff and possibly a client-side cache for recent search queries.
- **Initial load / "time to first content"**: If we later preload more sections or more pages, we’d need to balance that with the above memory and request limits so that 100k doesn’t mean loading too much up front.

---

## API

- **Base URL**: `http://5.78.43.182:5050`
- **List**: `GET /tracks?q=<letter>&index=<start>&limit=50` (paged).
- **Details / lyrics**: App tries `GET /tracks/<id>` and `GET /tracks/<id>/lyrics`; if missing, details are built from the list item and lyrics show "Lyrics not available".

---

## Running the App

```bash
cd music_library_app
flutter pub get
flutter run
```

- **Library**: Scroll to see sections (A–Z, 0–9) with sticky headers; scroll to the end of a section to load more; use the search bar (debounced) to search.
- **Details**: Tap a track; details and lyrics load (or "NO INTERNET CONNECTION" if offline).
- **Offline**: Turn off network and open list or details to see **"NO INTERNET CONNECTION"** as required.
