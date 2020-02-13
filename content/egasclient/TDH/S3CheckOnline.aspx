<%@ Page LANGUAGE="VB" %>
<%@ import namespace="BosBase" %>
<%@ import namespace="BOSL" %>
<%@ import namespace="BOSG" %>

<%
    If checkLogin() <> "" Then
        Response.Write("0")
        Response.End()
    End If
%>