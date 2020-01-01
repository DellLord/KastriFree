unit DW.OSMetadata.Android;

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
  // Android
  Androidapi.JNI.Os;

type
  TPlatformOSMetadata = record
  private
    class var FMetadata: JBundle;
    class function GetMetadata: JBundle; static;
  public
    class function ContainsKey(const AKey: string): Boolean; static;
    class function GetValue(const AKey: string; var AValue: string): Boolean; static;
  end;

implementation

uses
  // Android
  Androidapi.JNI.GraphicsContentViewText, Androidapi.JNI.JavaTypes, Androidapi.Helpers;

{ TPlatformOSMetadata }

class function TPlatformOSMetadata.GetMetadata: JBundle;
var
  LFlags: Integer;
begin
  if FMetadata = nil then
  begin
    LFlags := TJPackageManager.JavaClass.GET_META_DATA;
    FMetadata := TAndroidHelper.Context.getPackageManager.getApplicationInfo(TAndroidHelper.Context.getPackageName, LFlags).metaData;
  end;
  Result := FMetadata;
end;

class function TPlatformOSMetadata.ContainsKey(const AKey: string): Boolean;
begin
  Result := GetMetadata.containsKey(StringToJString(AKey));
end;

class function TPlatformOSMetadata.GetValue(const AKey: string; var AValue: string): Boolean;
begin
  Result := ContainsKey(AKey);
  if Result then
    AValue := JStringToString(GetMetadata.getString(StringToJString(AKey)));
end;

end.