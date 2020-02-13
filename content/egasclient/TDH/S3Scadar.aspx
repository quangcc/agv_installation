<%@ Page LANGUAGE="VB" CodePage="65001" ASPCompat="true" %>
<%@ import namespace="BosBase" %>
<%@ import namespace="BOSL" %>
<%@ import namespace="BOSG" %>
<%@ import namespace="aysocks.sock1" %>

<Script runAt="Server">

'// PCE and TIMING CONTROL
Private Const C_Display_Rfr_Time As Integer = 2000 '//2 seconds
Private Const C_PCE_Min_Time As Integer = 250 '//0.25 seconds. 20 pumps, avg 8 pumps have jspumppending -> display refresh time is 2s.
Private Const C_TPV_URL As String = "ws://[=HOSTIP]:[=HOSTPORT]/BHTDSocket?clientId=[=ACCESSID]&accessToken=[=ACCESSTOCKEN]"

'Private Const CMD_S3_PUMP_ENABLE As String = "61"
'Private Const CMD_S3_PUMP_ENABLE_YESNO As String = "62"
'Private Const CMD_S3_PUMP_DISABLE As String = "63"
'Private Const CMD_S3_PUMP_JOB As String = "65"
'Private Const CMD_S3_PUMP_JOB_CANCEL As String = "67"
'Private Const CMD_S3_PUMP_JOB_STATUS As String = "69"
Private Const GUI_S3_PAID_STATUS_CHANGE As String = "CPST"
Private Const PUMP_DEFAULT_WIDTH As Short = 233
Private Const PUMP_DEFAULT_HEIGHT As Short = 107
Private Const C_COL_W2 As Short = 115
Private Const C_COL_W3 As Short = 75

Private SRVSettings, TDHSettings, ConnectionStr, jspumponoffs, jspumpids, jspumppendings, jobplays, maxJobLines, maxJobInserts, jobdefaultPaids, jsWidths, jsFontSizes, jsProductColors As String
Private printIPs, POSIPs, BankSrvs, PumpSeris, StationNos, proNames As String

Private jsPumpCnt As Integer
Private WShift As String

'////////////// Pump display console /////////////////////////////
Private Function PumpRender(ByRef PumpId As Integer, byRef pumpName As String, byRef ProductI As Long, byRef productName As String, byRef Price As Double, byRef isWsOpen As Boolean, _
	byRef dispW As Integer, byRef dispH As Integer, byRef NoJobLines As Integer, byRef NoJobInserts As Integer, byRef defaultPaid As Integer, byRef pfontsize As Integer, byref ProductColor As String, _
	byRef playStatus As Integer, byRef ctrlRender As Boolean, byVal printIp As String, byVal POSIp As String, byVal BankSrv As String, byVal pumpseri As String, _
	byval pfullName As String, byval stationidx As String, optional byval ctrlplaypause As boolean=false) As String
	
	Dim t_col_W2 As Short = C_COL_W2
	Dim t_col_W3 As Short = C_COL_W3
	
	'// 1. Check pump on/off
	Dim isPumpOn As Boolean = False
	Dim css1 As String = "#999"
	Dim css4, css5, imgbtn, jobimgbtn As String
	Dim retHTML As String
	
	If ctrlRender Then
		If isWsOpen Then
			'Dim retData As String = TDHExecute(ConnectionStr, CMD_S3_PUMP_ENABLE_YESNO, PumpId, 1, 5)	
			'If IsTDHError(retData) Then
				'// socket sending failed
			'	Return retData
			'End If
			
			'Dim valarr() As String = Split$(retData,TDH_DataSepr)
			'isPumpOn = false '//(valarr(1)="1")
			'//test to see ret's pumpId is same as sent:
			'If valarr(0)<>PumpId Then
			'	Response.Write("Some odd thing error(different pumpid): " & valarr(0) & "<>" & PumpId)
			'sEnd If
			
			'//If isPumpOn Then
			'//	S3PumpSessionOverWrite(PumpID, Session.SessionID, Request.ServerVariables.Item("REMOTE_ADDR").toString())
			'//End If
		
		End If
	Else
		css1 = productColor
	End If

	'// js variable for timer to know pumpid
	jspumpids &= PumpId & ","
	jspumppendings &= "1," '// begining all need to be status refreshed
	'//jobplays &= Iif(playStatus=0,"false,", "true,") '// default when start page
	jobplays &= "false,"
	MaxJobLines &= NoJobLines & ","
	MaxJobInserts &= NoJobInserts & ","
	jobdefaultPaids &= defaultPaid & ","
	jsWidths &= dispW & ","
	jsFontSizes &= pfontsize & ","
	jsProductColors &= "'" & ProductColor & "',"
	printIPs &= "'" & printIp & "', "
	POSIPs &= "'" & POSIp & "', "
	BankSrvs &= "'" & BankSrv & "', "
	PumpSeris &= "'" & pumpseri & "', "
	proNames &= "'" & pfullName & "', "
	StationNos &= "'" & stationidx & "', "
	
	If isPumpOn Then
		css1 = productColor
		css4 = "'saleinputon'"
		css5 = "'displabel1'"
		imgbtn = "swap_icon.gif"
		jobimgbtn = Iif(playStatus=0,"play_icon.png","pause_icon.png")
		jspumponoffs &= "true,"
	Else
		css4 = "'saleinputoff'"
		css5 = "'displabel1dis'"
		imgbtn = "swap_icon_red.gif"
		jobimgbtn = "trans_icon.png" '// start page: play is default disabled
		jspumponoffs &= "false,"
	End If
	
	If dispW>PUMP_DEFAULT_WIDTH Then
		t_col_W2 *= dispW/PUMP_DEFAULT_WIDTH
		t_col_W3 *= dispW/PUMP_DEFAULT_WIDTH 	
		
	End If
		
	
	retHTML = _
		"<table id='pumptable" & jsPumpCnt & "' cellspacing=0 width='" & dispW & "' class='pumpbox' style='border:3px solid " & css1 & "'>" & _
		"<tr><td id='pumphead" & jsPumpCnt & "' style='background:" & css1 & "' noWrap><table width='100%' cellpadding=0 cellspacing=0 class='pumphdrsize'><tr>" & _
		"<td>" & _
		Iif(ctrlRender, "<img src='../img/" & imgbtn & "' name='pumpctrl" & jsPumpCnt & "' class='imggo' title='Đổi trạng thái bán bình thường /Tự phục vụ' onclick='setpump(" & PumpId & "," & jsPumpCnt & ")'> &nbsp;", "") & _
		"<a href='javascript:s3logview1(" & PumpId & ", WSID);'><font class='stnumberbig'>" & pumpName & "</font></a> - " & productName & _
		Iif(ctrlRender, "<td align=right><img src='../img/" & jobimgbtn & "' name='jobctrl" & jsPumpCnt & "' class='imggo' onclick='setjobplay(" & PumpId & "," & jsPumpCnt & ")' title='play/pause'>", "") & _
		"</table>" & _
		"<tr><td nowrap>" & _
		"<table class=" & css5 & " id='inputtable" & jsPumpCnt & "'>" & _
		"<tr>" & _
		Iif(ctrlRender, _
		"<td width='" & t_col_W2 & "' align=right nowrap><input  id='saleliter" & jsPumpCnt & "' autocomplete='off' size=2 class=" & css4 & " style='font-size:" & pfontsize & "px'" & _
		" onkeypress=""if(isEnterOnly(event)){cmdsale(" & PumpId & ",this.value," & Price & "," & ProductI & "," & jsPumpCnt & ",1)}"" onfocus='currPumpDisp(" & jsPumpCnt & "," & PumpId & ");thisselect(this)'>" & _
		"<td width='" & t_col_W3 & "' align=right nowrap><input id='saleamt" & jsPumpCnt & "' autocomplete='off' size=6 class=" & css4 & " style='font-size:" & pfontsize & "px'" & _
		" onkeypress=""if(isEnterOnly(event)){cmdsale(" & PumpId & ",this.value," & Price & "," & ProductI & "," & jsPumpCnt & ",2);this.value=insertSepr(this.value)}"" onfocus='currPumpDisp(" & jsPumpCnt & "," & PumpId & ");thisselect(this)' onchange='this.value=insertSepr(this.value)'>", "") & _
		"</table>"
	
	'// 'saledis*' is the content to be refreshed by js timer
	retHTML &= "<tr height='" & dispH & "'><td id='saledisp" & jsPumpCnt & "' valign='top'></table>"
	
	jsPumpCnt += 1
	
	Return retHTML
End Function

Private DisProductOnSales(20) As Boolean
Private DisProductFKs(20) As Long
Private DisProductAmts(20) As Double
Private DisProductPrices(20) As Double
Private DisProductCodes(20) As String
Private DisProductNames(20) As String
Private DisProductCnt As Integer

Private Function searchDisProduct(byVal PR As Long, byVal oriPrice As Double) As Double
	Dim i As Integer
	For i=0 To DisProductCnt
		If DisProductFKs(i)=PR Then
			DisProductOnSales(i) = True
			DisProductPrices(i) = oriPrice-DisProductAmts(i)
			Return DisProductAmts(i)
			Exit For
		End If
	Next
End Function

</script>

<%

If checkLogin() <> "" Then
	Response.Write ("<script language='javascript'>location.href='" & checkLogin() & "';</" & "script>")
	Response.End
End If

Dim Conn As ADODB.Connection
Dim RS As New ADODB.Recordset
OpenDB(Conn)
RS.Activeconnection = Conn

WShift = Request("WShift")

%>

<html>

<head>
<title>S3 - Sale scadar</title>

<LINK REL=STYLESHEET HREF="../Include/S3.css" type="text/css">

<script language="javascript" src="../Include/utils.js"></script>

<script language="javascript">
function s3trlaunch() {
	var f=document.bosfrm;
	var qty1=removeSepr(f.invqty.value);
	if(!isNumeric(qty1)){
		alert('Lít / tiền sai định dạng số!');
		return false;
	}
	var trtype=f.invtr.value;
	var openW=950;
	if(trtype=='412' || trtype=='411') {
		openW=1120;
	}
	ajdia('../TRX/S3Tran.aspx?tt='+trtype+'&WShift='+WSID+'&pr='+escape(f.invpr.value)+'&qty='+qty1, 'S3trW',openW,500);
}

