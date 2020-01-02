unit DW.Location.Android;

{*******************************************************}
{                                                       }
{                    Kastri Free                        }
{                                                       }
{          DelphiWorlds Cross-Platform Library          }
{                                                       }
{*******************************************************}

{$I DW.GlobalDefines.inc}

interface

uses
  // RTL
  System.Sensors,
  // Android
  Androidapi.JNI.App, AndroidApi.JNI.GraphicsContentViewText, Androidapi.JNI.Os, Androidapi.JNIBridge, Androidapi.JNI.Location,
  AndroidApi.JNI.JavaTypes,
  // DW
  DW.TimerTask.Android;

type
  TLocation = class;

  TLocationListener = class(TJavaLocal, JLocationListener)
  private
    FLocation: TLocation;
  public
    constructor Create(const ALocation: TLocation);
    procedure onLocationChanged(location: JLocation); cdecl;
    procedure onProviderDisabled(provider: JString); cdecl;
    procedure onProviderEnabled(provider: JString); cdecl;
    procedure onStatusChanged(provider: JString; status: Integer; extras: JBundle); cdecl;
  end;

  TLocationSource = (Listeners, Timer, Requested);

  TLocationChangeEvent = procedure(Sender: TObject; const Location: TLocationCoord2D; const ASource: TLocationSource) of object;

  TLocation = class(TObject)
  private
    FGPSLocationListener: JLocationListener;
    FIsPaused: Boolean;
    FLastChange: TDateTime;
    FLocationManager: JLocationManager;
    FMinimumChangeInterval: Integer;
    FMonitoringDistance: Integer;
    FMonitoringInterval: Integer;
    FNeedsBackground: Boolean;
    FNetworkLocationListener: JLocationListener;
    FTimerTask: TTimerTask;
    FOnLocationChange: TLocationChangeEvent;
    function AreListenersInstalled: Boolean;
    procedure BroadcastLocation(const ALocation: TLocationCoord2D);
    procedure CreateListeners;
    function GetLastKnownLocation: TLocationCoord2D;
    function GetLocationMode: Integer;
    function HasPermissions: Boolean;
    procedure RemoveListeners;
    procedure InternalRequestLastKnownLocation(const ASource: TLocationSource);
    procedure SetIsPaused(const AValue: Boolean);
    procedure SetMonitoringDistance(const Value: Integer);
    procedure SetMonitoringInterval(const Value: Integer);
    procedure TimerRunHandler(Sender: TObject);
  protected
    procedure LocationChange(const ALocation: TLocationCoord2D; const ASource: TLocationSource);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Pause;
    procedure Resume;
    procedure RequestLastKnownLocation;
    property IsPaused: Boolean read FIsPaused;
    property MinimumChangeInterval: Integer read FMinimumChangeInterval write FMinimumChangeInterval;
    property MonitoringDistance: Integer read FMonitoringDistance write SetMonitoringDistance;
    property MonitoringInterval: Integer read FMonitoringInterval write SetMonitoringInterval;
    property NeedsBackground: Boolean read FNeedsBackground write FNeedsBackground;
    property TimerTask: TTimerTask read FTimerTask;
    property OnLocationChange: TLocationChangeEvent read FOnLocationChange write FOnLocationChange;
  end;

implementation

uses
  // RTL
  System.Permissions, System.SysUtils, System.DateUtils,
  // Android
  Androidapi.Helpers, Androidapi.JNI.Provider,
  // DW
  DW.OSLog, DW.Androidapi.JNI.Timer,  DW.Androidapi.JNI.LocalBroadcastManager, DW.Consts.Android, DW.OSDevice;

const
  cDefaultLocationMonitoringInterval = 15000;
  cDefaultLocationMonitoringDistance = 10;

  cInvalidLatitude = 91;
  cInvalidLongitude = 181;

{ TLocationListener }

constructor TLocationListener.Create(const ALocation: TLocation);
begin
  inherited Create;
  FLocation := ALocation;
end;

