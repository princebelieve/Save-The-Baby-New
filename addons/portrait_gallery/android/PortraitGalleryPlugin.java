package com.savethebaby.gallery;

import android.Manifest;
import android.app.Activity;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.media.MediaScannerConnection;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;
import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStream;
import java.util.Collections;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/** Writes only game-provided PNGs; never reads the player's photo library. */
public final class PortraitGalleryPlugin extends GodotPlugin {
    private static final int STORAGE_REQUEST = 4718;
    private static final String ALBUM = "Pictures/Save The Baby/";
    private final ExecutorService worker = Executors.newSingleThreadExecutor();
    private byte[] waitingPng;
    private String waitingName;
    private String waitingId;

    public PortraitGalleryPlugin(Godot godot) { super(godot); }
    @Override public String getPluginName() { return "PortraitGallery"; }
    @Override public Set<SignalInfo> getPluginSignals() {
        return Collections.singleton(new SignalInfo("portrait_saved",String.class,Boolean.class,String.class));
    }

    @UsedByGodot
    public void savePortrait(byte[] png, String filename, String requestId) {
        Activity activity = getActivity();
        if (activity == null || png == null || png.length < 8 || png.length > 20000000
                || !filename.matches("SaveTheBaby_[A-Za-z0-9_-]+\\.png")) {
            result(requestId,false,"Could not prepare this portrait. Please try again.");
            return;
        }
        if (Build.VERSION.SDK_INT <= 28 && activity.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
            activity.runOnUiThread(() -> {
                if (waitingId != null) {
                    result(requestId,false,"A gallery permission request is already open.");
                    return;
                }
                waitingPng = png; waitingName = filename; waitingId = requestId;
                activity.requestPermissions(new String[]{Manifest.permission.WRITE_EXTERNAL_STORAGE},STORAGE_REQUEST);
            });
            return;
        }
        write(png,filename,requestId);
    }

    @Override public void onMainRequestPermissionsResult(int requestCode, String[] permissions, int[] grants) {
        if (requestCode != STORAGE_REQUEST || waitingId == null) return;
        byte[] png = waitingPng; String filename = waitingName; String id = waitingId;
        waitingPng = null; waitingName = null; waitingId = null;
        if (grants.length > 0 && grants[0] == PackageManager.PERMISSION_GRANTED) write(png,filename,id);
        else result(id,false,"Gallery access was declined. Your portrait is still in the game album.");
    }

    private void write(byte[] png, String filename, String id) {
        Activity activity = getActivity();
        if (activity == null) { result(id,false,"The gallery is not ready. Please try again."); return; }
        worker.execute(() -> {
            Uri inserted = null;
            ContentResolver resolver = activity.getContentResolver();
            try {
                if (Build.VERSION.SDK_INT >= 29) {
                    Uri collection = MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY);
                    // An interrupted/retried request must not create duplicate images.
                    try (Cursor cursor = resolver.query(collection,new String[]{MediaStore.Images.Media._ID,MediaStore.Images.Media.IS_PENDING},
                            MediaStore.Images.Media.DISPLAY_NAME+"=? AND "+MediaStore.Images.Media.RELATIVE_PATH+"=?",new String[]{filename,ALBUM},null)) {
                        if (cursor != null && cursor.moveToFirst()) {
                            Uri existing = Uri.withAppendedPath(collection,Long.toString(cursor.getLong(0)));
                            if (cursor.getInt(1) == 0) { result(id,true,"Saved to gallery · Save The Baby"); return; }
                            resolver.delete(existing,null,null);
                        }
                    }
                    ContentValues values = new ContentValues();
                    values.put(MediaStore.Images.Media.DISPLAY_NAME,filename);
                    values.put(MediaStore.Images.Media.MIME_TYPE,"image/png");
                    values.put(MediaStore.Images.Media.RELATIVE_PATH,ALBUM);
                    values.put(MediaStore.Images.Media.IS_PENDING,1);
                    inserted = resolver.insert(collection,values);
                    if (inserted == null) throw new java.io.IOException("No media entry");
                    try (OutputStream stream = resolver.openOutputStream(inserted)) {
                        if (stream == null) throw new java.io.IOException("No output stream");
                        stream.write(png);
                    }
                    values.clear(); values.put(MediaStore.Images.Media.IS_PENDING,0);
                    resolver.update(inserted,values,null,null);
                } else {
                    File folder = new File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES),"Save The Baby");
                    if (!folder.isDirectory() && !folder.mkdirs()) throw new java.io.IOException("Album unavailable");
                    File target = new File(folder,filename);
                    if (!target.exists() || target.length() == 0) {
                        File temporary = new File(folder,filename+".pending");
                        try (FileOutputStream stream = new FileOutputStream(temporary)) { stream.write(png); }
                        if (!temporary.renameTo(target)) throw new java.io.IOException("Cannot publish picture");
                    }
                    MediaScannerConnection.scanFile(activity,new String[]{target.getAbsolutePath()},new String[]{"image/png"},null);
                }
                result(id,true,"Saved to gallery · Save The Baby");
            } catch (Exception error) {
                if (inserted != null) { try { resolver.delete(inserted,null,null); } catch (Exception ignored) {} }
                result(id,false,"Could not save to gallery. Check available storage and try again.");
            }
        });
    }

    private void result(String id, boolean success, String message) {
        emitSignal("portrait_saved",id,success,message);
    }
}
