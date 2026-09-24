Locales = Locales or {}

function _L(key, lang)
    lang = lang or Config.Locale or 'ar'
    local pack = Locales[lang] or Locales['en']
    return (pack and pack[key]) or (Locales['en'] and Locales['en'][key]) or key
end
