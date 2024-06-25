unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, Menus, lNetComponents, lNet, LCLIntf;

type

  { TForm1 }

  TForm1 = class(TForm)
    back: TButton;
    change: TButton;
    output: TListBox;
    transfer_btn: TButton;
    deposit_btn: TButton;
    continue_payout: TButton;
    iban: TEdit;
    empty1: TButton;
    transfer_money_inp: TEdit;
    tenEur: TButton;
    twentyEur: TButton;
    FiftyEur: TButton;
    HundredEur: TButton;
    TwoHundredEur: TButton;
    empty: TButton;
    get_money: TButton;
    four: TButton;
    payout_Counter_pnl: TPanel;
    TCP: TLTCPComponent;
    one: TButton;
    two: TButton;
    five: TButton;
    eight: TButton;
    three: TButton;
    six: TButton;
    nine: TButton;
    PIN: TPanel;
    zero: TButton;
    stop: TButton;
    desposit_money: TButton;
    del_last_pin_digit: TButton;
    confirm_pin: TButton;
    confirm: TButton;
    check_account: TButton;
    check_history: TButton;
    transfer_money: TButton;
    change_currency: TButton;
    language: TButton;
    seven: TButton;
    account_key: TEdit;
    output_old: TMemo;
    procedure backClick(Sender: TObject);
    procedure changeClick(Sender: TObject);
    procedure change_currencyClick(Sender: TObject);
    procedure check_accountClick(Sender: TObject);
    procedure check_historyClick(Sender: TObject);
    procedure confirm_pinClick(Sender: TObject);
    procedure continue_payoutClick(Sender: TObject);
    procedure del_last_pin_digitClick(Sender: TObject);
    procedure deposit_btnClick(Sender: TObject);
    procedure desposit_moneyClick(Sender: TObject);
    procedure emptyClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure confirmClick(Sender: TObject);
    procedure get_moneyClick(Sender: TObject);
    procedure stopClick(Sender: TObject);
    procedure TCPConnect(aSocket: TLSocket);
    procedure TCPDisconnect(aSocket: TLSocket);
    procedure TCPError(const msg: string; aSocket: TLSocket);
    procedure TCPReceive(aSocket: TLSocket);
    procedure ToggleButtons(Activate_Bool: Boolean);
    procedure NumberButtonClick(Sender: TObject);
    procedure activate_numpad();
    procedure CheckLength();
    procedure activateBank(Activate_Bool: Boolean);
    procedure payout(Sender: TObject);
    procedure ActivatePayoutElements(Activate_Bool: Boolean);
    procedure transfer_btnClick(Sender: TObject);
    procedure transfer_moneyClick(Sender: TObject);
    procedure ActivateTransfer(Activate_Bool: Boolean);
    procedure change_currency_payout(Sender: TObject);
    procedure DestroyBtns();

  private

  public
    fnet: TLconnection;

  end;

var
  Form1: TForm1;
  card_in_use, history_active: boolean;
  account_key_str, account_pin: string;
  MESG, Name, CONN_IP_ADDR: String;
  CONN_PORT, payout_counter: integer;

implementation
      uses lCommon;

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  TCP := TLTCPComponent.Create(Self);
  TCP.SocketNet := LAF_INET;
end;

procedure TForm1.confirmClick(Sender: TObject);
begin
  account_pin := '';
  account_key_str := account_key.Text;
  account_key.Enabled := false;
  ToggleButtons(true);
  stop.Enabled := true;
end;

procedure TForm1.get_moneyClick(Sender: TObject);
begin
  DestroyBtns();
  payout_counter := 0;
  ActivatePayoutElements(true);
  continue_payout.Visible := true;
  tenEur.onClick := @payout;
  twentyEur.onClick := @payout;
  fiftyEur.onClick := @payout;
  hundredEur.onClick := @payout;
  twoHundredEur.onClick := @payout;
end;

procedure TForm1.stopClick(Sender: TObject);
begin
  account_pin := '';
  PIN.Caption := '';
  ToggleButtons(false);
  activateBank(False);
  stop.enabled := False;
  if TCP.Connected then
  begin
    TCP.Disconnect;
  end
end;

procedure TForm1.TCPDisconnect(aSocket: TLSocket);
begin
  aSocket := nil;
  output.items.Add('Verbindung unterbrochen!');
  Sleep(200);
  output.items.Clear();
  output.items.Add('Bis Bald!');
