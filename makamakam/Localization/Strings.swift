import Foundation

/// Every word the app says, in both languages, in one file.
///
/// Seed content — names, landmark sentences, the memories people wrote — stays in
/// the language it was written in. Translating a neighbour's sentence about a
/// swept yard would be putting words in their mouth.
enum S: String {
    // Shared
    case close, cancel, save, recorded
    case verifiedYes, verifiedNo
    case lockDistance, lockDistanceUnknown, lockAtSite
    case simulationBadge, pretendPresentBadge
    case hapticsEyebrow, hapticsToggle, hapticsNote

    // Tabs
    case tabFind, tabSaved, tabSettings

    // Find
    case findPrivacyNote
    case findMapCaveat, findRecentre
    case savedTitle, savedEmpty, savedEmptyNote, settingsTitle
    case nearbySurveyed, nearbyNotSurveyed, nearbyDirections, nearbyFromAppleMaps
    case nearbyDismiss
    case findCemeteryPlaceholder, findCemeteryPrivacyNote
    case legendSurveyed, legendNotSurveyed
    case resultsNearby, resultsElsewhere, resultsSearching
    case findNoCemeteries, findNoCemeteriesNote
    case cemeteryOpen, cemeteryGravesEyebrow, cemeteryGraveSearch
    case cemeteryNoGraves, cemeterySurveyNote
    case cemeteryNoPhoto, cemeteryPhotoCount
    case fieldSitePhotoHeader, fieldSitePhotoAdd, fieldSitePhotoClear
    case fieldSitePhotoCount, fieldSitePhotoNote
    case fieldStandHeader, fieldStandAtGate, fieldStandNote
    case searchClearAccessibility

    // Grave
    case graveSave, graveUnsave
    case doorGuideTitle, doorGuideDetail
    case doorTendTitle, doorTendDetail
    case doorWallTitle, doorWallDetail, doorProfileTitle, doorProfileDetail
    case stewardEyebrow, stewardNote
    case claimNone, claimButton, claimNeedsName
    case diedOn, born, died
    case parentageBin, parentageBinti, parentageSon, parentageDaughter, parentageChild
    case photosEyebrow, photoHeadstone, photoPerson, photoClose

    // Orient
    case orientWalk, orientPlanAccessibility
    case planAccessibility, planNorthUp, planFacing, planTapHint, planYouAre, planYouElsewhere
    case planExpand, planReset, planOpenGrave, planFullHint, planFollow
    case planNoFix, planPretending

    // Approach
    case approachAccuracy, approachAccuracyUnknown, approachHonestyNote
    case approachCompassUntrusted, approachWaiting
    case arrowAccessibility, closeGuideAccessibility

    // Arrive
    case arriveHeadline, arriveConfirm, arriveReject, arrivePhotoMissing

    // Tend
    case tendTitle, tendGuidanceEyebrow
    case flowerNote
    case flowerButton
    case passageHowToRead, passageMeaning

    // Faith and traditions
    case faithIslam, faithHindu, faithKristen, faithKatolik
    case faithBuddha, faithKonghucu, faithOther, faithUnrecorded
    case guidanceFollowsRecord, guidanceFallback, guidanceNoneForFaith
    case traditionIslam, traditionHindu, traditionNone
    case traditionHinduNote, traditionNoneNote

    // The wall
    case wallTitle, wallEmpty, wallEmptyNote
    case wallOpen, wallFamilyOnly, wallClosed
    case wallOpenNote, wallFamilyOnlyNote, wallClosedNote
    case wallVisibilityEyebrow, wallHiddenFromYou
    case wallCheckIn
    case wallPostHereNote, wallPostAwayNote, wallPostTitle, wallPostSend, wallCanCheckIn
    case wallCheckInNote
    case wallVisited, wallVisitedWithFlowers, wallWroteStory
    case wallAddStory, wallStoryPlaceholder
    case wallSince, wallModerationNote

    // The profile
    case profileTitle, profileEmpty, profileEmptyNote, profileEyebrow

    // Memories
    case pendingSteward, pendingFamily, moderateShow, moderateRemove

    // Write
    case writtenByEyebrow, fieldName, fieldRelationship, attributionNote
    case relationshipUnstated

    // Field mode (hidden behind the version number)
    case fieldTitle, fieldPresenceHeader, fieldPresenceToggle, fieldPresenceNote
    case fieldHapticsHeader, fieldPulseToggle, fieldRehearse, fieldRehearseStop
    case fieldRehearseAt, fieldInterval, fieldIntensity, fieldHoldAt
    case fieldTapNear, fieldTapArrive, fieldHapticsNote
    case fieldSurveyHeader, fieldRecordGrave, fieldExport
    case fieldSimHeader, fieldSimTarget, fieldSimStart, fieldSimStop, fieldSimNote
    case fieldStateHeader, fieldAuth, fieldPosition, fieldAccuracy
    case fieldHeading, fieldHeadingUsable, fieldDistanceToSite, fieldCountedPresent
    case fieldNone, fieldYes, fieldNo
    case authNotAsked, authDenied, authRestricted, authAlways, authWhenInUse, authUnknown

