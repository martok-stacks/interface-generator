unit DocumentProcessor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DOM, dateutils;

type
  TStringArray = array of String;

  TDocumentProcessor = class
  private
    fIndentLevel: integer;
    fDelayedComment: TDOMElement;
    procedure ProcessCallback(Callback: TDOMElement);
    procedure ProcessStruct(Struct: TDOMElement);
    procedure ProcessField(Field: TDOMElement);
  protected

    procedure ProcessVerbatim(Verbatim: TDOMElement);
    procedure ProcessConsts(Consts: TDOMElement);
    procedure ProcessConst(Constd: TDOMElement);
    function ContentToValue(item: TDOMElement): string;
    procedure ProcessComment(Comment: TDOMElement);
    procedure ProcessTypeAlias(TypeAlias: TDOMElement);
    procedure ProcessEnum(Enum: TDOMElement);
    procedure ProcessEnumItem(Item: TDOMElement; More: boolean);
    procedure ProcessInterface(Intf: TDOMElement);
    procedure ProcessMethod(Method: TDOMElement);
    function ConvertParam(Param: TDOMElement; More: boolean): string;
    procedure ProcessTypes(Types: TDOMElement);
    procedure ProcessDeclarations(Declarations: TDOMElement);
    procedure ProcessHeader(Header: TDOMElement);

    procedure IndentMore;
    procedure IndentDone;
    procedure PrintIndented(const RawText: string);
  protected
    function Language: string; virtual; abstract;
    procedure EmitModuleHeader(ModulName: string); virtual; abstract;
    procedure EmitModuleFooter; virtual; abstract;
    procedure EmitDeclarationBegin; virtual; abstract;
    procedure EmitDeclarationEnd; virtual; abstract;
    procedure EmitConstBlockBegin; virtual; abstract;
    procedure EmitConstBlockEnd; virtual; abstract;
    procedure EmitTypeBlockBegin; virtual; abstract;
    procedure EmitTypeBlockEnd; virtual; abstract;
    procedure EmitConstDef(Name, Value: string); virtual; abstract;
    procedure EmitTypeAlias(NewName, OldName: string); virtual; abstract;
    procedure EmitEnumBegin(Name: string; BaseSize: integer); virtual; abstract;
    procedure EmitEnumEnd; virtual; abstract;
    procedure EmitEnumItem(Name, Value: string; More: boolean); virtual; abstract;
    procedure EmitInterfaceBegin(Name: string; GUID: TGuid; Parents: TStringArray); virtual; abstract;
    procedure EmitInterfaceEnd; virtual; abstract;
    procedure EmitInterfaceMethod(const name, return, params: string); virtual; abstract;
    procedure EmitStructBegin(Name: string); virtual; abstract;
    procedure EmitStructEnd(Name: string); virtual; abstract;
    procedure EmitStructField(const name, ftype: string); virtual; abstract;
    function ConvertLiteralType(const TypeSpec, Value: string): string; virtual;
    function ConvertType(const aType: string): String; virtual;
    function ConvertComment(const style, Value: string): string; virtual; abstract;
    function ConvertParam(const name, ptype, attrib: string; More: boolean): string; virtual; abstract;
    procedure EmitCallback(const name, return, params: string); virtual; abstract;
  public
    procedure Translate(const Doc: TXMLDocument);
    class procedure FatalError(Msg: String; Fmt: array of const);
  end;

function Implode(Str: TStringArray; Glue: String): string;

implementation

const
  nHeader                          = 'header';
  aHeaderModule                    = 'module';
  nVerbatim                        = 'verbatim';
  aVerbatimLang                    = 'lang';
  nDeclarations                    = 'declarations';
  nConstants                       = 'constants';
  nConst                           = 'const';
  aConstName                       = 'name';
  nTypes                           = 'types';
  nValue                           = 'v';
  aValueType                       = 'type';
  nComment                         = 'comment';
  aCommentStyle                    = 'style';
  nCommentDelayed                  = 'comto';
  nAlias                           = 'alias';
  aAliasName                       = 'name';
  aAliasType                       = 'type';
  nEnum                            = 'enum';
  aEnumName                        = 'name';
  aEnumSize                        = 'size';
  nItem                            = 'item';
  aItemName                        = 'name';
  nInterface                       = 'interface';
  aInterfaceName                   = 'name';
  aInterfaceGUID                   = 'guid';
  nExtends                         = 'extends';
  nMethod                          = 'method';
  aMethodName                      = 'name';
  aMethodReturn                    = 'return';
  nParam                           = 'param';
  aParamName                       = 'name';
  aParamType                       = 'type';
  aParamAttrib                     = 'attr';
  nCallback                        = 'callback';
  aCallbackName                    = 'name';
  aCallbackReturn                  = 'return';
  nStruct                          = 'struct';
  aStructName                      = 'name';
  nField                           = 'field';
  aFieldName                       = 'name';
  aFieldType                       = 'type';

