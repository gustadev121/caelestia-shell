pragma Singleton

import Quickshell
import Caelestia.I18n

Singleton {
    property var _regexCache: ({})

    function percent(value: int): string {
        // TRANSLATORS: %1 = a number
        return Tr.tr("%1%").arg(value);
    }

    function percentOne(value: real): string {
        return percent(Math.round(value * 100));
    }

    function testRegexList(filterList: list<string>, target: string): bool {
        const regexChecker = /^\^.*\$$/;
        for (const filter of filterList) {
            if (regexChecker.test(filter)) {
                let re = _regexCache[filter];
                if (!re) {
                    re = new RegExp(filter);
                    _regexCache[filter] = re;
                }
                if (re.test(target))
                    return true;
            } else {
                if (filter === target)
                    return true;
            }
        }
        return false;
    }

    function stripMarkup(text: string): string {
        if (!text)
            return text;

        let s = text;

        // Decode common HTML entities so escaped markup doesn't leak through
        s = s.replace(/&nbsp;/g, " ")
            .replace(/&amp;/g, "&")
            .replace(/&lt;/g, "<")
            .replace(/&gt;/g, ">")
            .replace(/&quot;/g, "\"")
            .replace(/&#39;/g, "'")
            .replace(/&#(\d+);/g, (m, dec) => String.fromCharCode(Number(dec)));

        // Remove HTML tags (but not stray < or > used as comparison operators)
        s = s.replace(/<[a-zA-Z][^>]*>|<\/[a-zA-Z][^>]*>|<!--[\s\S]*?-->/g, "");

        // Markdown images and links: ![alt](url), [text](url)
        s = s.replace(/!\[([^\]]*)\]\([^)]*\)/g, "$1");
        s = s.replace(/\[([^\]]*)\]\([^)]*\)/g, "$1");

        // Markdown strong, emphasis, strikethrough and inline code
        s = s.replace(/\*\*([^*]+)\*\*/g, "$1");
        s = s.replace(/__([^_]+)__/g, "$1");
        s = s.replace(/\*([^*\n]+)\*/g, "$1");
        s = s.replace(/(^|\s)_([^_\n]+)_(?=\s|$)/g, "$1$2");
        s = s.replace(/~~([^~\n]+)~~/g, "$1");
        s = s.replace(/`([^`\n]+)`/g, "$1");

        // Markdown headings, blockquotes and list markers
        s = s.replace(/^\s{0,3}#{1,6}\s+/gm, "");
        s = s.replace(/^\s{0,3}>\s?/gm, "");
        s = s.replace(/^\s*([-*+]|\d+[.)])\s+/gm, "$1 ");

        return s;
    }
}
