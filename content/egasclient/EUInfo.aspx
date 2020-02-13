<%@ Page LANGUAGE="VB" CodePage="65001" ASPCompat="true" %>
<%@ import namespace="BosBase" %>
<%@ import namespace="BOSG" %>
<%@ import namespace="BOSL" %>
<%@ import namespace="System.Web" %>
<%@ import namespace="System.Collections" %>
<script lang="vb" runat="server">
    Private Const C_sysparamTDHConnect As String = "TDHDBCONNECT"
	Private ConnStr As String = System.Configuration.ConfigurationManager.appSettings("CCHXD")
    Private Function readsysconfigClone(ByRef rs As ADODB.RecordSet, ByRef param As String, Optional ByVal POSC As String="") As String
		If POSC<>"" Then 
			rs.open("select sysvalue from sysparams where C='" & param & "' And paramClass=" & POSC)
			If rs.EOF Then 
				POSC=""
				rs.Close()
			End If
		End If
        If POSC="" Then
            rs.open("select sysvalue from sysparams where C='" & param & "' And paramClass=0")
        End If
        If Not rs.EOF Then
            readsysconfigClone = IIF(IsDBNull(rs(0).Value), Nothing, rs(0).Value)
        Else
            readsysconfigClone = ""
        End If
        rs.Close()
    End Function
	