function Implode(Str: TStringArray; Glue: String): string;
var
  i: integer;
begin
  Result:= '';
  if Length(Str) = 0 then
    exit;
  for i:= 0 to high(Str)-1 do
    Result:= Result + Str[i] + Glue;
  Result:= Result + Str[high(Str)];
end;


{ TDocumentProcessor }

class procedure TDocumentProcessor.FatalError(Msg: String; Fmt: array of const);
begin
  WriteLn(ErrOutput, Format(Msg, Fmt));
  halt(1);
end;

function TDocumentProcessor.ContentToValue(item: TDOMElement): string;
var
  v: TDOMElement;
begin
  if not item.HasChildNodes then
    Exit('');

  if item.FirstChild.NodeName = nValue then begin
    v:= item.FirstChild as TDOMElement;
    Result:= ConvertLiteralType(v.AttribStrings[aValueType], v.TextContent);
  end else
    Result:= ConvertLiteralType('', item.TextContent);
end;

procedure TDocumentProcessor.ProcessVerbatim(Verbatim: TDOMElement);
begin
  if CompareText(Verbatim.AttribStrings[aVerbatimLang], Language) = 0 then
    PrintIndented(Verbatim.TextContent);
end;

procedure TDocumentProcessor.ProcessConst(Constd: TDOMElement);
var
  name,val: string;
begin
  name:= Constd.AttribStrings[aConstName];
  val:= ContentToValue(Constd);
  EmitConstDef(name, val);
end;

procedure TDocumentProcessor.ProcessConsts(Consts: TDOMElement);
var
  i: integer;
begin
  EmitConstBlockBegin;
  IndentMore;

  for i:= 0 to Consts.ChildNodes.Count-1 do
    case Consts.ChildNodes[i].NodeName of
      nComment: ProcessComment(Consts.ChildNodes[i] as TDOMElement);
      nCommentDelayed: fDelayedComment:= Consts.ChildNodes[i] as TDOMElement;
      nVerbatim: ProcessVerbatim(Consts.ChildNodes[i] as TDOMElement);
      nConst: ProcessConst(Consts.ChildNodes[i] as TDOMElement);
    else
      FatalError('Consts: Unknown node type %s',[Consts.ChildNodes[i].NodeName]);
    end;

  IndentDone;
  EmitConstBlockEnd;
end;

procedure TDocumentProcessor.ProcessComment(Comment: TDOMElement);
var
  st,c: string;