procedure TLocationListener.onLocationChanged(location: JLocation);
begin
  FLocation.LocationChange(TLocationCoord2D.Create(location.getLatitude, location.getLongitude), TLocationSource.Listeners);
end;

procedure TLocationListener.onProviderDisabled(provider: JString);
begin
  //
end;

procedure TLocationListener.onProviderEnabled(provider: JString);
begin
  //
end;

procedure TLocationListener.onStatusChanged(provider: JString; status: Integer; extras: JBundle);
begin
  //
end;

{ TLocation }

constructor TLocation.Create;
begin
  inherited;
  FIsPaused := True;
  FTimerTask := TTimerTask.Create;
  FTimerTask.OnRun := TimerRunHandler;
  FMonitoringDistance := cDefaultLocationMonitoringDistance;
  FMonitoringInterval := cDefaultLocationMonitoringInterval;
end;

destructor TLocation.Destroy;
begin
  FTimerTask.DisposeOf;
  FTimerTask := nil;
  inherited;
end;

function TLocation.GetLastKnownLocation: TLocationCoord2D;
var
  LLocation: JLocation;
  LProviders: JList;
  I: Integer;
begin
  Result := TLocationCoord2D.Create(cInvalidLatitude, cInvalidLongitude);
  if FLocationManager <> nil then
  begin
    LProviders := FLocationManager.getProviders(True);
    for I := 0 to LProviders.size - 1 do
    begin
      LLocation := FLocationManager.getLastKnownLocation(TJString.Wrap(TAndroidHelper.JObjectToID(LProviders.get(I))));
      if LLocation <> nil then
        Exit(TLocationCoord2D.Create(LLocation.getLatitude, LLocation.getLongitude));  // <======
    end;
    TOSLog.w('Unable to get last known location from enabled providers');
  end
  else
    TOSLog.e('TLocation.GetLastKnownLocation - FLocationManager is NIL');
end;

function TLocation.GetLocationMode: Integer;
begin
  Result := TJSettings_Secure.JavaClass.getInt(TAndroidHelper.ContentResolver, TJSettings_Secure.JavaClass.LOCATION_MODE);
end;

procedure TLocation.CreateListeners;
var
  LObject: JObject;
begin
  try
    if not HasPermissions then
      TOSLog.w('Insufficient permissions to use location services', True);
    if HasPermissions and not AreListenersInstalled then
    begin
      LObject := TAndroidHelper.Context.getSystemService(TJContext.JavaClass.LOCATION_SERVICE);
      if LObject <> nil then
      begin
        FLocationManager := TJLocationManager.Wrap((LObject as ILocalObject).GetObjectID);
        if FLocationManager.isProviderEnabled(TJLocationManager.JavaClass.GPS_PROVIDER) then
        begin
          FGPSLocationListener := TLocationListener.Create(Self);
          FLocationManager.requestLocationUpdates(TJLocationManager.JavaClass.GPS_PROVIDER, FMonitoringInterval, FMonitoringDistance,
            FGPSLocationListener, TJLooper.JavaClass.getMainLooper);
          TOSLog.d('GPS location listener installed');
        end
        else
          TOSLog.d('GPS provider not enabled');
        if FLocationManager.isProviderEnabled(TJLocationManager.JavaClass.NETWORK_PROVIDER) then
        begin
          FNetworkLocationListener := TLocationListener.Create(Self);
          FLocationManager.requestLocationUpdates(TJLocationManager.JavaClass.NETWORK_PROVIDER, FMonitoringInterval, FMonitoringDistance,
            FNetworkLocationListener, TJLooper.JavaClass.getMainLooper);
          TOSLog.d('Network location listener installed');
        end
        else
          TOSLog.d('Network provider not enabled');
      end
      else
        TOSLog.w('Unable to obtain location service');
    end
    else if not HasPermissions and AreListenersInstalled then
      RemoveListeners;
    if AreListenersInstalled then
      TOSLog.d('Location services started');
  finally
    SetIsPaused(not AreListenersInstalled);
  end;
end;

