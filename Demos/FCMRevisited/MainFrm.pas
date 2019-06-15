unit MainFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.ScrollBox, FMX.Memo, FMX.Controls.Presentation,
  FMX.StdCtrls, FMX.Layouts, FMX.Objects,
  DW.Firebase.Messaging;

type
  TfrmMain = class(TForm)
    ContentLayout: TLayout;
    FirebaseCMLabel: TLabel;
    TokenLabel: TLabel;
    TokenMemo: TMemo;
    MessagesLabel: TLabel;
    MessagesMemo: TMemo;
    ClearMessagesButton: TButton;
    BackgroundRectangle: TRectangle;
    procedure ClearMessagesButtonClick(Sender: TObject);
  private
    FFCM: TFirebaseMessaging;
    procedure CreateFirebaseMessaging;
    procedure FCMAuthorizationResultHandler(Sender: TObject; const AGranted: Boolean);
    procedure FCMTokenReceivedHandler(Sender: TObject; const AToken: string);
    procedure FCMMessageReceivedHandler(Sender: TObject; const APayload: TStrings);
  protected
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

uses
  DW.OSLog, DW.UIHelper;

{ TfrmMain }

constructor TfrmMain.Create(AOwner: TComponent);
begin
  inherited;
  CreateFirebaseMessaging;
end;

procedure TfrmMain.CreateFirebaseMessaging;
begin
  FFCM := TFirebaseMessaging.Create;
  FFCM.OnAuthorizationResult := FCMAuthorizationResultHandler;
  FFCM.OnTokenReceived := FCMTokenReceivedHandler;
  FFCM.OnMessageReceived := FCMMessageReceivedHandler;
  FFCM.RequestAuthorization;
end;

destructor TfrmMain.Destroy;
begin
  FFCM.Free;
  inherited;
end;

procedure TfrmMain.ClearMessagesButtonClick(Sender: TObject);
begin
  MessagesMemo.Lines.Clear;
end;

procedure TfrmMain.Resize;
begin
  inherited;
  // Spacing for iPhoneX display
  ContentLayout.Margins.Rect := TUIHelper.GetOffsetRect;
end;

procedure TfrmMain.FCMAuthorizationResultHandler(Sender: TObject; const AGranted: Boolean);
begin
  if AGranted then
    FFCM.Connect;
end;

procedure TfrmMain.FCMTokenReceivedHandler(Sender: TObject; const AToken: string);
begin
  TokenMemo.Lines.Text := AToken;
  // TokenMemo.Lines.Text := FFCM.DeviceToken;
  TOSLog.d('Token in FCMTokenReceivedHandler: %s', [AToken]);
end;

procedure TfrmMain.FCMMessageReceivedHandler(Sender: TObject; const APayload: TStrings);
begin
  MessagesMemo.Lines.AddStrings(APayload);
end;

end.
