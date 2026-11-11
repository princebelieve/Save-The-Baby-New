# Desktop login return

The game now creates a temporary listener on `127.0.0.1` when desktop sign-in
starts. The server stores only its ephemeral port and random 256-bit handoff
path. On desktop, the completion page links to that listener instead of relying
on an installed `savethebaby:` protocol handler. The listener resumes polling and
requests foreground focus; on Windows it also activates the game process, with
an editor-parent fallback for embedded Godot runs. Android retains its existing
package-specific intent.

The handoff contains no Google code, login verifier or session token. It cannot
sign a user in. OAuth still requires the browser cookie and verified Google
nonce, and game redemption still requires the original device proof. Only
loopback ports 1024–65535 and a 64-character hexadecimal random path are accepted.
The listener expires after 15 minutes and caps pending clients, request size and
request time. The game must still be running for the button to work.

Refreshing an already completed/claimed callback renders success again instead
of trying to reuse the Google code or reporting the deliberately cleared cookie
as a missing session. A genuinely missing cookie before completion still fails
securely and asks for a new sign-in. The duplicate app-link control was removed.

Verification:

- `npm.cmd test` in `server`: desktop/Android handoffs, callback reload both
  before and after redemption, invalid return parameters, existing account data,
  retry-safe login redemption and cancellation.
- Godot `--headless --path . --script res://tests/desktop_login_return_checks.gd`
  with isolated APPDATA: real HTTP handoff, bad-token rejection, callback signal,
  listener reuse and expiry.
- `tools/run_checks.ps1 -Suite economy_checks`: existing account/settings checks.

Manual end-to-end check requires a fresh sign-in from the updated running game;
previous browser pages cannot acquire a newly created local connection. After
Google sign-in, clicking Return should navigate to the local acknowledgement
and bring the running game/editor forward. Windows may restrict foreground
focus; the account still resumes via polling if focus is refused. A genuine
Google login and installed Android app launch remain device checks.
