package com.savethebaby.auth;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;

/** One unambiguous browser return handler, forwarding to the existing game task. */
public final class AuthReturnActivity extends Activity {
    @Override public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Uri uri = getIntent().getData();
        if (uri != null && "savethebaby".equals(uri.getScheme())
                && "auth".equals(uri.getHost()) && "/complete".equals(uri.getPath())) {
            Intent game = new Intent(Intent.ACTION_VIEW, uri);
            game.setClassName(getPackageName(), "com.godot.game.GodotApp");
            game.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
            startActivity(game);
        }
        finish();
    }
}
