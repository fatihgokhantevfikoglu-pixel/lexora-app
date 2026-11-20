package com.lexora.lexora_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // EKLENTİLERİ ZORLA KAYDET (sqflite hatasını çözer)
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }
}