end;

procedure TForm1.TCPError(const msg: string; aSocket: TLSocket);
begin
  aSocket := nil;
  output.items.Add('- - - - - -');
  output.items.Add('Ein Fehler ist aufgetreten...');
  output.items.Add('Haben Sie sich mit der richtigen IP und dem richtigen Port verbunden?');
  output.items.Add('Läuft der Server?');
  output.items.Add('Fehler: ' + msg);
  output.items.Add('- - - - - -');
end;

procedure TForm1.TCPReceive(aSocket: TLSocket);
var
  recv_msg: string;
begin
  recv_msg := '';
  aSocket.GetMessage(recv_msg);
  account_pin := '';

  if recv_msg = '#history#' then
  begin
    history_active := not history_active;
  end
  else if history_active then
  begin
    output.Items.Add(recv_msg);
    output.TopIndex := output.Items.Count - 1;
  end
  else if recv_msg = 'account_check=true' then
  begin
    output.Items.Add(recv_msg);
    output.TopIndex := output.Items.Count - 1;
    Sleep(200);
    output.Items.Add('Account verified!');
    Sleep(500);
    output.Items.Clear();
    activateBank(true);
  end
  else if recv_msg = 'account_check=false' then
  begin
    output.Items.Add('Ungültige Account Daten!');
    output.TopIndex := output.Items.Count - 1;
  end
  else
  begin
    output.Items.Add(recv_msg);
    output.TopIndex := output.Items.Count - 1;
  end;
end;




procedure TForm1.del_last_pin_digitClick(Sender: TObject);
var
  temp_pin_str: string;
  temp_acc_pin: string;
begin
  temp_pin_str := PIN.Caption;
  temp_acc_pin := account_pin;
  if Length(PIN.Caption) > 0 then
  begin
    Delete(temp_pin_str, Length(PIN.Caption), 1);
    Delete(temp_acc_pin, Length(temp_acc_pin), 1);
    PIN.Caption := temp_pin_str;
    account_pin := temp_acc_pin;
  end;
  CheckLength();
end;

procedure TForm1.deposit_btnClick(Sender: TObject);
begin
  output.items.add(intToStr(payout_counter) + ' EUR wurde zum Konto hinzugefügt');
  TCP.SendMessage('deposit#' + account_key.text + '#' + intToStr(payout_counter));
  Sleep(500);
  payout_counter_pnl.Caption := '0 EUR';
  ActivatePayoutElements(false);
  deposit_btn.Visible := False;
end;

procedure TForm1.desposit_moneyClick(Sender: TObject);
begin
  DestroyBtns();
  payout_counter := 0;
  ActivatePayoutElements(true);
  deposit_btn.Visible := true;
  tenEur.onClick := @payout;
  twentyEur.onClick := @payout;
  fiftyEur.onClick := @payout;
  hundredEur.onClick := @payout;
  twoHundredEur.onClick := @payout;
end;

procedure TForm1.emptyClick(Sender: TObject);
begin
  output.items.clear();
end;

procedure TForm1.confirm_pinClick(Sender: TObject);
begin
  CONN_IP_ADDR := '127.0.0.1';
  CONN_PORT := 8000;
  try
    output.items.Add('Connecting...');
    if TCP.Connect(CONN_IP_ADDR, CONN_PORT) then
    begin
      ToggleButtons(false);
      confirm.Enabled := false;
      account_key.Enabled := false;
    end;
  except
    on E: Exception do
      output.items.Add('Fehler beim Verbindungsversuch: ' + E.Message);
  end;
end;

procedure TForm1.check_accountClick(Sender: TObject);
begin
  DestroyBtns();
  TCP.SendMessage('get_balance#' + account_key.text)
end;

procedure TForm1.backClick(Sender: TObject);
begin
  DestroyBtns();
end;

procedure TForm1.DestroyBtns();
begin
  payout_counter_pnl.Caption := '0 EUR';
  ActivateTransfer(false);
  ActivatePayoutElements(false);
  deposit_btn.visible := false;
  continue_payout.visible := false;
  change.visible := false;
end;

procedure TForm1.changeClick(Sender: TObject);
var
  remaining_amount: integer;
  notes200, notes100, notes50, notes20, notes10: integer;
