program geni;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, getopts,
  { you can add units after this }
  DOM, XMLRead, DocumentProcessor,
  DocProcessorFPC, DocProcessorCPP_XIntf;

var
  optInputFile: String;
  optOutputFile: String;
  optLanguage: String;

var
  domParser: TDOMParser;
  fs: TFileStream;
  inp: TXMLInputSource;
  doc: TXMLDocument;
  dp: TDocumentProcessor;
  ior: Word;
begin
  while true do
    case GetOpt('i:o:l:') of
      EndOfOptions: break;
      'i': optInputFile:= OptArg;
      'o': optOutputFile:= OptArg;
      'l': optLanguage:= OptArg;
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
    domParser:= TDOMParser.Create;
    try
      domParser.Options.PreserveWhiteSpace := false;
      domParser.Options.Namespaces := True;
      fs:= TFileStream.Create(optInputFile, fmOpenRead);
      try
        inp := TXMLInputSource.Create(fs);
        try
          domParser.Parse(inp, doc);
          if Assigned(doc) then begin
            dp.Translate(doc);
          end;
        finally
          inp.Free;
        end;
      finally
        FreeAndNil(fs);
      end;
    finally
      FreeAndNil(domParser);
    end;
  finally
    FreeAndNil(dp);
  end;
end.

