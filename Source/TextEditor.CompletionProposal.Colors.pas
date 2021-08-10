unit TextEditor.CompletionProposal.Colors;

interface

uses
  System.Classes, System.UITypes;

type
  TTextEditorCompletionProposalColors = class(TPersistent)
  strict private
    FBackground: TColor;
    FForeground: TColor;
    FSelectedBackground: TColor;
    FSelectedText: TColor;
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
  published
    property Background: TColor read FBackground write FBackground default TColors.SysWindow;
    property Foreground: TColor read FForeground write FForeground default TColors.SysWindowText;
    property SelectedBackground: TColor read FSelectedBackground write FSelectedBackground default TColors.SysHighlight;
    property SelectedText: TColor read FSelectedText write FSelectedText default TColors.SysHighlightText;
  end;

implementation

constructor TTextEditorCompletionProposalColors.Create;
begin
  inherited;

  FBackground := TColors.SysWindow;
  FForeground := TColors.SysWindowText;
  FSelectedBackground := TColors.SysHighlight;
  FSelectedText := TColors.SysHighlightText;
end;

procedure TTextEditorCompletionProposalColors.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorCompletionProposalColors) then
  with ASource as TTextEditorCompletionProposalColors do
  begin
    Self.FBackground := FBackground;
    Self.FForeground := FForeground;
    Self.FSelectedBackground := FSelectedBackground;
    Self.FSelectedText := FSelectedText;
  end
  else
    inherited Assign(ASource);
end;

end.
