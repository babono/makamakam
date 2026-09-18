import Foundation

/// One passage: Arabic, Latin transliteration, Indonesian meaning.
///
/// Many people do not have these memorised and feel quietly embarrassed about
/// it. This is the highest-value, lowest-risk screen in the product (PRD §9), so
/// nothing here is abbreviated for layout reasons and nothing is presented as
/// more complete than it is.
struct Passage: Identifiable, Hashable {
    let id: String
    let title: String
    /// Nil where there is nothing to add.
    let noteID: String?
    let noteEN: String?
    let arabic: String
    /// Transliteration is the same in both languages — it is Arabic written in
    /// Latin letters, not Indonesian.
    let latin: String
    let meaningID: String
    let meaningEN: String

    func note(_ lang: Lang) -> String? {
        lang.code == .id ? noteID : noteEN
    }

    func meaning(_ lang: Lang) -> String {
        lang.code == .id ? meaningID : meaningEN
    }
}

struct PassageGroup: Identifiable, Hashable {
    let id: String
    let titleID: String
    let titleEN: String
    let subtitleID: String
    let subtitleEN: String
    let passages: [Passage]

    func title(_ lang: Lang) -> String { lang.code == .id ? titleID : titleEN }
    func subtitle(_ lang: Lang) -> String { lang.code == .id ? subtitleID : subtitleEN }
}

enum PrayerLibrary {
    static func groups(for tradition: Tradition) -> [PassageGroup] {
        switch tradition {
        case .islam: return islam
        case .hindu, .umum: return []
        }
    }

    /// Shown instead of text the team has no business writing itself.
    static func unavailableNote(for tradition: Tradition, lang: Lang) -> String? {
        switch tradition {
        case .islam: return nil
        case .hindu: return lang.t(.traditionHinduNote)
        case .umum: return lang.t(.traditionNoneNote)
        }
    }

    // MARK: - Islam

    static let islam: [PassageGroup] = [
        PassageGroup(
            id: "masuk",
            titleID: "Saat masuk pemakaman",
            titleEN: "As you enter the cemetery",
            subtitleID: "Salam diucapkan kepada penghuni pemakaman, bukan kepada satu makam.",
            subtitleEN: "The salam is spoken to everyone buried here, not to one grave.",
            passages: [salam]
        ),
        PassageGroup(
            id: "bacaan",
            titleID: "Bacaan di makam",
            titleEN: "Readings at the grave",
            subtitleID: "Urutan yang lazim di Indonesia. Dibaca sesuai kemampuan, tidak harus seluruhnya.",
            subtitleEN: "The order commonly kept in Indonesia. Read as much as you can; you are not expected to read all of it.",
            passages: [fatihah, ikhlas, falaq, nas, ayatKursi, yasin]
        ),
        PassageGroup(
            id: "tahlil",
            titleID: "Tahlil ringkas",
            titleEN: "Short tahlil",
            subtitleID: "Dibaca berulang, pelan, tanpa dihitung.",
            subtitleEN: "Repeated slowly, and never counted.",
            passages: [istighfar, tahlil, shalawat]
        ),
        PassageGroup(
            id: "doa",
            titleID: "Doa ziarah kubur",
            titleEN: "Prayer for the one who died",
            subtitleID: "Permohonan ampunan untuk yang telah wafat.",
            subtitleEN: "Asking forgiveness for the person buried here.",
            passages: [doaZiarah]
        )
    ]

    static let salam = Passage(
        id: "salam",
        title: "Salam masuk",
        noteID: "Diucapkan saat melangkah masuk, sebelum mencari makam.",
        noteEN: "Said as you step in, before you go looking for the grave.",
        arabic: "السَّلَامُ عَلَيْكُمْ دَارَ قَوْمٍ مُؤْمِنِينَ وَإِنَّا إِنْ شَاءَ اللَّهُ بِكُمْ لَاحِقُونَ",
        latin: "Assalāmu ‘alaikum dāra qaumin mu’minīn, wa innā in syā’allāhu bikum lāḥiqūn.",
        meaningID: "Semoga keselamatan atas kalian, wahai penghuni negeri kaum mukminin. Dan kami, insya Allah, akan menyusul kalian.",
        meaningEN: "Peace be upon you, dwellers of this place, believing people. And we will, God willing, follow after you."
    )

