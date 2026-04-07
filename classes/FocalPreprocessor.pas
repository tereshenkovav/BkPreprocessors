unit FocalPreprocessor ;

interface
uses Classes, SysUtils, Optional, AbstractPreprocessor ;

type
  TFocalPreprocessor = class(TAbstractPreprocessor)
  private
    packnames:Boolean ;
  protected
    function SetParamFromPair(const name:string; const value:string):Boolean ; override ;
    function SetPragma(const name:string):Boolean; override ;
    function StripCommentFromLine(const line:string):string ; override ;
    function GetDefineCommandFromLine(const line: string; var defname: string): TDefBlockCommand; override ;
    function isIncludeDirective(const line:string; var incfile:string):Boolean ; override ;
    function isPragmaDirective(const line:string; var pragma:string):Boolean ; override ;
  public
    constructor Create(const Ainputfile:string) ;
    function getResult():TOptional<TStringList> ;
  end;

implementation
uses SourceEncodings, NamePacker ;

{ TFocalPreprocessor }

constructor TFocalPreprocessor.Create(const Ainputfile: string);
begin
  inherited Create(Ainputfile) ;
  packnames:=False ;
end;

// Переопределения настроек конкретного препроцессора

function TFocalPreprocessor.isIncludeDirective(const line: string;
  var incfile: string): Boolean;
begin
  Result:=False ;
  if line.Trim().IndexOf('#INCLUDE ')=0 then begin
    incfile:=line.Replace('#INCLUDE ','').Trim() ;
    Result:=True ;
  end;
end;

function TFocalPreprocessor.isPragmaDirective(const line: string;
  var pragma: string): Boolean;
begin
  Result:=False ;
  if line.Trim().ToUpper().IndexOf('#PRAGMA')=0 then begin
    pragma:=line.Trim().ToUpper().Replace('#PRAGMA','').Trim() ;
    Result:=True ;
  end;
end;

function TFocalPreprocessor.GetDefineCommandFromLine(const line: string;
  var defname: string): TDefBlockCommand;
begin
  Result:=dbcNone ;
  if line.Trim().IndexOf('#IFDEF')=0 then begin
    Result:=dbcDefine ;
    defname:=line.Replace('#IFDEF','').Trim().ToUpper() ;
  end;
  if line.Trim().IndexOf('#ELSE')=0 then Result:=dbcElse ;
  if line.Trim().IndexOf('#ENDIF')=0 then Result:=dbcEnd ;
end;

function TFocalPreprocessor.SetParamFromPair(const name, value: string): Boolean;
begin
  Result:=True ;
  if name='packnames' then packnames:=value.ToLower()='true' else
  Result:=False ;
end;

function TFocalPreprocessor.SetPragma(const name: string): Boolean;
begin
  // В Фокале нет дополнительных прагм
  Result:=False ;
end;

function TFocalPreprocessor.StripCommentFromLine(const line: string): string;
var i:Integer ;
    instring:Boolean ;
begin
  instring:=False ;
  for i := 1 to line.Length do begin
    if line[i]='"' then instring:=not instring ;
    if not instring then
      if (line[i]='#')or (line.Substring(i-1,2)='//') then
        Exit(line.Substring(0,i-1)) ;
  end;
  Result:=line ;
end;

// Функция основной работы
function TFocalPreprocessor.getResult(): TOptional<TStringList>;
var script:TStringList ;
begin
  try
  UpdateParamsByPragmas() ;

  // Загрузка файла с учетом включаемых файлов
  script:=loadSourceFile(inputfile,getEncoding()) ;

  // Обработка условных директив и удаление комментариев
  ProcessPragmasAndComments(script) ;

  if packnames then
    with TNamePacker.Create(script,FOCAL_NAME_ALIASES) do begin
      script.Free ;
      script:=getPackedLines() ;
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
