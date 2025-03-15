local Const = {};

---@alias app.EnemyDef.CrownType integer

---@type table<string, app.EnemyDef.CrownType>
Const.CrownType = {
    None = 0,
    Small = 1,
    Big = 2,
    King = 3,
}

Const.CrownNames = {
    [Const.CrownType.None] = "Normal",
    [Const.CrownType.Small] = "Small",
    [Const.CrownType.Big] = "Big",
    [Const.CrownType.King] = "King"
}

Const.CrownIcons = {
    [Const.CrownType.None] = "none",
    [Const.CrownType.Small] = "miniCrown",
    [Const.CrownType.Big] = "bigCrown",
    [Const.CrownType.King] = "kingCrown"
}

-- Languages --

---@type table<string, via.Language>
Const.Language = {
    Japanese = 0,
    English = 1,
    Korean = 11,
    TraditionalChinese = 12,
    SimplifiedChinese = 13,
}


Const.Fonts = {
    Default = {
        FONT_FAMILY = "Noto Sans",
        FONT_NAME = 'NotoSans-Bold.ttf',
        GLYPH_RANGES = {
            0x0020, 0x00FF, -- Basic Latin + Latin Supplement
            0x0370, 0x03FF, -- Greek alphabet
            0x2000, 0x206F, -- General Punctuation
            0x2160, 0x217F, -- Roman Numbers
            0xFF00, 0xFFEF, -- Half-width characters
            0,
        }
    },
    [Const.Language.SimplifiedChinese] = {
        FONT_FAMILY = "Noto Sans SC",
        FONT_NAME = 'NotoSansSC-Bold.otf',
        GLYPH_RANGES = {
            0x0020, 0x00FF, -- Basic Latin + Latin Supplement
            0x0370, 0x03FF, -- Greek alphabet
            0x2000, 0x206F, -- General Punctuation
            0x2160, 0x217F, -- Roman Numbers
            0x3000, 0x30FF, -- CJK Symbols and Punctuations, Hiragana, Katakana
            0x31F0, 0x31FF, -- Katakana Phonetic Extensions
            0xFF00, 0xFFEF, -- Half-width characters
            0x4e00, 0x9FAF, -- CJK Ideograms
            0,
        }
    },
    [Const.Language.TraditionalChinese] = {
        FONT_FAMILY = "Noto Sans SC",
        FONT_NAME = 'NotoSansSC-Bold.otf',
        GLYPH_RANGES = {
            0x0020, 0x00FF, -- Basic Latin + Latin Supplement
            0x0370, 0x03FF, -- Greek alphabet
            0x2000, 0x206F, -- General Punctuation
            0x2160, 0x217F, -- Roman Numbers
            0x3000, 0x30FF, -- CJK Symbols and Punctuations, Hiragana, Katakana
            0x31F0, 0x31FF, -- Katakana Phonetic Extensions
            0xFF00, 0xFFEF, -- Half-width characters
            0x4e00, 0x9FAF, -- CJK Ideograms
            0,
        }
    },
    [Const.Language.Korean] = {
        FONT_FAMILY = "Noto Sans KR",
        FONT_NAME = "NotoSansKR-Bold.otf",
        GLYPH_RANGES = {
            0x0020, 0x00FF, -- Basic Latin + Latin SupplementFontCN
            0x0370, 0x03FF, -- Greek alphabet
            0x2000, 0x206F, -- General Punctuation
            0x2160, 0x217F, -- Roman Numbers
            0x3000, 0x30FF, -- CJK Symbols and Punctuations, Hiragana, Katakana
            0x3130, 0x318F, -- Hangul Compatibility Jamo
            0x31F0, 0x31FF, -- Katakana Phonetic Extensions
            0xFF00, 0xFFEF, -- Half-width characters
            0x4e00, 0x9FAF, -- CJK Ideograms
            0xA960, 0xA97F, -- Hangul Jamo Extended-A
            0xAC00, 0xD7A3, -- Hangul Syllables
            0xD7B0, 0xD7FF, -- Hangul Jamo Extended-B
            0,
        },
    },
    [Const.Language.Japanese] = {
        FONT_FAMILY = "Noto Sans JP",
        FONT_NAME = "NotoSansJP-Regular.otf",
        GLYPH_RANGES = {
            0x0020, 0x00FF, -- Basic Latin + Latin Supplement
            0x0370, 0x03FF, -- Greek alphabet
            0x2000, 0x206F, -- General Punctuation
            0x2160, 0x217F, -- Roman Numbers
            0x3000, 0x30FF, -- CJK Symbols and Punctuations, Hiragana, Katakana
            0x31F0, 0x31FF, -- Katakana Phonetic Extensions
            0x4e00, 0x9FFF, -- CJK Ideograms
            0xFF00, 0xFFEF, -- Half-width characters
            0,
        },
    },
    DEFAULT_FONT_SIZE = 18,
    SIZES = {
        TINY = 0,
        SMALL = 1,
        MEDIUM = 2,
        LARGE = 3,
        HUGE = 4
    }
}

return Const;
