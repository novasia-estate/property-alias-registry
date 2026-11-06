# Key policy 1.0

The public `normalize(value)` function returns a key string or `nil, error_code`. It accepts at most4096bytes. UTF-8 validation rejects overlong sequences, continuation-byte errors, truncated sequences, surrogate code points and values above U+10FFFF.

Mapped characters:

| Input | Output |
| --- | --- |
| ASCII A–Z | a–z |
| ASCII tab | space |
| U+00A0, U+202F, U+3000 | space |
| U+2010 through U+2015 | hyphen-minus |
| U+2018, U+2019 | ASCII apostrophe |

Runs of resulting ordinary spaces are collapsed and edge ordinary spaces removed. Other valid code points are preserved, including combining marks and meaningful joiners. There is no NFC/NFKC operation and no non-ASCII case folding. `Гарден` and `гарден` need separate aliases. Latin C and Cyrillic С remain different. Store explicit approved aliases instead of assuming transliteration or visual similarity.

ASCII/C1 controls reject except tab; U+2028/U+2029 and directional embedding/isolate controls U+202A–U+202E/U+2066–U+2069 reject. This list is not a full spoofing-detection or Unicode-security standard. A string passing this policy may still be confusing or inappropriate; human review remains necessary.

Punctuation normalization can cause collisions. The resolver preserves multiple candidates, and audit() reports those collisions. Changing this policy in a future release can change keys and therefore requires deliberate migration/review of existing registries.
