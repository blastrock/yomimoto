<p align="center">
  <img src="assets/meta/icon.png" width="200" height="200">
</p>

<h1 align="center">読本 Yomimoto</h1>

<p align="center">
  A Japanese book reader with instant dictionary lookup and Anki card creation,
  built for e-ink Android devices.
</p>

---

Yomimoto is a fork of
[jidoujisho](https://github.com/arianneorpilla/jidoujisho) 2.9.1, stripped
down to a reader: the video player, in-app browser, WebSocket, lyrics, ChatGPT
and clipboard sources are gone, and what remains is books, dictionaries and
card creation.

* 📚 Read books offline via an **embedded ッツ Ebook Reader** (EPUB, HTMLZ)
* 🖼️ Read and mine manga pre-processed with **Mokuro**, and export or crop the current image
* 📖 Tap and drag selection of text for **instant dictionary lookups**
* 📘 Import **Yomichan** and **Migaku** dictionaries, with pitch and frequency information
* 🃏 **Export flashcards to AnkiDroid**, with modular enhancements (Forvo audio,
  example sentences from Massif, Tatoeba or ImmersionKit, image pickers, …)

E-ink specific tuning (refresh behaviour, contrast, animation suppression) is
planned.

## Using the application

- **ッツ Ebook Reader** reads books in **EPUB or HTMLZ** format.
- **Mokuro volumes** must be in HTML format, with their images in the relative
  directory.
- **Keep Android WebView up to date.** This resolves most issues with ッツ Ebook
  Reader and Mokuro.
- [Yomichan](https://foosoft.net/projects/yomichan/) dictionaries for Japanese
  can be imported; [some can be found here](https://drive.google.com/drive/folders/1tTdLppnqMfVC5otPlX_cs4ixlIgjv_lH).

### Exporting to AnkiDroid

* AnkiDroid must be installed; on first export Yomimoto adds a **Yomimoto** note
  type to it
* The deck you last exported to is remembered
* Card fields can be edited before export, and export profiles allow other note
  types and field orders
* Tap a field's icon in the Card Creator to lock it, e.g. to export the same
  sentence several times

## Building

```sh
tool/fetch_ttu.sh                                          # ttu reader build → assets/ttu-ebook-reader/
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build apk --release --split-per-abi
```

See [`docs/TOOLCHAIN.md`](docs/TOOLCHAIN.md) for the toolchain versions.

## Author and credits

Yomimoto is developed by **Philippe Daouadi**.

It is based on **jidoujisho** by
[Arianne Orpilla](https://github.com/arianneorpilla) and
[its contributors](https://github.com/arianneorpilla/jidoujisho/graphs/contributors),
originally built for the Japanese language learning community. Logo by suzy
and Aaron Marbella. The embedded reader is a fork of
[ッツ Ebook Reader](https://github.com/ttu-ttu/ebook-reader).

## License

Yomimoto is free software, distributed under the
[GNU General Public License v3](LICENSE), like jidoujisho before it.
