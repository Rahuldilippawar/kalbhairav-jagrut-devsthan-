import '../utils/convert.dart';
import 'festivals.dart';
import 'panchang.dart';

// Palettes (dark → light) used by the festival banners.
const _saffron = [0xFF7F0000, 0xFFD84315, 0xFFFF8F00];
const _red = [0xFF5D0000, 0xFFB71C1C, 0xFFF57C00];
const _maroon = [0xFF1F0000, 0xFF5E0000, 0xFF9E1B1B];
const _ganesh = [0xFF7A0A00, 0xFFE65100, 0xFFFFB300];
const _night = [0xFF070B26, 0xFF1A237E, 0xFF3949AB];
const _vitthal = [0xFF0A1236, 0xFF1C2E7A, 0xFF4A6CD4];
const _diwali = [0xFF1A0033, 0xFF4A148C, 0xFFE65100];
const _green = [0xFF0B3D12, 0xFF2E7D32, 0xFF8BC34A];
const _pink = [0xFF6A0036, 0xFFC2185B, 0xFFFF7043];
const _holi = [0xFF5E1A8C, 0xFFD81B60, 0xFFFFB300];
const _devi = [0xFF4A0010, 0xFFAD1457, 0xFFFF6F00];
const _dawn = [0xFFE65100, 0xFFFFA000, 0xFFFFE082];
const _cream = [0xFF5D4037, 0xFF8D6E63];
const _shiva = [0xFF0B1A2E, 0xFF263E5E, 0xFF4F7CA8];
const _tricolor = [0xFFFF9933, 0xFFFFF3E0, 0xFF138808];
const _shivaji = [0xFF4E1600, 0xFFBF360C, 0xFFFF9800];

const _darkText = 0xFF3E1A00;
const _darkAccent = 0xFF8B0000;

const _jai = 'श्री काळभैरव महाराजांची कृपा आपणा सर्वांवर सदैव राहो.';

