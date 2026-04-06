unit BasicPreprocessor ;

interface
uses Classes, SysUtils, Optional, AbstractPreprocessor ;

type
  TBasicPreprocessor = class(TAbstractPreprocessor)
  private
    autonumlines:Boolean ;
    packnames:Boolean ;
    stripspaces:Boolean ;
    startline,stepline:Integer ;
    function StripCommentFromLine(const line:string):string ; override ;
    procedure UpdateParamsByPragmas() ;
  public
    constructor Create(const Ainputfile:string) ;
    procedure SetParamsFromPairs(pairs:TStringList) ;
    function getResult():TOptional<TStringList> ;
  end;

implementation
uses SourceEncodings, LineNumerator, NamePacker, SpaceStripper ;

{ TBasicPreprocessor }

constructor TBasicPreprocessor.Create(const Ainputfile: string);
begin
  inherited Create(Ainputfile) ;
  autonumlines:=False ;
  packnames:=False ;
  startline:=10 ;
  stepline:=10 ;
end;

procedure TBasicPreprocessor.SetParamsFromPairs(pairs: TStringList);
var i:Integer ;
    enc:TOptional<TEncoding> ;
begin
  for i := 0 to pairs.Count-1 do begin
    if pairs.Names[i]='codepage' then begin
      enc:=getEncodingByName(pairs.ValueFromIndex[i]) ;
      if enc then SetEncodingFromParams(enc.Value) else raise Exception.Create('Unknown codepage: '+pairs.ValueFromIndex[i]) ;
    end
    else
    if pairs.Names[i]='autonumlines' then autonumlines:=pairs.ValueFromIndex[i].ToLower()='true' else
    if pairs.Names[i]='startline' then startline:=StrToInt(pairs.ValueFromIndex[i]) else
    if pairs.Names[i]='stepline' then stepline:=StrToInt(pairs.ValueFromIndex[i]) else
    if pairs.Names[i]='define' then AddDefine(pairs.ValueFromIndex[i].ToUpper()) else
    if pairs.Names[i]='packnames' then packnames:=pairs.ValueFromIndex[i].ToLower()='true' else
    if pairs.Names[i]='stripspaces' then stripspaces:=pairs.ValueFromIndex[i].ToLower()='true' else
      raise Exception.Create('Unknown parameter: '+pairs.Names[i]) ;
  end;
end;

function TBasicPreprocessor.StripCommentFromLine(const line: string): string;
var i:Integer ;
    instring:Boolean ;
begin
  instring:=False ;
  for i := 1 to line.Length do begin
    if line[i]='"' then instring:=not instring ;
    if not instring then
      if (line[i]='''')or (line.Substring(i-1,3).ToUpper()='REM') then
        Exit(line.Substring(0,i-2)) ;
  end;
  Result:=line ;
end;

procedure TBasicPreprocessor.UpdateParamsByPragmas();
var s,pragma:string ;
    lines:TStringList ;
    newenc:TOptional<TEncoding> ;
begin
  lines:=TStringList.Create() ;
  lines.LoadFromFile(inputfile,TEncoding.GetEncoding(866)) ;
  for s in lines do
    if s.Trim().ToUpper().IndexOf('''$PRAGMA:')=0 then begin
      pragma:=s.Trim().ToUpper().Replace('''$PRAGMA:','').Replace('''','').Trim() ;
      newenc:=getEncodingByName(pragma) ;
      if newenc then pragmaenc:=newenc else
      if pragma='AUTONUMLINES' then autonumlines:=True else
        raise Exception.Create('Unknown PRAGMA: '+pragma);
    end ;
  lines.Free ;
end;

function TBasicPreprocessor.getResult(): TOptional<TStringList>;
var script:TStringList ;
begin
  try
  UpdateParamsByPragmas() ;

  // Загрузка файла с учетом включаемых файлов
  script:=loadSourceFile(inputfile,getEncoding()) ;

  // Обработка условных директив и удаление комментариев
  ProcessPragmasAndComments(script) ;

  if autonumlines then
    with TLineNumerator.Create(script,startline,stepline) do begin
      script.Free ;
      script:=getNumeratedLines() ;
      Free ;
    end;

  // Обязательно после автонумерации
  if packnames then
    with TNamePacker.Create(script) do begin
      script.Free ;
      script:=getPackedLines() ;
      Free ;
    end;

  // Обязательно после автонумерации и после упаковки символов
  if stripspaces then
    with TSpaceStripper.Create(script) do begin
      script.Free ;
      script:=getStrippedLines() ;
      Free ;
    end;

  Result:=script ;
  except
    on E:Exception do begin
      errmsg:=E.message ;
      Exit(TOptional<TStringList>.NullOptional) ;
    end ;
  end;
end;

end.
