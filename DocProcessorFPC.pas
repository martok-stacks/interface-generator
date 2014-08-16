unit DocProcessorFPC;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DocumentProcessor;

type
  TDocumentProcessorFPC = class(TDocumentProcessor)
  protected
    function Language: string; override;
    procedure EmitModuleHeader(ModulName: string); override;
    procedure EmitModuleFooter; override;
    procedure EmitDeclarationBegin; override;
    procedure EmitDeclarationEnd; override;
    procedure EmitConstBlockBegin; override;
    procedure EmitConstBlockEnd; override;
    procedure EmitTypeBlockBegin; override;
    procedure EmitTypeBlockEnd; override;
    function ConvertLiteralType(const TypeSpec, Value: string): string; override;
    function ConvertComment(const style, Value: string): string; override;
    procedure EmitConstDef(Name, Value: string); override;
    procedure EmitTypeAlias(NewName, OldName: string); override;
    procedure EmitEnumBegin(Name: string; BaseSize: integer); override;
    procedure EmitEnumEnd; override;
    procedure EmitEnumItem(Name, Value: string; More: boolean); override;
    procedure EmitInterfaceBegin(Name: string; GUID: TGuid; Parents: TStringArray); override;
    procedure EmitInterfaceEnd; override;
    procedure EmitInterfaceMethod(const name, return, params: string); override;
    function ConvertParam(const name, ptype, attrib: string; More: boolean): string; override;
    procedure EmitCallback(const name, return, params: string); override;
    procedure EmitStructBegin(Name: string); override;
    procedure EmitStructEnd({%H-}Name: string); override;
    procedure EmitStructField(const name, ftype: string); override;
  end;

implementation

{ TDocumentProcessorFPC }

function TDocumentProcessorFPC.Language: string;
begin
  Result:= 'fpc';
end;

procedure TDocumentProcessorFPC.EmitModuleHeader(ModulName: string);
begin
  PrintIndented(Format('unit %s;',[ModulName]));
  PrintIndented('');
end;

procedure TDocumentProcessorFPC.EmitModuleFooter;
begin
  PrintIndented('end.');
end;

procedure TDocumentProcessorFPC.EmitDeclarationBegin;
begin
  PrintIndented('');
  PrintIndented('interface');
  PrintIndented('');
end;

procedure TDocumentProcessorFPC.EmitDeclarationEnd;
begin
  PrintIndented('implementation');
end;

procedure TDocumentProcessorFPC.EmitConstBlockBegin;
begin
  PrintIndented('const');
end;

procedure TDocumentProcessorFPC.EmitConstBlockEnd;
begin
  PrintIndented('');
end;

procedure TDocumentProcessorFPC.EmitTypeBlockBegin;
begin
  PrintIndented('type');
end;

procedure TDocumentProcessorFPC.EmitTypeBlockEnd;
begin
  PrintIndented('');
end;

function TDocumentProcessorFPC.ConvertLiteralType(const TypeSpec, Value: string): string;
begin
  case TypeSpec of
    'hex': Result:= '$' + Value;
    'string': Result:= AnsiQuotedStr(Value, '''');
  else
    Result:=inherited ConvertLiteralType(TypeSpec, Value);
  end;
end;

function TDocumentProcessorFPC.ConvertComment(const style, Value: string): string;
begin
  case style of
    'line': Result:= '// ' + Value;
    'block': Result:= '(* ' + sLineBreak + Value + sLineBreak + ' *)';
    'inline': Result:= '{ ' + Value + ' }';
  end;
end;

procedure TDocumentProcessorFPC.EmitConstDef(Name, Value: string);
begin
  PrintIndented(Name + ' = ' + Value + ';');
end;

procedure TDocumentProcessorFPC.EmitTypeAlias(NewName, OldName: string);
begin
  PrintIndented(NewName+' = type '+ OldName + ';');
end;

procedure TDocumentProcessorFPC.EmitEnumBegin(Name: string; BaseSize: integer);
begin
  PrintIndented('{$MINENUMSIZE '+IntToStr(BaseSize)+'}');
  PrintIndented(Name + ' = (');
end;

procedure TDocumentProcessorFPC.EmitEnumEnd;
begin
  PrintIndented(');');
  PrintIndented('{$MINENUMSIZE DEFAULT}');
end;

procedure TDocumentProcessorFPC.EmitEnumItem(Name, Value: string; More: boolean);
var
  s: string;
begin
  s:= Name;
  if Value > '' then
    s:= s + ' = ' + Value;
  if More then
    s:= s + ',';
  PrintIndented(s);
end;

procedure TDocumentProcessorFPC.EmitInterfaceBegin(Name: string; GUID: TGuid; Parents: TStringArray);
var
  par: String;
begin
  par:= Implode(Parents, ', ');
  if par > '' then
    par:= '('+par+')';
  PrintIndented(format('%s = interface%s',[Name,par]));
  IndentMore;
  PrintIndented('['+QuotedStr(GUIDToString(GUID))+']');
  IndentDone;
end;

procedure TDocumentProcessorFPC.EmitInterfaceEnd;
begin
  PrintIndented('end;');
  PrintIndented('');
end;

procedure TDocumentProcessorFPC.EmitInterfaceMethod(const name, return, params: string);
var
  p: string;
begin
  if Params > '' then
    p:= '('+Params+')'
  else
    p:= '';
  if return > '' then
    PrintIndented(format('function %s%s: %s;',[name, p, return]))
  else
    PrintIndented(format('procedure %s%s;',[name, p]));
end;

function TDocumentProcessorFPC.ConvertParam(const name, ptype, attrib: string; More: boolean): string;
begin
  Result:= '';
  case attrib of
    '':;
    'out': Result:= 'out ';
    'const': Result:= 'const ';
    'var': Result:= 'var ';
  else
    FatalError('Unkown method attribute: %s',[attrib]);
  end;
  Result:= Result + name + ': ' + ptype;
  if more then
    Result:= Result + '; ';
end;

procedure TDocumentProcessorFPC.EmitCallback(const name, return, params: string);
var
  p: string;
begin
  if Params > '' then
    p:= '('+Params+')'
  else
    p:= '';
  if return > '' then
    PrintIndented(format('%s = function %s: %s;',[name, p, return]))
  else
    PrintIndented(format('%s = procedure %s;',[name, p]));
end;

procedure TDocumentProcessorFPC.EmitStructBegin(Name: string);
begin
  PrintIndented(Name+' = record');
end;

procedure TDocumentProcessorFPC.EmitStructEnd(Name: string);
begin
  PrintIndented('end;');
end;

procedure TDocumentProcessorFPC.EmitStructField(const name, ftype: string);
begin
  PrintIndented(name + ': ' + ftype + ';');
end;

end.