    // Survey capture and export
    case surveyTitle, surveyIdentity, surveyNameField, surveyFatherField
    case surveyGender, surveyGenderMale, surveyGenderFemale, surveyUnrecorded
    case surveyDeathDate, surveyBlock, surveyRow, surveyPlot, surveyReligion
    case plotBlock, plotRow, plotPlot, plotEyebrow
    case surveyCoordsHeader, surveyWaitingFix, surveyAccuracyValue, surveyCoordsNote
    case surveyHeadstoneHeader, surveyTakePhoto, surveyRetakePhoto
    case surveyPortraitHeader, surveyTakePortrait, surveyRetakePortrait, surveyPortraitNote
    case surveyLandmarkHeader, surveyLandmarkField, surveyLandmarkNote
    case surveySave, surveySaved
    case exportTitle, exportCount, exportEmpty, exportPrepare, exportShare, exportNote

    // About
    case aboutLede
    case aboutYouEyebrow, aboutYouNote
    case familyToggle, familyToggleNote
    case languageEyebrow, guidanceLabel
    case notDoingEyebrow, principleNotifications, principleCounts
    case principleNothingAdded, principlePurchases, principleNoVirtual
    case dataEyebrow, dataNote, prayerReviewNote, versionLine
    case syncEyebrow, syncNever, syncAt, syncChecking, syncFailed, syncRefresh, syncNote, syncUnavailable
    case icloudEyebrow, icloudSignedIn, icloudNoAccount, icloudRestricted, icloudUnknown
    case icloudNote, icloudQuotaNote
    case postDestinationTitle, postDestinationBody, postDestinationAgree, postDestinationCancel
}

