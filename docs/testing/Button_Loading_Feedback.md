# Button feedback audit

Checked game navigation, settings, lessons, restoration/reward screens, account actions, coin shop, rewarded ads, result transitions and browser authentication.

| Actions | Feedback |
| --- | --- |
| Settings, menus, lessons, card swaps and local reward claims | Immediate control/screen change and existing press/audio feedback. Their disabled states remain owned by the action. |
| Google / guardian sign-in | Signing-in caption, existing progress bar/status, duplicate prevention and cancellation/failure recovery. |
| Cloud save/load, sign out, account deletion, purchased supply and pending purchase check | Visible operation dialog while pending; duplicate account operations blocked; dialog released on completion/error. |
| Online price retry | Loading caption and disabled retry button until the request finishes; catalog request has a timeout. |
| Coin shop | Online-price loading message; purchase/verification wait message; conflicting buttons unavailable while payment is pending. Pending-purchase checks have a 30-second wait limit. |
| Rewarded ads / result interstitial | Pending caption and disabled action controls during the ad; normal captions restored afterward. |
| Browser Google consent / return to game | Opening caption, accessible live status and duplicate suppression. Native form/link navigation is preserved. Browser Back resets controls; a failed app launch becomes retryable after five seconds. |

Validation: button_feedback_checks 19 checks, mobile_ui_checks 1,314 checks, journey_checks 246 checks and server tests 18 tests passed. Economy suite also passed. Browser feedback tests exercise click/submit handlers, duplicate suppression, Back recovery and missing-handler retry. This is automated local validation, not a physical-device or live Render deployment check.

Browser changes require deploying the server; game changes require running this project or exporting an updated app.
