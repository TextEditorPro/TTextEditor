unit TTextEditorDemo.Frame.PrintPreview;

interface

uses
  System.Classes, System.SysUtils, Vcl.Controls, Vcl.ExtCtrls, Vcl.Forms, Vcl.StdCtrls, TextEditor.Print.Preview;

type
  TFramePrintPreview = class(TFrame)
    ButtonPageFirst: TButton;
    ButtonPageLast: TButton;
    ButtonPageNext: TButton;
    ButtonPagePrevious: TButton;
    CheckBoxColors: TCheckBox;
    CheckBoxHighlight: TCheckBox;
    CheckBoxLineNumbers: TCheckBox;
    CheckBoxWordWrap: TCheckBox;
    ComboBoxPreviewScale: TComboBox;
    LabelPage: TLabel;
    LabelPreviewScale: TLabel;
    PanelPreviewBar: TPanel;
    PrintPreview: TTextEditorPrintPreview;
    procedure ButtonPageFirstClick(Sender: TObject);
    procedure ButtonPageLastClick(Sender: TObject);
    procedure ButtonPageNextClick(Sender: TObject);
    procedure ButtonPagePreviousClick(Sender: TObject);
    procedure CheckBoxPreviewOptionClick(Sender: TObject);
    procedure ComboBoxPreviewScaleChange(Sender: TObject);
    procedure PrintPreviewPreviewPage(ASender: TObject; APageNumber: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    procedure UpdatePageLabel;
    procedure UpdatePrintPreview(const AFileName: string);
  end;

implementation

{$R *.dfm}

constructor TFramePrintPreview.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  PrintPreview.EditorPrint.Header.Add('$TITLE$', nil, taCenter, 1);
  PrintPreview.EditorPrint.Footer.Add('Page $PAGENUM$ of $PAGECOUNT$', nil, taCenter, 1);
  PrintPreview.ScaleMode := pscPageWidth;
end;

procedure TFramePrintPreview.UpdatePrintPreview(const AFileName: string);
begin
  PrintPreview.EditorPrint.Title := if AFileName.IsEmpty then 'TTextEditor' else ExtractFileName(AFileName);
  PrintPreview.UpdatePreview;

  UpdatePageLabel;
end;

procedure TFramePrintPreview.UpdatePageLabel;
begin
  LabelPage.Caption := Format('Page %d / %d', [PrintPreview.PageNumber, PrintPreview.PageCount]);
end;

procedure TFramePrintPreview.ButtonPageFirstClick(Sender: TObject);
begin
  PrintPreview.FirstPage;
end;

procedure TFramePrintPreview.ButtonPageLastClick(Sender: TObject);
begin
  PrintPreview.LastPage;
end;

procedure TFramePrintPreview.ButtonPageNextClick(Sender: TObject);
begin
  PrintPreview.NextPage;
end;

procedure TFramePrintPreview.ButtonPagePreviousClick(Sender: TObject);
begin
  PrintPreview.PreviousPage;
end;

procedure TFramePrintPreview.ComboBoxPreviewScaleChange(Sender: TObject);
begin
   case ComboBoxPreviewScale.ItemIndex of
    0:
      PrintPreview.ScaleMode := pscWholePage;
    1:
      PrintPreview.ScaleMode := pscPageWidth;
  else
    PrintPreview.ScalePercent := ComboBoxPreviewScale.Items[ComboBoxPreviewScale.ItemIndex].Replace(' %', '').ToInteger;
  end;
end;

procedure TFramePrintPreview.PrintPreviewPreviewPage(ASender: TObject; APageNumber: Integer);
begin
  UpdatePageLabel;
end;

procedure TFramePrintPreview.CheckBoxPreviewOptionClick(Sender: TObject);
begin
  PrintPreview.EditorPrint.Colors := CheckBoxColors.Checked;
  PrintPreview.EditorPrint.LineNumbers := CheckBoxLineNumbers.Checked;
  PrintPreview.EditorPrint.Wrap := CheckBoxWordWrap.Checked;
  PrintPreview.EditorPrint.Highlight := CheckBoxHighlight.Checked;

  PrintPreview.UpdatePreview;
end;

end.
