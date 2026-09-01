(*
 ***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License.        *
 *                                                                         *
 ***************************************************************************
*)

unit dQTHProfile;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, dSqlUserData, uDbUtils, uInternalConnection;

type
  TdmQTHProfile = class(TDataModule)
  private

  public
    function  GetNewProfileNumber() : Integer;
    function  ProfileExists(ProfileNumber : String) : Boolean;
    function  ProfileInUse(ProfileNumber : String) : Boolean;

    procedure AddNewProfile(ProfileNumber, Locator, Qth, Equipment, Remarks : String; ProfileVisible : Integer);
    procedure UpdateNewProfile(OldProfileNumber, ProfileNumber, Locator, Qth, Equipment, Remarks : String; ProfileVisible : Integer);
    procedure DeleteProfile(ProfileNumber : String);
    procedure UpdateVisibility(ProfileNumber : String; Visible : Boolean);
  end;

var
  dmQTHProfile: TdmQTHProfile;

implementation

function TdmQTHProfile.GetNewProfileNumber() : Integer;
var
  Connection : TInternalConnection;
begin
  Connection := GetNewInternalConnection();
  try
    Connection.Q.SQL.Text := dmSqlUserData.SqlNewProfileNumber;
    Connection.Q.Open;

    Result := Connection.Q.Fields[0].AsInteger + 1;

  finally
    FreeAndNil(Connection);
  end;
end;

procedure TdmQTHProfile.AddNewProfile(ProfileNumber, Locator, Qth, Equipment, Remarks : String; ProfileVisible : Integer);
var
  C : TInternalConnection;
begin
  C := GetNewInternalConnection();
  try
    C.T.StartTransaction;
    C.Q.SQL.Text := dmSqlUserData.SqlInsertProfile;
    C.Q.Prepare;
    C.Q.ParamByName('nr').AsString := ProfileNumber;
    C.Q.ParamByName('locator').AsString := Locator;
    C.Q.ParamByName('qth').AsString := Qth;
    C.Q.ParamByName('rig').AsString := Equipment;
    C.Q.ParamByName('remarks').AsString := Remarks;
    C.Q.ParamByName('visible').AsInteger := ProfileVisible;
    C.Q.ExecSQL;
    C.T.Commit;
  finally
    FreeAndNil(C);
  end;
end;

procedure TdmQTHProfile.UpdateNewProfile(OldProfileNumber, ProfileNumber, Locator, Qth, Equipment, Remarks : String; ProfileVisible : Integer);
var
  C : TInternalConnection;
begin
  C := GetNewInternalConnection();
  try
    C.T.StartTransaction;
    C.Q.SQL.Text := dmSqlUserData.SqlUpdateProfile;
    C.Q.Prepare;
    C.Q.ParamByName('nr').AsString := ProfileNumber;
    C.Q.ParamByName('locator').AsString := Locator;
    C.Q.ParamByName('qth').AsString := Qth;
    C.Q.ParamByName('rig').AsString := Equipment;
    C.Q.ParamByName('remarks').AsString := Remarks;
    C.Q.ParamByName('visible').AsInteger := ProfileVisible;
    C.Q.ParamByName('old_nr').AsString := OldProfileNumber;
    C.Q.ExecSQL;
    C.T.Commit;

    if (OldProfileNumber <> ProfileNumber) then
    begin
      C.Q.SQL.Text := dmSqlUserData.SqlUpdateQsoProfile;
      C.Q.Prepare;
      C.Q.ParamByName('new_profile').AsString := ProfileNumber;
      C.Q.ParamByName('old_profile').AsString := OldProfileNumber;
      C.Q.ExecSQL;
      C.T.Commit;
    end;
  finally
    FreeAndNil(C);
  end;
end;

function TdmQTHProfile.ProfileExists(ProfileNumber : String) : Boolean;
var
  C : TinternalConnection;
begin
  C := GetNewInternalConnection();
  try
    C.Q.SQL.Text := dmSqlUserData.SqlProfileExists;
    C.Q.Prepare;
    C.Q.ParamByName('profile_number').AsString := ProfileNumber;
    C.Q.Open;

    Result := C.Q.Fields[0].AsInteger > 0;

    C.Q.Close;
  finally
    FreeAndNil(C);
  end;
end;

function TdmQTHProfile.ProfileInUse(ProfileNumber : String) : Boolean;
var
  C : TinternalConnection;
begin
  C := GetNewInternalConnection();
  try
    C.Q.SQL.Text := dmSqlUserData.SqlProfileInUse;
    C.Q.Prepare;
    C.Q.ParamByName('profile_number').AsString := ProfileNumber;
    C.Q.Open;

    Result := not C.Q.Fields[0].IsNull;

    C.Q.Close;
  finally
    FreeAndNil(C);
  end;
end;

procedure TdmQTHProfile.DeleteProfile(ProfileNumber : String);
var
  C : TinternalConnection;
begin
  C := GetNewInternalConnection();
  try
    C.T.StartTransaction;
    C.Q.SQL.Text := dmSqlUserData.SqlDeleteProfile;
    C.Q.Prepare;
    C.Q.ParamByName('profile_number').AsString := ProfileNumber;
    C.Q.ExecSQL;
    C.T.Commit;
    C.Q.Close;
  finally
    FreeAndNil(C);
  end;
end;

procedure TdmQTHProfile.UpdateVisibility(ProfileNumber : String; Visible : Boolean);
var
  C : TinternalConnection;
begin
  C := GetNewInternalConnection();
  try
    C.T.StartTransaction;
    C.Q.SQL.Text := dmSqlUserData.SqlUpdateProfileVisibility;
    C.Q.Prepare;
    if (Visible) then
    begin
      C.Q.ParamByName('visible').AsInteger := 1;
    end
    else begin
      C.Q.ParamByName('visible').AsInteger := 0;
    end;
    C.Q.ParamByName('profile_number').AsString := ProfileNumber;
    C.Q.ExecSQL;
    C.T.Commit;
    C.Q.Close;
  finally
    FreeAndNil(C);
  end;
end;

end.