/// Festivals, jayantis and national days with their Maharashtrian date
/// rules (amanta months: 0 = चैत्र … 11 = फाल्गुन; tithi 1–15 शुक्ल,
/// 16–30 कृष्ण) and banner content.
const festivalCatalog = <Festival>[
  // ---- चैत्र
  Festival(
    id: 'gudhipadwa', name: 'गुढीपाडवा', kind: FestivalKind.festival, rule: LunarRule(0, 1),
    headline: '🚩 गुढीपाडवा व नववर्षाच्या हार्दिक शुभेच्छा',
    message: 'नवे वर्ष आपणा सर्वांना सुख, समृद्धी, आरोग्य आणि यश घेऊन येवो. $_jai',
    layout: 'festive', gradient: _saffron,
  ),
  Festival(
    id: 'swamisamarth', name: 'श्री स्वामी समर्थ प्रकट दिन', kind: FestivalKind.jayanti, rule: LunarRule(0, 2),
    headline: '🙏 श्री स्वामी समर्थ प्रकट दिन',
    message: 'भिऊ नकोस, मी तुझ्या पाठीशी आहे. श्री स्वामी समर्थ प्रकट दिनानिमित्त सर्व भाविकांना हार्दिक शुभेच्छा.',
    gradient: _saffron, headlineFont: 'rozhaOne',
  ),
  Festival(
    id: 'ramnavami', name: 'श्री राम नवमी', kind: FestivalKind.jayanti, rule: LunarRule(0, 9, Karmakal.madhyahna),
    headline: '🏹 श्री राम नवमीच्या हार्दिक शुभेच्छा',
    message: 'मर्यादा पुरुषोत्तम प्रभू श्रीरामचंद्रांच्या जन्मोत्सवानिमित्त सर्वांना मंगलमय शुभेच्छा. जय श्रीराम!',
    gradient: _saffron,
  ),
  Festival(
    id: 'hanumanjayanti', name: 'हनुमान जयंती', kind: FestivalKind.jayanti, rule: LunarRule(0, 15),
    headline: '🚩 हनुमान जयंतीच्या हार्दिक शुभेच्छा',
    message: 'बल, बुद्धी आणि भक्तीचे प्रतीक श्री हनुमान आपणा सर्वांना शक्ती आणि आरोग्य देवो. जय बजरंगबली!',
    gradient: _red, headlineFont: 'palanquinDark',
  ),
  // ---- वैशाख
  Festival(
    id: 'akshayatritiya', name: 'अक्षय्य तृतीया', kind: FestivalKind.festival, rule: LunarRule(1, 3),
    headline: '✨ अक्षय्य तृतीयेच्या हार्दिक शुभेच्छा',
    message: 'या शुभ दिनी आपल्या घरी सुख, समृद्धी आणि आनंद अक्षय राहो. $_jai',
    layout: 'classic', gradient: _dawn, textColor: _darkText, accentColor: _darkAccent,
  ),
  Festival(
    id: 'narasimhajayanti', name: 'श्री नृसिंह जयंती', kind: FestivalKind.jayanti, rule: LunarRule(1, 14),
    headline: '🦁 श्री नृसिंह जयंती',
    message: 'भक्तरक्षक श्री नृसिंह भगवान सर्वांचे रक्षण करोत. नृसिंह जयंतीच्या हार्दिक शुभेच्छा.',
    gradient: _maroon,
  ),
  Festival(
    id: 'buddhapurnima', name: 'बुद्ध पौर्णिमा', kind: FestivalKind.jayanti, rule: LunarRule(1, 15),
    headline: '☸️ बुद्ध पौर्णिमेच्या हार्दिक शुभेच्छा',
    message: 'करुणा, शांती आणि प्रज्ञेचा संदेश देणाऱ्या भगवान गौतम बुद्धांना विनम्र अभिवादन.',
    layout: 'minimal', gradient: _cream, headlineFont: 'tiroMarathi',
  ),
  // ---- ज्येष्ठ
  Festival(
    id: 'vatpurnima', name: 'वटपौर्णिमा', kind: FestivalKind.festival, rule: LunarRule(2, 15, Karmakal.aparahna),
    headline: '🌳 वटपौर्णिमेच्या हार्दिक शुभेच्छा',
    message: 'सौभाग्य, अखंड प्रेम आणि सुखी सहजीवनासाठी सर्व माता-भगिनींना वटपौर्णिमेच्या मनःपूर्वक शुभेच्छा.',
    layout: 'festive', gradient: _green,
  ),
  // ---- आषाढ
  Festival(
    id: 'ashadhi', name: 'आषाढी एकादशी', kind: FestivalKind.festival, rule: LunarRule(3, 11),
    headline: '🙏 आषाढी एकादशीच्या हार्दिक शुभेच्छा',
    message: 'पंढरीच्या विठुरायाचे नामस्मरण करू या. जय जय राम कृष्ण हरी! सर्व वारकरी व भाविकांना शुभेच्छा.',
    gradient: _vitthal, headlineFont: 'rozhaOne',
  ),
  Festival(
    id: 'gurupurnima', name: 'गुरुपौर्णिमा', kind: FestivalKind.festival, rule: LunarRule(3, 15),
    headline: '🙏 गुरुपौर्णिमेच्या हार्दिक शुभेच्छा',
    message: 'गुरुर्ब्रह्मा गुरुर्विष्णुः गुरुर्देवो महेश्वरः. ज्ञानाचा प्रकाश देणाऱ्या सर्व गुरुजनांना वंदन.',
    gradient: _maroon, headlineFont: 'tiroMarathi',
  ),
  // ---- श्रावण
  Festival(
    id: 'nagpanchami', name: 'नागपंचमी', kind: FestivalKind.festival, rule: LunarRule(4, 5),
    headline: '🐍 नागपंचमीच्या हार्दिक शुभेच्छा',
    message: 'निसर्ग आणि जीवसृष्टीचा आदर करणाऱ्या या सणानिमित्त सर्वांना मंगलमय शुभेच्छा.',
    layout: 'festive', gradient: _green,
  ),
  Festival(
    id: 'raksha', name: 'नारळी पौर्णिमा / रक्षाबंधन', kind: FestivalKind.festival, rule: LunarRule(4, 15),
    headline: '🎀 रक्षाबंधन व नारळी पौर्णिमेच्या शुभेच्छा',
    message: 'बहीण-भावाच्या पवित्र नात्याचा हा सण आपल्या जीवनात प्रेम आणि आनंद घेऊन येवो.',
    layout: 'festive', gradient: _pink,
  ),
  Festival(
    id: 'gokulashtami', name: 'गोकुळाष्टमी', kind: FestivalKind.festival, rule: LunarRule(4, 23, Karmakal.nishita),
    headline: '🦚 श्रीकृष्ण जन्माष्टमीच्या शुभेच्छा',
    message: 'नंदाघरी आनंद भयो, जय कन्हैयालाल की! गोकुळाष्टमीच्या सर्वांना हार्दिक शुभेच्छा.',
    gradient: _night, headlineFont: 'rozhaOne',
  ),
  Festival(
    id: 'dahihandi', name: 'दहीहंडी', kind: FestivalKind.festival, rule: OffsetRule('gokulashtami', 1),
    headline: '🏺 दहीहंडी उत्सवाच्या शुभेच्छा',
    message: 'गोविंदा आला रे आला! एकजूट, उत्साह आणि आनंदाचा उत्सव साजरा करू या.',
    layout: 'festive', gradient: _ganesh, headlineFont: 'modak',
  ),
  Festival(
    id: 'pola', name: 'बैलपोळा', kind: FestivalKind.festival, rule: LunarRule(4, 30, Karmakal.aparahna),
    headline: '🐂 बैलपोळ्याच्या हार्दिक शुभेच्छा',
    message: 'वर्षभर शेतात राबणाऱ्या सर्जा-राजाचा सन्मान करणारा हा सण बळीराजाला सुख-समृद्धी देवो.',
    layout: 'festive', gradient: _ganesh,
  ),
  // ---- भाद्रपद
  Festival(
    id: 'hartalika', name: 'हरितालिका', kind: FestivalKind.festival, rule: LunarRule(5, 3),
    headline: '🌸 हरितालिकेच्या हार्दिक शुभेच्छा',
    message: 'माता पार्वतीच्या आशीर्वादाने सर्व माता-भगिनींना सौभाग्य आणि सुख लाभो.',
    layout: 'festive', gradient: _pink,
  ),
  Festival(
    id: 'ganeshchaturthi', name: 'श्री गणेश चतुर्थी', kind: FestivalKind.festival,
    rule: LunarRule(5, 4, Karmakal.madhyahna),
    headline: '🐘 गणपती बाप्पा मोरया!',
    message: 'श्री गणेश चतुर्थीच्या हार्दिक शुभेच्छा. विघ्नहर्ता गणराय सर्व विघ्ने दूर करून सुख-समृद्धी देवो.',
    layout: 'festive', gradient: _ganesh, headlineFont: 'modak',
  ),
  Festival(
    id: 'rishipanchami', name: 'ऋषिपंचमी', kind: FestivalKind.festival, rule: LunarRule(5, 5),
    headline: '🙏 ऋषिपंचमी',
    message: 'सप्तर्षींच्या चरणी वंदन. ऋषिपंचमीच्या सर्वांना शुभेच्छा.',
    layout: 'minimal', gradient: _cream, headlineFont: 'tiroMarathi',
  ),
  Festival(
    id: 'anantchaturdashi', name: 'अनंत चतुर्दशी', kind: FestivalKind.festival, rule: LunarRule(5, 14),
    headline: '🐘 गणपती बाप्पा मोरया, पुढच्या वर्षी लवकर या!',
    message: 'अनंत चतुर्दशीनिमित्त बाप्पाला भावपूर्ण निरोप. श्री गणरायाचा आशीर्वाद सदैव राहो.',
    layout: 'festive', gradient: _ganesh,
  ),
  // ---- आश्विन (नवरात्र, दसरा, दिवाळी)
  Festival(
    id: 'ghatasthapana', name: 'घटस्थापना – नवरात्र आरंभ', kind: FestivalKind.festival, rule: LunarRule(6, 1),
    headline: '🪔 नवरात्र उत्सवाच्या हार्दिक शुभेच्छा',
    message: 'घटस्थापनेपासून आदिशक्तीचा जागर सुरू. पहिला दिवस – देवी शैलपुत्री. आई जगदंबा सर्वांचे कल्याण करो.',
    layout: 'festive', gradient: _devi,
  ),
  Festival(
    id: 'navratri2', name: 'नवरात्र – दुसरा दिवस', kind: FestivalKind.festival, rule: LunarRule(6, 2),
    headline: '🌺 नवरात्र – दुसरा दिवस',
    message: 'देवी ब्रह्मचारिणीच्या कृपेने तप, संयम आणि शक्ती लाभो. उदे गं अंबे उदे!',
    gradient: _devi,
  ),
  Festival(
    id: 'navratri3', name: 'नवरात्र – तिसरा दिवस', kind: FestivalKind.festival, rule: LunarRule(6, 3),
    headline: '🌺 नवरात्र – तिसरा दिवस',
    message: 'देवी चंद्रघंटेच्या आशीर्वादाने जीवनात शांती व धैर्य लाभो. उदे गं अंबे उदे!',
    gradient: _devi,
  ),
  Festival(
    id: 'navratri4', name: 'नवरात्र – चौथा दिवस', kind: FestivalKind.festival, rule: LunarRule(6, 4),
    headline: '🌺 नवरात्र – चौथा दिवस',
    message: 'देवी कूष्मांडेच्या कृपेने आरोग्य व समृद्धी लाभो. उदे गं अंबे उदे!',
    gradient: _devi,
  ),
  Festival(
    id: 'lalitapanchami', name: 'ललिता पंचमी', kind: FestivalKind.festival, rule: LunarRule(6, 5),
    headline: '🌺 ललिता पंचमी – नवरात्र पाचवा दिवस',
    message: 'देवी स्कंदमातेच्या आशीर्वादाने कुटुंबात प्रेम व सौख्य नांदो. उदे गं अंबे उदे!',
    gradient: _devi,
  ),
  Festival(
    id: 'navratri6', name: 'नवरात्र – सहावा दिवस', kind: FestivalKind.festival, rule: LunarRule(6, 6),
    headline: '🌺 नवरात्र – सहावा दिवस',
    message: 'देवी कात्यायनीच्या कृपेने सर्व संकटे दूर होवोत. उदे गं अंबे उदे!',
    gradient: _devi,
  ),
  Festival(
    id: 'navratri7', name: 'नवरात्र – सातवा दिवस', kind: FestivalKind.festival, rule: LunarRule(6, 7),
    headline: '🌺 नवरात्र – सातवा दिवस',
    message: 'देवी कालरात्री सर्व भय दूर करो. उदे गं अंबे उदे!',
    gradient: _maroon,
  ),
  Festival(
    id: 'durgashtami', name: 'दुर्गाष्टमी', kind: FestivalKind.festival, rule: LunarRule(6, 8),
    headline: '🔱 दुर्गाष्टमीच्या हार्दिक शुभेच्छा',
    message: 'नवरात्रीचा आठवा दिवस – देवी महागौरी. आई दुर्गा सर्वांना शक्ती, भक्ती आणि सौभाग्य देवो.',
    layout: 'festive', gradient: _devi,
  ),
  Festival(
    id: 'mahanavami', name: 'महानवमी', kind: FestivalKind.festival, rule: LunarRule(6, 9),
    headline: '🔱 महानवमीच्या हार्दिक शुभेच्छा',
    message: 'नवरात्रीचा नववा दिवस – देवी सिद्धिदात्री. आई जगदंबेच्या कृपेने सर्व मनोकामना पूर्ण होवोत.',
    layout: 'festive', gradient: _devi,
  ),
  Festival(
    id: 'dasara', name: 'विजयादशमी (दसरा)', kind: FestivalKind.festival, rule: LunarRule(6, 10, Karmakal.aparahna),
    headline: '🏹 विजयादशमी (दसरा)च्या हार्दिक शुभेच्छा',
    message: 'सोने घ्या, सोन्यासारखे राहा! असत्यावर सत्याचा विजय साजरा करणारा हा सण सर्वांना यश देवो.',
    layout: 'festive', gradient: _saffron,
  ),
  Festival(
    id: 'kojagiri', name: 'कोजागिरी पौर्णिमा', kind: FestivalKind.festival, rule: LunarRule(6, 15, Karmakal.nishita),
    headline: '🌕 कोजागिरी पौर्णिमेच्या शुभेच्छा',
    message: 'शरद पौर्णिमेच्या चांदण्यात आटीव दुधाचा आस्वाद घेऊ या. को जागर्ति? लक्ष्मी सर्वांच्या घरी नांदो.',
    gradient: _night, headlineFont: 'rozhaOne',
  ),
  Festival(
    id: 'vasubaras', name: 'वसुबारस', kind: FestivalKind.festival, rule: LunarRule(6, 27, Karmakal.pradosh),
    headline: '🐄 वसुबारस – दिवाळीच्या शुभेच्छा',
    message: 'गाय-वासराच्या पूजनाने दिवाळीचा शुभारंभ. सर्वांना दीपावलीच्या मंगलमय शुभेच्छा.',
    layout: 'festive', gradient: _diwali,
  ),
  Festival(
    id: 'dhanteras', name: 'धनत्रयोदशी', kind: FestivalKind.festival, rule: LunarRule(6, 28, Karmakal.pradosh),
    headline: '🪙 धनत्रयोदशीच्या हार्दिक शुभेच्छा',
    message: 'धन्वंतरींच्या कृपेने उत्तम आरोग्य आणि लक्ष्मीच्या कृपेने समृद्धी लाभो.',
    layout: 'festive', gradient: _diwali,
  ),
  Festival(
    id: 'narakchaturdashi', name: 'नरक चतुर्दशी', kind: FestivalKind.festival,
    rule: LunarRule(6, 29, Karmakal.arunodaya),
    headline: '🪔 नरक चतुर्दशी – अभ्यंगस्नान',
    message: 'दिवाळीच्या पहिल्या आंघोळीच्या सर्वांना मंगलमय शुभेच्छा. अंधारावर प्रकाशाचा विजय होवो.',
    layout: 'festive', gradient: _diwali,
  ),
  Festival(
    id: 'lakshmipujan', name: 'लक्ष्मीपूजन (दिवाळी)', kind: FestivalKind.festival,
    rule: LunarRule(6, 30, Karmakal.aparahna),
    headline: '🪔 शुभ दीपावली – लक्ष्मीपूजन',
    message: 'दीपावलीचा प्रकाश आपल्या जीवनात सुख, समृद्धी आणि आनंद घेऊन येवो. $_jai',
    layout: 'festive', gradient: _diwali, headlineFont: 'rozhaOne',
  ),
  // ---- कार्तिक
  Festival(
    id: 'padwa', name: 'बलिप्रतिपदा (दिवाळी पाडवा)', kind: FestivalKind.festival, rule: LunarRule(7, 1),
    headline: '🪔 दिवाळी पाडव्याच्या हार्दिक शुभेच्छा',
    message: 'इडा पिडा टळो, बळीचे राज्य येवो! नूतन वर्ष सुख-समृद्धीचे जावो.',
    layout: 'festive', gradient: _diwali,
  ),
  Festival(
    id: 'bhaubeej', name: 'भाऊबीज', kind: FestivalKind.festival, rule: LunarRule(7, 2),
    headline: '💐 भाऊबीजेच्या हार्दिक शुभेच्छा',
    message: 'बहीण-भावाचे प्रेम असेच वृद्धिंगत होवो. सर्वांना भाऊबीजेच्या मनःपूर्वक शुभेच्छा.',
    layout: 'festive', gradient: _pink,
  ),
  Festival(
    id: 'kartiki', name: 'कार्तिकी एकादशी', kind: FestivalKind.festival, rule: LunarRule(7, 11),
    headline: '🙏 कार्तिकी एकादशीच्या शुभेच्छा',
    message: 'प्रबोधिनी एकादशीनिमित्त विठ्ठल-रखुमाईच्या चरणी वंदन. जय जय राम कृष्ण हरी!',
    gradient: _vitthal, headlineFont: 'rozhaOne',
  ),
  Festival(
    id: 'tulsivivah', name: 'तुळशी विवाह', kind: FestivalKind.festival, rule: LunarRule(7, 12, Karmakal.pradosh),
    headline: '🌿 तुळशी विवाहाच्या शुभेच्छा',
    message: 'तुळशी विवाहाने शुभ कार्यांचा आरंभ. सर्वांच्या घरी मांगल्य नांदो.',
    layout: 'festive', gradient: _green,
  ),
  Festival(
    id: 'tripurari', name: 'त्रिपुरारी पौर्णिमा', kind: FestivalKind.festival, rule: LunarRule(7, 15),
    headline: '🪔 त्रिपुरारी पौर्णिमेच्या शुभेच्छा',
    message: 'देवदिवाळीनिमित्त दीपोत्सव. महादेवाच्या कृपेने सर्वांचे जीवन प्रकाशमय होवो.',
    gradient: _shiva,
  ),
  Festival(
    id: 'kalbhairavjayanti', name: 'श्री काळभैरव जयंती', kind: FestivalKind.jayanti,
    rule: LunarRule(7, 23, Karmakal.madhyahna),
    headline: '🔱 श्री काळभैरव जयंतीच्या हार्दिक शुभेच्छा',
    message: 'श्री काळभैरव जागृत देवस्थान, रुंधाटी येथे जयंती उत्सव. सर्व भाविकांनी दर्शनाचा लाभ घ्यावा. जय काळभैरव!',
    gradient: _maroon, headlineFont: 'rozhaOne',
  ),
  // ---- मार्गशीर्ष
  Festival(
    id: 'champashashthi', name: 'चंपाषष्ठी', kind: FestivalKind.festival, rule: LunarRule(8, 6),
    headline: '🟡 चंपाषष्ठी – येळकोट येळकोट जय मल्हार',
    message: 'श्री खंडेरायाच्या कृपेने सर्वांचे कल्याण होवो. चंपाषष्ठीच्या हार्दिक शुभेच्छा.',
    layout: 'festive', gradient: _ganesh,
  ),
  Festival(
    id: 'gitajayanti', name: 'गीता जयंती', kind: FestivalKind.jayanti, rule: LunarRule(8, 11),
    headline: '📖 गीता जयंती',
    message: 'कर्मण्येवाधिकारस्ते मा फलेषु कदाचन. श्रीमद्भगवद्गीता जयंतीच्या शुभेच्छा.',
    layout: 'minimal', gradient: _cream, headlineFont: 'tiroMarathi',
  ),
  Festival(
    id: 'dattajayanti', name: 'दत्त जयंती', kind: FestivalKind.jayanti, rule: LunarRule(8, 15, Karmakal.pradosh),
    headline: '🙏 श्री दत्त जयंतीच्या हार्दिक शुभेच्छा',
    message: 'दिगंबरा दिगंबरा श्रीपाद वल्लभ दिगंबरा. श्री गुरुदेव दत्त सर्वांचे कल्याण करोत.',
    gradient: _saffron, headlineFont: 'rozhaOne',
  ),
  // ---- पौष / संक्रांत
  Festival(
    id: 'bhogi', name: 'भोगी', kind: FestivalKind.festival, rule: SankrantiRule(9, offsetDays: -1),
    headline: '🌾 भोगीच्या हार्दिक शुभेच्छा',
    message: 'नव्या धान्याच्या आनंदाचा हा सण सर्वांना सुख-समृद्धी देवो.',
    layout: 'festive', gradient: _green,
  ),
  Festival(
    id: 'makarsankranti', name: 'मकर संक्रांत', kind: FestivalKind.festival, rule: SankrantiRule(9),
    headline: '🪁 तिळगूळ घ्या, गोड गोड बोला!',
    message: 'मकर संक्रांतीच्या हार्दिक शुभेच्छा. नात्यांमधला गोडवा असाच वाढत राहो.',
    layout: 'festive', gradient: _dawn, textColor: _darkText, accentColor: _darkAccent, headlineFont: 'modak',
  ),
  // ---- माघ
  Festival(
    id: 'ganeshjayanti', name: 'श्री गणेश जयंती', kind: FestivalKind.jayanti, rule: LunarRule(10, 4, Karmakal.madhyahna),
    headline: '🐘 माघी गणेश जयंतीच्या शुभेच्छा',
    message: 'श्री गणरायाच्या जन्मोत्सवानिमित्त सर्वांना मंगलमय शुभेच्छा. गणपती बाप्पा मोरया!',
    gradient: _ganesh,
  ),
  Festival(
    id: 'vasantpanchami', name: 'वसंत पंचमी', kind: FestivalKind.festival, rule: LunarRule(10, 5),
    headline: '🌼 वसंत पंचमीच्या शुभेच्छा',
    message: 'विद्येची देवता सरस्वती सर्वांना ज्ञान आणि सद्बुद्धी देवो.',
    layout: 'classic', gradient: _dawn, textColor: _darkText, accentColor: _darkAccent,
  ),
  Festival(
    id: 'rathasaptami', name: 'रथसप्तमी', kind: FestivalKind.festival, rule: LunarRule(10, 7),
    headline: '☀️ रथसप्तमीच्या शुभेच्छा',
    message: 'सूर्यनारायणाच्या कृपेने सर्वांना उत्तम आरोग्य आणि तेज लाभो.',
    layout: 'classic', gradient: _dawn, textColor: _darkText, accentColor: _darkAccent,
  ),
  Festival(
    id: 'gajananprakat', name: 'श्री गजानन महाराज प्रकट दिन', kind: FestivalKind.jayanti, rule: LunarRule(10, 22),
    headline: '🙏 श्री गजानन महाराज प्रकट दिन',
    message: 'गण गण गणात बोते. श्री संत गजानन महाराजांच्या प्रकट दिनानिमित्त सर्व भाविकांना शुभेच्छा.',
    gradient: _saffron,
  ),
  Festival(
    id: 'mahashivratri', name: 'महाशिवरात्री', kind: FestivalKind.festival, rule: LunarRule(10, 29, Karmakal.nishita),
    headline: '🔱 महाशिवरात्रीच्या हार्दिक शुभेच्छा',
    message: 'ॐ नमः शिवाय. भोलेनाथ आणि श्री काळभैरव सर्वांचे रक्षण करोत. हर हर महादेव!',
    gradient: _shiva, headlineFont: 'rozhaOne',
  ),
  // ---- फाल्गुन
  Festival(
    id: 'holi', name: 'होळी', kind: FestivalKind.festival, rule: LunarRule(11, 15, Karmakal.pradosh),
    headline: '🔥 होळीच्या हार्दिक शुभेच्छा',
    message: 'होळीच्या अग्नीत सर्व वाईट गोष्टी जळून जावोत आणि जीवनात आनंदाचे रंग भरोत.',
    layout: 'festive', gradient: _red,
  ),
  Festival(
    id: 'dhulivandan', name: 'धुलिवंदन', kind: FestivalKind.festival, rule: OffsetRule('holi', 1),
    headline: '🎨 धुलिवंदनाच्या रंगीत शुभेच्छा',
    message: 'रंगांचा हा सण आपल्या जीवनात आनंद, प्रेम आणि उत्साहाचे रंग भरो.',
    layout: 'festive', gradient: _holi, headlineFont: 'modak',
  ),
  Festival(
    id: 'tukarambeej', name: 'तुकाराम बीज', kind: FestivalKind.jayanti, rule: LunarRule(11, 17),
    headline: '🙏 तुकाराम बीज',
    message: 'जगद्गुरू संत तुकाराम महाराजांना विनम्र अभिवादन. बोला पुंडलिक वरदे हरी विठ्ठल!',
    gradient: _vitthal,
  ),
  Festival(
    id: 'rangpanchami', name: 'रंगपंचमी', kind: FestivalKind.festival, rule: LunarRule(11, 20),
    headline: '🎨 रंगपंचमीच्या हार्दिक शुभेच्छा',
    message: 'प्रेम, मैत्री आणि आनंदाच्या रंगांनी जीवन उजळून निघो.',
    layout: 'festive', gradient: _holi, headlineFont: 'modak',
  ),
  // ---- दिनांकानुसार (जयंती व राष्ट्रीय दिवस)
  Festival(
    id: 'newyear', name: 'नववर्ष', kind: FestivalKind.national, rule: DateRule(1, 1),
    headline: '🎉 नववर्षाच्या हार्दिक शुभेच्छा',
    message: 'नवे वर्ष आपणा सर्वांना आरोग्य, आनंद आणि यश देवो. $_jai',
    layout: 'festive', gradient: _diwali,
  ),
  Festival(
    id: 'savitribai', name: 'क्रांतिज्योती सावित्रीबाई फुले जयंती', kind: FestivalKind.jayanti, rule: DateRule(1, 3),
    headline: '🙏 सावित्रीबाई फुले जयंती',
    message: 'स्त्री शिक्षणाच्या जननी क्रांतिज्योती सावित्रीबाई फुले यांना जयंतीनिमित्त विनम्र अभिवादन.',
    layout: 'minimal', gradient: _cream, headlineFont: 'tiroMarathi',
  ),
  Festival(
    id: 'republicday', name: 'प्रजासत्ताक दिन', kind: FestivalKind.national, rule: DateRule(1, 26),
    headline: '🇮🇳 प्रजासत्ताक दिनाच्या हार्दिक शुभेच्छा',
    message: 'संविधानाचा सन्मान करू या, देशाची एकता जपू या. जय हिंद!',
    layout: 'classic', gradient: _tricolor, textColor: 0xFF0D2A6B, accentColor: 0xFF000080, headlineFont: 'palanquinDark',
  ),
  Festival(
    id: 'shivjayanti', name: 'छत्रपती शिवाजी महाराज जयंती', kind: FestivalKind.jayanti, rule: DateRule(2, 19),
    headline: '🚩 शिवजयंतीच्या हार्दिक शुभेच्छा',
    message: 'हिंदवी स्वराज्य संस्थापक छत्रपती शिवाजी महाराजांना मानाचा मुजरा. जय भवानी, जय शिवाजी!',
    gradient: _shivaji, headlineFont: 'rozhaOne',
  ),
  Festival(
    id: 'marathibhashadin', name: 'मराठी भाषा गौरव दिन', kind: FestivalKind.national, rule: DateRule(2, 27),
    headline: '📜 मराठी भाषा गौरव दिनाच्या शुभेच्छा',
    message: 'माझ्या मराठीचे बोलु कौतुके, परि अमृतातेहि पैजासी जिंके. मराठी असल्याचा अभिमान बाळगू या.',
    layout: 'minimal', gradient: _cream, headlineFont: 'tiroMarathi',
  ),
  Festival(
    id: 'phulejayanti', name: 'महात्मा ज्योतिराव फुले जयंती', kind: FestivalKind.jayanti, rule: DateRule(4, 11),
    headline: '🙏 महात्मा फुले जयंती',
    message: 'सत्यशोधक, समाजसुधारक महात्मा ज्योतिराव फुले यांना जयंतीनिमित्त विनम्र अभिवादन.',
    layout: 'minimal', gradient: _cream, headlineFont: 'tiroMarathi',
  ),
  Festival(
    id: 'ambedkarjayanti', name: 'डॉ. बाबासाहेब आंबेडकर जयंती', kind: FestivalKind.jayanti, rule: DateRule(4, 14),
    headline: '🙏 भीमजयंतीच्या हार्दिक शुभेच्छा',
    message: 'भारतीय संविधानाचे शिल्पकार डॉ. बाबासाहेब आंबेडकर यांना जयंतीनिमित्त विनम्र अभिवादन.',
    gradient: _night,
  ),
  Festival(
    id: 'maharashtradin', name: 'महाराष्ट्र दिन', kind: FestivalKind.national, rule: DateRule(5, 1),
    headline: '🚩 महाराष्ट्र दिनाच्या हार्दिक शुभेच्छा',
    message: 'जय जय महाराष्ट्र माझा, गर्जा महाराष्ट्र माझा! सर्वांना महाराष्ट्र दिन व कामगार दिनाच्या शुभेच्छा.',
    gradient: _shivaji, headlineFont: 'palanquinDark',
  ),
  Festival(
    id: 'shivrajyabhishek', name: 'शिवराज्याभिषेक दिन', kind: FestivalKind.national, rule: DateRule(6, 6),
    headline: '👑 शिवराज्याभिषेक दिनाच्या शुभेच्छा',
    message: 'छत्रपती शिवाजी महाराजांच्या राज्याभिषेक दिनानिमित्त मानाचा मुजरा. जय शिवराय!',
    gradient: _shivaji, headlineFont: 'rozhaOne',
  ),
  Festival(
    id: 'shahujayanti', name: 'राजर्षी शाहू महाराज जयंती', kind: FestivalKind.jayanti, rule: DateRule(6, 26),
    headline: '🙏 राजर्षी शाहू महाराज जयंती',
    message: 'सामाजिक न्यायाचे प्रणेते राजर्षी शाहू महाराज यांना जयंतीनिमित्त विनम्र अभिवादन.',
    layout: 'minimal', gradient: _cream, headlineFont: 'tiroMarathi',
  ),
  Festival(
    id: 'tilakjayanti', name: 'लोकमान्य टिळक जयंती', kind: FestivalKind.jayanti, rule: DateRule(7, 23),
    headline: '🙏 लोकमान्य टिळक जयंती',
    message: 'स्वराज्य हा माझा जन्मसिद्ध हक्क आहे आणि तो मी मिळवणारच! लोकमान्यांना विनम्र अभिवादन.',
    layout: 'minimal', gradient: _cream, headlineFont: 'tiroMarathi',
  ),
  Festival(
    id: 'independenceday', name: 'स्वातंत्र्य दिन', kind: FestivalKind.national, rule: DateRule(8, 15),
    headline: '🇮🇳 स्वातंत्र्य दिनाच्या हार्दिक शुभेच्छा',
    message: 'स्वातंत्र्यसैनिकांच्या बलिदानाला वंदन. देशाची प्रगती हेच आपले ध्येय. जय हिंद!',
    layout: 'classic', gradient: _tricolor, textColor: 0xFF0D2A6B, accentColor: 0xFF000080, headlineFont: 'palanquinDark',
  ),
  Festival(
    id: 'gandhijayanti', name: 'महात्मा गांधी जयंती', kind: FestivalKind.national, rule: DateRule(10, 2),
    headline: '🙏 गांधी जयंती',
    message: 'सत्य आणि अहिंसेचे पुजारी महात्मा गांधी यांना जयंतीनिमित्त विनम्र अभिवादन.',
    layout: 'minimal', gradient: _cream, headlineFont: 'tiroMarathi',
  ),
];