begin
  notes200 := 0;
  notes100 := 0;
  notes50 := 0;
  notes20 := 0;
  notes10 := 0;
  TCP.SendMessage('change_currency#' + account_key.text + '#' + intToStr(payout_counter));
  tenEur.Caption := '10 EUR';
  twentyEur.Caption := '20 EUR';
  fiftyEur.Caption := '50 EUR';
  hundredEur.Caption := '100 EUR';
  twoHundredEur.Caption := '200 EUR';

  notes200 := payout_counter div 200;
  remaining_amount := payout_counter mod 200;

  notes100 := remaining_amount div 100;
  remaining_amount := remaining_amount mod 100;

  notes50 := remaining_amount div 50;
  remaining_amount := remaining_amount mod 50;

  notes20 := remaining_amount div 20;
  remaining_amount := remaining_amount mod 20;

  notes10 := remaining_amount div 10;

  output.items.add('- - - Scheine - - -');
  output.items.add('200 $: ' + intToStr(notes200));
  output.items.add('100 $: ' + intToStr(notes100));
  output.items.add('50 $: ' + intToStr(notes50));
  output.items.add('20 $: ' + intToStr(notes20));
  output.items.add('10 $: ' + intToStr(notes10));
  payout_Counter_pnl.Caption := '0 EUR';
  ActivatePayoutElements(false);

  change.Visible := false;
end;

procedure TForm1.change_currencyClick(Sender: TObject);
begin
  DestroyBtns();
  payout_counter := 0;
  ActivatePayoutElements(true);
  change.Visible := true;
  payout_counter_pnl.Caption := '0 $';
  tenEur.Caption := '10 $';
  twentyEur.Caption := '20 $';
  fiftyEur.Caption := '50 $';
  hundredEur.Caption := '100 $';
  twoHundredEur.Caption := '200 $';

  tenEur.onClick := @change_currency_payout;
  twentyEur.onClick := @change_currency_payout;
  fiftyEur.onClick := @change_currency_payout;
  hundredEur.onClick := @change_currency_payout;
  twoHundredEur.onClick := @change_currency_payout;
end;

procedure TForm1.check_historyClick(Sender: TObject);
begin
  DestroyBtns();
  TCP.SendMessage('get_history#' + account_key.text);
end;

procedure TForm1.continue_payoutClick(Sender: TObject);
var
  remaining_amount: integer;
  notes200, notes100, notes50, notes20, notes10: integer;
begin
  notes200 := 0;
  notes100 := 0;
  notes50 := 0;
  notes20 := 0;
  notes10 := 0;

  TCP.SendMessage('payout#' + account_key.text + '#' + IntToStr(payout_counter));
  Sleep(500);

  notes200 := payout_counter div 200;
  remaining_amount := payout_counter mod 200;

  notes100 := remaining_amount div 100;
  remaining_amount := remaining_amount mod 100;

  notes50 := remaining_amount div 50;
  remaining_amount := remaining_amount mod 50;

  notes20 := remaining_amount div 20;
  remaining_amount := remaining_amount mod 20;

  notes10 := remaining_amount div 10;

  output.items.add('- - - Scheine - - -');
  output.items.add('200 EUR: ' + intToStr(notes200));
  output.items.add('100 EUR: ' + intToStr(notes100));
  output.items.add('50 EUR: ' + intToStr(notes50));
  output.items.add('20 EUR: ' + intToStr(notes20));
  output.items.add('10 EUR: ' + intToStr(notes10));
  payout_Counter_pnl.Caption := '0 EUR';
  ActivatePayoutElements(false);
  continue_payout.Visible := false;
end;


procedure TForm1.TCPConnect(aSocket: TLSocket);
var
  cmd: string;
begin
  output.items.Add('Verbindung hergestellt!');
  Sleep(500);
  output.items.clear;
  cmd := 'check#' + account_key.text + '#' + account_pin;
  TCP.SendMessage(cmd);
end;

procedure TForm1.ToggleButtons(Activate_Bool: Boolean);
var
  ButtonNames: array[0..9] of string = ('zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine');
  i: integer;
  Button: TButton;
begin
  for i := 0 to 9 do
  begin
    Button := FindComponent(ButtonNames[i]) as TButton;
    if Assigned(Button) then
      Button.Enabled := Activate_Bool;
  end;
  del_last_pin_digit.Enabled := Activate_Bool;
  confirm_pin.Enabled := Activate_Bool;
  confirm.Enabled := not Activate_Bool;
  account_key.Enabled := not Activate_Bool;
  activate_numpad();
end;

