﻿unit TextEditor.CodeFolding.Regions;

interface

uses
  System.Classes, System.SysUtils, TextEditor.Consts, TextEditor.SkipRegions, TextEditor.Types;

type
  TTextEditorCodeFoldingRegion = class;

  TTextEditorCodeFoldingRegionItem = class(TCollectionItem)
  strict private
    FBeginWithBreakChar: Boolean;
    FBreakCharFollows: Boolean;
    FBreakIfNotFoundBeforeNextRegion: string;
    FCheckIfThenOneLiner: Boolean;
    FCloseAtNextToken: Boolean;
    FCloseToken: string;
    FCloseTokenBeginningOfLine: Boolean;
    FCloseTokenLength: Integer;
    FNoDuplicateClose: Boolean;
    FNoSubs: Boolean;
    FOpenIsClose: Boolean;
    FOpenToken: string;
    FOpenTokenBeginningOfLine: Boolean;
    FOpenTokenBreaksLine: Boolean;
    FOpenTokenCanBeFollowedBy: string;
    FOpenTokenEnd: string;
    FOpenTokenLength: Integer;
    FParentRegionItem: TTextEditorCodeFoldingRegionItem;
    FRemoveRange: Boolean;
    FSharedClose: Boolean;
    FShowGuideLine: Boolean;
    FSkipIfFoundAfterOpenTokenArray: TTextEditorArrayOfString;
    FSkipIfFoundAfterOpenTokenArrayCount: Integer;
    FTokenEndIsPreviousLine: Boolean;
    procedure SetSkipIfFoundAfterOpenTokenArrayCount(const AValue: Integer);
  public
    constructor Create(ACollection: TCollection); override;
    property BeginWithBreakChar: Boolean read FBeginWithBreakChar write FBeginWithBreakChar;
    property BreakCharFollows: Boolean read FBreakCharFollows write FBreakCharFollows default True;
    property BreakIfNotFoundBeforeNextRegion: string read FBreakIfNotFoundBeforeNextRegion write FBreakIfNotFoundBeforeNextRegion;
    property CheckIfThenOneLiner: Boolean read FCheckIfThenOneLiner write FCheckIfThenOneLiner;
    property CloseAtNextToken: Boolean read FCloseAtNextToken write FCloseAtNextToken;
    property CloseToken: string read FCloseToken write FCloseToken;
    property CloseTokenBeginningOfLine: Boolean read FCloseTokenBeginningOfLine write FCloseTokenBeginningOfLine default False;
    property CloseTokenLength: Integer read FCloseTokenLength write FCloseTokenLength;
    property NoDuplicateClose: Boolean read FNoDuplicateClose write FNoDuplicateClose default False;
    property NoSubs: Boolean read FNoSubs write FNoSubs default False;
    property OpenIsClose: Boolean read FOpenIsClose write FOpenIsClose default False;
    property OpenToken: string read FOpenToken write FOpenToken;
    property OpenTokenBeginningOfLine: Boolean read FOpenTokenBeginningOfLine write FOpenTokenBeginningOfLine default False;
    property OpenTokenBreaksLine: Boolean read FOpenTokenBreaksLine write FOpenTokenBreaksLine default False;
    property OpenTokenCanBeFollowedBy: string read FOpenTokenCanBeFollowedBy write FOpenTokenCanBeFollowedBy;
    property OpenTokenEnd: string read FOpenTokenEnd write FOpenTokenEnd;
    property OpenTokenLength: Integer read FOpenTokenLength write FOpenTokenLength;
    property ParentRegionItem: TTextEditorCodeFoldingRegionItem read FParentRegionItem write FParentRegionItem;
    property RemoveRange: Boolean read FRemoveRange write FRemoveRange;
    property SharedClose: Boolean read FSharedClose write FSharedClose default False;
    property ShowGuideLine: Boolean read FShowGuideLine write FShowGuideLine default True;
    property SkipIfFoundAfterOpenTokenArray: TTextEditorArrayOfString read FSkipIfFoundAfterOpenTokenArray write FSkipIfFoundAfterOpenTokenArray;
    property SkipIfFoundAfterOpenTokenArrayCount: Integer read FSkipIfFoundAfterOpenTokenArrayCount write SetSkipIfFoundAfterOpenTokenArrayCount;
    property TokenEndIsPreviousLine: Boolean read FTokenEndIsPreviousLine write FTokenEndIsPreviousLine default False;
  end;

  TTextEditorCodeFoldingRegion = class(TCollection)
  strict private
    FCloseToken: string;
    FEscapeChar: Char;
    FOpenToken: string;
    FSkipRegions: TTextEditorSkipRegions;
    FStringEscapeChar: Char;
    function FindItem(const AOpenToken: string): TTextEditorCodeFoldingRegionItem;
    function GetItem(const AIndex: Integer): TTextEditorCodeFoldingRegionItem;
  public
    constructor Create(AItemClass: TCollectionItemClass);
    destructor Destroy; override;
    function Add(const AOpenToken: string; const ACloseToken: string): TTextEditorCodeFoldingRegionItem;
    function Contains(const AOpenToken: string): Boolean;
    property CloseToken: string read FCloseToken write FCloseToken;
    property EscapeChar: Char read FEscapeChar write FEscapeChar default TControlCharacters.Null;
    property Items[const AIndex: Integer]: TTextEditorCodeFoldingRegionItem read GetItem; default;
    property OpenToken: string read FOpenToken write FOpenToken;
    property SkipRegions: TTextEditorSkipRegions read FSkipRegions;
    property StringEscapeChar: Char read FStringEscapeChar write FStringEscapeChar default TControlCharacters.Null;
  end;

  TTextEditorCodeFoldingRegions = array of TTextEditorCodeFoldingRegion;

