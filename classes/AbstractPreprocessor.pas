unit AbstractPreprocessor ;

interface
uses Classes, SysUtils, Optional ;

type
  TDefBlockState = (dbsNone,dbsThen,dbsElse) ;
  TDefBlockCommand = (dbcNone,dbcDefine,dbcElse,dbcEnd) ;

  TAbstractPreprocessor = class
  protected
    inputfile:string ;
    errmsg:string ;
    pragmaenc,paramenc:TOptional<TEncoding> ;
    deflist:TStringList ;
    packnames:Boolean ;
    origcodepage:Boolean ;
    function LoadSourceFile(const filename: string; srcenc:TEncoding): TStringList;
    procedure ProcessPragmasAndComments(script:TStringList) ;
    procedure UpdateParamsByPragmas() ;
    // Блок для переопределения в конкретном препроцессоре
    function SetParamFromPair(const name:string; const value:string):Boolean ; virtual ; abstract ;
    function SetPragma(const name:string):Boolean ; virtual ; abstract ;
    function StripCommentFromLine(const line:string):string ; virtual ; abstract ;
    function GetDefineCommandFromLine(const line:string; var defname:string):TDefBlockCommand ; virtual ; abstract ;
    function isIncludeDirective(const line:string; var incfile:string):Boolean ; virtual ; abstract ;
    function isPragmaDirective(const line:string; var pragma:string):Boolean ; virtual ; abstract ;
  public
    constructor Create(const Ainputfile:string) ;
    destructor Destroy ; override ;
    procedure SetEncodingFromParams(value:TEncoding) ;
    procedure SetParamsFromPairs(pairs:TStringList) ;
    procedure AddDefine(const name:string) ;
    function getErrMsg():string ;
    function getEncoding():TEncoding ;
    function getOutputEncoding():TEncoding ;
  end;

implementation
uses SourceEncodings, LineNumerator, NamePacker, SpaceStripper ;

{ TAbstractPreprocessor }

constructor TAbstractPreprocessor.Create(const Ainputfile: string);
begin
  inputfile:=Ainputfile ;
  packnames:=False ;
  origcodepage:=False ;
  pragmaenc:=TOptional<TEncoding>.NullOptional ;
  paramenc:=TOptional<TEncoding>.NullOptional ;
  deflist:=TStringList.Create() ;
end;

destructor TAbstractPreprocessor.Destroy;
begin
  deflist.Free ;
  inherited Destroy;
end;

procedure TAbstractPreprocessor.AddDefine(const name: string);
begin
  deflist.Add(name) ;
end;

function TAbstractPreprocessor.getEncoding: TEncoding;
begin
  // Кодировка по умолчанию
  Result:=TEncoding.UTF8 ;
  // Приоритет у командной строки, потом у прагмы
  if paramenc then Result:=paramenc.Value else
  if pragmaenc then Result:=pragmaenc.Value ;
end;

function TAbstractPreprocessor.getErrMsg: string;
begin
  Result:=errmsg ;
end;

function TAbstractPreprocessor.getOutputEncoding: TEncoding;
begin
  if origcodepage then Result:=getEncoding() else Result:=TEncoding.GetEncoding(20866) ;
end;

procedure TAbstractPreprocessor.SetEncodingFromParams(value: TEncoding);
begin
  paramenc:=value ;
end;

procedure TAbstractPreprocessor.SetParamsFromPairs(pairs: TStringList);
var i:Integer ;
    enc:TOptional<TEncoding> ;
begin
  for i := 0 to pairs.Count-1 do begin
    // Сначала общие параметры
    if pairs.Names[i]='codepage' then begin
      enc:=getEncodingByName(pairs.ValueFromIndex[i]) ;
      if enc then SetEncodingFromParams(enc.Value) else raise Exception.Create('Unknown codepage: '+pairs.ValueFromIndex[i]) ;
    end
    else
    if pairs.Names[i]='define' then AddDefine(pairs.ValueFromIndex[i].ToUpper()) else
    if pairs.Names[i]='packnames' then packnames:=pairs.ValueFromIndex[i].ToLower()='true' else
    if pairs.Names[i]='origcodepage' then origcodepage:=pairs.ValueFromIndex[i].ToLower()='true' else
    // потом вызов настроки уникальных параметров для конкретного препроцессора
    if not SetParamFromPair(pairs.Names[i],pairs.ValueFromIndex[i]) then
      raise Exception.Create('Unknown parameter: '+pairs.Names[i]) ;
  end;
end;

procedure TAbstractPreprocessor.UpdateParamsByPragmas();
var s,pragma:string ;
    lines:TStringList ;
    newenc:TOptional<TEncoding> ;
begin
  lines:=TStringList.Create() ;
  lines.LoadFromFile(inputfile,TEncoding.GetEncoding(866)) ;
  for s in lines do
    if isPragmaDirective(s,pragma) then begin
      // Сначала обработка прагмы кодировки, общей для всех
      newenc:=getEncodingByName(pragma) ;
      if newenc then pragmaenc:=newenc else
      // Потом уникальная прагма для конкретного препроцессора
      if not SetPragma(pragma) then
        raise Exception.Create('Unknown PRAGMA: '+pragma);
    end ;
  lines.Free ;
end;

function TAbstractPreprocessor.LoadSourceFile(const filename: string; srcenc:TEncoding): TStringList;
var i,j:Integer ;
    incfile:string ;
    included:TStringList ;
begin
  if not FileExists(filename) then raise Exception.Create('Not found file: '+filename);

  Result:=TStringList.Create() ;
  Result.LoadFromFile(filename,srcenc) ;
  i:=0 ;
  while i<Result.Count do begin
    if isIncludeDirective(Result[i], incfile) then begin
      included:=LoadSourceFile(incfile, srcenc) ;
      Result.Delete(i) ;
      for j:=0 to included.Count-1 do
        Result.Insert(i+j,included[j]) ;
      included.Free ;
    end
    else
      Inc(i) ;
  end ;
end;

procedure TAbstractPreprocessor.ProcessPragmasAndComments(script:TStringList) ;
var i:Integer ;
    currentdefblock:string ;
    currentdefblockstate:TDefBlockState ;
begin
  // Обработка условных директив и удаление комментариев
  i:=0 ;
  currentdefblock:='' ;
  currentdefblockstate:=dbsNone ;
  while i<script.Count do begin
    case GetDefineCommandFromLine(script[i],currentdefblock) of
      dbcDefine:
        if currentdefblockstate=dbsNone then
          currentdefblockstate:=dbsThen
        else
          raise Exception.Create('Multilevel IFDEF not supported yet') ;
      dbcElse:
        if currentdefblockstate=dbsThen then
          currentdefblockstate:=dbsElse
        else
          raise Exception.Create('ELSE without IFDEF') ;
      dbcEnd:
        if currentdefblockstate in [dbsThen,dbsElse] then
          currentdefblockstate:=dbsNone
        else
          raise Exception.Create('ENDIF without ELSE or IFDEF') ;
    end;
    script[i]:=StripCommentFromLine(script[i]).Trim() ;
    if script[i].Length=0 then script.Delete(i) else
    if (currentdefblockstate=dbsThen)and
      (deflist.IndexOf(currentdefblock)=-1) then script.Delete(i) else
    if (currentdefblockstate=dbsElse)and
      (deflist.IndexOf(currentdefblock)<>-1) then script.Delete(i) else
       Inc(i) ;
  end;
end;

end.