procedure TForm1.NumberButtonClick(Sender: TObject);
var
  temp_pin: string;
begin
  temp_pin := account_pin + (Sender as TButton).Caption;
  account_pin := temp_pin;
  PIN.Caption := PIN.Caption + '*';
  CheckLength();
end;

procedure TForm1.payout(Sender: TObject);
var
  temp_data: string;
begin
  temp_data := (Sender as TButton).Caption;

  if temp_data = '10 EUR' then
    payout_counter := payout_counter + 10
  else if temp_data = '20 EUR' then
    payout_counter := payout_counter + 20
  else if temp_data = '50 EUR' then
    payout_counter := payout_counter + 50
  else if temp_data = '100 EUR' then
    payout_counter := payout_counter + 100
  else if temp_data = '200 EUR' then
    payout_counter := payout_counter + 200;

  payout_Counter_pnl.Caption := IntToStr(payout_counter) + ' EUR';
end;


procedure TForm1.change_currency_payout(Sender: TObject);
var
  temp_data: string;
begin
  temp_data := (Sender as TButton).Caption;

  if temp_data = '10 $' then
    payout_counter := payout_counter + 10
  else if temp_data = '20 $' then
    payout_counter := payout_counter + 20
  else if temp_data = '50 $' then
    payout_counter := payout_counter + 50
  else if temp_data = '100 $' then
    payout_counter := payout_counter + 100
  else if temp_data = '200 $' then
    payout_counter := payout_counter + 200;

  payout_Counter_pnl.Caption := IntToStr(payout_counter) + ' $';
end;


procedure TForm1.CheckLength();
begin
  if Length(PIN.Caption) > 4 then
  begin
    PIN.Color := clRed;
    confirm_pin.Enabled := false;
  end
  else
  begin
    PIN.Color := clDefault;
    confirm_pin.Enabled := true;
  end;
end;

procedure TForm1.activate_numpad();
begin
  zero.OnClick := @NumberButtonClick;
  one.OnClick := @NumberButtonClick;
  two.OnClick := @NumberButtonClick;
  three.OnClick := @NumberButtonClick;
  four.OnClick := @NumberButtonClick;
  five.OnClick := @NumberButtonClick;
  six.OnClick := @NumberButtonClick;
  seven.OnClick := @NumberButtonClick;
  eight.OnClick := @NumberButtonClick;
  nine.OnClick := @NumberButtonClick;
end;

procedure TForm1.activateBank(Activate_Bool: Boolean);
begin
  get_money.Enabled := Activate_Bool;
  desposit_money.Enabled := Activate_Bool;
  check_account.Enabled := Activate_Bool;
  check_history.Enabled := Activate_Bool;
  transfer_money.Enabled := Activate_Bool;
  change_currency.Enabled := Activate_Bool;
  empty.Enabled := Activate_Bool;
end;

procedure TForm1.ActivatePayoutElements(Activate_Bool: Boolean);
begin
  tenEur.Visible := Activate_Bool;
  twentyEur.Visible := Activate_Bool;
  FiftyEur.Visible := Activate_Bool;
  HundredEur.Visible := Activate_Bool;
  TwoHundredEur.Visible := Activate_Bool;
  payout_counter_pnl.Visible := Activate_Bool;
  back.Visible := Activate_Bool;
  tenEur.Caption := '10 EUR';
  twentyEur.Caption := '20 EUR';
  fiftyEur.Caption := '50 EUR';
  hundredEur.Caption := '100 EUR';
  twoHundredEur.Caption := '200 EUR';
end;

procedure TForm1.transfer_btnClick(Sender: TObject);
var
  iban_str: string;
  money_count: integer;
begin
  iban_str := iban.text;
  money_count := strToInt(transfer_money_inp.text);
  TCP.SendMessage('transfer#' + account_key.text + '#' + iban_str + '#' + transfer_money_inp.text);
  output.items.add('Überweise ' + intToStr(money_count) + ' EUR nach ' + iban_str);
  Sleep(500);
  ActivateTransfer(false);
end;

procedure TForm1.ActivateTransfer(Activate_Bool: Boolean);
begin
  iban.visible := Activate_Bool;
  transfer_money_inp.visible := Activate_Bool;
  transfer_btn.visible := Activate_Bool;
  back.Visible := Activate_Bool;
end;

procedure TForm1.transfer_moneyClick(Sender: TObject);
begin
  DestroyBtns();
  ActivateTransfer(true);

end;


end.

