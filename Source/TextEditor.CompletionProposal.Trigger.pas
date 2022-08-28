unit TextEditor.CompletionProposal.Trigger;

interface

uses
  System.Classes;

const
  DEFAULT_INTERVAL = 300;

type
  TTextEditorCompletionProposalTrigger = class(TPersistent)
  strict private
    FActive: Boolean;
    FChars: string;
    FInterval: Integer;
    function IsCharsStored: Boolean;
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
  published
    property Active: Boolean read FActive write FActive default False;
    property Chars: string read FChars write FChars stored IsCharsStored;
    property Interval: Integer read FInterval write FInterval default DEFAULT_INTERVAL;
  end;

implementation

uses
  TextEditor.Consts;

constructor TTextEditorCompletionProposalTrigger.Create;
begin
  inherited;

  FActive := False;
  FChars := TCharacters.Dot;
  FInterval := DEFAULT_INTERVAL;
end;

procedure TTextEditorCompletionProposalTrigger.Assign(ASource: TPersistent);
begin
  if Assigned(ASource) and (ASource is TTextEditorCompletionProposalTrigger) then
  with ASource as TTextEditorCompletionProposalTrigger do
  begin
    Self.FActive := FActive;
    Self.FChars := FChars;
    Self.FInterval := FInterval;
  end
  else
    inherited Assign(ASource);
end;

function TTextEditorCompletionProposalTrigger.IsCharsStored: Boolean;
begin
  Result := FChars <> TCharacters.Dot;
end;

end.