enum Strings {
    static let table: [S: (id: String, en: String)] = [

        // MARK: Shared
        .close: ("Tutup", "Close"),
        .cancel: ("Batal", "Cancel"),
        .save: ("Simpan", "Save"),
        .recorded: ("Tercatat.", "Recorded."),
        .verifiedYes: ("Sudah dicek di lokasi", "Checked on site"),
        .verifiedNo: ("Belum dicek di lokasi", "Not checked on site"),
        .lockDistance: (
            "Anda sekitar %@ dari sana.",
            "You are about %@ from there."
        ),
        .lockDistanceUnknown: (
            "Jarak Anda belum diketahui.",
            "How far away you are is not known yet."
        ),
        .lockAtSite: ("Anda berada di pemakaman.", "You are at the cemetery."),
        .simulationBadge: ("Mode simulasi", "Simulation mode"),
        .hapticsEyebrow: ("Getaran", "Vibration"),
        .hapticsToggle: ("Getaran saat mendekat", "Pulse as you get closer"),
        .hapticsNote: (
            "Ponsel berdenyut makin sering dan makin kuat saat Anda mendekat, supaya ponsel bisa tetap di sisi badan dan mata Anda pada barisan makam. Getaran berhenti begitu Anda sampai.",
            "The phone pulses faster and stronger as you close in, so it can stay at your side and your eyes can stay on the rows. It stops the moment you arrive."
        ),
        .pretendPresentBadge: (
            "Mode uji — dianggap berada di pemakaman",
            "Test mode — treated as present at the cemetery"
        ),

        // MARK: Tabs
        .tabFind: ("Cari", "Find"),
        .tabSaved: ("Disimpan", "Saved"),
        .tabSettings: ("Pengaturan", "Settings"),

        .savedTitle: ("Makam yang Anda simpan", "Graves you kept"),
        .savedEmpty: ("Belum ada makam yang disimpan.", "You haven't kept any graves yet."),
        .savedEmptyNote: (
            "Cari sebuah nama, lalu ketuk tanda pembatas di kanan atas untuk menyimpannya di sini. Daftar ini hanya milik Anda — pengguna lain tidak bisa melihatnya.",
            "Search a name, then tap the bookmark at the top right to keep it here. This list is yours alone — no other user can see it."
        ),
        .settingsTitle: ("Pengaturan", "Settings"),
        .findMapCaveat: (
            "Peta hanya sampai gerbang. Di dalam, denah blok dan penanda nisan yang menuntun.",
            "The map only reaches the gate. Inside, the block plan and the headstone description take over."
        ),
        .findRecentre: ("Kembali ke pemakaman", "Back to the cemetery"),
        .nearbySurveyed: ("Sudah disurvei", "Surveyed"),
        .nearbyFromAppleMaps: (
            "Dari peta Apple. Belum ada catatan makam di aplikasi ini.",
            "From Apple Maps. This app holds no grave records for it."
        ),
        .nearbyNotSurveyed: (
            "Belum disurvei — aplikasi hanya bisa mengantar sampai gerbang.",
            "Not surveyed — the app can only take you to the gate."
        ),
        .nearbyDirections: ("Rute", "Directions"),
        .nearbyDismiss: ("Tutup keterangan", "Close this marker"),
        .findCemeteryPlaceholder: ("Cari pemakaman atau nama kota", "Cemetery or city name"),
        .findCemeteryPrivacyNote: (
            "Mulai dari pemakamannya — di sekitar sini atau di kota lain. Nama almarhum dicari di dalam pemakaman yang sudah disurvei.",
            "Start with the burial ground, here or in another city. Names are searched inside a cemetery that has been surveyed."
        ),
        .findNoCemeteries: ("Tidak ada pemakaman yang cocok.", "No cemetery matches that."),
        .findNoCemeteriesNote: (
            "Coba nama kotanya — misalnya Jakarta — atau geser peta lalu ketuk penandanya.",
            "Try the name of a city — Jakarta, say — or move the map and tap a marker."
        ),
        .resultsNearby: ("Di sekitar sini", "Around here"),
        .resultsElsewhere: ("Di kota lain", "Further away"),
        .resultsSearching: ("Mencari…", "Searching…"),
        .legendSurveyed: ("Bisa dicari sampai ke makam", "Searchable down to a grave"),
        .legendNotSurveyed: ("Hanya sampai gerbang", "Only as far as the gate"),
        .cemeteryOpen: ("Buka pemakaman ini", "Open this cemetery"),
        .cemeteryNoPhoto: (
            "Belum ada foto pemakaman ini. Foto diambil saat survei lapangan.",
            "No photograph of this cemetery yet. They are taken during the field survey."
        ),
        .cemeteryPhotoCount: ("%1$d dari %2$d", "%1$d of %2$d"),
        .fieldSitePhotoHeader: ("Foto pemakaman", "Cemetery photographs"),
        .fieldSitePhotoAdd: ("Ambil foto pemakaman", "Photograph the cemetery"),
        .fieldSitePhotoClear: ("Hapus semua foto pemakaman", "Delete all cemetery photographs"),
        .fieldSitePhotoCount: ("%d foto tersimpan", "%d photographs kept"),
        .fieldSitePhotoNote: (
            "Foto gerbang atau jalan masuk — yang dikenali orang dari jalan. Foto ini yang muncul sebagai penanda di peta dan sebagai foto utama di layar pemakaman. Tersimpan di ponsel ini saja.",
            "The gate or the way in — what somebody recognises from the road. These become the marker on the map and the hero on the cemetery screen. Kept on this phone only."
        ),
        .cemeteryGravesEyebrow: ("Makam yang sudah disurvei", "Graves surveyed here"),
        .cemeteryGraveSearch: ("Nama almarhum atau almarhumah", "Name of the person who died"),
        .cemeteryNoGraves: (
            "Tidak ada nama yang cocok di pemakaman ini.",
            "No name here matches that."
        ),
        .cemeterySurveyNote: (
            "Baru satu blok yang disurvei. Juru kunci masih bisa membantu mencari di blok lain.",
            "Only one block has been surveyed so far. The caretaker can still help you look in the others."
        ),

        // MARK: Find
        .findPrivacyNote: (
            "Anda tidak perlu izin siapa pun untuk mencari. Tidak ada yang diberi tahu bahwa Anda mencari.",
            "You need nobody's permission to look. No one is told that you searched."
        ),
        .searchClearAccessibility: ("Hapus pencarian", "Clear the search"),

        // MARK: Grave
        .graveSave: ("Simpan makam ini", "Keep this grave"),
        .graveUnsave: ("Hapus dari simpanan", "Stop keeping this grave"),
        .doorGuideTitle: ("Tunjukkan jalan", "Show me the way"),
        .doorGuideDetail: (
            "Denah blok, lalu arah dan jarak sampai beberapa meter terakhir.",
            "The block plan, then a direction and a distance until the last few metres."
        ),
        .doorTendTitle: ("Tuntunan ziarah", "What to do here"),
        .doorTendDetail: (
            "Doa dan bacaan, mengikuti agama yang tercatat untuk almarhum.",
            "Prayers and readings, following the faith recorded for the person buried here."
        ),
        .doorWallTitle: ("Dinding", "The wall"),
        .doorWallDetail: (
            "Ziarah, bunga dan kenangan — berurutan sejak hari wafat.",
            "Visits, flowers and memories — in order, since the day of the death."
        ),
        .doorProfileTitle: ("Tentang almarhum", "About this person"),
        .doorProfileDetail: (
            "Riwayat hidup yang ditulis keluarga.",
            "A life, written by the family."
        ),
        .stewardEyebrow: ("Penjaga catatan makam", "Keeper of this record"),
        .stewardNote: (
            "Keluarga inti memegang catatan makam ini. Kenangan yang Anda tulis sampai kepada mereka lebih dahulu.",
            "The immediate family holds this record. A memory you write reaches them first."
        ),
        .claimNone: (
            "Belum ada keluarga yang memegang catatan makam ini.",
            "No family member holds this record yet."
        ),
        .claimButton: (
            "Saya keluarga inti, saya pegang catatan ini",
            "I am immediate family — I'll hold this record"
        ),
        .claimNeedsName: (
            "Isi nama Anda dulu di menu Tentang",
            "Add your name in About first"
        ),
        .diedOn: ("Wafat %@", "Died %@"),
        .parentageBin: ("bin %@", "bin %@"),
        .parentageBinti: ("binti %@", "binti %@"),
        .parentageSon: ("putra dari %@", "son of %@"),
        .parentageDaughter: ("putri dari %@", "daughter of %@"),
        .parentageChild: ("anak dari %@", "child of %@"),
        .photosEyebrow: ("Foto", "Photographs"),
        .photoHeadstone: ("Nisan", "The headstone"),
        .photoPerson: ("Almarhum", "The person"),
        .photoClose: ("Tutup foto", "Close the photograph"),
        .born: ("Lahir %@", "Born %@"),
        .died: ("Wafat %@", "Died %@"),

        // MARK: Orient
        .orientWalk: ("Saya mulai berjalan", "I'm walking now"),
        .planAccessibility: (
            "Denah %1$@, %2$d makam.",
            "Plan of %1$@, %2$d graves."
        ),
        .planNorthUp: ("Utara di atas", "North is up"),
        .planFacing: ("Diputar mengikuti arah Anda menghadap", "Turned to the way you are facing"),
        .planTapHint: ("Ketuk sebuah makam untuk melihat namanya.", "Tap a grave to see whose it is."),
        .planExpand: ("Perbesar denah", "Open the plan"),
        .planReset: ("Kembalikan", "Reset"),
        .planFollow: ("Ikuti arah saya", "Follow my heading"),
        .planOpenGrave: ("Buka makam ini", "Open this grave"),
        .planFullHint: (
            "Cubit untuk memperbesar, geser untuk berpindah. Ketuk sebuah makam untuk melihat namanya. Utara selalu di atas.",
            "Pinch to zoom, drag to move. Tap a grave to see whose it is. North stays up."
        ),
        .planNoFix: (
            "Posisi Anda belum diketahui, jadi belum digambar. Ketuk sebuah makam untuk melihat namanya.",
            "Your position is not known yet, so it is not drawn. Tap a grave to see whose it is."
        ),
        .planPretending: (
            "Mode uji sedang menganggap Anda hadir. Titik pada denah memakai posisi asli, jadi tidak digambar.",
            "Test mode is treating you as present. The dot uses your real position, so it is not drawn."
        ),
        .planYouElsewhere: (
            "Anda sedang tidak berada di pemakaman ini, jadi posisi Anda tidak digambar.",
            "You are not at this cemetery, so your position is not drawn."
        ),
        .planYouAre: (
            "Lingkaran menunjukkan seberapa jauh posisi Anda bisa meleset.",
            "The circle is how far your position may be out."
        ),
        .orientPlanAccessibility: (
            "Denah blok %1$@. Makam berada di baris %2$d, petak %3$d.",
            "Plan of block %1$@. The grave is in row %2$d, plot %3$d."
        ),

        // MARK: Approach
        .approachAccuracy: ("Ketepatan sinyal ±%d m", "Signal accuracy ±%d m"),
        .approachAccuracyUnknown: ("Ketepatan sinyal belum diketahui", "Signal accuracy not known yet"),
        .approachHonestyNote: (
            "Ketepatan tidak membaik saat Anda mendekat. Beberapa meter terakhir ditempuh dengan mata, bukan dengan sinyal.",
            "Accuracy does not improve as you get closer. The last few metres are walked with your eyes, not with a signal."
        ),
        .approachCompassUntrusted: (
            "Kompas sedang tidak bisa dipercaya di titik ini.",
            "The compass cannot be trusted at this spot."
        ),
        .approachWaiting: ("Menunggu sinyal.", "Waiting for a signal."),
        .arrowAccessibility: ("Arah makam", "Direction of the grave"),
        .closeGuideAccessibility: ("Tutup petunjuk", "Close the directions"),

        // MARK: Arrive
        .arriveHeadline: (
            "Anda sudah sampai. Sisanya dilihat, bukan dihitung.",
            "You're here. The rest is looked at, not measured."
        ),
        .arriveConfirm: ("Benar, ini makamnya", "Yes, this is the grave"),
        .arriveReject: ("Bukan ini — kembali", "Not this one — go back"),
        .arrivePhotoMissing: (
            "Foto nisan belum diambil saat survei.\nGunakan petunjuk di bawah.",
            "No headstone photo was taken during the survey.\nUse the description below."
        ),

        // MARK: Tend
        .tendTitle: ("Ziarah", "Visiting"),
        .tendGuidanceEyebrow: ("Tuntunan", "Guidance"),
        .flowerNote: (
            "Aplikasi ini tidak menyediakan bunga. Bunga yang Anda tabur adalah bunga sungguhan — di sini hanya dicatat bahwa itu terjadi, supaya yang tidak bisa datang tahu bahwa ada yang datang.",
            "This app does not hand you a flower. The ones you scatter are real — it only notes that it happened, so someone who could not come knows that somebody did."
        ),
        .flowerButton: ("Saya menabur bunga hari ini", "I scattered flowers today"),
        .passageHowToRead: ("Cara membaca", "How to say it"),
        .passageMeaning: ("Artinya", "What it means"),

        // MARK: Faith
        .faithIslam: ("Islam", "Islam"),
        .faithHindu: ("Hindu", "Hindu"),
        .faithKristen: ("Kristen", "Christian"),
        .faithKatolik: ("Katolik", "Catholic"),
        .faithBuddha: ("Buddha", "Buddhist"),
        .faithKonghucu: ("Konghucu", "Confucian"),
        .faithOther: ("Agama lain", "Another faith"),
        .faithUnrecorded: ("Agama tidak tercatat", "Faith not recorded"),
        .guidanceFollowsRecord: (
            "Tuntunan mengikuti agama yang tercatat untuk almarhum: %@.",
            "The guidance follows the faith recorded for the person buried here: %@."
        ),
        .guidanceFallback: (
            "Agama almarhum tidak tercatat dalam survei, jadi tuntunan mengikuti pilihan Anda. Tanyakan kepada juru kunci atau keluarga bila ragu.",
            "The survey could not confirm this person's faith, so the guidance follows your own setting. Ask the caretaker or the family if you are unsure."
        ),
        .guidanceNoneForFaith: (
            "Tuntunan untuk %@ belum disiapkan. Teks keagamaan hanya ditambahkan setelah disusun bersama tokoh setempat.",
            "Guidance for %@ has not been prepared. Religious text is only added once it has been put together with a local authority."
        ),

        // MARK: Traditions
        .traditionIslam: ("Islam", "Islam"),
        .traditionHindu: ("Hindu Bali", "Balinese Hindu"),
        .traditionNone: ("Tanpa tuntunan", "No guidance"),
        .traditionHinduNote: (
            "Tuntunan untuk tradisi Hindu Bali belum disiapkan. Teks ini hanya akan ditambahkan setelah disusun bersama pemangku setempat, bukan disalin dari sumber yang tidak jelas.",
            "Guidance for Balinese Hindu practice has not been prepared. It will only be added once it has been put together with a local pemangku, not copied from an unattributed source."
        ),
        .traditionNoneNote: (
            "Tidak ada tuntunan yang ditampilkan. Berdiamlah sejenak, dengan cara Anda sendiri.",
            "No guidance is shown. Stand a while, in your own way."
        ),

        // MARK: The wall
        .wallTitle: ("Dinding", "The wall"),
        .wallEmpty: ("Belum ada apa pun di dinding ini.", "Nothing on this wall yet."),
        .wallEmptyNote: (
            "Dinding dimulai sejak hari wafat. Ziarah yang dicatat di makam dan cerita yang ditulis dari mana saja akan muncul di sini, berurutan.",
            "The wall begins on the day of the death. Visits recorded at the grave and stories written from anywhere appear here, in order."
        ),
        .wallOpen: ("Terbuka", "Open"),
        .wallFamilyOnly: ("Hanya keluarga", "Family only"),
        .wallClosed: ("Ditutup", "Closed"),
        .wallOpenNote: (
            "Siapa pun yang menemukan makam ini bisa membacanya.",
            "Anyone who finds this grave can read it."
        ),
        .wallFamilyOnlyNote: (
            "Hanya keluarga yang memegang catatan makam yang bisa membacanya. Orang lain tetap bisa menulis, dan tulisannya menunggu keputusan Anda.",
            "Only the family who holds the record can read it. Others may still write, and what they write waits for you."
        ),
        .wallClosedNote: (
            "Dinding ditutup. Tidak ada yang bisa membacanya, termasuk keluarga, sampai Anda membukanya lagi.",
            "The wall is closed. Nobody can read it, the family included, until you open it again."
        ),
        .wallVisibilityEyebrow: ("Siapa yang boleh membaca", "Who may read this"),
        .wallHiddenFromYou: (
            "Keluarga menutup dinding makam ini. Anda masih bisa menulis, dan tulisan Anda sampai kepada mereka.",
            "The family has closed this wall. You can still write, and what you write reaches them."
        ),
        .wallCheckIn: ("Catat ziarah hari ini", "Record today's visit"),
        .wallCanCheckIn: ("Anda di sini — bisa mencatat ziarah", "You are here — a visit can be recorded"),
        .wallPostTitle: ("Tulis di dinding", "Write on the wall"),
        .wallPostSend: ("Kirim", "Post it"),
        .wallPostHereNote: (
            "Anda berada di makam ini, jadi tulisan ini dicatat sebagai ziarah.",
            "You are at this grave, so this will be recorded as a visit."
        ),
        .wallPostAwayNote: (
            "Bisa ditulis dari mana saja. Kehadiran di makam dicatat sendiri oleh aplikasi, tidak pernah diklaim.",
            "Can be written from anywhere. Being at the grave is something the app records for itself, never something you claim."
        ),
        .wallCheckInNote: (
            "Tulis sepatah kata bila mau — boleh juga dikosongkan.",
            "Add a line if you want to. It can stay empty."
        ),
        .wallVisited: ("berziarah", "visited"),
        .wallVisitedWithFlowers: ("berziarah dan menabur bunga", "visited and scattered flowers"),
        .wallWroteStory: ("menulis kenangan", "wrote a memory"),
        .wallAddStory: ("Tulis kenangan", "Write a memory"),
        .wallStoryPlaceholder: (
            "Ceritakan satu hal yang Anda ingat tentang %@…",
            "Tell one thing you remember about %@…"
        ),
        .wallSince: ("Sejak %@", "Since %@"),
        .wallModerationNote: (
            "Anda memegang catatan makam ini. Tulisan orang lain menunggu keputusan Anda sebelum terlihat.",
            "You hold this record. What other people write waits for you before anyone sees it."
        ),

        // MARK: The profile
        .profileTitle: ("Tentang almarhum", "About this person"),
        .profileEyebrow: ("Ditulis keluarga", "Written by the family"),
        .profileEmpty: ("Keluarga belum menuliskan apa pun.", "The family has not written anything yet."),
        .profileEmptyNote: (
            "Halaman ini ditulis oleh keluarga yang memegang catatan makam, lewat halaman admin.",
            "This page is written by the family who holds the record, through the admin site."
        ),

        // MARK: Memories
        .pendingSteward: ("Menunggu keputusan Anda", "Waiting for your decision"),
        .pendingFamily: ("Menunggu keluarga", "Waiting for the family"),
        .moderateShow: ("Tampilkan", "Show it"),
        .moderateRemove: ("Hapus dari sini", "Remove it"),

        // MARK: Write
        .writtenByEyebrow: ("Ditulis oleh", "Written by"),
        .fieldName: ("Nama Anda", "Your name"),
        .fieldRelationship: (
            "Hubungan Anda — misalnya: teman sekolah",
            "How you knew them — school friend, neighbour…"
        ),
        .attributionNote: (
            "Nama diperlukan supaya keluarga tahu cerita ini datang dari siapa.",
            "The name is needed so the family knows who the story came from."
        ),
        .relationshipUnstated: ("Tidak disebutkan", "Not stated"),

        // MARK: Field mode
        .fieldTitle: ("Mode lapangan", "Field mode"),
        .fieldPresenceHeader: ("Kehadiran", "Presence"),
        .fieldPresenceToggle: ("Anggap saya di pemakaman", "Treat me as at the cemetery"),
        .fieldPresenceNote: (
            "Membuka tuntunan ziarah, catatan bunga dan kenangan seolah-olah Anda berdiri di pemakaman. Hanya untuk uji coba dan demo — kunci kehadiran adalah inti produk ini, jadi jangan tinggalkan menyala.",
            "Opens the prayers, the flower record and the memories as though you were standing in the cemetery. For testing and rehearsal only — the presence locks are the point of this product, so do not leave it on."
        ),
        .fieldHapticsHeader: ("Getaran", "Vibration"),
        .fieldPulseToggle: ("Denyut mendekat aktif", "Approach pulse on"),
        .fieldRehearse: ("Jalankan 80 m → 8 m (18 detik)", "Run 80 m → 8 m (18 seconds)"),
        .fieldRehearseStop: ("Hentikan", "Stop"),
        .fieldRehearseAt: ("Sedang di", "Now at"),
        .fieldInterval: ("Jeda", "Gap"),
        .fieldIntensity: ("Kekuatan", "Strength"),
        .fieldHoldAt: ("Tahan di satu jarak: %d m", "Hold at one distance: %d m"),
        .fieldTapNear: ("Getaran ambang dekat (20 m)", "Near-threshold tap (20 m)"),
        .fieldTapArrive: ("Getaran sampai (8 m)", "Arrival tap (8 m)"),
        .fieldHapticsNote: (
            "Untuk merasakan denyut tanpa berjalan ke makam. Geser slider dan tahan jarinya — denyut mengikuti jarak itu, dan berhenti saat dilepas. Getaran tidak terasa di Simulator, dan mati bila Mode Daya Rendah menyala atau Getaran Sistem dimatikan di Pengaturan iOS.",
            "For feeling the pulse without walking to a grave. Drag the slider and hold — the pulse follows that distance and stops when you let go. Haptics are silent in the Simulator, and off entirely in Low Power Mode or when System Haptics is turned off in iOS Settings."
        ),
        .fieldSurveyHeader: ("Survei lapangan", "Field survey"),
        .fieldRecordGrave: ("Rekam makam", "Record a grave"),
        .fieldExport: ("Lihat & ekspor JSON", "View and export JSON"),
        .fieldStandHeader: ("Posisi palsu", "Pretend position"),
        .fieldStandAtGate: ("Taruh saya di gerbang", "Put me at the gate"),
        .fieldStandNote: (
            "Menempatkan Anda diam di gerbang pemakaman, supaya denah bisa dilihat dari meja kerja. Posisi asli kembali dipakai setelah simulasi dihentikan.",
            "Stands you still at the cemetery gate, so the plan can be looked at from a desk. Your real position returns when the simulation is stopped."
        ),
        .fieldSimHeader: ("Simulasi berjalan", "Simulated walk"),
        .fieldSimTarget: ("Makam tujuan", "Target grave"),
        .fieldSimStart: ("Mulai berjalan dari 60 m", "Start walking from 60 m"),
        .fieldSimStop: ("Hentikan simulasi", "Stop the simulation"),
        .fieldSimNote: (
            "Hanya untuk latihan dan demo. Posisi palsu, dan setiap layar akan menyebutkan bahwa mode ini aktif.",
            "For rehearsal only. The position is invented, and every screen says so while it is running."
        ),
        .fieldStateHeader: ("Keadaan sekarang", "Where things stand"),
        .fieldAuth: ("Izin lokasi", "Location permission"),
        .fieldPosition: ("Posisi", "Position"),
        .fieldAccuracy: ("Ketepatan", "Accuracy"),
        .fieldHeading: ("Arah kompas", "Compass heading"),
        .fieldHeadingUsable: ("Kompas layak dipakai", "Compass usable"),
        .fieldDistanceToSite: ("Jarak ke pemakaman", "Distance to the cemetery"),
        .fieldCountedPresent: ("Dianggap hadir", "Counted as present"),
        .fieldNone: ("belum ada", "none yet"),
        .fieldYes: ("ya", "yes"),
        .fieldNo: ("tidak", "no"),
        .authNotAsked: ("belum ditanya", "not asked"),
        .authDenied: ("ditolak", "denied"),
        .authRestricted: ("dibatasi", "restricted"),
        .authAlways: ("selalu", "always"),
        .authWhenInUse: ("saat dipakai", "while using"),
        .authUnknown: ("tidak diketahui", "unknown"),

        // MARK: Survey
        .surveyTitle: ("Rekam makam", "Record a grave"),
        .surveyIdentity: ("Identitas", "Identity"),
        .surveyNameField: ("Nama seperti tertulis di nisan", "Name as written on the headstone"),
        .surveyFatherField: ("Nama ayah (tanpa bin/binti)", "Father's name (without bin/binti)"),
        .surveyGender: ("Jenis kelamin", "Gender"),
        .surveyGenderMale: ("Laki-laki", "Male"),
        .surveyGenderFemale: ("Perempuan", "Female"),
        .surveyUnrecorded: ("Tidak tercatat", "Not recorded"),
        .surveyDeathDate: ("Tanggal wafat (yyyy-mm-dd)", "Date of death (yyyy-mm-dd)"),
        .plotBlock: ("Blok %@", "Block %@"),
        .plotRow: ("Baris %d", "Row %d"),
        .plotPlot: ("Petak %d", "Plot %d"),
        .plotEyebrow: ("Nomor dalam catatan pengurus", "Reference in the caretaker's ledger"),
        .surveyBlock: ("Blok", "Block"),
        .surveyRow: ("Baris %d", "Row %d"),
        .surveyPlot: ("Petak %d", "Plot %d"),
        .surveyReligion: ("Agama", "Faith"),
        .surveyCoordsHeader: ("Koordinat saat ini", "Current coordinates"),
        .surveyWaitingFix: ("Menunggu sinyal GPS.", "Waiting for a GPS fix."),
        .surveyAccuracyValue: ("Ketepatan ±%.1f m", "Accuracy ±%.1f m"),
        .surveyCoordsNote: (
            "Berdirilah di kaki makam, menghadap nisan, lalu simpan. Jangan melangkahi makam.",
            "Stand at the foot of the grave, facing the headstone, then save. Do not step over a grave."
        ),
        .surveyHeadstoneHeader: ("Foto nisan", "Headstone photograph"),
        .surveyTakePhoto: ("Ambil foto", "Take the photograph"),
        .surveyRetakePhoto: ("Ambil ulang", "Take it again"),
        .surveyPortraitHeader: ("Foto almarhum", "Photograph of the person"),
        .surveyTakePortrait: ("Ambil foto almarhum", "Photograph the person"),
        .surveyRetakePortrait: ("Ambil ulang", "Take it again"),
        .surveyPortraitNote: (
            "Hanya bila keluarga menawarkan dan mengizinkan. Banyak keluarga tidak punya foto, dan itu bukan kekurangan — kolom ini boleh dibiarkan kosong.",
            "Only where the family offers one and permits it. Many families have no photograph, and that is not a gap — leave this empty."
        ),
        .surveyLandmarkHeader: ("Penanda", "Landmark"),
        .surveyLandmarkField: (
            "Satu kalimat penanda — apa yang terlihat dari dekat",
            "One sentence — what you can see from close up"
        ),
        .surveyLandmarkNote: (
            "Kalimat inilah yang menjembatani beberapa meter terakhir yang tidak bisa dijangkau GPS. Tulis apa yang dilihat mata, bukan arah mata angin.",
            "This sentence is what bridges the last few metres GPS cannot. Write what the eye sees, not a compass direction."
        ),
        .surveySave: ("Simpan makam ini", "Save this grave"),
        .surveySaved: ("Tersimpan: %@", "Saved: %@"),
        .exportTitle: ("Ekspor survei", "Export the survey"),
        .exportCount: ("%d makam direkam", "%d graves recorded"),
        .exportEmpty: ("Belum ada makam yang direkam.", "No graves recorded yet."),
        .exportPrepare: ("Siapkan berkas JSON", "Prepare the JSON file"),
        .exportShare: ("Bagikan graves-survey.json", "Share graves-survey.json"),
        .exportNote: (
            "Foto disimpan sebagai berkas terpisah di samping JSON, dengan nama yang sama seperti yang tertulis di dalamnya.",
            "Photographs are written as separate files beside the JSON, named exactly as the JSON refers to them."
        ),

        // MARK: About
        .aboutLede: (
            "Aplikasi ini menuntun Anda ke satu makam, memberi tahu apa yang bisa dilakukan setibanya di sana, dan meneruskan apa yang Anda ingat kepada keluarga yang mungkin belum pernah mendengarnya.",
            "This app walks you to one grave, tells you what you might do once you're standing there, and carries what you remember to a family who may never have heard it."
        ),
        .aboutYouEyebrow: ("Tentang Anda", "About you"),
        .aboutYouNote: (
            "Disimpan di ponsel ini saja, dipakai untuk menandatangani kenangan dan catatan kunjungan.",
            "Kept on this phone only, used to sign the memories and visits you record."
        ),
        .familyToggle: ("Saya keluarga inti", "I am immediate family"),
        .familyToggleNote: (
            "Keluarga inti dapat memegang catatan sebuah makam dan memutuskan kenangan mana yang ditampilkan.",
            "Immediate family can hold a grave's record and decide which memories appear."
        ),
        .languageEyebrow: ("Bahasa", "Language"),
        .guidanceLabel: ("Tuntunan", "Guidance"),
        .notDoingEyebrow: ("Yang tidak dilakukan aplikasi ini", "What this app will not do"),
        .principleNotifications: (
            "Tidak ada pemberitahuan. Aplikasi ini tidak akan pernah mengingatkan Anda untuk berziarah.",
            "No notifications. It will never remind you to visit."
        ),
        .principleCounts: (
            "Tidak ada angka. Kunjungan dan bunga tidak dijumlah, tidak diperingkat.",
            "No numbers. Visits and flowers are never totalled or ranked."
        ),
        .principleNothingAdded: (
            "Tidak ada yang ditambahkan ke makam. Tidak ada plakat, tidak ada kode, tidak ada apa pun yang dipasang.",
            "Nothing is added to the grave. No plaque, no code, nothing fixed to it."
        ),
        .principlePurchases: (
            "Tidak ada bunga digital dan tidak ada pembelian apa pun.",
            "No digital flowers, and nothing is ever for sale."
        ),
        .principleNoVirtual: (
            "Tidak ada ziarah virtual. Aplikasi ini tidak menggantikan kedatangan.",
            "No virtual visiting. This app is not a substitute for going."
        ),
        .syncEyebrow: ("Pembaruan data", "Record updates"),
        .syncNever: (
            "Memakai data bawaan aplikasi. Belum pernah diperbarui dari server.",
            "Running on the survey bundled with the app. Never updated from the server."
        ),
        .syncAt: ("Terakhir diperbarui %@", "Last updated %@"),
        .syncChecking: ("Sedang memeriksa…", "Checking…"),
        .syncFailed: (
            "Pemeriksaan terakhir gagal. Data yang ada tetap dipakai dan tetap bekerja.",
            "The last check failed. What is already here stays, and still works."
        ),
        .syncRefresh: ("Periksa pembaruan", "Check for updates"),
        .icloudEyebrow: ("iCloud", "iCloud"),
        .icloudSignedIn: (
            "Tulisan Anda ditandatangani dengan Apple ID di ponsel ini.",
            "What you write is signed with the Apple ID on this phone."
        ),
        .icloudNoAccount: (
            "Tidak ada Apple ID yang masuk di ponsel ini, jadi tulisan Anda tersimpan di sini saja dan belum sampai ke keluarga.",
            "No Apple ID is signed in on this phone, so what you write stays here and does not reach the family."
        ),
        .icloudRestricted: (
            "iCloud dibatasi di ponsel ini. Tulisan Anda tersimpan di sini saja.",
            "iCloud is restricted on this phone. What you write stays here."
        ),
        .icloudUnknown: ("Keadaan iCloud belum diketahui.", "iCloud status is not known yet."),
        .icloudNote: (
            "Ziarah dan kenangan disimpan di wadah iCloud milik aplikasi ini, bukan di penyimpanan iCloud Anda — jadi tidak memakan kuota Anda dan tidak terpengaruh bila iCloud Anda penuh.",
            "Visits and memories are stored in this app's own iCloud container, not in your iCloud storage — so they use none of your quota, and a full iCloud does not stop them."
        ),
        .icloudQuotaNote: (
            "Makam yang Anda simpan disalin ke iCloud pribadi Anda sendiri — tidak terlihat oleh pengguna lain, dan ikut berpindah bila Anda ganti ponsel. Daftarnya tetap ada di ponsel ini meski iCloud penuh atau tidak ada Apple ID.",
            "The graves you keep are copied to your own private iCloud — invisible to other users, and they follow you to a new phone. The list stays on this phone even if iCloud is full or no Apple ID is signed in."
        ),
        .postDestinationTitle: ("Sebelum Anda mengirim", "Before you post"),
        .postDestinationBody: (
            "Tulisan ini dikirim ke wadah iCloud milik Makamakam, ditandatangani dengan Apple ID di ponsel ini, dan bisa dibaca peziarah lain sesuai izin keluarga.\n\nIni bukan penyimpanan iCloud pribadi Anda dan tidak memakai kuota Anda. Catatan pribadi Anda tidak pernah ikut terkirim.",
            "What you write is sent to Makamakam's own iCloud container, signed with the Apple ID on this phone, and can be read by other visitors as far as the family allows.\n\nThis is not your personal iCloud storage and uses none of your quota. Your private notes are never sent."
        ),
        .postDestinationAgree: ("Saya mengerti", "I understand"),
        .postDestinationCancel: ("Nanti saja", "Not now"),
        .syncUnavailable: (
            "Build ini tidak menyertakan izin CloudKit, jadi pembaruan dimatikan. Aplikasi berjalan penuh dengan data bawaan.",
            "This build carries no CloudKit entitlement, so updates are off. The app runs fully on its bundled survey."
        ),
        .syncNote: (
            "Pembaruan hanya menambah atau memperbaiki catatan makam. Aplikasi tetap bekerja penuh tanpa jaringan, memakai data terakhir yang tersimpan.",
            "An update only adds to or corrects the grave records. The app keeps working fully without a network, on whatever it last stored."
        ),

        .dataEyebrow: ("Data", "Data"),
        .dataNote: (
            "Data makam di %@ berasal dari survei lapangan, disimpan di dalam aplikasi, dan bekerja tanpa jaringan. Catatan pribadi Anda tidak pernah meninggalkan ponsel ini.",
            "The grave records for %@ come from a field survey, are stored inside the app, and work with no network at all. Your private notes never leave this phone."
        ),
        .prayerReviewNote: (
            "Teks doa perlu diperiksa kembali bersama juru kunci atau tokoh setempat sebelum dipakai luas.",
            "The prayer texts need checking with the caretaker or a local authority before wider use."
        ),
        .versionLine: ("Versi %1$@ (%2$@)", "Version %1$@ (%2$@)")
    ]
}