function s3wsview(ws){
	ajPage('S3WSSum.aspx?ws='+ws,s3wsviewRet);
}

function s3wsviewRet(http){
	var disp=g_tag('S3sumdiv');
	disp.style.display='block';
	disp.style.top='34px';
	disp.style.left='400px';
	disp.innerHTML=http.responseText;
	g_tag('S3pumpgrp').style.display='none';
}

function s3wsviewclose(){
	g_tag('S3sumdiv').style.display='none';
}

function s3wsviewtran(ws,searchstr){
	ajPage('S3WSTrans.aspx?ws='+ws+'&searchstr='+_formval2NCR(searchstr),s3wsviewRet);
}

function s3logview(ws){
	ajdia('../RPT/RPT.aspx?id=S3Logs&ws='+ws,'S3logviewW',790,520);
}

function s3logview1(p, ws){
	ajdia('../RPT/RPT.aspx?id=S3Logs&pumpid='+p+'&ws='+ws,'S3logviewW',790,520);
}

function s3debug(){
	var disp=g_tag('S3PCEstatus');
	if(disp.style.display=='none') disp.style.display='block';
}

function s3debugclose(){
	g_tag('S3PCEstatus').style.display='none';
}

function s3tredit(id, ws) {
	ajdia('../TRX/Tr.aspx?id=' + id + '&noheader=on&&WShift=' + ws, 's3treditW', 950, 450);
}

function detachview(url,win,w,h){
	ajdia(url, win, w, h);
}

function showpumpgrp(){
	g_tag('S3pumpgrp').style.display='block';
	g_tag('S3sumdiv').style.display='none';
}

function closepumpgrp(){
	g_tag('S3pumpgrp').style.display='none';
}

function changepumpgrp(grp){
	ajPage('S3ChangePumpGroup.aspx',changepumpgrpRet, 'grp=' + grp);
}

function changepumpgrpRet(http){
	if (http.responseText!='')
		alert(http.responseText);
	else
		location.reload();
}

function s3wsviewpayment(ws){
	var disp=g_tag('S3sumdiv');
	disp.style.display='block';
	var a1 = g_tag("viewPayment");
	disp.style.top = (elmTop(a1) + a1.offsetHeight) + "px";
	disp.style.left = (elmLeft(a1) - disp.offsetWidth + a1.offsetWidth) + "px";
	g_tag('S3pumpgrp').style.display='none';
}

function s3wsviewpaymentRet(http){
}

var card_capture=false;
var currPump = -1;
var currPumpId = -1;
var currCardNo='';
//var lastobjfocus=null;
//var lastobjval;

function cardread(e){
	if (!e) var e=window.event;
	var kc=ekeyCode(e);
	var a=g_tag('card_place');

	if(e.shiftKey && kc==53){
		cancel_bubble(e);
		g_tag('card_slide').style.display='inline';
		a.innerHTML='';
		a.style.display='none';
		
		//lastobjfocus=document.activeElement;
		//lastobjval=lastobjfocus.value;

		//setTimeout(function() {g_tag('card_img').focus()}, 15);
		
		card_capture=true;
		setTimeout('cardvalidate()',600); // 600ms for card read stream input
		//a.innerHTML  = 'S62015000000018888¿º2015000000018888»12122016';
		//lastobjfocus.disabled=true;
	}
	else if(card_capture) {
		cancel_bubble(e);
		if(kc>31) a.innerHTML += String.fromCharCode(kc);
	}
}
document.onkeydown = cardread;

function cardvalidate(){
	ajPage('S3cardValidate.aspx',cardvalidateRet,'ct='+g_tag('card_place').innerHTML);
}

function cardvalidateKB(){
	//cardKBswitch();
	//g_tag('cardkeyboard').value='';
	g_tag('card_slide').style.display='inline';
	ajPage('S3cardValidate.aspx',cardvalidateRet,'ct='+g_tag('cardkeyboard').value+'&manual=on');
}


function cardvalidateRet(http){
	var b=g_tag('card_place');
	b.style.display='inline';
	b.style.color='#000066';
	var str=http.responseText;
	b.innerHTML=str + " <img src='../img/closeW.gif' class='imggo' onclick='cardClear()'>";
	if(str.indexOf(': ')>0) currCardNo=str.substring(0,str.indexOf(': '));
	card_capture=false;
	//setTimeout(function() {lastobjfocus.focus()}, 15);
}

function cardClear(){
	g_tag('card_slide').style.display='none';
	currCardNo='';
}

function usecard(){
	currCardNo='';
	g_tag('card_place').style.color='#CCCCCC';
}

function refreshbocard(pumpid,pumptt){
	//sendPCEreq('S3MgrStatus.aspx',loaddisplayRet,s3statusparams(pumpid,pumptt,'<%=CMD_S3_PUMP_JOB_STATUS%>',<%=WShift%>));
	showcardClose();
}

function showcardClose(){
	var a=g_tag('showcarddiv');
	a.style.background='#E6E6E0';
	a.style.display='none';
}

function cardunassign(logI){
	if(confirm('Hủy số thẻ cho giao dịch này?'))
		ajPage('S3CardUnAssign.aspx',cardunassignRet,'logI=' + logI);
}

function cardunassignRet(http){
	var pumpid=http.responseText;
	refreshbocard(pumpid,searchpumptt(pumpid));
}

function currPumpDisp(pumptt,pumpid){
	if(currPump>=0)
		g_tag('inputtable'+currPump).style.background='white';
	
	currPump = pumptt;
	currPumpId = pumpid
	g_tag('inputtable'+currPump).style.background='#E6E6E0';
}

function cardKBswitch(){
	var kbi=g_tag('cardkeyboard');
	if(kbi.style.display=='none'){
		kbi.style.display='inline';
		g_tag('card_imgKB').src='../img/card_icon.png';
		kbi.focus();
	}
	else{
		kbi.style.display='none';
		g_tag('card_imgKB').src='../img/card_iconBW.png';
	}
}
</script>

</head>

<body onkeyDown="escPage(event)">
<div id='showcarddiv' style='position:absolute;display:none;background:#E6E6E0;color:black;border:#449 solid 1px;padding:3px'></div>
<div id='showbarcodediv' style='position:absolute;display:none;background:#E6E6E0;color:black;border:#449 solid 1px;padding:3px'></div>
<div id='showpaymethoddiv' style='position:absolute;display:none;background:#E6E6E0;color:black;border:#449 solid 1px;padding:3px'></div>
<div id='card_slide' style='position:absolute;top:4px;left:220px;display:none;background:#CCF;border-top:#66A solid 4px;padding:2px'>
	<img src='../img/card_icon.png' align='absmiddle'>
	<div id='card_place' style='font-weight:bold'></div>
</div>

<div id='S3sumdiv' style='position:absolute;background:#e6e6e0;color:black;display:none;border:2px solid #334;border-radius:0px 0px 8px 8px;padding:6px'></div>
<div id='S3PCEstatus' style='position:absolute;top:34px;left:473px;width:400px;background:#000;border:2px solid #334;border-radius:0px 0px 8px 8px;padding:2px'>
<table width='100%'><tr><td id='renderstatus' valign='top' style='color:#4C4'><td align='right' valign='top'><img src='../Img/closeW.gif' class='imggo' onclick='s3debugclose()'></table>
</div>
<div id='S3pumpgrp' style='position:absolute;display:none;top:34px;left:495px;width:200px;background:#f0f0e6;border:2px solid #334;border-radius:0px 0px 8px 8px;padding:1px;'>
</div>

