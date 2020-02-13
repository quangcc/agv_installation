<%@ Page LANGUAGE="VB" CodePage="65001" ASPCompat="true" %>
<%@ import namespace="BosBase" %>
<%@ import namespace="BOSG" %>
<%@ import namespace="BOSL" %>
<%@ import namespace="aysocks.sock1" %>
<%@ import namespace="AYRPT" %>
<%
If checkLogin() <> "" Then
	Response.Write ("<script language='javascript'>location.href='" & checkLogin() & "';</" & "script>")
	Response.End
End If
%>

<Script runAt="Server">
    Private Const C_sysparamTDHSetting As String = "TDHSETTINGS"
    Private Const C_sysparamTDHConnect As String = "TDHDBCONNECT"
    Private Const C_sysparamQRCodeConnect As String = "QRCODEDBCONNECT"
    Private Const C_sysparamPOSBankConn As String = "SRVMGRCONN"
    Private Const paramTab As String = "SYSPARAMS"

    '// create syaprams class 0 and also clone to class=POSID for synchronization
    Private sub writesysconfigClone(ByRef RS As ADODB.RecordSet, ByRef param As String, ByRef paramval As String)
        Dim sysparamExists As Boolean
        RS.Open ("Select I From " & paramTab & " Where C='" & param & "' And paramClass=" & Session("U_POSName"))
        If Not RS.EOF Then sysparamExists = True
        RS.Close
        Dim stmt, op As String
        If sysparamExists
            op = "U"
            stmt = "update " & paramTab & " set sysvalue='" & paramval & "' where C='" & param & "' And paramClass=" & Session("U_POSName")
        Else
            op = "I"
            stmt = "insert into " & paramTab & "(I, C, sysvalue, paramClass) values ([~@]'" & param & "','" & paramval & "', " & Session("U_POSName") & ")"
        End If

        '// Write-log for sysparam class = POSID
        SQLExec(RS, stmt, True, "BOS.BASETAB_SEQ", "", paramTab, -1, op)

        '// No write-log for sysparams class 0
        writesysconfig(RS,param,paramval)
    End Sub

    Private Function readsysconfigClone(ByRef rs As ADODB.RecordSet, ByRef param As String) As String
        rs.open("select sysvalue from sysparams where C='" & param & "' And paramClass=" & Session("U_POSName"))
        If rs.EOF Then
            rs.Close
            rs.open("select sysvalue from sysparams where C='" & param & "' And paramClass=0")
        End If
        If Not rs.EOF Then
            readsysconfigClone = IIF(IsDBNull(rs(0).Value), Nothing, rs(0).Value)
        Else
            readsysconfigClone = ""
        End If
        rs.Close()
    End Function

    Dim InputTitles() As String = {"TDH IP", "TDH Port", "TĐH Password", "Số lượng máy POS", _
        "Pump Comport", "Tank Comport", "Alarm Comport", _
        "Permit-Pump-Connect", "Permit-Tank-Connect", "Permit-POS-Connect"}
    Dim InputTypes() As Short = {0,1,0,1,1,1,1,1,1,1}
    Private Const pwdIndex As Integer = 2

    Private Function TDHInfoParam(ByRef Infos() As String, ByRef index As Short, byRef fmt As Integer)
        Dim val = Request.Form.Item("param" & index)
        If fmt = 1 Then '// check numeric 
            If Not isNumeric(val) Then
                Return "Cần nhập trường số cho " & InputTitles(index) & ".<br>"
            End If
        End If
        Infos(Index) = val
        Return ""
    End Function

</Script>

<html>
<head><title>Cấu hình chung CHXD</title>
<LINK REL=STYLESHEET HREF="../Include/font_<%=Session("UFONT")%>.css" type="text/css"> <LINK REL=STYLESHEET HREF="../Include/skin_<%=Session("USKIN")%>.css" type="text/css">

<script language="javascript" src="../Include/utils.js"></script>
<script language="javascript" src="../Include/hdr.js"></script>

</head>

<Body>

