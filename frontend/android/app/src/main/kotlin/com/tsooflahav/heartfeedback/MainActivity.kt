package com.tsooflahav.heartfeedback

import android.media.AudioManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Side buttons adjust the same stream used by voices, beeps and SoundGuard,
        // including while the app is idle and the sound-readiness dialog is open.
        volumeControlStream = AudioManager.STREAM_MUSIC
    }
}