    static let fatihah = Passage(
        id: "fatihah",
        title: "Al-Fātiḥah",
        noteID: nil,
        noteEN: nil,
        arabic: """
        بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ
        الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ
        الرَّحْمَٰنِ الرَّحِيمِ
        مَالِكِ يَوْمِ الدِّينِ
        إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ
        اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ
        صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ
        """,
        latin: """
        Bismillāhir-raḥmānir-raḥīm.
        Al-ḥamdu lillāhi rabbil-‘ālamīn.
        Ar-raḥmānir-raḥīm.
        Māliki yaumid-dīn.
        Iyyāka na‘budu wa iyyāka nasta‘īn.
        Ihdinaṣ-ṣirāṭal-mustaqīm.
        Ṣirāṭal-lażīna an‘amta ‘alaihim, gairil-magḍūbi ‘alaihim wa laḍ-ḍāllīn.
        """,
        meaningID: """
        Dengan nama Allah Yang Maha Pengasih, Maha Penyayang.
        Segala puji bagi Allah, Tuhan seluruh alam.
        Yang Maha Pengasih, Maha Penyayang.
        Pemilik hari pembalasan.
        Hanya kepada-Mu kami menyembah dan hanya kepada-Mu kami mohon pertolongan.
        Tunjukilah kami jalan yang lurus.
        Jalan orang-orang yang telah Engkau beri nikmat, bukan jalan mereka yang dimurkai dan bukan pula jalan mereka yang sesat.
        """,
        meaningEN: """
        In the name of God, the Most Gracious, the Most Merciful.
        All praise belongs to God, Lord of all the worlds.
        The Most Gracious, the Most Merciful.
        Master of the Day of Judgement.
        You alone we worship, and from You alone we seek help.
        Guide us along the straight path.
        The path of those You have blessed, not of those who incur anger, nor of those who go astray.
        """
    )

    static let ikhlas = Passage(
        id: "ikhlas",
        title: "Al-Ikhlāṣ",
        noteID: "Lazim dibaca tiga kali.",
        noteEN: "Commonly read three times.",
        arabic: """
        قُلْ هُوَ اللَّهُ أَحَدٌ
        اللَّهُ الصَّمَدُ
        لَمْ يَلِدْ وَلَمْ يُولَدْ
        وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ
        """,
        latin: """
        Qul huwallāhu aḥad.
        Allāhuṣ-ṣamad.
        Lam yalid wa lam yūlad.
        Wa lam yakul-lahū kufuwan aḥad.
        """,
        meaningID: """
        Katakanlah: Dialah Allah, Yang Maha Esa.
        Allah tempat bergantung segala sesuatu.
        Dia tidak beranak dan tidak pula diperanakkan.
        Dan tidak ada sesuatu pun yang setara dengan Dia.
        """,
        meaningEN: """
        Say: He is God, the One.
        God, on whom all depend.
        He does not beget, nor was He begotten.
        And there is none comparable to Him.
        """
    )

    static let falaq = Passage(
        id: "falaq",
        title: "Al-Falaq",
        noteID: nil,
        noteEN: nil,
        arabic: """
        قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ
        مِن شَرِّ مَا خَلَقَ
        وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ
        وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ
        وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ
        """,
        latin: """
        Qul a‘ūżu birabbil-falaq.
        Min syarri mā khalaq.
        Wa min syarri gāsiqin iżā waqab.
        Wa min syarrin-naffāṡāti fil-‘uqad.
        Wa min syarri ḥāsidin iżā ḥasad.
        """,
        meaningID: """
        Katakanlah: Aku berlindung kepada Tuhan yang menguasai subuh.
        Dari kejahatan makhluk yang Dia ciptakan.
        Dan dari kejahatan malam apabila telah gelap gulita.
        Dan dari kejahatan para peniup pada buhul-buhul.
        Dan dari kejahatan orang yang dengki apabila ia dengki.
        """,
        meaningEN: """
        Say: I seek refuge in the Lord of the daybreak.
        From the harm of what He has created.
        And from the harm of darkness when it settles.
        And from the harm of those who blow on knots.
        And from the harm of an envier when he envies.
        """
    )

