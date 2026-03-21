unit UnitTestBasicPreprocessor;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TestBasicPreprocessor = class
  private
    function getInputFile(idx:Integer):string ;
    function getOptFile(idx:Integer):string ;
    function getOutputFile(idx:Integer):string ;
  public
    [Test]
    procedure TestFromFiles;
  end;

implementation
uses Classes, SysUtils,
  BasicPreprocessor, SourceEncodings, Optional, IOUtils ;

const CASES_PATH = '..\..\cases_basic\' ;

function TestBasicPreprocessor.getInputFile(idx: Integer): string;
begin
  Result:=CASES_PATH+Format('test%.2d.bas',[idx]) ;
end;

function TestBasicPreprocessor.getOptFile(idx: Integer): string;
begin
  Result:=CASES_PATH+Format('test%.2d.opt',[idx]) ;
end;

function TestBasicPreprocessor.getOutputFile(idx: Integer): string;
begin
  Result:=CASES_PATH+Format('test%.2d.out',[idx]) ;
end;

procedure TestBasicPreprocessor.TestFromFiles;
var i,j,idx:Integer ;
    basic:TBasicPreprocessor ;
    pairs:TStringList ;
    res:TOptional<TStringList> ;
    expected:TStringList ;
begin
  idx:=0 ;

  TDirectory.SetCurrentDirectory(CASES_PATH) ;
  while FileExists(getInputFile(idx)) do begin
    basic:=TBasicPreprocessor.Create(getInputFile(idx)) ;

    if FileExists(getOptFile(idx)) then begin
      pairs:=TStringList.Create() ;
      pairs.LoadFromFile(getOptFile(idx)) ;
      basic.SetParamsFromPairs(pairs) ;
      pairs.Free ;
    end;

    res:=basic.getResult() ;
    if not res.IsOk then raise Exception.Create('Preprocessor error: '+basic.getErrMsg()) ;

    expected:=TStringList.Create() ;
    expected.LoadFromFile(getOutputFile(idx),TEncoding.UTF8) ;
    Assert.AreEqual(expected.Count,res.Value.Count,Format('Test %.2d',[idx])) ;
    for j := 0 to expected.Count-1 do
      Assert.AreEqual(expected[j],res.Value[j],Format('Test %.2d, line %d',[idx,j])) ;
    res.Value.Free ;
    expected.Free ;

    basic.Free ;

    Inc(idx) ;
  end ;
end;

initialization
  TDUnitX.RegisterTestFixture(TestBasicPreprocessor);

end.