</script>
<%
Try 
	Dim Conn As New ADODB.Connection
	Dim RS As New ADODB.RecordSet
	Conn.Open(strDec(ConnStr))
	RS.ActiveConnection=Conn
	Dim outHtm = New StringBuilder()
	
	Dim POSI, POSC,COMI As String 
	POSI = readsysconfigClone(RS, "@POSI")
	COMI = readsysconfigClone(RS, "@COMPANYI")
	POSC = readsysconfigClone(RS, "@POSID")
	outHtm.Append("{")
	outHtm.AppendLine(" ""POSID"": """ & POSI & """,")
	outHtm.AppendLine(" ""POSC"": """ & POSC & """,")
	Dim POSN, POSADD As String 
	RS.Open("Select N, Address From POS Where I=" & POSI)
	If Not RS.EOF Then 
		POSN = StrNull(RS(0).Value)
		POSADD = StrNull(RS(1).Value)
	End If
	RS.Close()
	outHtm.AppendLine(" ""POSNAME"": """ & POSN & """,")
	outHtm.AppendLine(" ""POSADD"": """ & POSADD & """,")
	Dim COMN, COMADD, COMTAX, COMC As String 
	RS.Open("Select N, Address,  TaxCode, C From MD.Company Where I=" & COMI)
	If Not RS.EOF Then 
		COMN = StrNull(RS(0).Value)
		COMADD = StrNull(RS(1).Value)
		COMTAX = StrNull(RS(2).Value)
		COMC = StrNull(RS(3).Value) 
	End If
	RS.Close()
	outHtm.AppendLine(" ""COMI"": """ & COMI & """,")
	outHtm.AppendLine(" ""COMNAME"": """ & COMN & """,")
	outHtm.AppendLine(" ""COMADD"": """ & COMADD & """,")
	outHtm.AppendLine(" ""COMTAX"": """ & COMTAX & """,")
	outHtm.AppendLine(" ""COMCODE"": """ & COMC & """,")

	Dim ConnCfgTdh() As String
	Dim ConnCfgTdh1() As String
	Dim ConnCfgEgas() As String 
	ConnCfgEgas = Split(strDec(ConnStr), ";")
	ConnCfgTdh=Split(AYDecompress(ReadSysConfigClone(RS, "TDHDBCONNECT", POSC)), ",;")
	Dim TDHConnStr As String = AYDecompress(ReadSysConfigClone(RS, "TDHSETTINGS", POSC))
	ConnCfgTdh1=Split(TDHConnStr, ",;")

	outHtm.AppendLine(" ""E_PROVIDER"": """ & ConnCfgEgas(0) & """,")
	outHtm.AppendLine(" ""E_SERVER"": """ & Replace(ConnCfgEgas(1),"\", "\\")& """,")
	outHtm.AppendLine(" ""E_DBNAME"": """ & ConnCfgEgas(2) & """,")
	outHtm.AppendLine(" ""E_USERID"": """ & ConnCfgEgas(3) & """,")
	outHtm.AppendLine(" ""E_PWD"": """ & ConnCfgEgas(4) & """, ")

	outHtm.AppendLine(" ""A_PROVIDER"": """ & ConnCfgTdh(0) & """,")
	outHtm.AppendLine(" ""A_SERVER"": """ & Replace(ConnCfgTdh(1),"\", "\\") & """,")
	outHtm.AppendLine(" ""A_DBNAME"": """ & ConnCfgTdh(2) & """,")
	outHtm.AppendLine(" ""A_USERID"": """ & ConnCfgTdh(3) & """,")
	outHtm.AppendLine(" ""A_PWD"": """ & ConnCfgTdh(4) & """, ")


	outHtm.AppendLine(" ""A_CONNSTR"": """ & TDHConnStr & """,")
	outHtm.AppendLine(" ""A_HOSTIP"": """ & ConnCfgTdh1(0) & """,")
	outHtm.AppendLine(" ""A_PORT"": """ & ConnCfgTdh1(1) & """,")
	outHtm.AppendLine(" ""A_AUTHOR"": """ & ConnCfgTdh1(2) & """, ")

	'//Min-Max:
	Dim MinQty, MaxQty, MinAmt, MaxAmt As String 
	Dim szInfo, szInfoV, szMinMax As String 
	Dim szTCode, szPayCard, szTrTab As String 
	Dim szagv_ALL_URLs As String 
	Dim i, j As Integer
	RS.Open("Select C, sysvalue From sysparams where paramclass= " & POSC)
	While Not RS.EOF
		szInfo = StrNull(RS(0).Value)
		szInfoV = StrNull(RS(1).Value)
		Select Case szInfo
			Case "agv_minqty":
				MinQty = szInfoV
			Case "agv_maxqty":
				MaxQty = szInfoV
			Case "agv_minamt":
				MinAmt = szInfoV
			Case "agv_maxamt":
				MaxAmt = szInfoV
		End Select
		RS.MoveNext()
	End While 
	RS.Close()

	RS.Open("Select C, sysvalue From sysparams where paramclass=0 ")
	While Not RS.EOF
		szInfo = StrNull(RS(0).Value)
		szInfoV = StrNull(RS(1).Value)
		Select Case szInfo
			Case "agv_minqty":
				If MinQty = "" Then
					outHtm.AppendLine(" ""MinQty"": " & szInfoV & ",")
				Else
					outHtm.AppendLine(" ""MinQty"": " & MinQty & ",")
				End If
			Case "agv_maxqty":
				If MaxQty = "" Then
					outHtm.AppendLine(" ""MaxQty"": " & szInfoV & ",")
				Else
					outHtm.AppendLine(" ""MaxQty"": " & MaxQty & ",")
				End If
			Case "agv_minamt":
				If MinAmt = "" Then
					outHtm.AppendLine(" ""MinAmt"": " & szInfoV & ",")
				Else
					outHtm.AppendLine(" ""MinAmt"": " & MinAmt & ",")
				End If
			Case "agv_maxamt": 
				If MaxAmt = "" Then
					outHtm.AppendLine(" ""MaxAmt"": " & szInfoV & ",")
				Else
					outHtm.AppendLine(" ""MaxAmt"": " & MaxAmt & ",")
				End If
			Case "agv_amtmin2print":
				outHtm.AppendLine(" ""AmtMin2Print"": " & szInfoV & ",")
			Case "agv_http":
				outHtm.AppendLine(" ""EgasServerHttp"": """ & szInfoV & """,")
			Case "agv_syncurl":
				outHtm.AppendLine(" ""EgasSyncServerHttp"": """ & szInfoV & """,")
			Case "@SYNCHCHECKREPEAT_SECONDS":
				outHtm.AppendLine(" ""SynchCheckRepeat_Seconds"": " & szInfoV & ",")
			Case "@SYNCHMAX_RECORDS":
				outHtm.AppendLine(" ""SynchMax_Records"": " & szInfoV & ",")
			Case "agv_start2play":
				outHtm.AppendLine(" ""Start2Play"": " & szInfoV & ",")
			Case "agv_playpause":
				outHtm.AppendLine(" ""ShowPlayPause"": " & szInfoV & ",")
			Case "agv_confirmss":
				outHtm.AppendLine(" ""ConfirmSS"": " & szInfoV & ",")
			Case "agv_tcode":
				szTCode = szInfoV
			Case "agv_paycardcode":
				szPayCard = szInfoV
		End Select
		RS.MoveNext()
	End While 
	RS.Close()
	

	'//Lấy thông số kết nối, tạo HĐĐT:
	outHtm.AppendLine(" ""InvoiceCfg"": { ")

	'//Get sysp
	szTrTab = Year(Now())
	RS.Open("Select C, sysvalue From MD.sysparams where paramclass=8 ")
	While Not RS.EOF
		szInfo = StrNull(RS(0).Value)
		szInfoV = StrNull(RS(1).Value)
		Select Case szInfo
			Case szTrTab:
				outHtm.AppendLine(" ""EgasTrTab"": ""T" & szInfoV & """,")
		End Select
		RS.MoveNext()
	End While 
	RS.Close()	
	
	RS.Open("Select C, N From einvinfo where C In ('einv_uchk') ")
	While Not RS.EOF
		szInfo = StrNull(RS(0).Value)
		szInfoV = StrNull(RS(1).Value)
		Select Case szInfo
			Case "einv_uchk":
				outHtm.AppendLine(" ""EInvUrlCheck"": """ & szInfoV & """,")
		End Select
		RS.MoveNext()
	End While 
	RS.Close()
	
	outHtm.AppendLine(" ""TCode"": [ ")
	If Trim(szTCode)<>"" Then 
		Dim str() As String = Split(szTCode, ";")
		For i=0 To UBound(str)
			outHtm.AppendLine("{")
			outHtm.AppendLine(" ""Type"": """ & Split(str(i), "||")(0) & """, ")
			outHtm.AppendLine(" ""Value"": """ & Split(str(i), "||")(1) & """ ")
			outHtm.AppendLine("}")
			If i<UBound(str) Then outHtm.AppendLine(",")
		Next 
	End If
	outHtm.AppendLine(" ], ")
	outHtm.AppendLine(" ""PayCard"": [ ")
	If Trim(szPayCard)<>"" Then 
		Dim str() As String = Split(szPayCard, ";")
		For i=0 To UBound(str)
			outHtm.AppendLine("{")
			outHtm.AppendLine(" ""Type"": """ & Split(str(i), "||")(0) & """, ")
			outHtm.AppendLine(" ""Value"": """ & GetSQLVal(RS, "Select I From MD.paymentcard Where C='" & Split(str(i), "||")(1) & "'") & """ ")
			outHtm.AppendLine("}")
			If i<UBound(str) Then outHtm.AppendLine(",")
		Next 
	End If
	outHtm.AppendLine(" ] ")
	outHtm.AppendLine(" }}")

	If Request("param") <> "" 
		Response.Write(outHtm.ToString())
	Else 
		Response.Write(AyCompress(outHtm.ToString()))
	End If

	outHtm = Nothing
	RS = Nothing
	CloseDB(Conn)
Catch Ex0 As Exception 
	Response.Write("-1^Có lỗi hệ thống: " & Ex0.ToString())
End Try 
%>