program geni;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, getopts,
  { you can add units after this }
  DOM, XMLRead, XMLWrite, DocumentProcessor,
  DocProcessorFPC, DocProcessorCPP_XIntf;

var
  optInputFile: String;
  optOutputFile: String;
  optLanguage: String;
  optDbgXML: boolean;

procedure ExpandIncludeStatements(const doc: TDOMElement; const BasePath: string);
var
  fn: string;
  rn: TDOMNode;
  inc: TDOMElement;
begin
  rn:= doc.FirstChild;
  while Assigned(rn) do begin
    if rn.NodeType = ELEMENT_NODE then begin
      if rn.NodeName='include' then begin
        inc:= rn as TDOMElement;
        fn:= inc.AttribStrings['path'];
        fn:= ExpandFileName(ConcatPaths([BasePath, fn]));
        ReadXMLFragment(inc, fn);
        ExpandIncludeStatements(inc, ExtractFilePath(fn));
        // move included nodes to where the include was
        while assigned(inc.FirstChild) do
          doc.InsertBefore(inc.FirstChild, inc);
        // note new work pos
        rn:= inc.PreviousSibling;
        // remove (now empty) include
        doc.RemoveChild(inc);
      end else
        ExpandIncludeStatements(rn as TDOMElement, BasePath);
    end;
    rn:= rn.NextSibling;
  end;
end;

var
  doc: TXMLDocument;
  dp: TDocumentProcessor;
  ior: Word;
begin
  while true do
    case GetOpt('i:o:l:d') of
      EndOfOptions: break;
      'i': optInputFile:= OptArg;
      'o': optOutputFile:= OptArg;
      'l': optLanguage:= OptArg;
      'd': optDbgXML:= true;
    end;

  if (optLanguage = '') or (optInputFile='') or (optOutputFile='') then
    TDocumentProcessor.FatalError('USAGE: %s -i InFile -o OutFile -l Language',[ExtractFileName(ParamStr(0))]);

  if not FileExists(optInputFile) then
    TDocumentProcessor.FatalError('Input File not found!',[]);

  if optOutputFile <> '-' then begin
    {$IOChecks off};
    ior:= IOResult;
    CloseFile(Output);
    AssignFile(Output, optOutputFile);
    Rewrite(Output);
    {$IOChecks on}
    ior:= IOResult;

    if ior<>0 then
      TDocumentProcessor.FatalError('Could not open output file, Error: %d',[ior]);
  end;

  case UpperCase(optLanguage) of
    'FPC': dp:= TDocumentProcessorFPC.Create;
    'CPP': TDocumentProcessor.FatalError('Please choose a C++ variant: CPP-XINTF',[]);
    'CPP-XINTF': dp:= TDocumentProcessorCPP_XIntf.Create;
  else
    TDocumentProcessor.FatalError('Unsupported target language: %s',[optLanguage]);
  end;

  try
    ReadXMLFile(doc, optInputFile);
    if Assigned(doc) then begin
      ExpandIncludeStatements(doc.DocumentElement, ExtractFilePath(ExpandFileName(optInputFile)));
      if optDbgXML then
        WriteXMLFile(doc, optOutputFile + '.xml');
      dp.Translate(doc);
    end;
  finally
    FreeAndNil(dp);
  end;
end.

