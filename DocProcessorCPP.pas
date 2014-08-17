unit DocProcessorCPP;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DocumentProcessor;

type
  TDocumentProcessorCPP = class(TDocumentProcessor)
  private
    fModDefineName: string;
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
    function ConvertLiteralType(const TypeSpec, ExplicitCast, Value: string): string; override;
    function ConvertComment(const style, Value: string): string; override;
    procedure EmitConstDef(Name: string; PadName: integer; Value: string); override;
    procedure EmitTypeAlias(NewName, OldName: string); override;
    procedure EmitEnumBegin(Name: string; BaseSize: integer); override;
    procedure EmitEnumEnd; override;
    procedure EmitEnumItem(Name: string; PadName: integer; Value: string; More: boolean); override;
    function ConvertParam(const name, ptype, attrib: string; More: boolean): string; override;
    procedure EmitCallback(const name, return, params: string); override;
    procedure EmitStructBegin({%H-}Name: string); override;
    procedure EmitStructEnd(Name: string); override;
    procedure EmitStructField(const name, ftype: string); override;
    function ConvertType(const aType: string): String; override;
  end;

implementation

{ TDocumentProcessorCPP }

function TDocumentProcessorCPP.Language: string;
begin
  Result:= 'cpp';
end;

procedure TDocumentProcessorCPP.EmitModuleHeader(ModulName: string);
begin
  fModDefineName:= '__'+UpperCase(ModulName)+'_H';
  PrintIndented('#ifndef '+fModDefineName);
  PrintIndented('#define '+fModDefineName);
  PrintIndented('');
end;

procedure TDocumentProcessorCPP.EmitModuleFooter;
begin
  PrintIndented('#endif');
end;

procedure TDocumentProcessorCPP.EmitDeclarationBegin;
begin
end;

procedure TDocumentProcessorCPP.EmitDeclarationEnd;
begin
end;

procedure TDocumentProcessorCPP.EmitConstBlockBegin;
begin
  PrintIndented('/* CONST */');
end;

procedure TDocumentProcessorCPP.EmitConstBlockEnd;
begin
  PrintIndented('');
end;

procedure TDocumentProcessorCPP.EmitTypeBlockBegin;
begin
  PrintIndented('/* TYPE */');
end;

procedure TDocumentProcessorCPP.EmitTypeBlockEnd;
begin
  PrintIndented('');
end;

function TDocumentProcessorCPP.ConvertLiteralType(const TypeSpec, ExplicitCast, Value: string): string;
begin
  case TypeSpec of
    'hex': Result:= '0x' + Value;
    'string': Result:= AnsiQuotedStr(Value, '"');
  else
    Result:= inherited;
  end;
  if ExplicitCast > '' then
    Result:= '('+ExplicitCast+')'+Result;
end;

function TDocumentProcessorCPP.ConvertComment(const style, Value: string): string;
begin
  case style of
    'line': Result:= '// ' + Value;
    'block': Result:= '/* ' + sLineBreak + Value + sLineBreak + ' */';
    'inline': Result:= '/* ' + Value + ' */';
  end;
end;

procedure TDocumentProcessorCPP.EmitConstDef(Name: string; PadName: integer; Value: string);
begin
  PrintIndented('#define ' + PadString(Name, ' ', PadName) + ' ' + Value);
end;

procedure TDocumentProcessorCPP.EmitTypeAlias(NewName, OldName: string);
begin
  PrintIndented('typedef '+OldName+' '+NewName + ';');
end;

procedure TDocumentProcessorCPP.EmitEnumBegin(Name: string; BaseSize: integer);
var
  bs: string;
begin
  case BaseSize of
    1: bs:= ' : unsigned char ';
    2: bs:= ' : unsigned char ';
    4: bs:= '';
  else
    FatalError('Target: unsupported enum size %d',[BaseSize]);
  end;
  PrintIndented('enum '+Name+bs+'{');
end;

procedure TDocumentProcessorCPP.EmitEnumEnd;
begin
  PrintIndented('};');
end;

procedure TDocumentProcessorCPP.EmitEnumItem(Name: string; PadName: integer; Value: string; More: boolean);
var
  s: string;
begin
  s:= Name;
  if Value > '' then
    s:= PadString(s,' ', PadName) + ' = ' + Value;
  if More then
    s:= s + ',';
  PrintIndented(s);
end;

function TDocumentProcessorCPP.ConvertParam(const name, ptype, attrib: string; More: boolean): string;
var
  t: string;
begin
  Result:= '';
  case attrib of
    '': t:= ptype;
    'out': t:= ptype + ' *';
    'const': t:= 'const '+ ptype;
    'var': t:= ptype + ' *';
  else
    FatalError('Target: Unkown method attribute: %s',[attrib]);
  end;
  Result:= t + ' ' + name;
  if more then
    Result:= Result + ', ';
end;

procedure TDocumentProcessorCPP.EmitCallback(const name, return, params: string);
begin
  if return > '' then
    PrintIndented(format('typedef %s (*%s)(%s);',[return, name, params]))
  else
    PrintIndented(format('typedef void (*%s)(%s);',[name, params]));
end;

procedure TDocumentProcessorCPP.EmitStructBegin(Name: string);
begin
  PrintIndented('typedef struct {');
end;

procedure TDocumentProcessorCPP.EmitStructEnd(Name: string);
begin
  PrintIndented('} '+Name + ';');
end;

procedure TDocumentProcessorCPP.EmitStructField(const name, ftype: string);
begin
  PrintIndented(ftype + ' ' + name + ';');
end;

function TDocumentProcessorCPP.ConvertType(const aType: string): String;
begin
  case LowerCase(aType) of
    'pointer': Exit('void*');
  end;
  Result:=inherited ConvertType(aType);
end;

end.