begin
  st:= Comment.AttribStrings[aCommentStyle];
  c:= Comment.TextContent;
  if st = '' then begin
    if Pos(#13,c) > 0 then
      st:= 'block'
    else
      st:= 'line';
  end;
  PrintIndented(ConvertComment(st, c));
end;

procedure TDocumentProcessor.ProcessTypeAlias(TypeAlias: TDOMElement);
begin
  EmitTypeAlias(TypeAlias.AttribStrings[aAliasName], ConvertType(TypeAlias.AttribStrings[aAliasType]));
end;

procedure TDocumentProcessor.ProcessEnumItem(Item: TDOMElement; More: boolean);
var
  name,val: string;
begin
  name:= Item.AttribStrings[aItemName];
  val:= ContentToValue(Item);
  EmitEnumItem(name, val, More);
end;

procedure TDocumentProcessor.ProcessEnum(Enum: TDOMElement);
var
  i: integer;
begin
  EmitEnumBegin(Enum.AttribStrings[aEnumName], StrToIntDef(Enum.AttribStrings[aEnumSize], 4));
  IndentMore;

  for i:= 0 to Enum.ChildNodes.Count-1 do
    case Enum.ChildNodes[i].NodeName of
      nItem: ProcessEnumItem(Enum.ChildNodes[i] as TDOMElement, i < Enum.ChildNodes.Count-1);
      nCommentDelayed: fDelayedComment:= Enum.ChildNodes[i] as TDOMElement;
    else
      FatalError('Enum: Unknown node type %s',[Enum.ChildNodes[i].NodeName]);
    end;

  IndentDone;
  EmitEnumEnd;
end;

function TDocumentProcessor.ConvertParam(Param: TDOMElement; More: boolean): string;
var
  n,t,a: string;
begin
  n:= Param.AttribStrings[aParamName];
  t:= ConvertType(Param.AttribStrings[aParamType]);
  a:= Param.AttribStrings[aParamAttrib];
  Result:= ConvertParam(n,t,a,More);
end;

procedure TDocumentProcessor.ProcessMethod(Method: TDOMElement);
var
  mn, ret,par: string;
  i: integer;
begin
  mn:= Method.AttribStrings[aMethodName];
  ret:= Method.AttribStrings[aMethodReturn];
  par:= '';

  for i:= Method.ChildNodes.Count-1 downto 0 do
    case Method.ChildNodes[i].NodeName of
      nParam: par:= ConvertParam(Method.ChildNodes[i] as TDOMElement, par>'') + par;
    else
      FatalError('Method: Unknown node type %s',[Method.ChildNodes[i].NodeName]);
    end;

  EmitInterfaceMethod(mn,ret,par);
end;

procedure TDocumentProcessor.ProcessInterface(Intf: TDOMElement);
var
  i: integer;
  extends: TDOMNodeList;
  parents: TStringArray;
begin
  extends:= Intf.GetElementsByTagName(nExtends);
  if Assigned(extends) then begin
    SetLength(parents, extends.Count);
    for i:= 0 to extends.Count-1 do
      parents[i]:= extends[i].TextContent;
    FreeAndNil(extends);
  end else
    SetLength(parents, 0);

  EmitInterfaceBegin(Intf.AttribStrings[aInterfaceName], StringToGUID(Intf.AttribStrings[aInterfaceGUID]), parents);
  IndentMore;


  for i:= 0 to Intf.ChildNodes.Count-1 do
    case Intf.ChildNodes[i].NodeName of
      nExtends: {already handled};
      nMethod: ProcessMethod(Intf.ChildNodes[i] as TDOMElement);
      nCommentDelayed: fDelayedComment:= Intf.ChildNodes[i] as TDOMElement;
    else
      FatalError('Intf: Unknown node type %s',[Intf.ChildNodes[i].NodeName]);
    end;

  IndentDone;
  EmitInterfaceEnd;
end;

procedure TDocumentProcessor.ProcessCallback(Callback: TDOMElement);
var
  mn, ret,par: string;
  i: integer;
begin
  mn:= Callback.AttribStrings[aCallbackName];
  ret:= Callback.AttribStrings[aCallbackReturn];
  par:= '';

  for i:= Callback.ChildNodes.Count-1 downto 0 do
    case Callback.ChildNodes[i].NodeName of
      nParam: par:= ConvertParam(Callback.ChildNodes[i] as TDOMElement, par>'') + par;
    else
      FatalError('Callback: Unknown node type %s',[Callback.ChildNodes[i].NodeName]);
    end;

  EmitCallback(mn,ret,par);
end;

procedure TDocumentProcessor.ProcessField(Field: TDOMElement);
var
  n,t: string;
begin
  n:= Field.AttribStrings[aFieldName];
  t:= ConvertType(Field.AttribStrings[aFieldType]);
  EmitStructField(n,t);
end;

procedure TDocumentProcessor.ProcessStruct(Struct: TDOMElement);
var
  mn: string;
  i: integer;
begin
  mn:= Struct.AttribStrings[aStructName];
  EmitStructBegin(mn);
  IndentMore;

  for i:= 0 to Struct.ChildNodes.Count-1 do
    case Struct.ChildNodes[i].NodeName of
      nField: ProcessField(Struct.ChildNodes[i] as TDOMElement);
      nCommentDelayed: fDelayedComment:= Struct.ChildNodes[i] as TDOMElement;
    else
      FatalError('Struct: Unknown node type %s',[Struct.ChildNodes[i].NodeName]);
    end;

  IndentDone;
  EmitStructEnd(mn);
end;

procedure TDocumentProcessor.ProcessTypes(Types: TDOMElement);
var
  i: integer;
begin
  EmitTypeBlockBegin;
  IndentMore;

  for i:= 0 to Types.ChildNodes.Count-1 do
    case Types.ChildNodes[i].NodeName of
      nComment: ProcessComment(Types.ChildNodes[i] as TDOMElement);
      nCommentDelayed: fDelayedComment:= Types.ChildNodes[i] as TDOMElement;
      nVerbatim: ProcessVerbatim(Types.ChildNodes[i] as TDOMElement);
      nAlias: ProcessTypeAlias(Types.ChildNodes[i] as TDOMElement);
      nEnum: ProcessEnum(Types.ChildNodes[i] as TDOMElement);
      nInterface: ProcessInterface(Types.ChildNodes[i] as TDOMElement);
      nCallback: ProcessCallback(Types.ChildNodes[i] as TDOMElement);
      nStruct: ProcessStruct(Types.ChildNodes[i] as TDOMElement);
    else
      FatalError('Types: Unknown node type %s',[Types.ChildNodes[i].NodeName]);
    end;

  IndentDone;
  EmitTypeBlockEnd;
end;

procedure TDocumentProcessor.ProcessDeclarations(Declarations: TDOMElement);
var
  i: integer;
begin
  EmitDeclarationBegin;

  for i:= 0 to Declarations.ChildNodes.Count-1 do
    case Declarations.ChildNodes[i].NodeName of
      nConstants: ProcessConsts(Declarations.ChildNodes[i] as TDOMElement);
      nTypes: ProcessTypes(Declarations.ChildNodes[i] as TDOMElement);
    else
      FatalError('Declarations: Unknown node type %s',[Declarations.ChildNodes[i].NodeName]);
    end;

  EmitDeclarationEnd;
end;

procedure TDocumentProcessor.ProcessHeader(Header: TDOMElement);
var
  i: integer;
begin
  PrintIndented(ConvertComment('inline', Format('GENERATED FILE, DO NOT EDIT! [Created %sZ]',[FormatDateTime('YYYY-MM-DD HH:NN:SS',LocalTimeToUniversal(Now))])));
  EmitModuleHeader(Header.AttribStrings[aHeaderModule]);

  for i:= 0 to Header.ChildNodes.Count-1 do
    case Header.ChildNodes[i].NodeName of
      nVerbatim: ProcessVerbatim(Header.ChildNodes[i] as TDOMElement);
      nDeclarations: ProcessDeclarations(Header.ChildNodes[i] as TDOMElement);
    else
      FatalError('Header: Unknown node type %s',[Header.ChildNodes[i].NodeName]);
    end;

  EmitModuleFooter;
end;

procedure TDocumentProcessor.IndentMore;
begin
  inc(fIndentLevel);
end;

procedure TDocumentProcessor.IndentDone;
begin
  dec(fIndentLevel);
  if fIndentLevel < 0 then fIndentLevel:= 0;
end;

function TrimLeftN(const s: String; N: integer): string;
var
  i: integer;
begin
  i:= 1;
  while (i < Length(s)) and (i<=n) and (s[i] = ' ') do
    inc(i);
  Result:= Copy(s, i, Maxint);
end;

procedure TDocumentProcessor.PrintIndented(const RawText: string);
  procedure DelayedCommentWrite(s: string);
  var
    dc: TDOMElement;
  begin
    if Assigned(fDelayedComment) then begin
      dc:= fDelayedComment;
      fDelayedComment:= nil;
      Write(s);
      ProcessComment(dc);
    end else
      WriteLn(s);
  end;

var
  lines: tstringlist;
  i, minSpaces, sp: integer;
  ln: string;
begin
  lines:= TStringList.Create;
  try
    lines.Text:= Trim(RawText);
    if lines.Count = 0 then begin
      WriteLn('');
      Exit;
    end;
    minSpaces:= 0;
    for i:= 1 to lines.Count-1 do begin
      sp:= Length(lines[i]) - Length(TrimLeft(lines[i]));
      if (sp < minSpaces) or (minSpaces = 0) then
        minSpaces:= sp;
    end;
    for i:= 0 to lines.Count-1 do begin
      lines[i]:= TrimLeftN(lines[i], minSpaces);
    end;
    for i:= 0 to lines.Count-1 do begin
      ln:= TrimRight(StringOfChar(' ', fIndentLevel*2) + lines[i]);
      DelayedCommentWrite(ln);
    end;
  finally
    FreeAndNil(lines);
  end;
end;

function TDocumentProcessor.ConvertLiteralType(const TypeSpec, Value: string): string;
begin
  if TypeSpec = '' then
    Result:= Value
  else
    FatalError('Unknown value type specifier: %s', [TypeSpec]);
end;

function TDocumentProcessor.ConvertType(const aType: string): String;
begin
  Result:= aType;
end;

procedure TDocumentProcessor.Translate(const Doc: TXMLDocument);
begin
  if Doc.DocumentElement.NodeName <> nHeader then
    FatalError('Document root is not %s',[nHeader]);
  ProcessHeader(Doc.DocumentElement);
end;

end.

