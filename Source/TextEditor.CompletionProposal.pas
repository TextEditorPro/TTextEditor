unit TextEditor.CompletionProposal;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Graphics, TextEditor.CompletionProposal.Snippets,
  TextEditor.CompletionProposal.Trigger, TextEditor.Types;

const
  TEXTEDITOR_COMPLETION_PROPOSAL_DEFAULT_OPTIONS = [cpoAutoConstraints, cpoAddHighlighterKeywords, cpoFiltered,
    cpoParseItemsFromText];

type
  TTextEditorCompletionProposal = class(TPersistent)
  strict private
    FActive: Boolean;
    FCloseChars: string;
    FKeywordCase: TTextEditorCompletionProposalKeywordCase;
    FMinHeight: Integer;
    FMinWidth: Integer;
    FOptions: TTextEditorCompletionProposalOptions;
    FOwner: TComponent;
    FShortCut: TShortCut;
    FSnippets: TTextEditorCompletionProposalSnippets;
    FTrigger: TTextEditorCompletionProposalTrigger;
    FVisible: Boolean;
    FVisibleLines: Integer;
    FWidth: Integer;
    function IsCloseCharsStored: Boolean;
    procedure SetSnippets(const AValue: TTextEditorCompletionProposalSnippets);
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(AOwner: TComponent);
    destructor Destroy; override;
    procedure Assign(ASource: TPersistent); override;
    procedure ChangeScale(const AMultiplier, ADivider: Integer);
    procedure SetOption(const AOption: TTextEditorCompletionProposalOption; const AEnabled: Boolean);
    property Visible: Boolean read FVisible write FVisible;
  published
    property CloseChars: string read FCloseChars write FCloseChars stored IsCloseCharsStored;
    property Active: Boolean read FActive write FActive default True;
    property KeywordCase: TTextEditorCompletionProposalKeywordCase read FKeywordCase write FKeywordCase default kcLowerCase;
    property MinHeight: Integer read FMinHeight write FMinHeight default 0;
    property MinWidth: Integer read FMinWidth write FMinWidth default 0;
    property Options: TTextEditorCompletionProposalOptions read FOptions write FOptions default TEXTEDITOR_COMPLETION_PROPOSAL_DEFAULT_OPTIONS;
    property ShortCut: TShortCut read FShortCut write FShortCut default 16416; // Ctrl+Space
    property Snippets: TTextEditorCompletionProposalSnippets read FSnippets write SetSnippets;
    property Trigger: TTextEditorCompletionProposalTrigger read FTrigger write FTrigger;
    property VisibleLines: Integer read FVisibleLines write FVisibleLines default 8;
    property Width: Integer read FWidth write FWidth default 260;
  end;

implementation

uses
  Winapi.Windows, System.SysUtils, Vcl.Menus, TextEditor.Consts;

constructor TTextEditorCompletionProposal.Create(AOwner: TComponent);
begin
  inherited Create;

  FOwner := AOwner;
  FActive := True;
  FCloseChars := TCharacterSets.DefaultCompletionProposalCloseChars;
  FSnippets := TTextEditorCompletionProposalSnippets.Create(Self);
  FOptions := TEXTEDITOR_COMPLETION_PROPOSAL_DEFAULT_OPTIONS;
  FShortCut := Vcl.Menus.ShortCut(Ord(' '), [ssCtrl]);
  FTrigger := TTextEditorCompletionProposalTrigger.Create;
  FVisibleLines := 8;
  FMinHeight := 0;
  FMinWidth := 0;
  FWidth := 260;
  FKeywordCase := kcLowerCase;
end;

destructor TTextEditorCompletionProposal.Destroy;
begin
  FreeAndNil(FSnippets);
  FreeAndNil(FTrigger);

  inherited Destroy;
end;

procedure TTextEditorCompletionProposal.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorCompletionProposal) then
  with ASource as TTextEditorCompletionProposal do
  begin
    Self.FActive := FActive;
    Self.FCloseChars := FCloseChars;
    Self.FSnippets.Assign(FSnippets);
    Self.FOptions := FOptions;
    Self.FShortCut := FShortCut;
    Self.FTrigger.Assign(FTrigger);
    Self.FVisibleLines := FVisibleLines;
    Self.FWidth := FWidth;
  end
  else
    inherited Assign(ASource);
end;

function TTextEditorCompletionProposal.IsCloseCharsStored: Boolean;
begin
  Result := FCloseChars <> TCharacterSets.DefaultCompletionProposalCloseChars;
end;

procedure TTextEditorCompletionProposal.ChangeScale(const AMultiplier, ADivider: Integer);
begin
  FWidth := MulDiv(FWidth, AMultiplier, ADivider);
end;

procedure TTextEditorCompletionProposal.SetOption(const AOption: TTextEditorCompletionProposalOption; const AEnabled: Boolean);
begin
  if AEnabled then
    Include(FOptions, AOption)
  else
    Exclude(FOptions, AOption);
end;

function TTextEditorCompletionProposal.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

procedure TTextEditorCompletionProposal.SetSnippets(const AValue: TTextEditorCompletionProposalSnippets);
begin
  FSnippets.Assign(AValue);
end;

end.

