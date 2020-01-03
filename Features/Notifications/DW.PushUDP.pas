unit DW.PushUDP;

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
  System.SysUtils, System.Classes,
  // Indy
  IdBaseComponent, IdComponent, IdUDPBase, IdUDPClient,
  // FMX
  FMX.Types;

type
  TPushUDP = class(TDataModule)
    UDPClient: TIdUDPClient;
    UDPTimer: TTimer;
    procedure UDPTimerTimer(Sender: TObject);
  private
    FDeviceID: string;
    FToken: string;
    procedure SendDeviceInfo;
  public
    procedure UpdateDeviceInfo(const ADeviceID, AToken: string);
  end;

var
  PushUDP: TPushUDP;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

uses
  // RTL
  System.JSON,
  // DW
  DW.Consts.Android, DW.OSMetadata;

procedure TPushUDP.UDPTimerTimer(Sender: TObject);
begin
  if not FToken.IsEmpty and not FDeviceID.IsEmpty then
    SendDeviceInfo;
end;

procedure TPushUDP.SendDeviceInfo;
var
  LJSON: TJSONObject;
  LOS, LChannelId: string;
begin
  if TOSVersion.Platform = TOSVersion.TPlatform.pfiOS then
    LOS := 'IOS'
  else if TOSVersion.Platform = TOSVersion.TPlatform.pfAndroid then
    LOS := 'Android'
  else
    LOS := 'Unknown';
  TOSMetadata.GetValue(cMetadataFCMDefaultChannelId, LChannelId);
  LJSON := TJSONObject.Create;
  try
    LJSON.AddPair('deviceid', FDeviceID);
    LJSON.AddPair('token', FToken);
    LJSON.AddPair('channelid', LChannelId);
    LJSON.AddPair('os', LOS);
    UDPClient.Broadcast(LJSON.ToJSON, UDPClient.Port);
  finally
    LJSON.Free;
  end;
end;

procedure TPushUDP.UpdateDeviceInfo(const ADeviceID, AToken: string);
begin
  FDeviceID := ADeviceID;
  FToken := AToken;
end;

end.
