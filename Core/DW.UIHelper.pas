unit DW.UIHelper;

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
  System.Types, System.UITypes,
  // FMX
  FMX.Types, FMX.Forms;

type
  /// <summary>
  ///   Helper functions specific to UI
  /// </summary>
  TUIHelper = record
  public
    /// <summary>
    ///   Special function for handling of "notch" based devices
    /// </summary>
    class function GetOffsetRect: TRectF; overload; static;
    class function GetOffsetRect(const AHandle: TWindowHandle): TRectF; overload; static;
    /// <summary>
    ///   Returns Black or White, depending on the background color supplied
    /// </summary>
    class function GetTextColor(const ABackgroundColor: TAlphaColor): TAlphaColor; static;
    /// <summary>
    ///   Force a repaint of the form
    /// </summary>
    class procedure Render(const AForm: TForm); static;
  end;

implementation

{$IF Defined(ANDROID)}
uses
  DW.UIHelper.Android;
{$ELSEIF Defined(IOS)}
uses
  DW.UIHelper.iOS;
{$ENDIF}

{ TUIHelper }

class function TUIHelper.GetOffsetRect: TRectF;
begin
  {$IF Defined(IOS) or Defined(Android)}
  Result := TPlatformUIHelper.GetOffsetRect;
  {$ELSE}
  Result := RectF(0, 0, 0, 0);
  {$ENDIF}
end;

class function TUIHelper.GetOffsetRect(const AHandle: TWindowHandle): TRectF;
begin
  {$IF Defined(IOS) or Defined(Android)}
  Result := TPlatformUIHelper.GetOffsetRect(AHandle);
  {$ELSE}
  Result := RectF(0, 0, 0, 0);
  {$ENDIF}
end;

class procedure TUIHelper.Render(const AForm: TForm);
begin
  // Should not be required in other OS's
  {$IF Defined(Android)}
  TPlatformUIHelper.Render(AForm);
  {$ENDIF}
end;

class function TUIHelper.GetTextColor(const ABackgroundColor: TAlphaColor): TAlphaColor;
var
  LRec: TAlphaColorRec;
begin
  LRec := TAlphaColorRec(ABackgroundColor);
  if ((LRec.R * 0.299) + (LRec.G * 0.587) + (LRec.B * 0.114)) > 127 then
    Result := TAlphaColorRec.Black
  else
    Result := TAlphaColorRec.White;
end;

end.
