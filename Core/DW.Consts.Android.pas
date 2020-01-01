unit DW.Consts.Android;

interface

const
  cPermissionAccessBackgroundLocation = 'android.permission.ACCESS_BACKGROUND_LOCATION';
  cPermissionAccessCoarseLocation = 'android.permission.ACCESS_COARSE_LOCATION';
  cPermissionAccessFineLocation = 'android.permission.ACCESS_FINE_LOCATION';
  cPermissionCamera = 'android.permission.CAMERA';
  cPermissionReadContacts = 'android.permission.READ_CONTACTS';
  cPermissionReadExternalStorage = 'android.permission.READ_EXTERNAL_STORAGE';
  cPermissionReadPhoneState = 'android.permission.READ_PHONE_STATE';
  cPermissionReadSMS = 'android.permission.READ_SMS';
  cPermissionReceiveMMS = 'android.permission.RECEIVE_MMS';
  cPermissionReceiveSMS = 'android.permission.RECEIVE_SMS';
  cPermissionReceiveWAPPush = 'android.permission.RECEIVE_WAP_PUSH';
  cPermissionRecordAudio = 'android.permission.RECORD_AUDIO';
  cPermissionSendSMS = 'android.permission.SEND_SMS';
  cPermissionUseFingerprint = 'android.permission.USE_FINGERPRINT';
  cPermissionWriteExternalStorage = 'android.permission.WRITE_EXTERNAL_STORAGE';

  cLocationPriorityBalancedPowerAccuracy = 102;
  cLocationPriorityHighAccuracy = 100;
  cLocationPriorityLowPower = 104;
  cLocationPriorityNoPower = 105;

  cLocationBroadcastAction = 'com.delphiworlds.kastri.LOCATION_BROADCAST_ACTION';
  cLocationBroadcastExtraLatitude = 'Latitude';
  cLocationBroadcastExtraLongitude = 'Longitude';

  cDWBroadcastReceiverName = 'com.delphiworlds.kastri.DWMultiBroadcastReceiver';
  cDWBroadcastReceiverActionAlarmTimer = cDWBroadcastReceiverName + '.ACTION_ALARM_TIMER';
  cDWBroadcastReceiverActionServiceAlarm = cDWBroadcastReceiverName + '.ACTION_SERVICE_ALARM';
  cDWBroadcastReceiverActionServiceRestart = cDWBroadcastReceiverName + '.ACTION_SERVICE_RESTART';
  cDWBroadcastReceiverExtraServiceRestart = cDWBroadcastReceiverName + '.EXTRA_SERVICE_RESTART';

  cServiceCommandAction = 'com.delphiworlds.action.SERVICE_COMMAND';
  cServiceBroadcastParamCommand = 'COMMAND';
  cServiceCommandAppBecameActive = 1;
  cServiceCommandAppEnteredBackground = 2;
  cServiceCommandAppWillTerminate = 3;

  cEMBTJavaServicePrefix = 'com.embarcadero.services.';

implementation

end.