<%

    Dim Conn As ADODB.Connection
    Dim RS As New ADODB.Recordset
    OpenDB(Conn)
    RS.ActiveConnection=Conn
    Dim i As Integer
    Dim ErrMsg As String

    '// Check permission
    Dim pcheckresult As String = checkmenupermission(RS)
    If pcheckresult<>"" Then
        RS=Nothing
        CloseDB(Conn)
        Response.Write (jsalert(pcheckresult))
        Response.End
    End If

    '// BOS Header
    If getPageStr("noheader")<>"on" Then
        Response.Write (HdrGen(RS))
    End If

    '//POS Connection info:
    Dim POSBankTitles() As String = {"Host IP", "Host Port", "Access ID", "Access Token"}
    Dim POSBankInfo() As String
    Try
        POSBankInfo = Split$(AyDeCompress(readsysconfigClone(RS, C_sysparamPOSBankConn)), TDH_msgSepr)
    Catch ex1 As Exception
        ReDim POSBankInfo(UBound(POSBankTitles))
    End Try
    If UBound(POSBankInfo) < UBound(POSBankTitles) Then ReDim POSBankInfo(UBound(POSBankTitles))

    '//// Socket connection infos
    Dim ConnectionString As String

    If Request.Form.Item("frmsubmit") = "savePOSBankConn" Then
        If getGlobalVar("APPLOCATION") = "POS" Then
            For i = 0 To UBound(POSBankTitles)
                POSBankInfo(i) = Request.Form.Item("posbank" & i)
            Next
            writesysconfigClone(RS, C_sysparamPOSBankConn, AyCompress(String.Join(TDH_msgSepr, POSBankInfo)))
        Else
            Response.Write("<font color='red'><b>Function is not available at this location</b></font>")
        End If
    End If
%>
<table cellpadding=8>
<tr>
<td valign=top nowrap>
	<form name='posbankfrm' method='POST' onSubmit="return false">
	<input type='hidden' name='frmsubmit' value='savePOSBankConn'>
	<font class='subtitle'>Kết nối service manager</font><p>
	<table border="0" cellspacing="0" cellpadding="3">
		<% 
            For i = 0 To UBound(POSBankTitles)
                Response.Write("<tr><td>" & POSBankTitles(i) & "</td><td><input name='posbank" & i & "' size=35 value='" & POSBankInfo(i) & "'></td></tr>")
            Next
            %>
		<tr><td></td><td><input type="button" class='btn' value=" Lưu " onClick="savePosBankInfo()">
<!--			<input type="button" id='testconnposbtn' class='btn' value="Test Connect" onClick="testConnPosBank()">-->
			<input type="reset" class='btn' value="Reset">
			</td></tr>
	</table>
	</form>
</table>

<script language='javascript'>
function configsaveall() {
	if(confirm('Lưu toàn bộ các thông số trên?')) {
		document.tdhfrm.frmsubmit.value='all';
		document.tdhfrm.submit()
	}
}

function changepassword() {
	if (document.pwdfrm.pwd.value.length<4) {
		alert('Password min 4 ký tự!');
		return;
	}
	document.pwdfrm.submit()
}

function dispcharacter() {
	var f=document.pwdfrm;
	if (f.seecharacter.checked)
		g_tag('seechars').innerHTML=f.pwd.value;
	else
		g_tag('seechars').innerHTML='';
}

function refreshdispchar() {
	var f=document.pwdfrm;
	if (f.seecharacter.checked)
		g_tag('seechars').innerHTML=f.pwd.value;
}

function savedbconnect() {
	document.dbfrm.submit()
}

var testconnecting = false;
function testconnection() {
	if (!testconnecting) {
		g_tag('testconnbtn').disabled=true;
		document.body.style.cursor='wait';
		testconnecting = true;
		ajFrmSubmit('testTDHDbConnect.aspx', document.dbfrm, testconnectionRet, null);
	}
}

function testconnectionRet(http) {
	document.body.style.cursor='default';
	alert(http.responseText);
	g_tag('testconnbtn').disabled=false;
	testconnecting = false;
}

var testqrconnecting = false;
function testqrconnection() {
	if (!testqrconnecting) {
		g_tag('testqrconnbtn').disabled=true;
		document.body.style.cursor='wait';
		testconnecting = true;
		ajFrmSubmit('testQRDbConnect.aspx', document.qrfrm, testqrconnectionRet, null);
	}
}

function testqrconnectionRet(http) {
	document.body.style.cursor='default';
	alert(http.responseText);
	g_tag('testqrconnbtn').disabled=false;
	testqrconnecting = false;
}

function saveqrconnect() {
	document.qrfrm.submit()
    }

function savePosBankInfo() {
    document.posbankfrm.submit();
}

var testpbconnecting = false;
function testConnPosBank() {
	if (!testpbconnecting) {
		g_tag('testconnposbtn').disabled=true;
		document.body.style.cursor='wait';
		testpbconnecting = true;
		ajFrmSubmit('../TDH/S3MgrTestConnPOSBank.aspx', document.posbankfrm, testConnPosBankRet, null);
	}
}

function testConnPosBankRet(http) {
    if (http) {
        var str = http.responseText;
        if (str == "0") {
            alert("Login expired");
            location.reload();
            return;
        }

    	g_tag('testconnposbtn').disabled=false;
        document.body.style.cursor = 'default';
        testpbconnecting = false;

        if (str.split("^")[0] == "-1") {
            alert("Lỗi hệ thống: " + str.split("^")[1]);
            return;
        }

        alert(str);
    }
}

function testsocket() {
	window.open('TestSocket.aspx');
}
</script>
<%
    RS =Nothing
    CloseDB(Conn)
%>
</body>
</html>