    static let nas = Passage(
        id: "nas",
        title: "An-Nās",
        noteID: nil,
        noteEN: nil,
        arabic: """
        قُلْ أَعُوذُ بِرَبِّ النَّاسِ
        مَلِكِ النَّاسِ
        إِلَٰهِ النَّاسِ
        مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ
        الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ
        مِنَ الْجِنَّةِ وَالنَّاسِ
        """,
        latin: """
        Qul a‘ūżu birabbin-nās.
        Malikin-nās.
        Ilāhin-nās.
        Min syarril-waswāsil-khannās.
        Allażī yuwaswisu fī ṣudūrin-nās.
        Minal-jinnati wan-nās.
        """,
        meaningID: """
        Katakanlah: Aku berlindung kepada Tuhan manusia.
        Raja manusia.
        Sembahan manusia.
        Dari kejahatan bisikan setan yang bersembunyi.
        Yang membisikkan ke dalam dada manusia.
        Dari golongan jin dan manusia.
        """,
        meaningEN: """
        Say: I seek refuge in the Lord of humankind.
        The King of humankind.
        The God of humankind.
        From the harm of the whisperer who withdraws.
        Who whispers into the hearts of people.
        From among jinn and people.
        """
    )

    static let ayatKursi = Passage(
        id: "ayat-kursi",
        title: "Āyat al-Kursī",
        noteID: "Al-Baqarah ayat 255.",
        noteEN: "Al-Baqarah, verse 255.",
        arabic: "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ",
        latin: "Allāhu lā ilāha illā huwal-ḥayyul-qayyūm. Lā ta’khużuhū sinatuw wa lā naum. Lahū mā fis-samāwāti wa mā fil-arḍ. Man żal-lażī yasyfa‘u ‘indahū illā bi’iżnih. Ya‘lamu mā baina aidīhim wa mā khalfahum. Wa lā yuḥīṭūna bisyai’im min ‘ilmihī illā bimā syā’. Wasi‘a kursiyyuhus-samāwāti wal-arḍ. Wa lā ya’ūduhū ḥifẓuhumā. Wa huwal-‘aliyyul-‘aẓīm.",
        meaningID: "Allah, tidak ada tuhan selain Dia, Yang Mahahidup, Yang terus-menerus mengurus makhluk-Nya. Dia tidak mengantuk dan tidak tidur. Milik-Nya apa yang ada di langit dan apa yang ada di bumi. Tidak ada yang dapat memberi syafaat di sisi-Nya tanpa izin-Nya. Dia mengetahui apa yang di hadapan mereka dan apa yang di belakang mereka, dan mereka tidak mengetahui sesuatu apa pun tentang ilmu-Nya melainkan apa yang Dia kehendaki. Kursi-Nya meliputi langit dan bumi. Dan Dia tidak merasa berat memelihara keduanya, dan Dia Mahatinggi lagi Mahabesar.",
        meaningEN: "God — there is no deity but Him, the Ever-Living, the Sustainer of all. Neither drowsiness nor sleep overtakes Him. To Him belongs whatever is in the heavens and whatever is on the earth. Who could intercede with Him except by His permission? He knows what lies before them and what lies behind them, and they grasp nothing of His knowledge except what He wills. His seat extends over the heavens and the earth, and their upkeep does not weary Him. He is the Most High, the Magnificent."
    )

    static let yasin = Passage(
        id: "yasin",
        title: "Yāsīn",
        noteID: "Hanya pembukaan yang dimuat di sini. Surah ini dibaca sampai ayat 83 — bawalah mushaf atau lanjutkan dari hafalan.",
        noteEN: "Only the opening is carried here. The surah runs to verse 83 — bring a mushaf, or continue from memory.",
        arabic: """
        يس
        وَالْقُرْآنِ الْحَكِيمِ
        إِنَّكَ لَمِنَ الْمُرْسَلِينَ
        عَلَىٰ صِرَاطٍ مُّسْتَقِيمٍ
        تَنزِيلَ الْعَزِيزِ الرَّحِيمِ
        لِتُنذِرَ قَوْمًا مَّا أُنذِرَ آبَاؤُهُمْ فَهُمْ غَافِلُونَ
        لَقَدْ حَقَّ الْقَوْلُ عَلَىٰ أَكْثَرِهِمْ فَهُمْ لَا يُؤْمِنُونَ
        """,
        latin: """
        Yā Sīn.
        Wal-qur’ānil-ḥakīm.
        Innaka laminal-mursalīn.
        ‘Alā ṣirāṭim mustaqīm.
        Tanzīlal-‘azīzir-raḥīm.
        Litunżira qaumam mā unżira ābā’uhum fahum gāfilūn.
        Laqad ḥaqqal-qaulu ‘alā akṡarihim fahum lā yu’minūn.
        """,
        meaningID: """
        Yā Sīn.
        Demi Al-Qur’an yang penuh hikmah.
        Sungguh, engkau benar-benar salah seorang dari rasul-rasul.
        Yang berada di atas jalan yang lurus.
        Sebagai wahyu yang diturunkan oleh Yang Mahaperkasa, Maha Penyayang.
        Agar engkau memberi peringatan kepada suatu kaum yang nenek moyangnya belum pernah diberi peringatan, karena itu mereka lalai.
        Sungguh, pasti berlaku perkataan terhadap kebanyakan mereka, karena mereka tidak beriman.
        """,
        meaningEN: """
        Yā Sīn.
        By the Qur’an, full of wisdom.
        You are indeed one of the messengers.
        On a straight path.
        A revelation sent down by the Almighty, the Merciful.
        So that you may warn a people whose forefathers were not warned, and who are therefore heedless.
        The word has come true against most of them, for they do not believe.
        """
    )

