# JNI and GDScript reflection require stable Godot bridge names and members.
-keep class org.godotengine.** { *; }
-keep class com.godot.** { *; }
-keep class * extends org.godotengine.godot.plugin.GodotPlugin { *; }
-keepclassmembers class * {
    @org.godotengine.godot.plugin.UsedByGodot <methods>;
}
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}

# The installed AdMob AARs have empty consumer rules. Preserve their callbacks.
-keep class com.poingstudios.godot.admob.** { *; }
# Billing classes and callbacks are reached via the Godot bridge.
-keep class org.godotengine.plugin.googleplaybilling.** { *; }
-keep class com.savethebaby.** { *; }

-keepattributes Signature,InnerClasses,EnclosingMethod,*Annotation*,SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
