package com.delphiworlds.kastri;

/*******************************************************
 *                                                     *
 *                  Kastri Free                        *
 *                                                     *
 *         DelphiWorlds Cross-Platform Library         *
 *                                                     *
 *******************************************************/

// Example metadata: <meta-data android:name="DWNotificationPublisher.WAKE_ON_NOTIFICATION" android:value="true" />

import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.os.PowerManager;
import android.util.Log;

public class DWWakeUp {

  private static final String TAG = "DWWakeUp";

  public static void checkWakeUp(Context context, String metaDataKey) {
    Bundle metaData = null;
    try {
      metaData = context.getPackageManager().getApplicationInfo(context.getPackageName(), PackageManager.GET_META_DATA).metaData;
    } catch (PackageManager.NameNotFoundException exception) {
      Log.w(TAG, "Unable to load metadata");
    }
    Log.d(TAG, "Checking metadata for " + metaDataKey);
    if ((metaData == null) || (!metaData.containsKey(metaDataKey) || !metaData.getBoolean(metaDataKey)))
      return;
    PowerManager powerManager = (PowerManager) context.getSystemService(Context.POWER_SERVICE);
    boolean isScreenOn = Build.VERSION.SDK_INT >= 20 ? powerManager.isInteractive() : powerManager.isScreenOn();
    if (!isScreenOn) {
      String wakeLockTag = context.getPackageName() + "." + TAG + "WakeLock";
      PowerManager.WakeLock wakeLock = powerManager.newWakeLock(PowerManager.SCREEN_DIM_WAKE_LOCK | PowerManager.ACQUIRE_CAUSES_WAKEUP, wakeLockTag);
      if (!wakeLock.isHeld())
        wakeLock.acquire();
    }  
  }
}