procedure TLocation.RemoveListeners;
begin
  try
    if FLocationManager <> nil then
    begin
      FLocationManager.removeUpdates(FGPSLocationListener);
      FLocationManager.removeUpdates(FNetworkLocationListener);
    end;
    FGPSLocationListener := nil;
    FNetworkLocationListener := nil;
    FLocationManager := nil;
  finally
    SetIsPaused(not AreListenersInstalled);
  end;
end;

procedure TLocation.InternalRequestLastKnownLocation(const ASource: TLocationSource);
var
  LLocation: TLocationCoord2D;
begin
  if not FIsPaused then
  begin
    LLocation := GetLastKnownLocation;
    if LLocation.Latitude <> cInvalidLatitude then
      LocationChange(LLocation, ASource)
    else
      TOSLog.w('TLocation.InternalRequestLastKnownLocation - returned location is INVALID');
  end;
end;

procedure TLocation.RequestLastKnownLocation;
begin
  InternalRequestLastKnownLocation(TLocationSource.Requested);
end;

procedure TLocation.SetIsPaused(const AValue: Boolean);
begin
  FIsPaused := AValue;
end;

procedure TLocation.SetMonitoringDistance(const Value: Integer);
var
  LWasListening: Boolean;
begin
  if Value <> FMonitoringDistance then
  begin
    LWasListening := AreListenersInstalled;
    RemoveListeners;
    FMonitoringDistance := Value;
    if LWasListening then
      CreateListeners;
  end;
end;

procedure TLocation.SetMonitoringInterval(const Value: Integer);
var
  LWasListening: Boolean;
begin
  if Value <> FMonitoringInterval then
  begin
    LWasListening := AreListenersInstalled;
    RemoveListeners;
    FMonitoringInterval := Value;
    if LWasListening then
      CreateListeners;
  end;
end;

procedure TLocation.TimerRunHandler(Sender: TObject);
begin
  InternalRequestLastKnownLocation(TLocationSource.Timer);
end;

function TLocation.HasPermissions: Boolean;
var
  LPermissions: TArray<string>;
begin
  LPermissions := [cPermissionAccessCoarseLocation, cPermissionAccessFineLocation];
  if FNeedsBackground and TOSVersion.Check(10) then
    LPermissions := LPermissions + [cPermissionAccessBackgroundLocation];
  Result := PermissionsService.IsEveryPermissionGranted(LPermissions);
end;

function TLocation.AreListenersInstalled: Boolean;
begin
  Result := (FGPSLocationListener <> nil) or (FNetworkLocationListener <> nil);
end;

procedure TLocation.BroadcastLocation(const ALocation: TLocationCoord2D);
var
  LIntent: JIntent;
begin
  LIntent := TJIntent.JavaClass.init(StringToJString(cLocationBroadcastAction));
  LIntent.putExtra(StringToJString(cLocationBroadcastExtraLatitude), ALocation.Latitude);
  LIntent.putExtra(StringToJString(cLocationBroadcastExtraLongitude), ALocation.Longitude);
  TJLocalBroadcastManager.JavaClass.getInstance(TAndroidHelper.Context).sendBroadcast(LIntent);
end;

procedure TLocation.LocationChange(const ALocation: TLocationCoord2D; const ASource: TLocationSource);
const
  cLocationSourceCaptions: array[TLocationSource] of string = ('Listeners', 'Timer', 'Requested');
begin
  if (FMinimumChangeInterval > 0) and (FLastChange > 0) and (SecondsBetween(Now, FLastChange) < FMinimumChangeInterval) then
    Exit; // <======
  TOSLog.d('Location change from %s: %2.6f, %2.6f', [cLocationSourceCaptions[ASource], ALocation.Latitude, ALocation.Longitude], True);
  FLastChange := Now;
  BroadcastLocation(ALocation);
  if Assigned(FOnLocationChange) then
    FOnLocationChange(Self, ALocation, ASource);
end;

procedure TLocation.Pause;
begin
  RemoveListeners;
end;

procedure TLocation.Resume;
begin
  CreateListeners;
end;

end.