/// Ekadashi names by amanta month (शुक्ल, कृष्ण).
const _ekadashiNames = [
  ('कामदा', 'वरूथिनी'), ('मोहिनी', 'अपरा'), ('निर्जला', 'योगिनी'), ('देवशयनी', 'कामिका'),
  ('पुत्रदा', 'अजा'), ('परिवर्तिनी', 'इंदिरा'), ('पाशांकुशा', 'रमा'), ('प्रबोधिनी', 'उत्पत्ती'),
  ('मोक्षदा', 'सफला'), ('पुत्रदा', 'षट्तिला'), ('जया', 'विजया'), ('आमलकी', 'पापमोचनी'),
];

String _masaLabel(PanchangMoment p) => '${p.adhik ? 'अधिक ' : ''}${masaNamesMr[p.masa]}';

Festival _vrat(String id, PanchangMoment p, DateTime d, String name, String headline, String message,
        {List<int> gradient = _maroon, String layout = 'classic', String headlineFont = 'yatraOne'}) =>
    Festival(
      id: '$id-${dateKey(d)}',
      name: name,
      kind: FestivalKind.vrat,
      rule: LunarRule(p.masa, p.tithi),
      headline: headline,
      message: message,
      layout: layout,
      gradient: gradient,
      headlineFont: headlineFont,
    );

