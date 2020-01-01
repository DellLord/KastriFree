unit DW.WebChromeClient.Android;

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
  System.Classes, System.Messaging,
  // Android
  Androidapi.JNIBridge, Androidapi.JNI.WebKit, Androidapi.JNI.GraphicsContentViewText,
  // FMX
  FMX.WebBrowser,
  // DW
  DW.Androidapi.JNI.DWWebChromeClient;

type
  TWebChromeClientManager = class;

  TWebChromeClientDelegate = class(TJavaLocal, JDWWebChromeClientDelegate)
  private
    FManager: TWebChromeClientManager;
  public
    { JDWWebChromeClientDelegate }
    function onFileChooserIntent(intent: JIntent): Boolean; cdecl;
  public
    constructor Create(const AManager: TWebChromeClientManager);
  end;

  TWebChromeClientManager = class(TComponent)
  private
    FWebChromeClient: JDWWebChromeClient;
    FDelegate: JDWWebChromeClientDelegate;
    procedure MessageResultNotificationHandler(const Sender: TObject; const M: TMessage);
  protected
    function HandleFileChooserIntent(intent: JIntent): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation

uses
  // RTL
  System.SysUtils,
  // Android
  Androidapi.Helpers, Androidapi.JNI.App;

const
  cFileChooserRequestCode = 9999;

{ TWebChromeClientDelegate }

constructor TWebChromeClientDelegate.Create(const AManager: TWebChromeClientManager);
begin
  inherited Create;
  FManager := AManager;
end;

function TWebChromeClientDelegate.onFileChooserIntent(intent: JIntent): Boolean;
begin
  Result := FManager.HandleFileChooserIntent(intent);
end;

{ TWebChromeClientManager }

constructor TWebChromeClientManager.Create(AOwner: TComponent);
var
  LWebView: JWebView;
begin
  inherited;
  TMessageManager.DefaultManager.SubscribeToMessage(TMessageResultNotification, MessageResultNotificationHandler);
  if Supports(AOwner, JWebView, LWebView) then
  begin
    FDelegate := TWebChromeClientDelegate.Create(Self);
    FWebChromeClient := TJDWWebChromeClient.JavaClass.init(FDelegate);
    LWebView.setWebChromeClient(FWebChromeClient);
  end;
end;

destructor TWebChromeClientManager.Destroy;
begin
  TMessageManager.DefaultManager.Unsubscribe(TMessageResultNotification, MessageResultNotificationHandler);
  inherited;
end;

function TWebChromeClientManager.HandleFileChooserIntent(intent: JIntent): Boolean;
begin
  TAndroidHelper.Activity.startActivityForResult(intent, cFileChooserRequestCode);
  Result := True;
end;

procedure TWebChromeClientManager.MessageResultNotificationHandler(const Sender: TObject; const M: TMessage);
var
  LResult: TMessageResultNotification;
begin
  if M is TMessageResultNotification then
  begin
    LResult := TMessageResultNotification(M);
    if LResult.RequestCode = cFileChooserRequestCode then
      FWebChromeClient.handleFileChooserResult(LResult.Value, LResult.ResultCode);
  end;
end;

end.