    static let istighfar = Passage(
        id: "istighfar",
        title: "Istigfar",
        noteID: "Dibaca berulang.",
        noteEN: "Repeated.",
        arabic: "أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ",
        latin: "Astagfirullāhal-‘aẓīm.",
        meaningID: "Aku memohon ampun kepada Allah Yang Mahaagung.",
        meaningEN: "I ask forgiveness of God, the Magnificent."
    )

    static let tahlil = Passage(
        id: "kalimat-tahlil",
        title: "Tahlil",
        noteID: "Dibaca berulang.",
        noteEN: "Repeated.",
        arabic: "لَا إِلَٰهَ إِلَّا اللَّهُ",
        latin: "Lā ilāha illallāh.",
        meaningID: "Tidak ada tuhan selain Allah.",
        meaningEN: "There is no deity but God."
    )

    static let shalawat = Passage(
        id: "shalawat",
        title: "Selawat",
        noteID: nil,
        noteEN: nil,
        arabic: "اللَّهُمَّ صَلِّ عَلَىٰ سَيِّدِنَا مُحَمَّدٍ وَعَلَىٰ آلِ سَيِّدِنَا مُحَمَّدٍ",
        latin: "Allāhumma ṣalli ‘alā sayyidinā Muḥammad, wa ‘alā āli sayyidinā Muḥammad.",
        meaningID: "Ya Allah, limpahkanlah rahmat kepada junjungan kami Nabi Muhammad dan kepada keluarga beliau.",
        meaningEN: "O God, send blessings upon our master Muhammad and upon the family of our master Muhammad."
    )

    static let doaZiarah = Passage(
        id: "doa-ziarah",
        title: "Doa untuk yang telah wafat",
        noteID: "Untuk perempuan, ganti “lahu” menjadi “lahā”.",
        noteEN: "For a woman, say “lahā” in place of “lahu”.",
        arabic: "اللَّهُمَّ اغْفِرْ لَهُ وَارْحَمْهُ وَعَافِهِ وَاعْفُ عَنْهُ، وَأَكْرِمْ نُزُلَهُ، وَوَسِّعْ مُدْخَلَهُ، وَاغْسِلْهُ بِالْمَاءِ وَالثَّلْجِ وَالْبَرَدِ، وَنَقِّهِ مِنَ الْخَطَايَا كَمَا نَقَّيْتَ الثَّوْبَ الْأَبْيَضَ مِنَ الدَّنَسِ",
        latin: "Allāhummagfir lahu warḥamhu wa ‘āfihi wa‘fu ‘anhu, wa akrim nuzulahu, wa wassi‘ mudkhalahu, wagsilhu bil-mā’i waṡ-ṡalji wal-barad, wa naqqihi minal-khaṭāyā kamā naqqaitaṡ-ṡaubal-abyaḍa minad-danas.",
        meaningID: "Ya Allah, ampunilah dia, rahmatilah dia, selamatkanlah dia dan maafkanlah dia. Muliakanlah tempat kembalinya, luaskanlah tempat masuknya, mandikanlah dia dengan air, salju dan embun. Bersihkanlah dia dari segala kesalahan sebagaimana Engkau membersihkan kain putih dari kotoran.",
        meaningEN: "O God, forgive them, have mercy on them, keep them safe and pardon them. Honour their resting place and widen their entry. Wash them with water, snow and hail, and cleanse them of their wrongs as a white cloth is cleansed of dirt."
    )
}
