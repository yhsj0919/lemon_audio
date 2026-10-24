# Local Windows fix

Based on `audio_service_win` 0.0.3 (https://github.com/HemantKArya/audio_service_win). Original LICENSE is retained.

- Text-only metadata updates do not call `ClearAll` or reload unchanged artwork.
- Reuse audio_service's local artwork cache path when provided.
- Removing artwork explicitly clears the thumbnail. Changing artwork replaces it after loading.
- Serialize metadata/thumbnail writes. Reject stale artwork completions after a newer cover, stop, or plugin disposal.

This package is owned as a local patch inside lemon_audio. Applications depend on lemon_audio normally, without a host dependency override.

Validation: two method-channel tests cover reuse of cached artwork and empty artwork URIs; lemon_audio's eight notification/lyric tests pass. Native compilation is verified through the MixMusic Windows build. The running desktop application can lock the final executable; do not stop it automatically. Visual flicker and rapid switching remain device checks, not automated UI tests.
