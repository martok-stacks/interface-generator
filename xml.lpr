program xml;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils,
  { you can add units after this }
  DOM, XMLRead, DocumentProcessor, DocProcessorFPC;

var
  optInputFile: String;
  optOutputFile: String;

var
  domParser: TDOMParser;
  fs: TFileStream;
  inp: TXMLInputSource;
  doc: TXMLDocument;
  dp: TDocumentProcessor;
begin
  optInputFile:= ExtractFilePath(ParamStr(0)) + 'OpenPGPIntf.xml';
  optOutputFile:= ExtractFilePath(ParamStr(0)) + 'OpenPGPIntf_gen.pas';
  CloseFile(Output);
  AssignFile(Output, optOutputFile);
  Rewrite(Output);

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
          dp:= TDocumentProcessorFPC.Create;
          try
            dp.Translate(doc);
          finally
            FreeAndNil(dp);
          end;
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
end.

