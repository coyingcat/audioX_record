package io.flutter.plugins;

import android.Manifest;
import android.app.Activity;
import android.app.ActivityManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.pm.PackageManager;
import android.media.MediaRecorder;
import android.os.Environment;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;

import java.io.IOException;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.MethodCall;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.plugins.FlutterPlugin;

import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugins.WavRecorder;

/**
 * AudioRecorderPlugin
 */
public class AudioRecorderPlugin implements FlutterPlugin, MethodCallHandler {

  private final int MY_PERMISSIONS_RECORD_AUDIO = 1;

  private boolean isRecording = false;

  private static final String LOG_TAG = "AudioRecorder";
  private MediaRecorder mRecorder = null;
  private static String mFilePath = null;
  private Date startTime = null;
  private String mExtension = "";
  private WavRecorder wavRecorder;

  private FlutterPluginBinding _flutterBinding;

  private MethodChannel channel;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    _flutterBinding = flutterPluginBinding;
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "audio_recorder");
    channel.setMethodCallHandler(this);
  }



  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {
      case "start":
        Log.d(LOG_TAG, "Start");
        Log.d(LOG_TAG, "11111____");
        String path = call.argument("path");
        mExtension = call.argument("extension");
        startTime = Calendar.getInstance().getTime();
        if (path != null) {

          mFilePath = Environment.getExternalStorageDirectory().getAbsolutePath() + "/" + path;
        } else {
          Log.d(LOG_TAG, "11111____222");
          String fileName = String.valueOf(startTime.getTime());
          mFilePath = Environment.getExternalStorageDirectory().getAbsolutePath() + "/" + fileName + mExtension;
        }

        Log.d(LOG_TAG, mFilePath);
        startRecording();
        isRecording = true;
        result.success(null);
        break;
      case "stop":
        Log.d(LOG_TAG, "Stop");
        stopRecording();
        long duration = Calendar.getInstance().getTime().getTime() - startTime.getTime();
        Log.d(LOG_TAG, "Duration : " + String.valueOf(duration));
        isRecording = false;
        HashMap<String, Object> recordingResult = new HashMap<>();
        recordingResult.put("duration", duration);
        recordingResult.put("path", mFilePath);
        recordingResult.put("audioOutputFormat", mExtension);
        result.success(recordingResult);
        break;
      case "isRecording":
        Log.d(LOG_TAG, "Get isRecording");
        result.success(isRecording);
        break;
      case "hasPermissions":
        Log.d(LOG_TAG, "Get hasPermissions");
        Context context = _flutterBinding.getApplicationContext();
        PackageManager pm = context.getPackageManager();
        int hasStoragePerm = pm.checkPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE, context.getPackageName());
        int hasRecordPerm = pm.checkPermission(Manifest.permission.RECORD_AUDIO, context.getPackageName());
        boolean hasPermissions = hasStoragePerm == PackageManager.PERMISSION_GRANTED && hasRecordPerm == PackageManager.PERMISSION_GRANTED;
        result.success(hasPermissions);
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  private void startRecording() {
    if (isOutputFormatWav()) {
      startWavRecording();
    } else {
      startNormalRecording();
    }
  }

  private void startNormalRecording() {
    mRecorder = new MediaRecorder();
    mRecorder.setAudioSource(MediaRecorder.AudioSource.MIC);
    mRecorder.setOutputFormat(getOutputFormatFromString(mExtension));
    mRecorder.setOutputFile(mFilePath);
    mRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC);

    try {
      mRecorder.prepare();
    } catch (IOException e) {
      Log.e(LOG_TAG, "prepare() failed");
    }

    mRecorder.start();
  }

  private void startWavRecording() {
    wavRecorder = new WavRecorder(_flutterBinding.getApplicationContext(), mFilePath);
    wavRecorder.startRecording();
  }

  private void stopRecording() {
    if (isOutputFormatWav()) {
      stopWavRecording();
    } else {
      stopNormalRecording();
    }
  }

  private void stopNormalRecording() {
    if (mRecorder != null){
      mRecorder.stop();
      mRecorder.reset();
      mRecorder.release();
      mRecorder = null;
    }
  }

  private void stopWavRecording() {
    wavRecorder.stopRecording();
  }

  private int getOutputFormatFromString(String outputFormat) {
    switch (outputFormat) {
      case ".mp4":
      case ".aac":
      case ".m4a":
        return MediaRecorder.OutputFormat.MPEG_4;
      default:
        return MediaRecorder.OutputFormat.MPEG_4;
    }
  }

  private boolean isOutputFormatWav() {
    return mExtension.equals(".wav");
  }


  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    _flutterBinding = null;
  }
}