<!--<div id='debugpanel'></div>-->
<table width='100%' cellpadding=2 class='hdrbar'><tr>
<td nowrap width='440'>
<a href='AboutS3.html' target='aboutS3W'><font class='pagetitle'>CH <%=Right$(Session("U_POSNAME"),3)%></font></a>
<img id='PauseAll' style='padding-left:6px' src='../img/pause_icon.png' class='imggo' title='Click to pause all pump' onclick='setAllPumpPlay()'>
<%
    Dim viewOnly As Boolean = (getGlobalVar("APPLOCATION")<>"POS") OrElse (Request("viewonly")="on")

    Dim i,j,k As Integer

    TDHSettings = ReadSysConfig(RS, "TDHSETTINGS")
    ConnectionStr = AYDecompress(TDHSettings)

    TDHSettings = Server.URLEncode(TDHSettings)
	
    SRVSettings = ReadSysConfig(RS, "SRVMGRCONN")
    SRVSettings = AYDecompress(SRVSettings)
	
	Dim SRVInfo() As string = Split$(SRVSettings, TDH_msgSepr)
	SRVSettings = C_TPV_URL
	SRVSettings = Replace(SRVSettings, "[=HOSTIP]", SRVInfo(0))
	SRVSettings = Replace(SRVSettings, "[=HOSTPORT]", SRVInfo(1))
	SRVSettings = Replace(SRVSettings, "[=ACCESSID]", SRVInfo(2))
	SRVSettings = Replace(SRVSettings, "[=ACCESSTOCKEN]", SRVInfo(3))

    Dim WSselectStr As String
    Dim WshiftCnt As Integer
    Dim prevWDate, wDateDOnly As Long
    Dim ws1 As Long = -1
    Dim tmpSQL As String
	
    '// get discount and also list of products
    RS.Open("Select FK, Dis, P.C, P.N From ProductDis Inner Join MD.P On FK=P.I Where SaleChannel=1 And POS=" & Session("U_POS") & " Order By P.C")
    While Not RS.EOF
        DisProductCnt += 1
        DisProductFKs(DisProductCnt) = RS("FK").Value
        DisProductAmts(DisProductCnt) = RS("Dis").Value
        DisProductCodes(DisProductCnt) = StrNull(RS("C").Value)
        DisProductNames(DisProductCnt) = StrNull(RS("N").Value)
        RS.MoveNext
    End While
    RS.Close

    '// determine cols, rows. Sysparams: C=PumpTDHID; SysValue=row,col; paramClass=6
    Dim rowEnd, colEnd, row, col, priceoff As Integer
    Dim pumps(8,16) As Integer '// array of TDHID
    Dim pumpNames(8,16) As String
    Dim productIs(8,16) As Long
    Dim productNames(8,16) As String
    Dim dispWidths(8,16) As Integer
    Dim dispHeights(8,16) As Integer
    Dim Prices(8,16) As Double
    Dim DispKinds(8,16) As Integer
    Dim KindColSpans(8,16) As Integer
    Dim KindRowSpans(8,16) As Integer
    Dim DefaultPaids(8,16) As Integer
    Dim JobsTodisplays(8,16) As Integer
    Dim JobsToInserts(8,16) As Integer
    Dim PumpfontSizes(8,16) As Integer
    Dim ProductColors(8,16) As String
    Dim PlayStatuss(8,16) As Integer
    Dim printIPs1(8,16) As String
    Dim POSIPs1(8,16) As String
    Dim BankSrvs1(8,16) As String
	Dim PumpSeris1(8,16) As String
	Dim StationNos1(8,16) As String
	Dim pfullName1(8,16) As String
    Dim stmp As String
    Dim pumpgrpTail As String

    If Session("S3_U_PumpGrp")="" OrElse Session("S3_U_PumpGrp")="-1" Then
        pumpgrpTail = " And RenderKind>0"
    Else
        pumpgrpTail = " And RenderKind=" & Session("S3_U_PumpGrp")
    End If

    Dim priceSQL_ As String = "Where srcID=-1 And dstId=(Select GRP From POS Where I=" & session("U_POS") & ") And T='PC1' And D<=" & SQLGetDate()
    Dim priceSQL As String = _
            "Select TPrice.waterId, TPrice.i7 As Price From TPrice Inner Join " & _
            "(Select waterID, Max(D) As MD From TPrice " & priceSQL_ & " Group By waterID) MaxDate " & _
            "On TPrice.D=MaxDate.MD And TPrice.waterID=maxDate.waterID " & _
            priceSQL_

    RS.Open("Select Pump.TDHID, Disprow, Dispcol, Coalesce(PumpDispTitle,Pump.C) As PumpC, Tank.P As ProductI, Coalesce(ProductDispTitle,P.N) As ProductN, Coalesce(DispColor,P.CommonCode) As ProductColor, Price, " & _
            "Coalesce(DispWidth," & PUMP_DEFAULT_WIDTH & ") As DispW, Coalesce(DispHeight," & PUMP_DEFAULT_HEIGHT & ") As DispH, " & _
            "Coalesce(KindColspan,1) As colspan1, Coalesce(Kindrowspan,1) As rowspan1, " & _
            "DefaultPaid, Coalesce(JobsTodisplay,5) As JobLines, Coalesce(JobsToWait,3) As JobInserts, Coalesce(fontsize,14) As pumpfontsize, " & _
            "coalesce(playStatus, 0) As playStatus, Coalesce(T5.PrintIP,'') As PrintIP, Coalesce(T5.POSIP,'') As POSIP, Coalesce(T5.BANKSVR,'') As BANKSVR, Coalesce(Pump.Seri, '') As PumpSeri, P.N As pFullName, Pump.StationNo " & _
            "From S3Config " & _
            "Inner Join Pump On S3Config.FK=Pump.I " & _
            "Inner Join Tank On Tank=Tank.I " & _
            "Inner Join MD.P On Tank.P=P.I " & _
			"Left Join CHXD.S3MCfg T5 On Coalesce(S3Config.RenderKind, 0)=T5.C " & _
            "Inner Join (" & priceSQL & ") Pricing On Tank.P=Pricing.waterid " & _
            "Where S3Config.POS=" & Session("U_POS") & _
            pumpgrpTail & _
            " And DispKind=1 Order By Pump.TDHID")

    While Not RS.EOF
        row = RS("Disprow").Value
        col = RS("Dispcol").Value
        priceoff = searchDisProduct(RS("ProductI").Value,RS("Price").Value)
        pumps(row,col)=RS("TDHID").Value
        pumpNames(row,col)=RS("PumpC").Value
        productIs(row,col)=RS("ProductI").Value
        productNames(row,col)=RS("ProductN").Value
        productColors(row,col)=RS("ProductColor").Value
        printIPs1(row,col)=RS("PrintIP").Value
        POSIPs1(row,col)=RS("POSIP").Value
        BankSrvs1(row,col)=RS("BANKSVR").Value
		PumpSeris1(row,col)=RS("PumpSeri").Value
		StationNos1(row,col)=RS("StationNo").Value
		pfullName1(row,col)=RS("pFullName").Value
        Prices(row,col)=CDbl(RS("Price").Value)-priceoff
        If row > rowEnd Then rowEnd = row
        If col > colEnd Then colEnd = col

        dispWidths(row,col)=RS("dispW").Value
        dispHeights(row,col)=RS("dispH").Value

        DispKinds(row,col)=1 '// this is pump, equal pumps(row,col)<>""
        If Not IsDbNull(RS("DefaultPaid").Value) Then
            DefaultPaids(row,col)=1
        Else
            DefaultPaids(row,col)= 0
        End If
        JobsTodisplays(row,col)=RS("JobLines").Value
        JobsToInserts(row,col)=RS("JobInserts").Value
        PumpfontSizes(row,col)=RS("pumpfontsize").value

        KindColSpans(row,col)=RS("colspan1").Value
        KindRowSpans(row,col)=RS("rowspan1").Value

        PlayStatuss(row,col)=CDblNull(RS("playStatus").Value)
        RS.MoveNext
    End While
    RS.Close	
    Response.Write (" &nbsp; &nbsp; <font class='pagetitle'><a id='chooseWS' href=""javascript:getListWS()"" Title=""Đổi sang ca khác"">Chon ca<a/></font>")
    stmp = "<table width='100%'><tr><td valign='top'><table><tr><td>• <a href='javascript:changepumpgrp(-1)'>[All]</a></td></tr>"

    RS.Open ("Select Distinct RenderKind From S3Config Where POS=" & Session("U_POS") & " And RenderKind>0")
    While Not RS.EOF
        stmp &= "<tr><td>• <a href='javascript:changepumpgrp(" & RS(0).value & ")'>Nhóm vòi bơm " & RS(0).value & "</a></td></tr>"
        RS.MoveNext
    End While
    RS.Close

    stmp &= "</table><td valign='top' align='right'><img src='../img/closeW.gif' class='imggo' onclick='closepumpgrp()'></table>"
    Response.Write("<script language='javascript'>g_tag('S3pumpgrp').innerHTML=""" & stmp & """;</script>")

    '// Get col, row separator
    RS.Open("Select Disprow, Dispcol, Coalesce(ProductDispTitle,'&nbsp;') As Title2, " & _
            "DispKind, Coalesce(KindColspan,1) As colspan1, Coalesce(Kindrowspan,1) As rowspan1, Coalesce(DispWidth,40) As DispW, Coalesce(DispHeight,40) As DispH " & _
            "From S3Config " & _
            "Where S3Config.POS=" & Session("U_POS") & _
            pumpGrpTail & _
            " And DispKind<>1")

    While Not RS.EOF
        row = RS("Disprow").Value
        col = RS("Dispcol").Value
        If row > rowEnd Then rowEnd = row
        If col > colEnd Then colEnd = col

        dispWidths(row,col)=RS("dispW").Value
        dispHeights(row,col)=RS("dispH").Value
        KindColSpans(row,col)=RS("colspan1").Value
        KindRowSpans(row,col)=RS("rowspan1").Value

        productNames(row,col)=RS("title2").Value

        DispKinds(row,col)=RS("DispKind").Value '// line or col separator
        RS.MoveNext
    End While
    RS.Close
%>
</a>
&nbsp; &nbsp; &nbsp;
<img id='card_imgKB' src='../img/card_iconBW.png' class='imggo' title='Click to keyboard input' onclick='cardKBswitch()'>
<input id='cardkeyboard' size=18 style='display:none' onkeypress='if(isEnterOnly(event))cardvalidateKB()'>
<td id='websocketstate' nowrap align='center' style='color:white;'>Chờ kết nối...</td>
<td align='right' nowrap>

<form name='bosfrm' onsubmit='return false'>

	<font class='hdrlinksepr'>
	<a href="javascript:showpumpgrp()">Nhóm vòi bơm: <%=Iif(Session("S3_U_PumpGrp")="","All", Session("S3_U_PumpGrp"))%></a> &nbsp; &nbsp; 
	<a href="javascript:s3wsviewtran(WSID,'')" id='logviewplace'>Ctừ xuất</a> &nbsp; &nbsp; 
	<a href='javascript:s3wsview(WSID)' id='logviewplace'>Tổng hợp</a> &nbsp; &nbsp; 
	<a href='javascript:s3logview(WSID)'>S3 Logs</a> &nbsp; &nbsp; 
	<a href='javascript:s3debug(WSID)'>PCE</a> &nbsp; &nbsp; 
	<a href='javascript:reloadConfig()' id='loadS3Cfg'>LOADS3CFG</a> &nbsp; &nbsp; 
	</font>

<% If Request("wsclosed")="" Then %>
<input name='invqty' size=12 value='Lít (tiền > 10000)' onkeypress='if(isEnterOnly(event))document.bosfrm.invpr.focus()' onfocus='thisselect(this)' onChange='this.value=insertSepr(this.value)' class='invselinput'>
<!--&nbsp; hoặc tiền: <input name='invamt' size=9 class='invinput' onkeypress='if(isEnterOnly(event))document.bosfrm.invpr.focus()'>-->
<Select name='invpr' onkeypress='if(isEnterOnly(event))document.bosfrm.invtr.focus()' class='invselinput'>
<%
For i=1 To DisProductCnt
	If DisProductOnSales(i) Then
		Response.Write("<option value='" & Replace$(DisProductCodes(i) & C_actbSepr & DisProductNames(i), "'","`") & ",>" & DisProductAmts(i) & "'>" & DisProductNames(i) & "</option>")
	End If
Next
%>
</Select>

<Select name='invtr' onkeypress='if(isEnterOnly(event))s3trlaunch()' class='invselinput'>
	<option value='401'>Hóa đơn vãng lai TIỀN MẶT</option>
	<option value='406'>Hóa đơn vãng lai THU THẺ</option>
	<option value='412'>Xuất công nợ CHƯA hóa đơn</option>
	<option value='411'>Xuất công nợ KIÊM hóa đơn</option>
</Select>

<!--<input type='button' value=' > ' onclick='s3trlaunch()'>-->
<img src='../img/go.gif' class='imggo' title='Xuất hóa đơn' onclick='s3trlaunch()'>

<% Else %>
<td style='width:446px'>&nbsp;</td>
<% End If %>

</form>
</table>

<table class='hdrbarlow' width='100%'><tr>
<td align='right' valign='top' nowrap>
<%
For i=1 To DisProductCnt
	If DisProductOnSales(i) Then
		If i>1 Then Response.Write ("&nbsp; - &nbsp;")
		Response.Write(DisProductNames(i) & ": <b>" & DisProductPrices(i) & "</b>đ")
	End If
Next
%>
</td></tr>
</table>

<%

'Dim pumplayout As String = "<table cellspacing=4 cellpadding=0><tr><td>[=1.1]<td>[=1.2]<td>[=1.4]<td>[=1.5]<tr><td>[=3.1]<td>[=3.2]<td>[=3.4]<td>[=3.5]</table>"
'	For row=1 To rowEnd
'		For col=1 To colEnd
'			If DispKinds(row,col)=1 Then
'				pumplayout = Replace$(pumplayout,"[=" & row & "." & col & "]", pumpRender(pumps(row,col), pumpNames(row,col), productIs(row,col), productNames(row,col), Prices(row,col),(Request("wsclosed")=""), dispWidths(row,col), dispHeights(row,col), JobsTodisplays(row,col), JobsToInserts(row,col), DefaultPaids(row,col), PumpfontSizes(row,col)))
'			End If
'		Next
'	Next
%>
<%'pumplayout%>
<%

Dim sameRowHasColSpan As Boolean

'// Draw pumps
Response.Write ("<table border=0 cellspacing=4 cellpadding=0>")
For row=1 To rowEnd
	Response.Write("<tr>")
	For col=1 To colEnd
		sameRowHasColSpan = False
		Select Case DispKinds(row,col)
		Case 1
			Response.Write("<td valign='top' colspan=" & KindColSpans(row,col) & " rowspan=" & KindRowSpans(row,col) & ">" & _
				pumpRender(pumps(row,col), pumpNames(row,col), productIs(row,col), productNames(row,col), Prices(row,col),(Request("wsclosed")=""), dispWidths(row,col), dispHeights(row,col), JobsTodisplays(row,col), JobsToInserts(row,col), DefaultPaids(row,col), PumpfontSizes(row,col), productColors(row,col), PlayStatuss(row,col), (Not viewOnly), PrintIPs1(row,col), POSIPs1(row,col), BankSrvs1(row,col), PumpSeris1(row,col), pFullName1(row,col), StationNos1(row,col)))
			'//Response.Write("</td><script language='javascript'>g_tag('renderstatus').innerHTML += 'Contacting PCE on Pump " & pumpNames(row,col) & " ...<br>';</script>")
			Response.Flush()
		Case 2
			Response.Write ("<td rowspan=" & KindRowSpans(row,col) & " width=" & dispWidths(row,col) & ">" & productNames(row,col))
		Case 3
			Response.Write ("<td colspan=" & KindColSpans(row,col) & " height=" & dispHeights(row,col) & ">" & productNames(row,col))
			sameRowHasColSpan = True
		Case -1
			'// Nothing
		Case Else 
			If Not sameRowHasColSpan Then Response.Write("<td>")
		End Select
	Next
	Response.Write("</tr>")
Next
Response.Write ("</table>")

%>

<script language='javascript'>
var timetocheck = 5; //5 minutes to check online s3
var checkonline = setTimeout(function () { s3checkonline(); }, timetocheck * 1000 * 60);
function s3checkonline() {
	ajPage("S3CheckOnline.aspx", s3checkonlineRet, "", null);
	function s3checkonlineRet(http) {
		if (http) {
			var str = http.responseText;
			if (str == "0") {
				location.reload();
			}
		}
	}
	checkonline = setTimeout(function () { s3checkonline(); }, timetocheck * 1000 * 60);
}

g_tag('S3PCEstatus').style.display='none';

var RET_ERROR_ID = "@ERROR(";
var iswsopen=true;
var isviewonly=<%=Iif(viewonly,"1","0")%>;
if(isviewonly) g_tag('renderstatus').innerHTML='';

function sendPCEreq(url, func, params){
	if (!isviewonly) g_tag('renderstatus').innerHTML='SENT: ' + params.substring(params.indexOf('CMD='),params.indexOf('pumptt=')-1);
	ajPage(url, func, params);
}

<%=iif(Request("wsclosed")="1","iswsopen=false;","")%>

function s3statusparams(pumpid,pumptt,CMD,ws){
	function ispumpenable(pumptt){
		return '&pumpenable='+(pumponoffs[pumptt] ? (jobplays[pumptt] ? 1:0):0) + '&pumponoff='+(pumponoffs[pumptt] ? 1:0);
	}
	return 'conn=<%=TDHSettings%>&sKey=<%=Session.SessionID%>&CMD='+CMD+'&pumpid='+pumpid+'&pumptt='+pumptt+ispumpenable(pumptt)+'&viewonly='+isviewonly+'&ws='+ws+'&maxlines='+maxjoblines[pumptt]+'&defaultpaid='+jobdefaultpaids[pumptt]+'&insertlines='+maxjobinserts[pumptt]+'&jsw='+jswidths[pumptt]+'&pfontsize='+jsfontsizes[pumptt];
}

function searchpumptt(pumpid){
	for(var i=0;i<jspumpids.length;i++) {
		if(jspumpids[i]==pumpid) {
			return i;
			break;
		}
	}
}

function changepaidstatus(logI,pumpid,amt,ws){
	var pumptt=searchpumptt(pumpid);
	sendPCEreq('S3MgrStatus.aspx',loaddisplayRet,s3statusparams(pumpid,pumptt,'<%=GUI_S3_PAID_STATUS_CHANGE%>',ws)+'&logI='+logI);
}

function debugmsg(msg){
	s3debug();g_tag('renderstatus').innerHTML += "<br><font color='red'>" + msg + "</font>";
}

function s3debugmsg(msg){
	s3debug();g_tag('renderstatus').innerHTML = "<br><font color='red'>" + msg + "</font>";
}

<% If jsPumpCnt>0 Then %>

var pumpcnt=<%=jsPumpCnt%>;
var pumponoffs =[<%=RemoveLastChar(jspumponoffs)%>];
var jspumpids =[<%=RemoveLastChar(jspumpids)%>];
var jspumppendings =[<%=RemoveLastChar(jspumppendings)%>];
var jobplays =[<%=RemoveLastChar(jobplays)%>];
var maxjoblines =[<%=RemoveLastChar(maxJobLines)%>];
var maxjobinserts =[<%=RemoveLastChar(maxJobInserts)%>];
var jobdefaultpaids =[<%=RemoveLastChar(jobDefaultPaids)%>];
var jswidths = [<%=RemoveLastChar(jsWidths)%>];
var jsfontsizes = [<%=RemoveLastChar(jsFontSizes)%>];
var productcolors = [<%=RemoveLastChar(jsProductColors)%>];
var printIPs = [<%=RemoveLastChar(PrintIPs)%>];
var POSIPs = [<%=RemoveLastChar(POSIPs)%>];
var BANKSRVs = [<%=RemoveLastChar(BANKSRVs)%>];
var PumpSeris = [<%=RemoveLastChar(PumpSeris)%>];
var productNames = [<%=RemoveLastChar(proNames)%>];
var stationNos = [<%=RemoveLastChar(StationNos)%>];
var t_col_W1 = 47;
var t_col_W2 = 80;
var t_col_W3 = 115;
var t_col_W4 = 20;
var t_col_W5 = 16;
var t_col_W6 = 25;
var Yfactor = 35942400;
var MFactor = 2764800;
var DFactor = 86400;
var HFactor = 3600;
var NFactor = 60;
var YearMedium = 1976;
var WSID=-1, WSDesc="Chọn ca";
var curPumpGrp = '<%=Session("S3_U_PumpGrp")%>';

//var _ldtimer = setTimeout('loaddisplay()',500); // first fire in 0.5 second

var pumpcycle=0,timercycle=0;

//if(pumponoffs[i] && jspumppendings[i]>0) {
//IF user set pump S3-disable but there are still jobs pending THEN refresh status only
//isviewonly only reads from DB

function loaddisplay(){
	//if(jspumppendings[pumpcycle]>0 || isviewonly) {
	//	sendPCEreq('S3MgrStatus.aspx',loaddisplayRet,s3statusparams(jspumpids[pumpcycle],pumpcycle,'<%=CMD_S3_PUMP_JOB_STATUS%>',<%=WShift%>));
	//}
    //Allways to check pump status
    sendPCEreq('S3MgrStatus.aspx',loaddisplayRet,s3statusparams(jspumpids[pumpcycle],pumpcycle,'<%=CMD_S3_PUMP_JOB_STATUS%>',<%=WShift%>));
	pumpcycle++;
	if(pumpcycle==pumpcnt) {pumpcycle=0;timercycle++;if(timercycle>2000)location.reload();}
	
	// calculate jspumppendings
	// logic: jspumppendings = 0, 1, 2
	// if jspumppendings=2 then cycleDivisor is added more (+3)
	
	var cycleDivisor=0,cyclestep=1000; //1 second default
	for(var i=0;i<pumpcnt;i++){
		cycleDivisor += jspumppendings[i];
		if(jspumppendings[i]==2) cycleDivisor++;
	}
    if (cycleDivisor > 0) {
        cyclestep = Math.round(<%=C_Display_Rfr_Time%>/cycleDivisor);
		if (cyclestep <<%=C_PCE_Min_Time%>) cyclestep =<%=C_PCE_Min_Time%>;
    } else {
        cyclestep=<%=C_PCE_Min_Time%>;
    }
	if(_ldtimer) clearTimeout(_ldtimer);
	_ldtimer = setTimeout('loaddisplay()',cyclestep);
}
function loaddisplayRet(http){
	var str=http.responseText;
	if(str=='0'){alert('Login Expired');location.reload();return;}
	if(str.substring(0,2)=='-1') {
		debugmsg(str.split("<%=PART_SEPR%>")[1]);
		return;
		// jspumppendings is not effected by -1^^ style return
	}
	var r=str.split('<%=PART_SEPR%>');
	jspumppendings[r[0]]=r[1];
	
	g_tag('saledisp'+r[0]).innerHTML=r[2];
	
	switch(r[3]) {
		case '@ERROR(431)':debugmsg("ERROR 431: Duplicated job sending to PCE");break;
		case '@ERROR(434)':debugmsg("ERROR 434: PCE might has been restarted");break;
		case '@ERROR(434).RELOAD':if(confirm('PCE might has been restarted (434). Refresh S3 screen?'))location.reload();break;
		default: if(r[3]!='') debugmsg(r[3]);
	}
	g_tag('renderstatus').innerHTML += r[4];
}


<% End If %>

/*
Socket to server:
*/
var sock = null;

//var wsuri = "ws://10.59.13.57:8000/BHTDSocket?clientId=0&accessToken=EAAFrIE64ZBMIBAP74JwV4Cbfbj9RoSP";
var wsuri = "<%=SRVSettings%>";
if(wsuri==""){
	wsuri = "ws://10.59.254.102:8000/BHTDSocket?clientId=0&accessToken=EAAFrIE64ZBMIBAP74JwV4Cbfbj9RoSP";
}
var reconncnt = 1;
var showplaypause = false;
var confirmSS = false;
var replaystr = " ";
var scadarStr = '{'
				+ '"clientId": 0, '
				+ '"commandCode": "507", '
				+ '"requestData": XXX'
				+ '}';
function WebSocketConnect(){
	if ("WebSocket" in window) {
		try {
			sock = new WebSocket(wsuri);
		}
		catch(err) {}		
	} else if ("MozWebSocket" in window) {
		sock = new MozWebSocket(wsuri);
	} else {
		ShowWebSockMsg("Browser does not support WebSocket!");
		return;
	}
	
	if (!sock){
		document.body.style.cursor='pointer';
		ShowWebSockMsg("Mất kết nối ");
		return;
	}
	
	sock.onopen = function() {
		document.body.style.cursor='pointer';
		ShowWebSockMsg("Đã kết nối ");
		getWShift();
		//setWShift();
		//getAllPumpState();
		//sendMsg(scadarStr);
	}

	sock.onclose = function(e) {
		//ShowWebSockMsg("Server is disconnected ");
		replaystr = "." + replaystr;
		reconncnt += 1;
		ShowWebSockMsg("Chờ kết nối" + replaystr);
		if(reconncnt>3){
			replaystr = " ";
			reconncnt = 1;
		}
		sock = null;
		/*Reconnect to server in 1 second/loop */
		setTimeout(function(){ WebSocketConnect();}, 1000);
	}

	sock.onerror = function(err) {
		ShowWebSockMsg(err);
		sock.close();
	}

	sock.onmessage = function(e) {
		if(e.data){
			var obj = JSON.parse(e.data);
			//alert(obj.commandCode);
			switch (obj.commandCode){
				case "502":
					/*
					** Check pump state:
					*/
					if(obj.responseCode=="00"){
						var pumptt = parseInt(obj.responseData.TDHIndex);
						pumponoffs[pumptt] = !obj.responseData.pumpState;
						setpumpRet(pumptt, "");
						jobplays[pumptt] = !obj.responseData.pumpPlayState;
						setjobplayRet(pumptt, "");
					}else{
						console.log(obj.responseCode);
					}
					break;
				case "503":
					/*
					** Result: Gửi lệnh bán hàng
					*/
					if(obj.responseCode=="00"){
					}else{
						console.log(obj.responseCode);
					}
					break;
				case "505":
					/*
					** Result: Gửi lệnh bán hàng
					*/
					if(obj.responseCode=="00"){
						var pumptt = parseInt(obj.responseData.TDHIndex);
						cmdcancelRet(pumptt, "");
					}else{
						console.log(obj.responseCode);
					}
					break;
					
				case "506":
					/*
					** Result: Bật tắt chế độ vòi bơm
					*/
					if(obj.responseCode=="00"){
						var pumptt = parseInt(obj.responseData.TDHIndex);
						setpumpRet(pumptt, "");
					}else if(obj.responseCode=="06"){
						s3debugmsg("Không tắt được vòi bơm khi đang có lệnh!");						
					}
					break;
					
				case "507":
					/*
					** Dữ liệu màn hình scadar:
					*/
					if(obj.responseCode=="00"){
						console.log(obj.responseData);
						getWShift();
						showplaypause = obj.responseData.ShowPlayPause;
						confirmSS = obj.responseData.ConfirmSS;
						setPlayPauseAll(obj.responseData.IsAllPlaying);
						var recCnt = parseInt(obj.responseData.RecordCounts);
						if(recCnt>0){
							dispAllPump(obj.responseData.ListData, curPumpGrp);
						}else{
							clearAllPumpDisp(obj.responseData.ListData, curPumpGrp);
						}							
					}else{
					}
					break;
				case "508":
					if(obj.responseCode=="00"){
						console.log(obj);
					}else{
						console.log(obj.responseCode);
					}
				case "509":
					/*
					** Thiết đặt ca bán hàng:
					*/
					if(obj.responseCode=="00"){
						console.log(obj);
						WSID = obj.responseData.wShiftId;
						WSDesc = obj.responseData.wShiftName;
						g_tag("chooseWS").innerHTML = WSDesc;
					}else{
						console.log(obj.responseCode);
					}
					break;
				case "510":
					if(obj.responseCode=="00"){
						var pumptt = parseInt(obj.responseData.TDHIndex);
						setjobplayRet(pumptt, "");
					}else{
						console.log(obj.responseCode);
					}
					break;
				case "512":
					if(obj.responseCode=="00"){
						location.reload();
					}else{
						console.log(obj.responseCode);
					}
					break;
				case "514":
					if(obj.responseCode=="00"){
						//location.reload();
						//console.log(obj);
						WSID = obj.responseData.wShiftId;
						WSDesc = obj.responseData.wShiftName;
						g_tag("chooseWS").innerHTML = WSDesc;
						
					}else{
						//console.log(obj.responseCode);
					}
					break;
				case "515":
					//alert(obj.responseCode);
					if(obj.responseCode=="00"){
					}else{
						console.log(obj.responseCode);
					}
					break;
					
				case "517":
					/*
					** Result: gửi yêu cầu thanh toán tới máy POS
					*/
					console.log("obj.responseData: " + obj.responseData);
					var json517 = JSON.parse(obj.responseData)
					if(json517["code"]=="01"){
						s3debugmsg("Thanh toán POS không thành công! </br> Lệnh bơm chưa kết thúc.");
					}
					else if(json517["code"]=="02"){
						s3debugmsg("Thanh toán POS không thành công! </br> Cấu hình IP máy POS không đúng!");
					}
					else if(json517["code"]=="001"){
						s3debugmsg("Thanh toán POS thành công! </br> Lỗi cập nhật database");
					}
					else if(json517["code"]!="00"){
						s3debugmsg("Thanh toán POS không thành công! </br> Lỗi: " + json517["code"] + " - " + json517["message"]);
					}
					/*else if(json517["code"]=="00"){
						s3debugmsg("Thanh toán POS thành công!");
					}
					*/

					break;
				case "521":
					if(obj.responseData["message"] != "SUCCESSFUL") {
						s3debugmsg(obj.responseData["description"]);
					}					
					break;
				case "522":
					if(obj.responseData["message"] != "SUCCESSFUL") {
						s3debugmsg(obj.responseData["description"]);
					}
					break;
				default:
					console.log(obj.commandCode);
			}
			document.body.style.cursor='pointer';
		}
	}
}

/*
** sendMsg	: Gửi lệnh sang ServerManager
** str		: Chuỗi lệnh yêu cầu
*/
function sendMsg(str) {
	if (sock) {
		document.body.style.cursor='wait';
		sock.send(str);
	} else {
		alert("Server is disconnected.");
	}
};

/*
** ShowWebSockMsg	: Hiển thị message của websocket
** str				: Chuỗi hiển thị
*/
function ShowWebSockMsg(str){
	g_tag("websocketstate").innerHTML = str;
}

/*
** setPumpDisp	: Set pump display
** str			: Pump display content
*/
function setPumpDisp(pumptt, str){
	g_tag("saledisp" + pumptt).innerHTML = str;
}

/*
** setPumpDisp	: Set All Pump Pause/Play
** str			: Pump display content
*/
function setPlayPauseAll(IsAllPlaying){
	if(!IsAllPlaying)
		document.images['PauseAll'].src='../img/play_icon.png';
	else
		document.images['PauseAll'].src='../img/pause_icon.png';
}
/*
** clearAllPumpDisp: Xóa thông tin scadar tất cả vòi bơm
*/
function clearAllPumpDisp(objData, pumpgrp){
	var pumpIsShow = false;
	var grppump;
	objData.forEach(function(itm){
		var pumptt = getPumpTT(itm.TDHID);
		grppump = '' + itm.PumpGroup;
		pumpIsShow = (pumpgrp=="" || pumpgrp=="-1" || pumpgrp==grppump)
		
		if(pumpIsShow){
			pumponoffs[pumptt] = !itm.PumpEnable;
			setpumpRet(pumptt, "");
			jobplays[pumptt] = !itm.PumpPlay;
			setjobplayRet(pumptt, "");
		}
	});
	for(var kk=0; kk<pumpcnt; kk++){
		setPumpDisp(kk, "");
	}
}

/*
** dispAllPump	: Hiển thị thông tin tất cả vòi bơm
** objData 		: JSon data
*/
function dispAllPump(objData, pumpgrp){
	//console.log(objData);
	var pumptt;
	var grppump;
	var pumpIsShow = false;
	objData.forEach(function(itm){
		pumpIsShow = false;
		pumptt = getPumpTT(itm.TDHID);
		grppump = '' + itm.PumpGroup;
		pumpIsShow = (pumpgrp=="" || pumpgrp=="-1" || pumpgrp==grppump)
		if(pumpIsShow){
			pumponoffs[pumptt] = !itm.PumpEnable;
			setpumpRet(pumptt, "");
			jobplays[pumptt] = !itm.PumpPlay;
			setjobplayRet(pumptt, "");
			
			//alert(pumptt);
			var pumpStr = "";
			var hh = 0;
			var qty = 0;
			var amt = 0
			if(itm.RecordCount>0){
				pumpStr += "<table style='color:black;font-size:" + jsfontsizes[pumptt] + "'>";
				itm.Data.forEach(function(itm1){
					hh++;
					if(hh>maxjoblines[pumptt]) return;
					switch(itm1.JobState){
						case 1:
							pumpStr += "<tr style='background:#FC0;color:#000;font-weight:bold'>";
							break;
						case 2:
							pumpStr += "<tr style='background:#4F0;color:#000;font-weight:bold'>";
							break;
						case -2:
							pumpStr += "<tr style='background:#999;color:#4F0;font-weight:bold'>";
							break;
						case 3:
							pumpStr += "<tr style='color:#999'>";
							break;
						case -1:
							// pending canceled
							pumpStr += "<tr style='color:red'>";
							break;
						case -9:
							// pre canceled
							pumpStr += "<tr style='color:red'>";
							break;						
						case -4:
							// @ERROR(432), PCE không tìm thấy lệnh
							pumpStr += "<tr style='color:blue;font-weight:bold'>";
							break;
						case -7:
							/*Xử lý lỗi -4, không tìm thấy dữ liệu Agas --> -7*/
							pumpStr += "<tr style='color:red;font-weight:bold'>";
							break;
						default:
							pumpStr += "<tr>"
					}
					
					if (itm1.JobState==1 || itm1.JobState==0 || itm1.JobState==-5){
						qty = itm1.cmdQty;
						amt = itm1.cmdAmt;
					}else{
						qty = itm1.retQty;
						amt = itm1.retAmt;
					}
					
					/*function showcard(pumptt,logI,pumpid,x1,lineN){*/
					if(itm1.CardNumber == ""){
						itm1.CardNumber = null;
					}
					pumpStr += "<td align='center' width='" + t_col_W4 + "'><img src='../img/" + (itm1.CardNumber!=null && itm1.CardNumber!=""?"card_Sicon":"card_SiconBW") + ".png' class='imggo' title='" + itm1.PAYID + "|" + itm1.S3ID + "' onclick='showcard(" + (itm1.CardNumber!=null && itm1.CardNumber!=""?pumptt:-1) + "," + itm1.S3ID + "," + itm1.PAYID + "," + itm.TDHID + "," + itm1.JobState + "," + itm1.cmdAmt + "," + hh + ", " + itm1.CardNumber + ", " + itm1.discount + " )'>";
					switch(itm1.T){
						case 1:
							//QRTrace
							pumpStr += "<td align='center' width='" + t_col_W4 + "'><img src='../img/S3QRCode.png' class='imggo' />";
							break;
						case 2:
						case 7:
							//BankCard
							pumpStr += "<td align='center' width='" + t_col_W4 + "'><img src='../img/bcard1.jpg' class='imggo' />";
							break;
						case 4:
						case 6:
							//Momo Success
							pumpStr += "<td align='center' width='" + t_col_W4 + "'><img src='../img/momo-success.png' class='imggo'  />";
							break;
						case 5:
							//Momo Fail (TDHID, REQAmt, PAYID, S3ID, JobState, PAYRefNo)
							pumpStr += "<td align='center' width='" + t_col_W4 + "'><img src='../img/momo-fail.png' class='imggo' onclick='revertMomo(" + itm1.TDHID + ", " + itm1.REQAmt + "," + itm1.PAYID + ", " + itm1.S3ID + ", " + itm1.JobState + ", " + itm1.PAYRefNo + ")' />";
							//pumpStr += "<td><img src='../img/momo-fail.png' class='imggo' />";							
							break;
						default:
							//Cash
							pumpStr += "<td align='center' width='" + t_col_W4 + "'><img src='../img/cash1.png' class='imggo' onclick='showPayMethod(" + itm.TDHID + "," + hh + "," + itm1.S3ID + "," + itm1.PAYID + "," + itm1.JobState + "," + amt + ")'/>"							
					}					
					pumpStr += "<td>" + getShortTimeStr(itm1.cmdTime); //cmdTime
					pumpStr += "<td align=right width='" + t_col_W2 + "'>" + NumFM(jsformat(qty, 2), ","); //retQty
					pumpStr += "<td align=right width='" + t_col_W3 + "'>" + NumFM(jsformat(amt, 0), ","); //retAmt
					pumpStr += "<td width='" + t_col_W4 + "' style='background:white;font-weight:normal'><a href='javascript:setPaidState(" + itm1.TDHID + "," + itm1.S3ID + "," + itm1.PAYID + "," + itm1.JobState + "," + (itm1.PAYState==1? "0)'><font color='#999999'>&#10003": "1)'><font color='#22AA00'><b>?</b>") + "</font></a>"; //paid state
					pumpStr += "<td  align='center' width='" + t_col_W4 + "' "; //command exec
					switch(itm1.JobState){
						case -5:
						case 0:
						case 1:
							pumpStr += " style='background:white'><img src='../img/Del.gif' class='imggo' onclick='cmdcancel(" + itm1.S3ID + "," + itm1.TDHID + "," + itm1.cmdAmt + ", 1)' />"
							break;
						case 2:
							pumpStr += " style='background:white'><img src='../img/stop_icon.png' class='imggo' onclick='cmdcancel(\"" + itm1.S3ID + "\"," + itm1.TDHID + "," + itm1.cmdAmt + ", 1)' />"
							break;
						case -2:
							pumpStr += " style='background:white'>";
							break;
						default:
							pumpStr += ">"
					}
				});
				pumpStr += "</table>";
			}
			//console.log(pumptt);
			if(pumpIsShow) setPumpDisp(pumptt, pumpStr);
		}
	});
}

/*
** NumFM:
*/
function NumFM(n,s){
	var str = '' + n;
	return str.replace(/ /g, s);
}

/*
** getShortTimeStr	: get short time string
** d				: aydatetime
*/
function getShortTimeStr(d){
	return '' + DateTimePart(d, "H") + ":" + DateTimePart(d, "N");// + ":" + DateTimePart(d, "S");
}

function DateTimePart(tmp, p1){
	var r;

	switch(p1){
		case "Y":
			r = parseInt(tmp / Yfactor)+YearMedium;
			break;
		case "M":
			r = parseInt((tmp % Yfactor)/MFactor);
			break;
		case "D":
			r = parseInt((tmp % Mfactor)/DFactor);
			break;
		case "H":
			r = parseInt((tmp % DFactor)/HFactor);
			break;
		case "N":
			r = parseInt((tmp % HFactor)/NFactor);
			break;
		case "S":
			r = parseInt(tmp % NFactor);
			break;
	}

	return r<10?'0' + r: '' + r;
}


/*
** getPumpTT	: Lấy thứ tự vòi bơm 
** pid			: TDHID	
*/
function getPumpTT(pid){
	var kq = -1;
	for(var kk=0; kk<pumpcnt; kk++){
		if (jspumpids[kk]==pid){
			kq = kk;
			break;
		}
	}
	return kq;
}

/*
** setpump	: Thiết đặt chế độ bán hàng của vòi bơm
** pumpid	: TDHID
** pumptt	: Số thứ tự vòi bơm
*/
function setpump(pumpid,pumptt) {
	if(!iswsopen){
		alert('Ca đã đóng!');
		return;
	}
	var cmd1=(pumponoffs[pumptt] ? false : true);	
	var msgStr = '{'
				+ '"clientId": 0, '
				+ '"commandCode": "506", '
				+ '"requestData": {' 
					+ '"TDHID": ' + pumpid + ', '
					+ '"TDHIndex": ' + pumptt + ', '
					+ '"pumpState": ' + cmd1 
					+ '}'
				+ '}';
	sendMsg(msgStr);
}

/*
** setpumpRet	: Kết quả - Thiết đặt chế độ bán hàng của vòi bơm
** pumptt		: Số thứ tự vòi bơm
** str			: Chuỗi thông báo trả về
*/
function setpumpRet(pumptt, str) {
	if (str!="") {
		alert(str);
		return;
	}
	var css1,css4,css5,jobimgbtn;
	if(pumponoffs[pumptt]){
		css1 = '#999';
		css4 = 'saleinputoff';
		css5 = 'displabel1dis';
		imgbtn = 'swap_icon_red.gif';
		jobimgbtn = 'trans_icon.png';
		g_tag('saleamt'+pumptt).readOnly=true;
		g_tag('saleliter'+pumptt).readOnly=true;
	}
	else {
		css1 = productcolors[pumptt];
		css4 = 'saleinputon';
		css5 = 'displabel1';
		imgbtn = 'swap_icon.gif';
		jobimgbtn = 'play_icon.png';
		g_tag('saleamt'+pumptt).readOnly=false;
		g_tag('saleliter'+pumptt).readOnly=false;
		//g_tag('saleamt'+pumptt).focus();
	}
	
	g_tag('pumptable'+pumptt).style.borderColor=css1;
	g_tag('pumphead'+pumptt).style.background=css1;
	g_tag('saleamt'+pumptt).className=css4;
	g_tag('saleliter'+pumptt).className=css4;
	g_tag('inputtable'+pumptt).className=css5;
	document.images['pumpctrl'+pumptt].src='../img/'+imgbtn;
	
	pumponoffs[pumptt] = !pumponoffs[pumptt];
	document.body.style.cursor='default';
	
	document.images['jobctrl'+pumptt].src='../img/'+jobimgbtn;
	jobplays[pumptt] = false; // default = off
}

/*
** getPumpState
*/
function getPumpState(pumpid,pumptt){
	var msgStr = '{'
				+ '"clientId": 0, '
				+ '"commandCode": "502", '
				+ '"requestData": {' 
					+ '"TDHID": ' + pumpid + ', '
					+ '"TDHIndex": ' + pumptt
					+ '}'
				+ '}';
	sendMsg(msgStr);
}

function getAllPumpState(){
	for(var kk=0; kk<pumpcnt; kk++){
		getPumpState(jspumpids[kk], kk);
	}
}
/*
** setjobplay	: Play/Pause chế độ bán hàng của vòi bơm
** pumpid		: TDHID
** pumptt		: Số thứ tự vòi bơm
*/
function setjobplay(pumpid, pumptt) {
	if(!iswsopen){
		alert('Ca đã đóng!');
		return;
	}
	if(!pumponoffs[pumptt]){
		//user click trans.gif
		//alert('Không cho phép play trong trạng thái bán hàng bình thường!');
		return;
	}
	var cmd1=(jobplays[pumptt] ? false : true);	
	var msgStr = '{'
				+ '"clientId": 0, '
				+ '"commandCode": "510", '
				+ '"requestData": {' 
					+ '"TDHID": ' + pumpid + ', '
					+ '"TDHIndex": ' + pumptt + ', '
					+ '"pumpState": ' + cmd1 
					+ '}'
				+ '}';
	sendMsg(msgStr);
	
	//ajPage('S3ChangePlay.aspx',setjobplayRet,'pumpid='+pumpid+'&pumptt='+pumptt+'&playstatus='+(jobplays[pumptt] ? 0:1));
	//sendMsg('{ "clientId": 0, "commandCode": "506", "requestData": { "TDHID": ' + pumpid + ', "TDHIndex": ' + pumptt + ', "pumpState": ' + cmd1 + '} 	}');
}


/*
** setAllPumpPlay	: Play/Pause chế độ bán hàng của tất cả vòi bơm
** pumpid		: TDHID
** pumptt		: Số thứ tự vòi bơm
*/
function setAllPumpPlay() {
	if(!iswsopen){
		alert('Ca đã đóng!');
		return;
	}	
	var msgStr = '{'
				+ '"clientId": 0, '
				+ '"commandCode": "5101"'
				+ '}';
	sendMsg(msgStr);	
}

/*
** setpumpRet	: Kết quả - Play/Pause chế độ bán hàng của vòi bơm
** pumptt		: Số thứ tự vòi bơm
** str			: Chuỗi thông báo trả về
*/
function setjobplayRet(pumptt, str){
	if (str!="") {
		alert(str);
		return;
	}
	if(jobplays[pumptt])
		document.images['jobctrl'+pumptt].src='../img/play_icon.png';
	else
		document.images['jobctrl'+pumptt].src='../img/pause_icon.png';
		
	if (!showplaypause){
		document.images['jobctrl'+pumptt].style.display='none';
	}else{
		document.images['jobctrl'+pumptt].style.display='inline';
	}
	jobplays[pumptt] = !jobplays[pumptt];
	
	// contact PCE, because before jspumppendings[pumptt] was set to 0 if pending at EGAS (status=0) and pump is paused
	jspumppendings[pumptt] = 1;
}

/*
** cmdsale	: Tạo lệnh bán hàng
** pumpid	: TDHID
** amt		: Tổng tiền thanh toán
** price	: Đơn giá
** product	: ID hàng hóa
** pumptt	: Thứ tự vòi bơm
** litORamt	: 1 - loại lệnh theo lượng||2 - theo tiền 
*/
function cmdsale(pumpid,amt,price,product,pumptt,litORamt){
	console.log("Voi " + pumpid + ", amt=" + amt);
	if(amt=='') return;
	var amt1=removeSepr(amt);
	
	if(!isInteger(amt1)&&litORamt==2 || !isNumeric(amt1)&&litORamt==1){
		alert('Số ' + (litORamt==1 ? 'lít':'tiền') + ' không hợp lệ!');
		return;
	}

	var amt2=parseFloat(amt1);
	var qty2=0;
	if(litORamt==1){
		qty2=amt2;
		amt2=parseInt(amt2*price);
		g_tag('saleamt'+pumptt).value=insertSepr(amt2);
	}
	else{
		qty2 = jsrnd(amt2/price,2);
		g_tag('saleliter'+pumptt).value=jsformat(amt2/price,2);
	}

	if(amt2<5000 && amt2!=0 || amt2>9999999){
		alert('Số cho phép xuất trong khoảng 5.000đ - 9.999.999đ, hoặc 0: chưa xác định');
		return;
	}

	if(pumponoffs[pumptt]){
		//sendPCEreq('S3MgrStatus.aspx',loaddisplayRet,s3statusparams(pumpid,pumptt,'<%=CMD_S3_PUMP_JOB%>',<%=WShift%>)+'&amt='+amt2+'&price='+price+'&product='+product+'&cardno='+currCardNo);
		//'{ "clientId": 0, "commandCode": "506", "requestData": { "TDHID": ' + pumpid + ', "TDHIndex": ' + pumptt + ', "pumpState": ' + cmd1 + '} 	}'
		var CardNumber = "";
		var CardType = "";
		if(currCardNo != ""){
			var str=currCardNo.split('/');
			CardNumber=str[0];
			CardType=str[1];			
		}
		console.log("currCardNo " + currCardNo);
		console.log("CardNumber " + CardNumber);
		console.log("CardType " + CardType);
		
		var msgStr = '{'
			+ '"clientId": 0, '
			+ '"commandCode": "503", '
			+ '"requestData": { '
				+ '"BANKSVR": "' + BANKSRVs[pumptt] + '", '
				+ '"BankCode": null, '
				+ '"CardHolderName": null, '
				+ '"MerchantId": null, '
				+ '"PAYAmt": ' + amt2 + ', '
				+ '"PAYInfo": null, '
				+ '"PAYRefNo": null, '
				+ '"PAYReqDate": null, '
				+ '"PAYResDate": null, '
				+ '"POSIP": "' + POSIPs[pumptt] + '", '
				+ '"PAYState": ' + jobdefaultpaids[pumptt] + ', '
				+ '"Price": ' + price + ', '
				+ '"ProductId": ' + product + ', '
				+ '"ProductName": "' + productNames[pumptt] + '", '
				+ '"PumpSeri": "' + PumpSeris[pumptt] + '", '
				+ '"REQAmt": ' + amt2 + ', '
				+ '"REQQty": ' + qty2 + ', '
				+ '"ReqType": null, '
				+ '"ReqStr": null, '
				+ '"ResCode": null, '
				+ '"ResStr": null, '
				+ '"TDHID": ' + pumpid + ', '
				+ '"TerminalId": null, '
				+ '"T": 3, '
				+ '"CardNumber": "' + CardNumber + '", '
				+ '"CardType": "' + CardType + '", '
				+ '"StationNo": ' + stationNos[pumptt] + ', '
				+ '"Confirmed": true '
			+ '} '
		+ '} ';		
		sendMsg(msgStr);
		usecard();
	}
}

/*
** cmdcancel	: Hủy lệnh bán
** 
*/
function cmdcancel(logI,pumpid,amt,toconfirmYN){
	if(toconfirmYN==1){
		if(!confirm('Hủy lệnh (' + insertSepr(amt) + ' vnđ)?')) return;
	}
	
	var pumptt=searchpumptt(pumpid);
	var msgStr = '{'
	    + '"clientId": 0, '
	    + '"commandCode": "505", '
	    + '"requestData": {'
	        + '"S3ID": ' + logI + ', '
	        + '"TDHID": ' + pumpid
			+ '}'
		+ '}';
	sendMsg(msgStr);
	//sendPCEreq('S3MgrStatus.aspx',loaddisplayRet,s3statusparams(pumpid,pumptt,'<%=CMD_S3_PUMP_JOB_CANCEL%>',ws)+'&logI='+logI);
}

function cmdcancelRet(pumptt, str){
	if (str!="") {
		alert(str);
		return;
	}
}

/*
** setPaidState
*/
function setPaidState(a, b, c, d, e){
	var msgStr = '{'
				+ '"clientId": 0, '
				+ '"commandCode": "515", '
				+ '"requestData": {'
					+ '"TDHID": ' + a + ', '
					+ '"S3ID": ' + b + ', '
					+ '"PAYID": ' + c + ', '
					+ '"JobState": ' + d + ', '
					+ '"PAYState": ' + e 
					+ '}'
				+ '}';
	sendMsg(msgStr);
}

/*
** showcard
*/
var dialogto=null;
function showcard(pumptt, logI, payI,pumpid, jobst,x1,lineN, cardstr, dis){
	//pumptt is validonly for S3log already having cardnumber
	if(pumptt != -1){
		if(cardstr==null) cardstr
		showcardRet1(pumptt, lineN, "&nbsp;<a href=\"javascript: if(confirm('Hủy số thẻ cho giao dịch này?')) setCardNumber(" + pumpid + ", " + logI + ", " + payI + ", " + jobst + ", '', 0)\">Hủy</a>&nbsp;&nbsp; CardNumber:" + cardstr + ",&nbsp;Discount:" + dis, 'showcardClose()');
		if (dialogto!=null) clearTimeout(dialogto);
		dialogto = setTimeout('showcardClose()',2500);
		//ajPage('S3CardShow.aspx',showcardRet,'pumptt='+pumptt+'&logI='+logI+'&linenumber='+lineN);
	}
	else {
		if(currCardNo!=''){
			//Validate cardnumber:
			var pars = "cardno="+currCardNo;
				pars += "&pumptt=" + pumptt;
				pars += "&pumpid=" + pumpid;
				pars += "&logI=" + logI;
				pars += "&payI=" + payI;
				pars += "&jobst=" + jobst;
				pars += "&linenumber=" + lineN;
			ajPage('S3CardAssign1.aspx', cardassignRet1, pars);
			usecard();
		}
		else{
			g_tag('showcarddiv').style.background='#FFCC00';
			showcardRet1(searchpumptt(pumpid),lineN,'Bạn cần quẹt thẻ trước khi gán cho giao dịch!','showcardClose()');
		}
	}
}



function showPayMethod(pumpid, lineN,S3ID,PAYID,JobState,Amt){		
	var kbiPay=g_tag('showpaymethoddiv');
	var kbiBar=g_tag('showbarcodediv');		
	
	if(kbiPay.style.display=='none' && kbiBar.style.display=='none'){
		var kbi = kbiPay;
		kbi.style.display='inline';
		kbi.style.background='#FFCC00';
		var p=g_tag('pumptable'+searchpumptt(pumpid));
		kbi.style.top=elmTop(p)+28+parseInt(lineN)*20;
		kbi.style.left=elmLeft(p) + 20;
		if(JobState!=2){
			kbi.innerHTML="<img src='../img/closeOK.gif' class='imggo' onclick='showPayMethodClose()'> <font color='black'>" + NumFM(jsformat(Amt, 0), ",") + " </font> <input id='txtPayMethod' size=1 style='display:inline' onkeypress='if(isEnterOnly(event))validatePayMethod(" + lineN + "," + pumpid + "," + S3ID + "," + PAYID + "," + JobState + "," + Amt +")'> <font style='color:blue;font-weight:bold'>1: </font> <img onclick='showReadBarCode(" + pumpid + "," + lineN + "," + S3ID + "," + PAYID + "," + JobState + "," + Amt + ")' src='../img/momo-success.png' class='imggo'  /> <font style='color:blue;font-weight:bold'>2: </font> <img onclick='sendCMD517(" + S3ID + ")' src='../img/bcard1.jpg' class='imggo'  />"
		}
		else{
			kbi.innerHTML="<img src='../img/closeOK.gif' class='imggo' onclick='showPayMethodClose()'> <font color='white'> Lệnh bơm chưa kết thúc! </font>"
		}
		
		var kbi=g_tag('txtPayMethod');
		kbi.focus();		
	}
	else if(kbiPay.style.display=='inline'){
		kbiPay.style.display='none';		
	} 
	else if(kbiBar.style.display=='inline'){
		kbiBar.style.display='none';	
	}
}

function showReadBarCode(pumpid, lineN,S3ID,PAYID,JobState,Amt){		
	var kbi=g_tag('txtPayMethod');
	var div=g_tag('showpaymethoddiv');
	div.style.display='none';
	
	var kbi=g_tag('showbarcodediv');	
	console.log("showbarcodediv " + kbi.style.display + " ");
	if(kbi.style.display=='none'){
		kbi.style.display='inline';
		kbi.style.background='#ac2473';
		showReadBarCodeInLine(kbi,searchpumptt(pumpid),lineN,pumpid,S3ID,PAYID,JobState,Amt);
	}
	else{
		kbi.style.display='none';		
	}
}
function showReadBarCodeInLine(scd,pumptt,lineN,TDHID,S3ID,PAYID,JobState,Amt){
	console.log(lineN + "," + TDHID + "," + S3ID + "," + PAYID + "," + JobState + "," + Amt );
	var p=g_tag('pumptable'+pumptt);
	scd.style.top=elmTop(p)+28+parseInt(lineN)*20;
	scd.style.left=elmLeft(p) + 20;
	if(JobState == 2){
		scd.innerHTML="<img src='../img/closeOK.gif' class='imggo' onclick='showbarcodeClose()'> <font color='white'> Lệnh bơm chưa kết thúc! </font>"
	}
	else{
		scd.innerHTML="<img src='../img/closeOK.gif' class='imggo' onclick='showbarcodeClose()'> <font color='white'> QRCode MoMo: </font> <input id='txtReadBarCode' size=25 style='display:inline' onkeypress='if(isEnterOnly(event))validateBarCode(" + lineN + "," + TDHID + "," + S3ID + "," + PAYID + "," + JobState + "," + Amt +")'>"
		var kbi=g_tag('txtReadBarCode');
		kbi.focus();
	}
	
	
}

function validateBarCode(lineN, TDHID, S3ID, PAYID, JobState, Amt){
	var kbi=g_tag('txtReadBarCode');
	var div=g_tag('showbarcodediv');
	div.style.display='none';	
	sendCMD521(TDHID, S3ID, PAYID, JobState, Amt, kbi.value);
}

function validatePayMethod(lineN, TDHID, S3ID, PAYID, JobState, Amt){
	var kbi=g_tag('txtPayMethod');
	var div=g_tag('showpaymethoddiv');
	div.style.display='none';
	if(kbi.value == "1"){
		showReadBarCode(TDHID, lineN,S3ID,PAYID,JobState,Amt);
	}
	else if(kbi.value == "2"){
		console.log("Gọi đến máy POS");
		sendCMD517(S3ID)
	}		
}



function showbarcodeClose(){
	var a=g_tag('showbarcodediv');
	a.style.background='#E6E6E0';
	a.style.display='none';
}

function showPayMethodClose(){
	var a=g_tag('showpaymethoddiv');
	a.style.background='#E6E6E0';
	a.style.display='none';
}

function cardassignRet1(http){
	if (http){
		var str=http.responseText.split(',>');
		var pumptt=searchpumptt(str[1]);
		setCardNumber(str[1], str[2], str[3], str[4], str[5], str[6]);
		g_tag('showcarddiv').style.background='#00CCFF';
		showcardRet1(pumptt,str[7],"&nbsp;CardNumber:" + str[5] + ",&nbsp;Discount:" +  str[6],'refreshbocard('+str[1]+','+pumptt+')');
		setTimeout('refreshbocard('+str[1]+','+pumptt+')',2000);
	}
}

function showcardRet1(pumptt,linenumber,r,action1){
	var scd=g_tag('showcarddiv');
	scd.style.display='inline';
	var p=g_tag('pumptable'+pumptt);
	scd.style.top=elmTop(p)+28+parseInt(linenumber)*20;
	scd.style.left=elmLeft(p);
	scd.innerHTML="<img src='../img/closeOK.gif' class='imggo' onclick='" + action1 + "'> "+r;
}

function showcardRet(http){
	var str=http.responseText.split(',>');
	//alert(http.responseText);
	showcardRet1(str[0],str[1],str[2],'showcardClose()');
	setTimeout('showcardClose()',2500);
}

/*
** cardassignRet
*/
function cardassignRet(http){
	g_tag('showcarddiv').style.background='#00CCFF';
	var str=http.responseText.split(',>');
	var pumpid=str[0];
	var pumptt=searchpumptt(pumpid);
	showcardRet1(pumptt,str[1],str[2],'refreshbocard('+pumpid+','+pumptt+')');
	setTimeout('refreshbocard('+pumpid+','+pumptt+')',2000);
}

function cardassignRet(http){
	g_tag('showcarddiv').style.background='#00CCFF';
	var str=http.responseText.split(',>');
	var pumpid=str[0];
	var pumptt=searchpumptt(pumpid);
	showcardRet1(pumptt,str[1],str[2],'refreshbocard('+pumpid+','+pumptt+')');
	setTimeout('refreshbocard('+pumpid+','+pumptt+')',2000);
}



function revertMomo(TDHID, REQAmt, PAYID, S3ID, JobState, PAYRefNo){	
	sendCMD522(TDHID, REQAmt, PAYID, S3ID, JobState, PAYRefNo);
}


/*
** call 521 
*/
function sendCMD517(S3ID){
	var kbi=g_tag('txtPayMethod');
	var div=g_tag('showpaymethoddiv');
	div.style.display='none';
	var msgStr = '{'
				+ '"clientId": 0, '
				+ '"commandCode": "517", '
				+ '"requestData": {'
					+ '"S3ID": ' + S3ID 
					+ '}'
				+ '}';
	console.log(msgStr);
	sendMsg(msgStr);
}

/*
** call 521 
*/
function sendCMD521(TDHID, S3ID, PAYID, JobState, REQAmt, PaymentCode){
	var msgStr = '{'
				+ '"clientId": 0, '
				+ '"commandCode": "521", '
				+ '"requestData": {'
					+ '"TDHID": ' + TDHID + ', '
					+ '"S3ID": ' + S3ID + ', '
					+ '"PAYID": ' + PAYID + ', '
					+ '"JobState": ' + JobState + ', '
					+ '"REQAmt": ' + REQAmt + ', '
					+ '"PaymentCode": "' + PaymentCode 
					+ '"}'
				+ '}';
	console.log(msgStr);
	sendMsg(msgStr);
}

/*
** call 522 
*/
function sendCMD522(TDHID, REQAmt, PAYID, S3ID, JobState, PAYRefNo){
	var msgStr = '{'
				+ '"clientId": 0, '
				+ '"commandCode": "522", '
				+ '"requestData": {'
					+ '"TDHID": ' + TDHID + ', '
					+ '"REQAmt": ' + REQAmt + ', '
					+ '"PAYID": ' + PAYID + ', '
					+ '"S3ID": ' + S3ID + ', '
					+ '"JobState": ' + JobState + ', '
					+ '"PAYRefNo": "' + PAYRefNo
					+ '"}'
				+ '}';
	console.log(msgStr);
	sendMsg(msgStr);
}


/*
** setCardNumber
*/
function setCardNumber(TDHID, S3ID, PAYID, JobState, CardNumber, discount){
	var msgStr = '{'
				+ '"clientId": 0, '
				+ '"commandCode": "508", '
				+ '"requestData": {'
					+ '"TDHID": ' + TDHID + ', '
					+ '"S3ID": ' + S3ID + ', '
					+ '"PAYID": ' + PAYID + ', '
					+ '"JobState": ' + JobState + ', '
					+ '"CardNumber": ' + CardNumber + ', '
					+ '"discount": ' + discount
					+ '}'
				+ '}';
	console.log(msgStr);
	sendMsg(msgStr);
}

/*
** reloadConfig: 
*/
function reloadConfig(){
	var msgStr = '{'
	    + '"clientId": 0, '
	    + '"commandCode": "512", '
		+ '}';
	sendMsg(msgStr);
}

/*
** 
*/
function setWShift(a,b,c){
	var msgStr = '{'
	    + '"clientId": 0, '
	    + '"commandCode": "509", '
		+ '"requestData": {'
				+ '"wShiftId": ' + a + ", "
				+ '"wShiftName": "' + c + '", '
			+ '}'
		+ '}';
	console.log(msgStr);
	sendMsg(msgStr);
	s3wsviewclose();
}

/*
** 
*/
function getWShift(){
	var msgStr = '{'
	    + '"clientId": 0, '
	    + '"commandCode": "514", '
		+ '}';
	//console.log(msgStr);
	sendMsg(msgStr);
}
/*
** List of wshift
*/
function getListWS(){
	ajPage("../TDH/S3ListOfWS.aspx", getListWSRet, "");
	
	function getListWSRet(http){
		if(http){
			var str = http.responseText;
			if (str=="-1"){
				alert("Login expired");
				return ;
			}
			var disp=g_tag('S3sumdiv');
			disp.style.display='block';
			disp.style.top='34px';
			disp.style.left='5px';
			disp.innerHTML=str;
			g_tag('S3pumpgrp').style.display='none';
			
			//g_tag("").innerHTML = str;
		}
	}
}
/*
* Startup WebSocket:
*/
window.onload = function() {
	WebSocketConnect();
};

</script>

<%
RS=Nothing
CloseDB(Conn)
%>

</body>
</html>