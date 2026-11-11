# Dialog readability audit — 11 November 2026

The Privacy Policy and Terms viewer used pale `#fff3d5` rich text on a cream paper panel. These two views share one implementation. Opening the window alone did not establish that its contents were readable. The repair gives both views dark body text, a visible heading and larger body type. Shared paper-dialog defaults now cover Label, RichTextLabel and button states; explicit view-level overrides can still supersede those defaults and therefore require tests.

The audit also found that the in-game Google Play purchase confirmation could exceed the viewport and hide its action buttons. Its long message now scrolls inside a bounded content area. Purchase actions were not executed during testing.

`tests/dialog_readability_checks.gd` opens nine real dialog states: Settings, Privacy Policy, Terms, guest Account, Coin Shop, supply confirmation, in-game Google Play confirmation, account-deletion confirmation, and service notice. It checks visible text contrast, legal-body font size and content presence, button text, and full-window bounds. The fixed build passes 68 checks. The existing mobile UI suite passes 1,268 checks, and the economy suite passes.

Run `powershell -ExecutionPolicy Bypass -File tools/run_checks.ps1 -Suite dialog_readability_checks` for the automated audit. A graphical run of the same scene with `-- --capture` writes screenshots to `.test-data/dialog-*.png`; numerical results are in `.test-data/dialog-readability-report.json`.

Scope: these results cover the nine listed in-game dialogs at the test viewport and the existing mobile UI suite's scenarios. They do not certify every dynamic state, localization, Android-native age/consent/permission dialog, or the external Google Play checkout. Those require device testing. The policy and terms text was not changed by this readability repair.