implementation

{ TTextEditorCodeFoldingRegionItem }

constructor TTextEditorCodeFoldingRegionItem.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);

  FSkipIfFoundAfterOpenTokenArrayCount := 0;
  FBreakIfNotFoundBeforeNextRegion := '';
  FCloseTokenBeginningOfLine := False;
  FNoDuplicateClose := False;
  FNoSubs := False;
  FOpenIsClose := False;
  FOpenTokenBeginningOfLine := False;
  FOpenTokenBreaksLine := False;
  FSharedClose := False;
  FBreakCharFollows := True;
  FCheckIfThenOneLiner := False;
  FRemoveRange := False;
end;

procedure TTextEditorCodeFoldingRegionItem.SetSkipIfFoundAfterOpenTokenArrayCount(const AValue: Integer);
begin
  FSkipIfFoundAfterOpenTokenArrayCount := AValue;
  SetLength(FSkipIfFoundAfterOpenTokenArray, AValue);
end;

{ TTextEditorCodeFoldingRegions }

function TTextEditorCodeFoldingRegion.Add(const AOpenToken: string; const ACloseToken: string): TTextEditorCodeFoldingRegionItem;
var
  LLow, LHigh, LMiddle, LCompare: Integer;
begin
  LLow := 0;
  LHigh := Count - 1;

  while LLow <= LHigh do
  begin
    LMiddle := (LLow + LHigh) div 2;

    LCompare := CompareText(AOpenToken, Items[LMiddle].OpenToken);

    if LCompare < 0 then
      LHigh := LMiddle - 1
    else
      LLow := LMiddle + 1;
  end;

  Result := TTextEditorCodeFoldingRegionItem(inherited Insert(LLow));

  with Result do
  begin
    OpenToken := AOpenToken;
    OpenTokenLength := AOpenToken.Length;
    CloseToken := ACloseToken;
    CloseTokenLength := ACloseToken.Length;
  end;
end;

constructor TTextEditorCodeFoldingRegion.Create(AItemClass: TCollectionItemClass);
begin
  inherited Create(AItemClass);

  FSkipRegions := TTextEditorSkipRegions.Create(TTextEditorSkipRegionItem);
  FEscapeChar := TControlCharacters.Null;
  FStringEscapeChar := TControlCharacters.Null;
end;

destructor TTextEditorCodeFoldingRegion.Destroy;
begin
  FSkipRegions.Free;

  inherited;
end;

function TTextEditorCodeFoldingRegion.FindItem(const AOpenToken: string): TTextEditorCodeFoldingRegionItem;
var
  LLow, LHigh, LMiddle, LCompare: Integer;
begin
  Result := nil;

  LLow := 0;
  LHigh := Count - 1;

  while LLow <= LHigh do
  begin
    LMiddle := (LLow + LHigh) div 2;

    LCompare := CompareText(AOpenToken, Items[LMiddle].OpenToken);

    if LCompare = 0 then
      Exit(Items[LMiddle])
    else
    if LCompare < 0 then
      LHigh := LMiddle - 1
    else
      LLow := LMiddle + 1;
  end;
end;

function TTextEditorCodeFoldingRegion.Contains(const AOpenToken: string): Boolean;
begin
  Result := Assigned(FindItem(AOpenToken));
end;

function TTextEditorCodeFoldingRegion.GetItem(const AIndex: Integer): TTextEditorCodeFoldingRegionItem;
begin
  Result := TTextEditorCodeFoldingRegionItem(inherited Items[AIndex]);
end;

end.