/// Monthly observances shown on the calendar and in the Banner Studio.
final monthlyVrats = <MonthlyVrat>[
  for (final shukla in [true, false])
    MonthlyVrat(shukla ? 11 : 26, Karmakal.sunrise, (p, d) {
      final names = _ekadashiNames[p.masa];
      final n = p.adhik ? (shukla ? 'पद्मिनी' : 'परमा') : (shukla ? names.$1 : names.$2);
      return _vrat('ekadashi', p, d, '$n एकादशी', '🙏 $n एकादशी',
          'आज $n एकादशी. विठ्ठलाचे नामस्मरण करू या. जय जय राम कृष्ण हरी!',
          gradient: _vitthal);
    }),
  MonthlyVrat(19, Karmakal.moonrise, (p, d) {
    final angarki = d.weekday == DateTime.tuesday;
    final n = angarki ? 'अंगारकी संकष्ट चतुर्थी' : 'संकष्ट चतुर्थी';
    return _vrat('sankashti', p, d, n, '🐘 $n',
        'श्री गणरायाच्या कृपेने सर्व संकटे दूर होवोत. चंद्रोदयानंतर उपवास सोडावा. गणपती बाप्पा मोरया!',
        gradient: _ganesh);
  }),
  MonthlyVrat(4, Karmakal.madhyahna, (p, d) => _vrat('vinayaki', p, d, 'विनायकी चतुर्थी', '🌺 विनायकी चतुर्थी',
      'श्री गणरायाच्या आशीर्वादाने सर्व कार्ये निर्विघ्न पार पडोत.',
      gradient: _ganesh)),
  MonthlyVrat(23, Karmakal.pradosh, (p, d) => _vrat('kalashtami', p, d, 'कालाष्टमी', '🔱 कालाष्टमी – जय काळभैरव',
      'आज कालाष्टमी – श्री काळभैरव महाराजांच्या उपासनेचा विशेष दिवस. रुंधाटी येथील श्री काळभैरव जागृत देवस्थानात दर्शनाचा लाभ घ्यावा.',
      layout: 'royal', headlineFont: 'rozhaOne')),
  for (final t in [13, 28])
    MonthlyVrat(t, Karmakal.pradosh, (p, d) {
      final prefix = switch (d.weekday) { DateTime.monday => 'सोम ', DateTime.saturday => 'शनि ', _ => '' };
      return _vrat('pradosh', p, d, '$prefixप्रदोष', '🔱 $prefixप्रदोष व्रत',
          'प्रदोषकाळी महादेवाचे पूजन करू या. ॐ नमः शिवाय.',
          gradient: _shiva);
    }),
  MonthlyVrat(29, Karmakal.nishita, (p, d) => _vrat('shivratri', p, d, 'मासिक शिवरात्री', '🔱 मासिक शिवरात्री',
      'हर हर महादेव! भोलेनाथ सर्वांचे रक्षण करो.',
      gradient: _shiva)),
  MonthlyVrat(15, Karmakal.sunrise, (p, d) => _vrat('purnima', p, d, '${_masaLabel(p)} पौर्णिमा', '🌕 ${_masaLabel(p)} पौर्णिमा',
      'पौर्णिमेच्या चांदण्यासारखे आपले जीवन प्रकाशमय होवो. $_jai',
      gradient: _night)),
  MonthlyVrat(30, Karmakal.sunrise, (p, d) {
    final somvati = d.weekday == DateTime.monday;
    final n = '${somvati ? 'सोमवती ' : ''}${_masaLabel(p)} अमावस्या';
    return _vrat('amavasya', p, d, n, '🌑 $n', 'आज $n. देवदर्शन व दानधर्माचा दिवस. $_jai', gradient: _shiva);
  }),
];
