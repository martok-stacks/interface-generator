unit DocProcessorCPP_XIntf;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DocumentProcessor, DocProcessorCPP;

type
  TDocumentProcessorCPP_XIntf = class(TDocumentProcessorCPP)
  protected
    procedure EmitInterfaceForward(Name: string); override;
    procedure EmitInterfaceBegin(Name: string; GUID: TGuid; Parents: TStringArray); override;
    procedure EmitInterfaceEnd; override;
    procedure EmitInterfaceMethod(const name, return, params: string); override;
  end;

implementation

{ TDocumentProcessorCPP_XIntf }

procedure TDocumentProcessorCPP_XIntf.EmitInterfaceForward(Name: string);
begin
  PrintIndented(format('%s = interface;',[Name]));
end;

procedure TDocumentProcessorCPP_XIntf.EmitInterfaceBegin(Name: string; GUID: TGuid; Parents: TStringArray);
var
  par: String;
begin
  par:= Implode(Parents, ', ');
  if par > '' then
    par:= '('+par+')';

  PrintIndented(Format('DECLARE_GUID(%s, MAKEGUID(%8x,%4x,%4x,%2x,%2x,%2x,%2x,%2x,%2x,%2x,%2x));',
               [Name,GUID.D1,GUID.D2,GUID.D3,GUID.D4[0],GUID.D4[1],GUID.D4[2],GUID.D4[3],GUID.D4[4],GUID.D4[5],GUID.D4[6],GUID.D4[7]]));
  PrintIndented(Format('DECLARE_INTERFACE_(%s, %s);',[Name, par]));
  PrintIndented('{');
end;

procedure TDocumentProcessorCPP_XIntf.EmitInterfaceEnd;
begin
  PrintIndented('}');
  PrintIndented('');
end;

procedure TDocumentProcessorCPP_XIntf.EmitInterfaceMethod(const name, return, params: string);
begin
  if return > '' then
    PrintIndented(format('STDMETHOD_(%s,%s)(%s) PURE;',[return, name, params]))
  else
    PrintIndented(format('STDMETHOD_(void,%s)(%s) PURE;',[name, params]));
end;

end.

