# Praise clips

These are processed copies of the user-provided `nice.ogg`, `excellent.ogg` and
`wonderful.ogg` in `../kenney/voiceover/`. The original recordings are preserved.
Although named `.ogg`, those recordings contain Opus rather than Vorbis and
were rejected by the project's Godot Vorbis importer.

Reproduce with `python tools/prepare_praise_audio.py` on Windows with VLC installed.
VLC decodes the sources; the script trims recorder silence with onset/tail padding,
filters below 100 Hz and above 7.2 kHz, matches active speech to approximately
-18 dB RMS, gently compresses peaks, and applies short edge fades. Output is
44.1 kHz mono 16-bit PCM WAV. Pitch and speaking rate are unchanged.

Calibration references are the existing Kenney `power_up`, `objective_achieved`
and `mission_completed` voice cues. Their measured active levels were -13.87,
-15.85 and -15.17 dB RMS. Praise sits behind those announcements; its measured
levels are -18.04, -18.27 and -18.10 dB RMS respectively. All rendered peaks remain below -3 dBFS.

Runtime uses one voice player on the existing SFX bus. Only the strongest praise
per resolved move is requested; it waits for impact clips to finish plus a quiet
gap. Praise starts are separated by at least 4.2 seconds. A new impact cancels
optional speech, and mission announcements take priority. SFX mute clears both
current and queued voices. The music playback path is unchanged.
