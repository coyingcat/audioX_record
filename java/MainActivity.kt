package com.example.qqqqq

import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugins.AudioRecorderPlugin;
import android.os.Bundle





class MainActivity: FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        flutterEngine!!.plugins.add(AudioRecorderPlugin())
    }

}
